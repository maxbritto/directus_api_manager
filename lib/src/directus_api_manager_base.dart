import 'dart:async';
import 'dart:developer';

import 'package:http/http.dart';
import 'package:mutex/mutex.dart';
import 'package:reflectable/reflectable.dart';

import 'annotations.dart';
import 'cache/cache_entry.dart';
import 'directus_api.dart';
import 'filter.dart';
import 'idirectus_api_manager.dart';
import 'metadata_generator.dart';
import 'model/directus_api_error.dart';
import 'model/directus_data.dart';
import 'model/directus_file.dart';
import 'model/directus_item_creation_result.dart';
import 'model/directus_login_result.dart';
import 'model/directus_user.dart';
import 'sort_property.dart';

import 'package:meta/meta.dart';

abstract class ILocalDirectusCacheInterface {
  Future<CacheEntry?> getCacheEntry({required String key});
  Future<void> setCacheEntry(
      {required CacheEntry cacheEntry, required List<String> tags});
  Future<void> removeCacheEntry({required String key});
  Future<void> removeCacheEntriesWithTag({required String tag});
  Future<void> clearCache();
}

class PreparedRequest {
  final dynamic request;
  final List<String> tags;

  PreparedRequest({required this.request, this.tags = const []});
}

class DirectusApiManager implements IDirectusApiManager {
  final Client _client;
  final IDirectusAPI _api;
  final MetadataGenerator _metadataGenerator = MetadataGenerator();

  /// Fill this property to aumtomatically have a configurable local cache
  /// You can use the already provided [JsonCacheEngine] to have an already implemented cache.
  /// Or you can create your own engine by extending [ILocalDirectusCacheInterface] an providing an instance of your engine in this property
  final ILocalDirectusCacheInterface? cacheEngine;
  final Mutex _requestLock = Mutex();

  @visibleForTesting
  DirectusUser? cachedCurrentUser;

  @override
  bool get shouldRefreshToken => _api.shouldRefreshToken;
  @override
  String? get accessToken => _api.accessToken;

  @override
  String? get refreshToken => _api.refreshToken;
  set refreshToken(String? value) => _api.refreshToken = value;

  @override
  String get webSocketBaseUrl {
    // Remove last / if present
    String url = _api.baseUrl;
    if (url.endsWith("/")) {
      url = url.substring(0, _api.baseUrl.length - 1);
    }
    if (url.startsWith("http")) {
      return "${url.replaceFirst("http", "ws")}/websocket";
    }

    throw Exception("Invalid base URL");
  }

  @override
  String get baseUrl => _api.baseUrl;

  /// Creates a new DirectusApiManager instance.
  /// [baseURL] : The base URL of the Directus instance
  /// [httpClient] : The HTTP client to use. If not provided, a new [Client] will be created.
  /// [saveRefreshTokenCallback] : A function that will be called when a new refresh token is received from the server. The function should save the token for later use.
  /// [loadRefreshTokenCallback] : A function that will be called when a new refresh token is needed to be sent to the server. The function should return the saved token.
  DirectusApiManager(
      {required String baseURL,
      Client? httpClient,
      this.cacheEngine,
      IDirectusAPI? api,
      Future<void> Function(String)? saveRefreshTokenCallback,
      Future<String?> Function()? loadRefreshTokenCallback})
      : _client = httpClient ?? Client(),
        _api = api ??
            DirectusAPI(baseURL,
                saveRefreshTokenCallback: saveRefreshTokenCallback,
                loadRefreshTokenCallback: loadRefreshTokenCallback) {
    DirectusFile.baseUrl = baseURL;
  }

  /// Handles request preparation, sending and parsing.
  ///
  /// [prepareRequest] : A function that prepares and returns the HTTP request to send
  /// [parseResponse] : A function that receives the HTTP response from the server and returns the final function result.
  ///
  /// Returns the result from the [parseResponse] call.
  ///
  /// Throws an exception if [prepareRequest] returns null or not a [BaseRequest] object
  Future<ResponseType> _sendRequest<ResponseType>(
      {required PreparedRequest Function() prepareRequest,
      required ResponseType Function(Response) parseResponse,
      bool dependsOnToken = true,
      String? requestIdentifier,
      bool canUseCacheForResponse = false,
      bool canSaveResponseToCache = true,
      bool canUseOldCachedResponseAsFallback = true,
      Duration maxCacheAge = const Duration(days: 1)}) async {
    if (dependsOnToken) {
      await _requestLock.acquire();
      if (_api.shouldRefreshToken) {
        await tryAndRefreshToken();
      }
      _requestLock.release();
    }
    final preparedRequest = prepareRequest();
    final request = preparedRequest.request;
    BaseRequest r;
    if (request is Future<BaseRequest> || request is Future<BaseRequest?>) {
      r = await request;
    } else if (request is BaseRequest) {
      r = request;
    } else {
      log("_sendRequest error. Received request : $request");
      throw Exception("No valid request to send");
    }
    Response? response;
    String? cacheEntryKey;
    CacheEntry? cacheEntry;
    final cacheEngine = this.cacheEngine;
    if (cacheEngine != null) {
      cacheEntryKey = requestIdentifier ??
          "${r.method} ${r.url.host} ${r.url.path} ${r.url.hashCode}";
      if (canUseCacheForResponse) {
        cacheEntry = await cacheEngine.getCacheEntry(key: cacheEntryKey);
      }
    }
    if (cacheEntry != null && cacheEntry.validUntil.isAfter(DateTime.now())) {
      response = cacheEntry.toResponse();
    } else {
      try {
        final streamedResponse = await _client.send(r);
        response = await Response.fromStream(streamedResponse);

        if (canSaveResponseToCache &&
            cacheEngine != null &&
            cacheEntryKey != null &&
            response.statusCode >= 200 &&
            response.statusCode <= 299) {
          await cacheEngine.setCacheEntry(
              cacheEntry: CacheEntry.fromResponse(response,
                  key: cacheEntryKey, maxCacheAge: maxCacheAge),
              tags: preparedRequest.tags);
        }
      } catch (e) {
        if (canUseOldCachedResponseAsFallback) {
          if (cacheEntryKey != null) {
            cacheEntry ??= await cacheEngine?.getCacheEntry(key: cacheEntryKey);
          }
          if (cacheEntry != null) {
            response = cacheEntry.toResponse();
          }
        } else if (e is DirectusApiError) {
          rethrow;
        }
        if (response == null) {
          throw DirectusApiError(
              response: response, customMessage: e.toString());
        }
      }
    }
    return parseResponse(response);
  }

  Client get client => _client;

  @override
  Future<bool> hasLoggedInUser() async {
    final preparedRequest = _api.prepareRefreshTokenRequest();
    return await preparedRequest.request != null;
  }

  /// Tries to refresh the current auth token.
  /// This function is called automatically when a request is made and the token is expired.
  /// There is no need to call this function manually from outside the framework.
  @override
  Future<bool> tryAndRefreshToken() async {
    bool tokenRefreshed = false;
    try {
      try {
        tokenRefreshed = await _sendRequest(
            canSaveResponseToCache: false,
            canUseCacheForResponse: false,
            prepareRequest: _api.prepareRefreshTokenRequest,
            dependsOnToken: false,
            parseResponse: (response) =>
                _api.parseRefreshTokenResponse(response));
        if (tokenRefreshed == false) {
          logoutDirectusUser();
        }
      } catch (_) {}
    } catch (error) {
      print(error);
    }
    return tokenRefreshed;
  }

  /// Logs in a user with the given [username], [password] and optional [oneTimePassword].
  /// Returns a Future [DirectusLoginResult] object that contains the result of the login attempt.
  @override
  Future<DirectusLoginResult> loginDirectusUser(
      String username, String password,
      {String? oneTimePassword}) {
    discardCurrentUserCache();
    return _sendRequest(
        prepareRequest: () {
          return _api.prepareLoginRequest(username, password,
              oneTimePassword: oneTimePassword);
        },
        dependsOnToken: false,
        canSaveResponseToCache: false,
        parseResponse: (response) => _api.parseLoginResponse(response));
  }

  Future? _currentUserLock;
  static const String _currentUserRequestIdentifier = "currentDirectusUser";

  /// Returns all the information about the currently logged in user.
  /// Returns null if no user is logged in.
  /// [fields] : A comma separated list of fields to return. If not provided, all fields will be returned.
  @override
  Future<DirectusUser?> currentDirectusUser(
      {String fields = "*",
      bool canUseCacheForResponse = false,
      bool canSaveResponseToCache = true,
      bool canUseOldCachedResponseAsFallback = true,
      Duration maxCacheAge = const Duration(days: 1)}) async {
    final completer = Completer();
    final lock = _currentUserLock;
    if (lock != null) {
      await lock;
    }
    _currentUserLock = completer.future;

    try {
      if (cachedCurrentUser == null && await hasLoggedInUser()) {
        cachedCurrentUser = await _sendRequest(
            requestIdentifier: _currentUserRequestIdentifier,
            canSaveResponseToCache: canSaveResponseToCache,
            canUseCacheForResponse: canUseCacheForResponse,
            canUseOldCachedResponseAsFallback:
                canUseOldCachedResponseAsFallback,
            maxCacheAge: maxCacheAge,
            prepareRequest: () =>
                _api.prepareGetCurrentUserRequest(fields: fields),
            parseResponse: (response) {
              final parsedJson = _api.parseGetSpecificItemResponse(response);
              return DirectusUser(parsedJson);
            });
      }
    } catch (error) {
      print(error);
    }

    _currentUserLock = null;
    completer.complete();
    return cachedCurrentUser;
  }

  void discardCurrentUserCache() {
    cachedCurrentUser = null;
    clearCacheWithKey(_currentUserRequestIdentifier);
  }

  /// Fetches the Directus user with the given [userId].
  /// Returns null if no user with the given [userId] exists.
  /// [fields] : A comma separated list of fields to return. If not provided, all fields will be returned.
  @Deprecated("Use [getSpecificItem] instead")
  Future<DirectusUser?> getDirectusUser(String userId, {String fields = "*"}) {
    return getSpecificItem<DirectusUser>(id: userId, fields: fields);
  }

  @Deprecated("Use [findListOfItems] instead")
  Future<Iterable<DirectusUser>> getDirectusUserList(
      {Filter? filter,
      int limit = -1,
      String? fields,
      List<SortProperty>? sortBy,
      int? offset}) {
    return findListOfItems<DirectusUser>(
        filter: filter,
        limit: limit,
        fields: fields,
        sortBy: sortBy,
        offset: offset);
  }

  @Deprecated("Use [updateItem] instead")
  Future<DirectusUser> updateDirectusUser(
      {required DirectusUser updatedUser, String fields = "*"}) {
    return updateItem(objectToUpdate: updatedUser, fields: fields);
  }

  /// Sends a password request to the server for the provided [email].
  /// Your server must have email sending configured. It will send an email (from the template located at `/extensions/templates/password-reset.liquid`) to the user with a link to page to finalize his password reset.
  /// Your directus server already has a web page where the user will be sent to choose and save a new password.
  ///
  /// You can provide an optional [resetUrl] if you want to send the user to your own password reset web page.
  /// If you do, you have to add the url the `PASSWORD_RESET_URL_ALLOW_LIST` environment variable for it to be accepted.
  /// That page will receive the reset token by parameter so you can call the password change api from there.
  @override
  Future<bool> requestPasswordReset({required String email, String? resetUrl}) {
    return _sendRequest(
        canSaveResponseToCache: false,
        prepareRequest: () =>
            _api.preparePasswordResetRequest(email: email, resetUrl: resetUrl),
        parseResponse: _api.parseGenericBoolResponse);
  }

  /// Saves the new password chosen by the user after requesting a password reset using the [requestPasswordReset] function.
  ///
  /// Only use this API if you do not rely on directus standard password reset page.
  /// If you have your own custom password reset page, it will receive the refresh [token] as a GET parameter on load and the user will have to chose a [password] himself.
  @override
  Future<bool> confirmPasswordReset(
      {required String token, required String password}) {
    return _sendRequest(
        canSaveResponseToCache: false,
        prepareRequest: () => _api.preparePasswordChangeRequest(
            token: token, newPassword: password),
        parseResponse: _api.parseGenericBoolResponse);
  }

  @Deprecated("Use [createNewItem] instead")
  Future<DirectusItemCreationResult<DirectusUser>> createNewDirectusUser(
      {required String email,
      required String password,
      String? firstname,
      String? lastname,
      String? roleUUID,
      Map<String, dynamic> otherProperties = const {},
      required Type Function(dynamic json) createItemFunction}) {
    final newUser = DirectusUser.newDirectusUser(
        email: email,
        password: password,
        firstname: firstname,
        lastname: lastname,
        roleUUID: roleUUID,
        otherProperties: otherProperties);
    return createNewItem<DirectusUser>(objectToCreate: newUser);
  }

  @override
  Future<bool> logoutDirectusUser() async {
    final logoutRequest = _api.prepareLogoutRequest();
    var wasLoggedOut = true;
    if (logoutRequest != null) {
      try {
        wasLoggedOut = await _sendRequest(
            canSaveResponseToCache: false,
            prepareRequest: () => logoutRequest,
            dependsOnToken: false,
            parseResponse: (response) => _api.parseLogoutResponse(response));
      } catch (_) {}
    }
    cacheEngine?.clearCache();
    discardCurrentUserCache();
    return wasLoggedOut;
  }

  CollectionMetadata _collectionMetadataFromClass(ClassMirror collectionType) {
    final CollectionMetadata collectionMetadata = collectionType.metadata
            .firstWhere((element) => element is CollectionMetadata)
        as CollectionMetadata;

    return collectionMetadata;
  }

  @override
  Future<Iterable<Type>> findListOfItems<Type extends DirectusData>(
      {Filter? filter,
      List<SortProperty>? sortBy,
      String? fields,
      int? limit,
      int? offset,
      String? requestIdentifier,
      bool canUseCacheForResponse = false,
      bool canSaveResponseToCache = true,
      bool canUseOldCachedResponseAsFallback = true,

      /// Extra tags to associate with the cache entry
      List<String> extraTags = const [],
      Duration maxCacheAge = const Duration(days: 1)}) {
    final collectionClass = _metadataGenerator.getClassMirrorForType(Type);
    final collectionMetadata = _collectionMetadataFromClass(collectionClass);
    return _sendRequest(
        requestIdentifier: requestIdentifier,
        canUseCacheForResponse: canUseCacheForResponse,
        canSaveResponseToCache: canSaveResponseToCache,
        canUseOldCachedResponseAsFallback: canUseOldCachedResponseAsFallback,
        maxCacheAge: maxCacheAge,
        prepareRequest: () => _api.prepareGetListOfItemsRequest(
            endpointName: collectionMetadata.endpointName,
            endpointPrefix: collectionMetadata.endpointPrefix,
            filter: filter,
            sortBy: sortBy,
            fields: fields ?? collectionMetadata.defaultFields,
            limit: limit,
            offset: offset,
            tags: ["${collectionMetadata.endpointName}/list", ...extraTags]),
        parseResponse: (response) => _api
            .parseGetListOfItemsResponse(response)
            .map((json) => collectionClass.newInstance('', [json]) as Type));
  }

  @override
  Future<Type?> getSpecificItem<Type extends DirectusData>(
      {required String id,
      String? fields,
      String? requestIdentifier,
      bool canUseCacheForResponse = false,
      bool canSaveResponseToCache = true,
      bool canUseOldCachedResponseAsFallback = true,

      /// Extra tags to associate with the cache entry
      List<String> extraTags = const [],
      Duration maxCacheAge = const Duration(days: 1)}) {
    final specificClass = _metadataGenerator.getClassMirrorForType(Type);
    final collectionMetadata = _collectionMetadataFromClass(specificClass);
    return _sendRequest(
        requestIdentifier: requestIdentifier,
        canUseCacheForResponse: canUseCacheForResponse,
        canSaveResponseToCache: canSaveResponseToCache,
        canUseOldCachedResponseAsFallback: canUseOldCachedResponseAsFallback,
        maxCacheAge: maxCacheAge,
        prepareRequest: () => _api.prepareGetSpecificItemRequest(
            endpointName: collectionMetadata.endpointName,
            endpointPrefix: collectionMetadata.endpointPrefix,
            itemId: id,
            fields: fields ?? collectionMetadata.defaultFields,
            tags: ["${collectionMetadata.endpointName}/$id", ...extraTags]),
        parseResponse: (response) {
          Type? item;
          try {
            final parsedJson = _api.parseGetSpecificItemResponse(response);
            item = specificClass.newInstance('', [parsedJson]) as Type;
          } catch (e) {
            log("Error while parsing response: $e");
          }
          return item;
        });
  }

  @override
  Future<DirectusItemCreationResult<Type>>
      createNewItem<Type extends DirectusData>({
    required Type objectToCreate,
    String? fields,

    /// Extra tags to clear from the cache
    List<String> extraTagsToClear = const [],
  }) async {
    final specificClass = _metadataGenerator.getClassMirrorForType(Type);
    final collectionMetadata = _collectionMetadataFromClass(specificClass);
    final DirectusItemCreationResult<Type> result = await _sendRequest(
        canSaveResponseToCache: false,
        prepareRequest: () => _api.prepareCreateNewItemRequest(
            endpointName: collectionMetadata.endpointName,
            endpointPrefix: collectionMetadata.endpointPrefix,
            objectData: objectToCreate.mapForObjectCreation(),
            fields: fields ?? collectionMetadata.defaultFields),
        parseResponse: (response) {
          return DirectusItemCreationResult.fromDirectus(
              api: _api, response: response, classMirror: specificClass);
        });
    if (cacheEngine != null) {
      await removeCacheEntriesWithTags(
          ["${collectionMetadata.endpointName}/list", ...extraTagsToClear]);
    }
    return result;
  }

  @override
  Future<DirectusItemCreationResult<Type>>
      createMultipleItems<Type extends DirectusData>({
    String? fields,
    required Iterable<Type> objectList,

    /// Extra tags to clear from the cache
    List<String> extraTags = const [],
  }) async {
    if (objectList.isEmpty) {
      throw Exception("objectList can not be empty");
    }
    final specificClass = _metadataGenerator.getClassMirrorForType(Type);
    final collectionMetadata = _collectionMetadataFromClass(specificClass);
    final List<Map<String, dynamic>> objectListData =
        objectList.map(((object) => object.mapForObjectCreation())).toList();
    final DirectusItemCreationResult<Type> result = await _sendRequest(
        canSaveResponseToCache: false,
        prepareRequest: () => _api.prepareCreateNewItemRequest(
            endpointName: collectionMetadata.endpointName,
            endpointPrefix: collectionMetadata.endpointPrefix,
            objectData: objectListData,
            fields: fields ?? collectionMetadata.defaultFields),
        parseResponse: (response) {
          switch (response.statusCode) {
            case 200:
              final DirectusItemCreationResult<Type> creationResult =
                  DirectusItemCreationResult(isSuccess: true);
              final listJson = _api.parseCreateNewItemResponse(response);
              if (listJson is List) {
                for (final itemJson in listJson) {
                  creationResult.createdItemList
                      .add(specificClass.newInstance('', [itemJson]) as Type);
                }
              }
              return creationResult;
            case 204:
              return DirectusItemCreationResult(isSuccess: true);
            default:
              return DirectusItemCreationResult(
                  isSuccess: false,
                  error: DirectusApiError(response: response));
          }
        });
    if (cacheEngine != null) {
      await removeCacheEntriesWithTags(
          ["${collectionMetadata.endpointName}/list", ...extraTags]);
    }
    return result;
  }

  /// Update the item with the given [objectToUpdate]. You have to specify a Type which extends DirectusData.
  ///
  /// By default it will return an object of the same type as the one you provided with the default fields you specified in the [CollectionMetadata] annotation. You change the fields by providing a [fields] parameter.
  ///
  ///If [force] is true, the update will be done even if the object does not need saving,
  ///otherwise it will only send the modified data for this object.
  @override
  Future<Type> updateItem<Type extends DirectusData>(
      {required Type objectToUpdate,
      String? fields,

      /// Extra tags to clear from the cache
      List<String> extraTagsToClear = const [],
      bool force = false}) async {
    final specificClass = _metadataGenerator.getClassMirrorForType(Type);
    final collectionMetadata = _collectionMetadataFromClass(specificClass);
    Type? updatedObjectReturnedFromServer;
    try {
      if (objectToUpdate.needsSaving || force) {
        final Map<String, dynamic> objectData = force
            ? Map.from(objectToUpdate.getRawData())
            : Map.from(objectToUpdate.updatedProperties);

        // Remove field that are not in the default update fields if necessary
        if (collectionMetadata.defaultUpdateFields != null &&
            collectionMetadata.defaultUpdateFields! != "*") {
          for (final field in objectData.keys.toList()) {
            if (!collectionMetadata.defaultUpdateFields!.contains(field) &&
                field != "id") {
              objectData.remove(field);
            }
          }
        }

        final Map<String, dynamic> updatedData = await _sendRequest(
            canSaveResponseToCache: false,
            prepareRequest: () => _api.prepareUpdateItemRequest(
                endpointName: collectionMetadata.endpointName,
                endpointPrefix: collectionMetadata.endpointPrefix,
                itemId: objectToUpdate.id!,
                objectData: objectData,
                fields: fields ??
                    collectionMetadata.defaultUpdateFields ??
                    collectionMetadata.defaultFields),
            parseResponse: (response) {
              final parsedJson = _api.parseUpdateItemResponse(response);
              return parsedJson;
            });

        // Merge the updated data with the original data
        final Map<String, dynamic> fullUpdatedData = {
          ...objectToUpdate.getRawData(),
          ...updatedData
        };

        // Return a new object with the updated data
        updatedObjectReturnedFromServer =
            specificClass.newInstance('', [fullUpdatedData]) as Type;
        if (updatedObjectReturnedFromServer is DirectusUser) {
          final currentUser = cachedCurrentUser;
          if (currentUser != null &&
              currentUser.id == updatedObjectReturnedFromServer.id) {
            discardCurrentUserCache();
            cachedCurrentUser = updatedObjectReturnedFromServer;
          }
        }
        if (cacheEngine != null) {
          await removeCacheEntriesWithTags([
            "${collectionMetadata.endpointName}/${objectToUpdate.id}",
            "${collectionMetadata.endpointName}/list",
            ...extraTagsToClear
          ]);
        }
      }
    } catch (error) {
      log("Error while updating item: $error");
      rethrow;
    }

    return updatedObjectReturnedFromServer ?? objectToUpdate;
  }

  @override
  Future<bool> deleteItem<Type extends DirectusData>({
    required String objectId,
    bool mustBeAuthenticated = true,

    /// Extra tags to clear from the cache
    List<String> extraTagsToClear = const [],
  }) async {
    final specificClass = _metadataGenerator.getClassMirrorForType(Type);
    final collectionMetadata = _collectionMetadataFromClass(specificClass);
    try {
      final wasDeleted = await _sendRequest(
          canSaveResponseToCache: false,
          prepareRequest: () => _api.prepareDeleteItemRequest(
              endpointName: collectionMetadata.endpointName,
              endpointPrefix: collectionMetadata.endpointPrefix,
              itemId: objectId,
              mustBeAuthenticated: mustBeAuthenticated),
          parseResponse: (response) => _api.parseGenericBoolResponse(response));
      if (cacheEngine != null) {
        await removeCacheEntriesWithTags([
          "${collectionMetadata.endpointName}/$objectId",
          "${collectionMetadata.endpointName}/list",
          ...extraTagsToClear
        ]);
      }
      return wasDeleted;
    } catch (error) {
      return Future.value(false);
    }
  }

  @override
  Future<bool> deleteMultipleItems<Type extends DirectusData>({
    required Iterable<dynamic> objectIdsToDelete,
    bool mustBeAuthenticated = true,

    /// Extra tags to clear from the cache
    List<String> extraTagsToClear = const [],
  }) async {
    if (objectIdsToDelete.isEmpty) {
      throw Exception("objectIdsToDelete can not be empty");
    }
    final specificClass = _metadataGenerator.getClassMirrorForType(Type);
    final collectionMetadata = _collectionMetadataFromClass(specificClass);
    final wereDeleted = await _sendRequest(
        canSaveResponseToCache: false,
        prepareRequest: () => _api.prepareDeleteMultipleItemRequest(
            endpointName: collectionMetadata.endpointName,
            endpointPrefix: collectionMetadata.endpointPrefix,
            itemIdList: objectIdsToDelete.toList(),
            mustBeAuthenticated: mustBeAuthenticated),
        parseResponse: (response) => _api.parseGenericBoolResponse(response));
    if (cacheEngine != null) {
      await removeCacheEntriesWithTags([
        "${collectionMetadata.endpointName}/list",
        ...objectIdsToDelete
            .map((objectId) => "${collectionMetadata.endpointName}/$objectId"),
        ...extraTagsToClear
      ]);
    }
    return wereDeleted;
  }

  @Deprecated("Use [deleteItem] instead")
  Future<bool> deleteUser(
      {required DirectusUser user, bool mustBeAuthenticated = true}) {
    final id = user.id;
    if (id == null) {
      throw Exception("User ID can not be null when trying to delete an user");
    }
    return deleteItem<DirectusUser>(objectId: id);
  }

  @override
  Future<DirectusFile> uploadFileFromUrl(
      {required String remoteUrl, String? title, String? folder}) async {
    return _sendRequest(
        canSaveResponseToCache: false,
        prepareRequest: () => _api.prepareFileImportRequest(
            url: remoteUrl, title: title, folder: folder),
        parseResponse: (response) => _api.parseFileUploadResponse(response));
  }

  @override
  Future<DirectusFile> uploadFile(
      {required List<int> fileBytes,
      required String filename,
      String? title,
      String? contentType,
      String? folder,
      String storage = "local",
      Map<String, dynamic>? additionalFields}) {
    return _sendRequest(
        canSaveResponseToCache: false,
        prepareRequest: () => _api.prepareNewFileUploadRequest(
            fileBytes: fileBytes,
            filename: filename,
            title: title,
            contentType: contentType,
            folder: folder,
            storage: storage,
            additionalFields: additionalFields),
        parseResponse: (response) => _api.parseFileUploadResponse(response));
  }

  @override
  Future<DirectusFile> updateExistingFile(
      {required List<int> fileBytes,
      required String fileId,
      required String filename,
      String? contentType}) {
    return _sendRequest(
        canSaveResponseToCache: false,
        prepareRequest: () => _api.prepareUpdateFileRequest(
            fileId: fileId,
            filename: filename,
            fileBytes: fileBytes,
            contentType: contentType),
        parseResponse: (response) => _api.parseFileUploadResponse(response));
  }

  @override
  Future<bool> deleteFile({required String fileId}) {
    return _sendRequest(
        canSaveResponseToCache: false,
        prepareRequest: () => _api.prepareFileDeleteRequest(fileId: fileId),
        parseResponse: (response) => _api.parseGenericBoolResponse(response));
  }

  @override
  Future<T> sendRequestToEndpoint<T>(
      {required BaseRequest Function() prepareRequest,
      required T Function(Response) jsonConverter,
      String? requestIdentifier,
      bool canUseCacheForResponse = false,
      bool canSaveResponseToCache = true,
      bool canUseOldCachedResponseAsFallback = true,

      /// Extra tags to associate with the cache entry
      List<String> extraTagsToAssociate = const [],

      /// Extra tags to clear from the cache if this request succeeds
      List<String> extraTagsToClear = const [],
      Duration maxCacheAge = const Duration(days: 1)}) async {
    final T result = await _sendRequest(
        requestIdentifier: requestIdentifier,
        canUseCacheForResponse: canUseCacheForResponse,
        canSaveResponseToCache: canSaveResponseToCache,
        canUseOldCachedResponseAsFallback: canUseOldCachedResponseAsFallback,
        maxCacheAge: maxCacheAge,
        prepareRequest: () {
          final request = prepareRequest();
          return PreparedRequest(
              request: _api.authenticateRequest(request),
              tags: ["customRequest", ...extraTagsToAssociate]);
        },
        parseResponse: (response) => jsonConverter(response));
    if (cacheEngine != null && extraTagsToClear.isNotEmpty) {
      await removeCacheEntriesWithTags(extraTagsToClear);
    }
    return result;
  }

  String convertPathToFullURL({required String path}) {
    return _api.convertPathToFullURL(path: path);
  }

  String? get currentAuthToken => _api.currentAuthToken;

  Future<void> clearCacheWithKey(String cacheEntryKey) async {
    try {
      await cacheEngine?.removeCacheEntry(key: cacheEntryKey);
    } catch (_) {}
  }

  /// Removes from cache any object with any of the given [tags].
  Future<void> removeCacheEntriesWithTags(List<String> tags) async {
    for (final tag in tags) {
      await cacheEngine?.removeCacheEntriesWithTag(tag: tag);
    }
  }

  /// Clears the cache for the object with the given [id].
  /// It is important to specify the type of the object with the [Type] annotation when calling the function.
  /// Example : clearCacheForObjectWithId<DirectusUser>(id);
  /// If you already have a full object of that type prefer using [clearCacheForObject] instead that will automatically infer the type of the received object.
  Future<void> clearCacheForObjectWithId<Type extends DirectusData>(
      dynamic id) {
    final specificClass = _metadataGenerator.getClassMirrorForType(Type);
    final collectionMetadata = _collectionMetadataFromClass(specificClass);
    final currentUserIsTheTarget =
        Type == DirectusUser && cachedCurrentUser?.id == id;
    if (currentUserIsTheTarget) {
      discardCurrentUserCache();
    }
    return removeCacheEntriesWithTags([
      "${collectionMetadata.endpointName}/$id",
      "${collectionMetadata.endpointName}/list"
    ]);
  }

  /// Clears the cache for the object with the given [object].
  Future<void> clearCacheForObject<Type extends DirectusData>(Type object) {
    return clearCacheForObjectWithId<Type>(object.id);
  }

  @override
  Future<bool> registerDirectusUser(
      {required String email,
      required String password,
      String? firstname,
      String? lastname}) {
    return _sendRequest(
        canSaveResponseToCache: false,
        prepareRequest: () => _api.prepareRegisterUserRequest(
            email: email,
            password: password,
            firstname: firstname,
            lastname: lastname),
        parseResponse: _api.parseGenericBoolResponse);
  }
}
