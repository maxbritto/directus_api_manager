import 'dart:async';

import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:directus_api_manager/src/directus_api.dart';
import 'package:http/http.dart';

class DirectusApiManager {
  final Client _client;
  final IDirectusAPI _api;

  DirectusUser? _currentUser;

  DirectusApiManager(
      {required String baseURL,
      required Client httpClient,
      Future<void> Function(String)? saveRefreshTokenCallback,
      Future<String?> Function()? loadRefreshTokenCallback})
      : _client = httpClient,
        _api = DirectusAPI(baseURL,
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
      {required dynamic Function() prepareRequest,
      required ResponseType Function(Response) parseResponse,
      bool dependsOnToken = true}) async {
    if (dependsOnToken && _api.shouldRefreshToken) {
      await _tryAndRefreshToken();
    }
    final request = prepareRequest();
    BaseRequest r;
    if (request is Future<BaseRequest> || request is Future<BaseRequest?>) {
      r = await request;
    } else if (request is BaseRequest) {
      r = request;
    } else {
      print("_sendRequest error. Received request : $request");
      throw Exception("No valid request to send");
    }
    final streamedResponse = await _client.send(r);
    final response = await Response.fromStream(streamedResponse);
    return parseResponse(response);
  }

  Client get client => _client;

  Future<bool> hasLoggedInUser() async {
    return await _api.prepareRefreshTokenRequest() != null;
  }

  Future? _refreshTokenLock;
  Future<bool> _tryAndRefreshToken() async {
    bool tokenRefreshed = false;
    final completer = Completer();
    final lock = _refreshTokenLock;
    if (lock != null) {
      await lock;
    }
    _refreshTokenLock = completer.future;

    try {
      try {
        tokenRefreshed = await _sendRequest(
            prepareRequest: () async => await _api.prepareRefreshTokenRequest(),
            dependsOnToken: false,
            parseResponse: (response) =>
                _api.parseRefreshTokenResponse(response));
      } catch (_) {}
    } catch (error) {
      print(error);
    }

    _refreshTokenLock = null;
    completer.complete();
    return tokenRefreshed;
  }

  Future<DirectusLoginResult> loginDirectusUser(
      String username, String password) {
    discardCurrentUserCache();
    return _sendRequest(
        prepareRequest: () {
          return _api.prepareLoginRequest(username, password);
        },
        dependsOnToken: false,
        parseResponse: (response) => _api.parseLoginResponse(response));
  }

  Future? _currentUserLock;
  Future<DirectusUser?> currentDirectusUser({String fields = "*"}) async {
    final completer = Completer();
    final lock = _currentUserLock;
    if (lock != null) {
      await lock;
    }
    _currentUserLock = completer.future;

    try {
      if (_currentUser == null && await hasLoggedInUser()) {
        _currentUser = await _sendRequest(
            prepareRequest: () =>
                _api.prepareGetCurrentUserRequest(fields: fields),
            parseResponse: (response) => _api.parseUserResponse(response));
      }
    } catch (error) {
      print(error);
    }

    _currentUserLock = null;
    completer.complete();
    return _currentUser;
  }

  void discardCurrentUserCache() {
    _currentUser = null;
  }

  Future<DirectusUser?> getDirectusUser(String userId, {String fields = "*"}) {
    return _sendRequest(
        prepareRequest: () =>
            _api.prepareGetSpecificUserRequest(userId, fields: fields),
        parseResponse: (response) => _api.parseUserResponse(response));
  }

  Future<Iterable<DirectusUser>> getDirectusUserList(
      {Filter? filter, int limit = -1}) {
    return _sendRequest(
        prepareRequest: () =>
            _api.prepareGetUserListRequest(filter: filter, limit: limit),
        parseResponse: (response) => _api.parseUserListResponse(response));
  }

  Future<DirectusUser> updateDirectusUser({required DirectusUser updatedUser}) {
    return _sendRequest(
        prepareRequest: () => _api.prepareUpdateUserRequest(updatedUser),
        parseResponse: (response) => _api.parseUserResponse(response));
  }

  /// Sends a password request to the server for the provided [email].
  /// Your server must have email sending configured. It will send an email (from the template located at `/extensions/templates/password-reset.liquid`) to the user with a link to page to finalize his password reset.
  /// Your directus server already has a web page where the user will be sent to choose and save a new password.
  ///
  /// You can provide an optional [resetUrl] if you want to send the user to your own password reset web page.
  /// If you do, you have to add the url the `PASSWORD_RESET_URL_ALLOW_LIST` environment variable for it to be accepted.
  /// That page will receive the reset token by parameter so you can call the password change api from there.
  Future<bool> requestPasswordReset({required String email, String? resetUrl}) {
    return _sendRequest(
        prepareRequest: () =>
            _api.preparePasswordResetRequest(email: email, resetUrl: resetUrl),
        parseResponse: _api.parseGenericBoolResponse);
  }

  /// Saves the new password chosen by the user after requesting a password reset using the [requestPasswordReset] function.
  ///
  /// Only use this API if you do not rely on directus standard password reset page.
  /// If you have your own custom password reset page, it will receive the refresh [token] as a GET parameter on load and the user will have to chose a [password] himself.
  Future<bool> confirmPasswordReset(
      {required String token, required String password}) {
    return _sendRequest(
        prepareRequest: () => _api.preparePasswordChangeRequest(
            token: token, newPassword: password),
        parseResponse: _api.parseGenericBoolResponse);
  }

  Future<DirectusItemCreationResult<Type>>
      createNewDirectusUser<Type extends DirectusUser>(
          {required String email,
          required String password,
          String? firstname,
          String? lastname,
          String? roleUUID,
          Map<String, dynamic> otherProperties = const {},
          required Type Function(dynamic json) createItemFunction}) {
    return _sendRequest(
        prepareRequest: () => _api.prepareCreateUserRequest(
            email: email,
            password: password,
            firstname: firstname,
            lastname: lastname,
            roleUUID: roleUUID,
            otherProperties: otherProperties),
        parseResponse: (response) {
          final DirectusItemCreationResult<Type> creationResult =
              DirectusItemCreationResult(
                  isSuccess:
                      response.statusCode == 200 || response.statusCode == 204);
          if (response.statusCode != 204) {
            creationResult.createdItemList
                .add(createItemFunction(_api.parseUserResponse(response)));
          }
          return creationResult;
        });
  }

  Future<bool> logoutDirectusUser() async {
    discardCurrentUserCache();
    var wasLoggedOut = false;
    try {
      wasLoggedOut = await _sendRequest(
          prepareRequest: () => _api.prepareLogoutRequest(),
          dependsOnToken: false,
          parseResponse: (response) => _api.parseLogoutResponse(response));
    } catch (_) {}
    if (wasLoggedOut) {
      _currentUser = null;
    }
    return wasLoggedOut;
  }

  Future<Iterable<Type>> findListOfItems<Type extends DirectusItem>(
      {required String name,
      Filter? filter,
      List<SortProperty>? sortBy,
      String fields = "*",
      int? limit,
      int? offset,
      required Type Function(dynamic json) createItemFunction}) {
    return _sendRequest(
        prepareRequest: () => _api.prepareGetListOfItemsRequest(name,
            filter: filter,
            sortBy: sortBy,
            fields: fields,
            limit: limit,
            offset: offset),
        parseResponse: (response) =>
            _api.parseGetListOfItemsResponse(response).map(createItemFunction));
  }

  Future<Type> getSpecificItem<Type extends DirectusItem>(
      {required String name,
      required String id,
      String fields = "*",
      required Type Function(dynamic json) createItemFunction}) {
    return _sendRequest(
        prepareRequest: () =>
            _api.prepareGetSpecificItemRequest(name, id, fields: fields),
        parseResponse: (response) =>
            createItemFunction(_api.parseGetSpecificItemResponse(response)));
  }

  Future<DirectusItemCreationResult<Type>>
      createNewItem<Type extends DirectusItem>(
          {required Type objectToCreate,
          required Type Function(dynamic json) createItemFunction}) {
    return _sendRequest(
        prepareRequest: () => _api.prepareCreateNewItemRequest(
            objectToCreate.endpointName, objectToCreate.toMap()),
        parseResponse: (response) {
          final DirectusItemCreationResult<Type> creationResult =
              DirectusItemCreationResult(
                  isSuccess:
                      response.statusCode == 200 || response.statusCode == 204);

          if (response.statusCode == 200) {
            creationResult.createdItemList.add(
                createItemFunction(_api.parseCreateNewItemResponse(response)));
          }
          return creationResult;
        });
  }

  Future<DirectusItemCreationResult<Type>>
      createMultipleItems<Type extends DirectusItem>(
          {String fields = "*",
          required Iterable<Type> objectList,
          required Type Function(dynamic json) createItemFunction}) {
    if (objectList.isEmpty) {
      throw Exception("objectList can not be empty");
    }
    final String endPoint = objectList.first.endpointName;
    final List<Map<String, dynamic>> objectListData =
        objectList.map(((object) => object.toMap())).toList();
    return _sendRequest(
        prepareRequest: () => _api.prepareCreateNewItemRequest(
            endPoint, objectListData,
            fields: fields),
        parseResponse: (response) {
          switch (response.statusCode) {
            case 200:
              final DirectusItemCreationResult<Type> creationResult =
                  DirectusItemCreationResult(isSuccess: true);
              final listJson = _api.parseCreateNewItemResponse(response);
              if (listJson is List) {
                for (final itemJson in listJson) {
                  creationResult.createdItemList
                      .add(createItemFunction(itemJson));
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
  }

  Future<Type> updateItem<Type extends DirectusItem>(
      {required Type objectToUpdate,
      required Type Function(dynamic json) updateItemFunction,
      String fields = "*"}) {
    try {
      if (objectToUpdate.needsSaving) {
        return _sendRequest(
            prepareRequest: () => _api.prepareUpdateItemRequest(
                objectToUpdate.endpointName,
                objectToUpdate.id!,
                objectToUpdate.updatedProperties,
                fields: fields),
            parseResponse: (response) =>
                updateItemFunction(_api.parseUpdateItemResponse(response)));
      }
    } catch (error) {
      if (objectToUpdate.id == null) {
        throw (Exception("Item ID can not be null"));
      }
    }

    return Future.value(objectToUpdate);
  }

  Future<bool> deleteItem<Type extends DirectusItem>(
      {required Type objectToDelete, bool mustBeAuthenticated = true}) {
    try {
      return _sendRequest(
          prepareRequest: () => _api.prepareDeleteItemRequest(
              objectToDelete.endpointName,
              objectToDelete.id!,
              mustBeAuthenticated),
          parseResponse: (response) => _api.parseGenericBoolResponse(response));
    } catch (error) {
      if (objectToDelete.id == null) {
        throw Exception("The item ID can not be null");
      }
      return Future.value(false);
    }
  }

  Future<bool> deleteMultipleItems<Type extends DirectusItem>(
      {required Iterable<Type> objectListToDelete,
      bool mustBeAuthenticated = true}) {
    if (objectListToDelete.isEmpty) {
      throw Exception("objectListToDelete can not be empty");
    }
    final String endPoint = objectListToDelete.first.endpointName;
    final List<dynamic> objectIdList = objectListToDelete.map(
      ((object) {
        if (object.id != null) {
          return object.id;
        }
      }),
    ).toList();
    return _sendRequest(
        prepareRequest: () => _api.prepareDeleteMultipleItemRequest(
            endPoint, objectIdList, mustBeAuthenticated),
        parseResponse: (response) => _api.parseGenericBoolResponse(response));
  }

  Future<bool> deleteUser(
      {required DirectusUser user, bool mustBeAuthenticated = true}) {
    return _sendRequest(
        prepareRequest: () =>
            _api.prepareDeleteUserRequest(user, mustBeAuthenticated),
        parseResponse: (response) => _api.parseDeleteUserResponse(response));
  }

  Future<DirectusFile> uploadFileFromUrl(
      {required String remoteUrl, String? title}) async {
    return _sendRequest(
        prepareRequest: () =>
            _api.prepareFileImportRequest(url: remoteUrl, title: title),
        parseResponse: (response) => _api.parseFileUploadResponse(response));
  }

  Future<DirectusFile> uploadFile(
      {required List<int> fileBytes,
      required String filename,
      String? title,
      String? contentType}) {
    return _sendRequest(
        prepareRequest: () => _api.prepareNewFileUploadRequest(
            fileBytes: fileBytes,
            filename: filename,
            title: title,
            contentType: contentType),
        parseResponse: (response) => _api.parseFileUploadResponse(response));
  }

  Future<DirectusFile> updateExistingFile(
      {required List<int> fileBytes,
      required String fileId,
      required String filename,
      String? contentType}) {
    return _sendRequest(
        prepareRequest: () => _api.prepareUpdateFileRequest(
            fileId: fileId,
            filename: filename,
            fileBytes: fileBytes,
            contentType: contentType),
        parseResponse: (response) => _api.parseFileUploadResponse(response));
  }

  Future<T> sendRequestToEndpoint<T>(
      {required BaseRequest Function() prepareRequest,
      required T Function(Response) jsonConverter}) {
    return _sendRequest(
        prepareRequest: () {
          final request = prepareRequest();
          return _api.authenticateRequest(request);
        },
        parseResponse: (response) => jsonConverter(response));
  }

  String convertPathToFullURL({required String path}) {
    return _api.convertPathToFullURL(path: path);
  }

  String? get currentAuthToken => _api.currentAuthToken;
}
