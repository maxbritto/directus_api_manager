import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:directus_api_manager/src/directus_api.dart';
import 'package:directus_api_manager/src/filter.dart';
import 'package:directus_api_manager/src/model/directus_user.dart';
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
            loadRefreshTokenCallback: loadRefreshTokenCallback);

  Future<Response> _sendRequest(Request request,
      {bool dependsOnToken = true}) async {
    Response? response;
    bool hasRefreshedToken;
    int refreshTokenAttempts = 0;

    do {
      hasRefreshedToken = false;

      final streamedResponse = await _client.send(request);
      response = await Response.fromStream(streamedResponse);

      if (dependsOnToken && response.statusCode == 401) {
        refreshTokenAttempts++;
        final newRequest = await _tryAndRefreshToken(request);
        if (newRequest != null) {
          request = newRequest;
          hasRefreshedToken = true;
        }
      }
    } while (response.statusCode == 401 &&
        hasRefreshedToken &&
        refreshTokenAttempts < 2);

    return response;
  }

  Future<bool> hasLoggedInUser() async {
    return await _api.prepareRefreshTokenRequest() != null;
  }

  Future<Request?> _tryAndRefreshToken(Request pendingRequest) async {
    Request? newRequest;
    final req = await _api.prepareRefreshTokenRequest();
    if (req != null) {
      final response = await _sendRequest(req, dependsOnToken: false);
      newRequest = _api.parseRefreshTokenResponse(response, pendingRequest);
    }
    return newRequest;
  }

  Future<DirectusLoginResult> loginDirectusUser(
      String username, String password) async {
    final response = await _sendRequest(
        _api.prepareLoginRequest(username, password),
        dependsOnToken: false);

    return _api.parseLoginResponse(response);
  }

  Future<DirectusUser?> currentDirectusUser() async {
    if (await hasLoggedInUser()) {
      final request = _api.prepareGetCurrentUserRequest();
      final response = await _sendRequest(request);
      return _api.parseUserResponse(response);
    } else {
      return Future.value(null);
    }
  }

  Future<DirectusUser?> getDirectusUser(String userId,
      {String fields = "*"}) async {
    final request = _api.prepareGetSpecificUserRequest(userId, fields: fields);
    final response = await _sendRequest(request);
    return _api.parseUserResponse(response);
  }

  Future<Iterable<DirectusUser>> getDirectusUserList() async {
    final request = _api.prepareGetUserListRequest();
    final response = await _sendRequest(request);
    return _api.parseUserListResponse(response);
  }

  Future<DirectusUser> updateDirectusUser(
      {required DirectusUser updatedUser}) async {
    final request = _api.prepareUpdateUserRequest(updatedUser);
    final response = await _sendRequest(request);
    return _api.parseUserResponse(response);
  }

  Future<DirectusUser> createNewDirectusUser(
      {required String email,
      required String password,
      String? firstname,
      String? lastname,
      String? roleUUID,
      Map<String, dynamic> otherProperties = const {}}) async {
    final request = _api.prepareCreateUserRequest(
        email: email,
        password: password,
        firstname: firstname,
        lastname: lastname,
        roleUUID: roleUUID,
        otherProperties: otherProperties);
    final response = await _sendRequest(request);
    return _api.parseUserResponse(response);
  }

  Future<bool> logoutDirectusUser() async {
    final request = _api.prepareLogoutRequest();
    if (request != null) {
      final response = await _sendRequest(request, dependsOnToken: false);
      return _api.parseLogoutResponse(response);
    } else {
      return false;
    }
  }

  Future<Iterable<Type>> findListOfItems<Type>(
      {required String name,
      Filter? filter,
      List<SortProperty>? sortBy,
      required Type Function(dynamic) jsonConverter}) async {
    final request =
        _api.prepareGetListOfItemsRequest(name, filter: filter, sortBy: sortBy);
    final response = await _sendRequest(request);
    return _api
        .parseGetListOfItemsResponse(response)
        .map((itemAsJsonObject) => jsonConverter(itemAsJsonObject));
  }

  Future<Type> getSpecificItem<Type>(
      {required String name,
      required String id,
      required Type Function(dynamic) jsonConverter}) async {
    final request = _api.prepareGetSpecificItemRequest(name, id);
    final response = await _sendRequest(request);
    return jsonConverter(_api.parseGetSpecificItemResponse(response));
  }

  Future<Type> createNewItem<Type>(
      {required String typeName,
      required Map<String, dynamic> objectData,
      required Type Function(dynamic) jsonConverter}) async {
    final request = _api.prepareCreateNewItemRequest(typeName, objectData);
    final response = await _sendRequest(request);
    return jsonConverter(_api.parseCreateNewItemResponse(response));
  }

  Future<Type> updateItem<Type>(
      {required String typeName,
      required String objectId,
      required Map<String, dynamic> objectData,
      required Type Function(dynamic) jsonConverter}) async {
    final request =
        _api.prepareUpdateItemRequest(typeName, objectId, objectData);
    final response = await _sendRequest(request);
    return jsonConverter(_api.parseUpdateItemResponse(response));
  }
}
