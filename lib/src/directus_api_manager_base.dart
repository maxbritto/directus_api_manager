import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:directus_api_manager/src/directus_api.dart';
import 'package:http/http.dart';

class DirectusApiManager {
  final Client _client;
  final IDirectusAPI _api;

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

  Future<bool> _tryAndRefreshToken() async {
    bool tokenRefreshed = false;

    try {
      tokenRefreshed = await _sendRequest(
          prepareRequest: () async => await _api.prepareRefreshTokenRequest(),
          dependsOnToken: false,
          parseResponse: (response) =>
              _api.parseRefreshTokenResponse(response));
    } catch (_) {}

    return tokenRefreshed;
  }

  Future<DirectusLoginResult> loginDirectusUser(
      String username, String password) {
    return _sendRequest(
        prepareRequest: () {
          return _api.prepareLoginRequest(username, password);
        },
        dependsOnToken: false,
        parseResponse: (response) => _api.parseLoginResponse(response));
  }

  Future<DirectusUser?> currentDirectusUser() async {
    if (await hasLoggedInUser()) {
      return _sendRequest(
          prepareRequest: () => _api.prepareGetCurrentUserRequest(),
          parseResponse: (response) => _api.parseUserResponse(response));
    } else {
      return Future.value(null);
    }
  }

  Future<DirectusUser?> getDirectusUser(String userId, {String fields = "*"}) {
    return _sendRequest(
        prepareRequest: () =>
            _api.prepareGetSpecificUserRequest(userId, fields: fields),
        parseResponse: (response) => _api.parseUserResponse(response));
  }

  Future<Iterable<DirectusUser>> getDirectusUserList() {
    return _sendRequest(
        prepareRequest: () => _api.prepareGetUserListRequest(),
        parseResponse: (response) => _api.parseUserListResponse(response));
  }

  Future<DirectusUser> updateDirectusUser({required DirectusUser updatedUser}) {
    return _sendRequest(
        prepareRequest: () => _api.prepareUpdateUserRequest(updatedUser),
        parseResponse: (response) => _api.parseUserResponse(response));
  }

  Future<DirectusUser> createNewDirectusUser(
      {required String email,
      required String password,
      String? firstname,
      String? lastname,
      String? roleUUID,
      Map<String, dynamic> otherProperties = const {}}) {
    return _sendRequest(
        prepareRequest: () => _api.prepareCreateUserRequest(
            email: email,
            password: password,
            firstname: firstname,
            lastname: lastname,
            roleUUID: roleUUID,
            otherProperties: otherProperties),
        parseResponse: (response) => _api.parseUserResponse(response));
  }

  Future<bool> logoutDirectusUser() {
    try {
      return _sendRequest(
          prepareRequest: () => _api.prepareLogoutRequest(),
          dependsOnToken: false,
          parseResponse: (response) => _api.parseLogoutResponse(response));
    } catch (_) {
      return Future.value(false);
    }
  }

  Future<Iterable<Type>> findListOfItems<Type>(
      {required String name,
      Filter? filter,
      List<SortProperty>? sortBy,
      required Type Function(dynamic) jsonConverter}) {
    return _sendRequest(
        prepareRequest: () => _api.prepareGetListOfItemsRequest(name,
            filter: filter, sortBy: sortBy),
        parseResponse: (response) => _api
            .parseGetListOfItemsResponse(response)
            .map((itemAsJsonObject) => jsonConverter(itemAsJsonObject)));
  }

  Future<Type> getSpecificItem<Type>(
      {required String name,
      required String id,
      required Type Function(dynamic) jsonConverter}) {
    return _sendRequest(
        prepareRequest: () => _api.prepareGetSpecificItemRequest(name, id),
        parseResponse: (response) =>
            jsonConverter(_api.parseGetSpecificItemResponse(response)));
  }

  Future<Type> createNewItem<Type>(
      {required String typeName,
      required Map<String, dynamic> objectData,
      required Type Function(dynamic) jsonConverter}) {
    return _sendRequest(
        prepareRequest: () =>
            _api.prepareCreateNewItemRequest(typeName, objectData),
        parseResponse: (response) =>
            jsonConverter(_api.parseCreateNewItemResponse(response)));
  }

  Future<Type> updateItem<Type>(
      {required String typeName,
      required String objectId,
      required Map<String, dynamic> objectData,
      required Type Function(dynamic) jsonConverter}) {
    return _sendRequest(
        prepareRequest: () =>
            _api.prepareUpdateItemRequest(typeName, objectId, objectData),
        parseResponse: (response) =>
            jsonConverter(_api.parseUpdateItemResponse(response)));
  }

  Future<bool> deleteItem(
      {required String typeName, required String objectId}) {
    return _sendRequest(
        prepareRequest: () => _api.prepareDeleteItemRequest(typeName, objectId),
        parseResponse: (response) => _api.parseDeleteItemResponse(response));
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

  String convertPathToFullURL({required String path}) {
    return _api.convertPathToFullURL(path: path);
  }
}
