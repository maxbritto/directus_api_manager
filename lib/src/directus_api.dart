import 'dart:convert';

import 'package:directus_api_manager/src/filter.dart';
import 'package:directus_api_manager/src/model/directus_file.dart';
import 'package:directus_api_manager/src/model/directus_login_result.dart';
import 'package:directus_api_manager/src/model/directus_user.dart';
import 'package:directus_api_manager/src/sort_property.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';

abstract class IDirectusAPI {
  bool get hasLoggedInUser;
  bool get shouldRefreshToken;

  BaseRequest prepareGetSpecificUserRequest(String userId,
      {String fields = "*"});
  BaseRequest prepareGetCurrentUserRequest();
  DirectusUser parseUserResponse(Response response);

  BaseRequest prepareUpdateUserRequest(DirectusUser updatedUser);
  BaseRequest prepareGetUserListRequest({Filter? filter});
  Iterable<DirectusUser> parseUserListResponse(Response response);
  BaseRequest prepareCreateUserRequest(
      {required String email,
      required String password,
      String? firstname,
      String? lastname,
      String? roleUUID,
      Map<String, dynamic> otherProperties = const {}});

  BaseRequest prepareGetListOfItemsRequest(String itemName,
      {String fields = "*", Filter? filter, List<SortProperty>? sortBy});
  Iterable<dynamic> parseGetListOfItemsResponse(Response response);

  BaseRequest prepareGetSpecificItemRequest(String itemName, String itemId,
      {String fields = "*"});
  dynamic parseGetSpecificItemResponse(Response response);

  Request prepareCreateNewItemRequest(
      String itemName, Map<String, dynamic> objectData);
  dynamic parseCreateNewItemResponse(Response response);

  Request prepareUpdateItemRequest(
      String itemName, String itemId, Map<String, dynamic> objectData);
  dynamic parseUpdateItemResponse(Response response);

  BaseRequest prepareDeleteItemRequest(
      String itemName, String itemId, bool mustBeAuthenticated);
  bool parseDeleteItemResponse(Response response);

  Future<Request?> prepareRefreshTokenRequest();
  bool parseRefreshTokenResponse(Response response);

  BaseRequest? prepareLogoutRequest();
  bool parseLogoutResponse(Response response);

  Request prepareLoginRequest(String username, String password);
  DirectusLoginResult parseLoginResponse(Response response);

  Request prepareUserInviteRequest(String email, String roleId);
  bool parseUserInviteResponse(Response response);

  Request prepareFileImportRequest({required String url, String? title});
  BaseRequest prepareNewFileUploadRequest(
      {required List<int> fileBytes,
      String? title,
      String? contentType,
      required String filename});
  BaseRequest prepareUpdateFileRequest(
      {required fileId,
      List<int>? fileBytes,
      String? title,
      String? contentType,
      required String filename});
  DirectusFile parseFileUploadResponse(Response response);

  String convertPathToFullURL({required String path});
}

class DirectusApiError {
  final Response? response;
  final String? customMessage;

  DirectusApiError({this.response, this.customMessage});

  @override
  String toString() {
    return "DirectusApiError : $customMessage : ${response?.statusCode} ${response?.body} ${response?.headers}";
  }
}

class DirectusAPI implements IDirectusAPI {
  String _baseURL;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _accessTokenExpirationDate;
  final Future<void> Function(String)? _saveRefreshTokenCallback;
  final Future<String?> Function()? _loadRefreshTokenCallback;

  DirectusAPI(this._baseURL,
      {Future<void> Function(String)? saveRefreshTokenCallback,
      Future<String?> Function()? loadRefreshTokenCallback})
      : _saveRefreshTokenCallback = saveRefreshTokenCallback,
        _loadRefreshTokenCallback = loadRefreshTokenCallback {
    if (_baseURL.endsWith("/")) {
      _baseURL = _baseURL.substring(0, _baseURL.length - 1);
    }
  }

  String get baseURL => _baseURL;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  @override
  bool get hasLoggedInUser => _refreshToken != null && _accessToken != null;
  @override
  bool get shouldRefreshToken {
    bool shouldRefresh = false;
    if (_refreshToken != null) {
      final accessTokenExpirationDate = _accessTokenExpirationDate;
      if (_accessToken == null ||
          (accessTokenExpirationDate != null &&
              accessTokenExpirationDate.isBefore(DateTime.now()))) {
        shouldRefresh = true;
      }
    }
    return shouldRefresh;
  }

  @override
  Request prepareLoginRequest(String username, String password) {
    final request = Request("POST", Uri.parse(_baseURL + "/auth/login"));
    final credentials = {};
    credentials["email"] = username;
    credentials["password"] = password;
    request.body = jsonEncode(credentials);
    request.addJsonHeaders();
    return request;
  }

  String? _extractErrorMessageFromResponse(Response response) {
    String? message;
    try {
      final errorList = jsonDecode(response.body)["errors"] as List;
      if (errorList.isNotEmpty) {
        final StringBuffer messageBuilder = StringBuffer();
        for (final error in errorList) {
          messageBuilder.write(error["message"]);
          messageBuilder.write("\n");
        }
        message = messageBuilder.toString();
      } else {
        message = null;
      }
    } catch (_) {}
    return message;
  }

  @override
  DirectusLoginResult parseLoginResponse(Response response) {
    _accessToken = null;
    _refreshToken = null;
    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        return const DirectusLoginResult(
            DirectusLoginResultType.invalidCredentials);
      } else {
        return DirectusLoginResult(DirectusLoginResultType.error,
            message: _extractErrorMessageFromResponse(response));
      }
    }

    try {
      final json = jsonDecode(response.body)["data"];
      _accessToken = json["access_token"];
      final refreshToken = json["refresh_token"];
      _refreshToken = refreshToken;
      final saveFunction = _saveRefreshTokenCallback;
      if (saveFunction != null) {
        saveFunction(refreshToken);
      }
      int? expirationDelay = json["expires"];
      if (expirationDelay != null && expirationDelay > 0) {
        _accessTokenExpirationDate =
            DateTime.now().add(Duration(milliseconds: expirationDelay));
      }
    } catch (_) {}
    if (_accessToken != null && _refreshToken != null) {
      return const DirectusLoginResult(DirectusLoginResultType.success);
    } else {
      return const DirectusLoginResult(DirectusLoginResultType.error,
          message: "Unrecognized response");
    }
  }

  @override
  Future<Request?> prepareRefreshTokenRequest() async {
    Request? request;

    if (_refreshToken == null) {
      final loadTokenFunction = _loadRefreshTokenCallback;
      if (loadTokenFunction != null) {
        _refreshToken = await loadTokenFunction();
      }
    }
    request = _prepareStokedRefreshTokenRequest();
    return request;
  }

  Request? _prepareStokedRefreshTokenRequest() {
    Request? request;
    final refreshToken = _refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      request = Request("POST", Uri.parse(_baseURL + "/auth/refresh"));
      request.body = jsonEncode({"refresh_token": refreshToken});
      request.addJsonHeaders();
    }
    return request;
  }

  BaseRequest _authenticateRequest(BaseRequest request) {
    final accessToken = _accessToken;
    if (accessToken != null) {
      request.headers["Authorization"] = "Bearer $accessToken";
    }
    return request;
  }

  @override
  bool parseRefreshTokenResponse(Response response) {
    final responseParsingResult = parseLoginResponse(response);
    return responseParsingResult.type == DirectusLoginResultType.success;
  }

  @override
  bool parseLogoutResponse(Response response) {
    if (response.statusCode < 200 || response.statusCode > 299) {
      return false;
    }
    _refreshToken = null;
    _accessToken = null;
    _accessTokenExpirationDate = null;
    return true;
  }

  @override
  Request? prepareLogoutRequest() {
    Request? logoutRequest;
    Request? tokenRefreshRequest = _prepareStokedRefreshTokenRequest();
    if (tokenRefreshRequest != null) {
      logoutRequest = Request("POST", Uri.parse(_baseURL + "/auth/logout"));
      logoutRequest.body = tokenRefreshRequest.body;
      logoutRequest.addJsonHeaders();
    }
    return logoutRequest;
  }

  dynamic _parseGenericResponse(Response response) {
    if (response.statusCode != 200) {
      throw DirectusApiError(response: response);
    }
    return jsonDecode(response.body)["data"];
  }

  @override
  Iterable parseGetListOfItemsResponse(Response response) {
    return _parseGenericResponse(response);
  }

  @override
  BaseRequest prepareGetListOfItemsRequest(String itemName,
      {String fields = "*", Filter? filter, List<SortProperty>? sortBy}) {
    return _prepareGetRequest("/items/$itemName",
        filter: filter, fields: fields, sortBy: sortBy);
  }

  @override
  parseGetSpecificItemResponse(Response response) {
    return _parseGenericResponse(response);
  }

  BaseRequest _prepareGetRequest(String path,
      {String fields = "*", Filter? filter, List<SortProperty>? sortBy}) {
    final urlBuilder = StringBuffer(_baseURL + "$path?fields=$fields");
    if (filter != null) {
      urlBuilder.write("&filter=${filter.asJSON}");
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      urlBuilder.write("&sort=" + sortBy.join(","));
    }
    Request request = Request("GET", Uri.parse(urlBuilder.toString()));
    return _authenticateRequest(request);
  }

  @override
  BaseRequest prepareGetSpecificItemRequest(String itemName, String itemId,
      {String fields = "*"}) {
    return _prepareGetRequest("/items/$itemName/$itemId", fields: fields);
  }

  @override
  Request prepareUserInviteRequest(String email, String roleId) {
    final request = Request("POST", Uri.parse("$_baseURL/users/invite"));
    request.body = jsonEncode({"email": email, "role": roleId});
    request.addJsonHeaders();
    return request;
  }

  @override
  bool parseUserInviteResponse(Response response) {
    return response.statusCode == 200;
  }

  @override
  dynamic parseCreateNewItemResponse(Response response) {
    return parseGetSpecificItemResponse(response);
  }

  @override
  dynamic parseUpdateItemResponse(Response response) {
    return parseGetSpecificItemResponse(response);
  }

  @override
  Request prepareCreateNewItemRequest(
      String itemName, Map<String, dynamic> objectData) {
    Request request = Request("POST", Uri.parse(_baseURL + "/items/$itemName"));
    request.body = jsonEncode(objectData);
    request.addJsonHeaders();
    return _authenticateRequest(request) as Request;
  }

  @override
  Request prepareUpdateItemRequest(
      String itemName, String itemId, Map<String, dynamic> objectData) {
    Request request =
        Request("PATCH", Uri.parse(_baseURL + "/items/$itemName/$itemId"));
    request.body = jsonEncode(objectData);
    request.addJsonHeaders();
    return _authenticateRequest(request) as Request;
  }

  @override
  DirectusUser parseUserResponse(Response response) {
    final userData = _parseGenericResponse(response);
    if (userData is Map<String, dynamic>) {
      return DirectusUser(userData);
    } else {
      throw "Invalid user response format";
    }
  }

  @override
  BaseRequest prepareGetCurrentUserRequest() {
    return prepareGetSpecificUserRequest("me");
  }

  @override
  BaseRequest prepareGetSpecificUserRequest(String userId,
      {String fields = "*"}) {
    return _prepareGetRequest("/users/$userId", fields: fields);
  }

  @override
  Iterable<DirectusUser> parseUserListResponse(Response response) {
    final userListData = _parseGenericResponse(response) as List;
    return userListData.map((userData) => DirectusUser(userData));
  }

  @override
  BaseRequest prepareGetUserListRequest({Filter? filter}) {
    return _prepareGetRequest("/users", filter: filter);
  }

  @override
  Request prepareCreateUserRequest(
      {required String email,
      required String password,
      String? firstname,
      String? lastname,
      String? roleUUID,
      Map<String, dynamic> otherProperties = const {}}) {
    Request request = Request("POST", Uri.parse(_baseURL + "/users"));
    final Map<String, dynamic> userProperties = {
      "email": email,
      "password": password
    };
    if (firstname != null) {
      userProperties["first_name"] = firstname;
    }
    if (lastname != null) {
      userProperties["last_name"] = lastname;
    }
    if (roleUUID != null) {
      userProperties["role"] = roleUUID;
    }
    for (final propertyKey in otherProperties.keys) {
      userProperties[propertyKey] = otherProperties[propertyKey];
    }
    request.body = jsonEncode(userProperties);
    request.addJsonHeaders();
    return _authenticateRequest(request) as Request;
  }

  @override
  Request prepareUpdateUserRequest(DirectusUser updatedUser) {
    Request request =
        Request("PATCH", Uri.parse(_baseURL + "/users/" + updatedUser.id));
    request.body = jsonEncode(updatedUser.allProperties..remove("id"));
    request.addJsonHeaders();
    return _authenticateRequest(request) as Request;
  }

  @override
  bool parseDeleteItemResponse(Response response) {
    _throwIfServerDeniedRequest(response);
    return true;
  }

  void _throwIfServerDeniedRequest(Response response) {
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw Exception(
          "Server denied this action HTTP code : ${response.statusCode}. ${response.reasonPhrase}. ${response.body}");
    }
  }

  @override
  BaseRequest prepareDeleteItemRequest(
      String itemName, String itemId, bool mustBeAuthenticated) {
    Request request =
        Request("DELETE", Uri.parse("$_baseURL/items/$itemName/$itemId"));
    if (mustBeAuthenticated) {
      return _authenticateRequest(request);
    }

    return request;
  }

  @override
  DirectusFile parseFileUploadResponse(Response response) {
    _throwIfServerDeniedRequest(response);
    return DirectusFile.fromJSON(jsonDecode(response.body)["data"]);
  }

  @override
  BaseRequest prepareNewFileUploadRequest(
      {required List<int> fileBytes,
      String? title,
      String? contentType,
      required String filename}) {
    return _prepareMultipartFileRequest(
        "POST", "$_baseURL/files", fileBytes, title,
        contentType: contentType, filename: filename);
  }

  MultipartRequest _prepareMultipartFileRequest(
      String method, String url, List<int>? fileBytes, String? title,
      {String? contentType, required String filename}) {
    final request = MultipartRequest(method, Uri.parse(url));
    if (title != null) {
      request.fields["title"] = title;
    }
    if (fileBytes != null) {
      request.files.add(MultipartFile.fromBytes("file", fileBytes,
          filename: filename,
          contentType:
              contentType != null ? MediaType.parse(contentType) : null));
    }
    return _authenticateRequest(request) as MultipartRequest;
  }

  @override
  BaseRequest prepareUpdateFileRequest(
      {required fileId,
      List<int>? fileBytes,
      String? title,
      String? contentType,
      required String filename}) {
    return _prepareMultipartFileRequest(
        "PATCH", "$_baseURL/files/$fileId", fileBytes, title,
        contentType: contentType, filename: filename);
  }

  @override
  Request prepareFileImportRequest({required String url, String? title}) {
    final request = Request("POST", Uri.parse("$_baseURL/files/import"));
    request.body = jsonEncode({
      "url": url,
      "data": {"title": title}
    });
    request.addJsonHeaders();
    return request;
  }

  @override
  String convertPathToFullURL({required String path}) {
    final buffer = StringBuffer(_baseURL);
    if (_baseURL.endsWith("/") == false && path.startsWith("/") == false) {
      buffer.write("/");
    }
    buffer.write(path);
    return buffer.toString();
  }
}

extension RequestJson on Request {
  addJsonHeaders() {
    headers["Content-Type"] = "application/json; charset=utf-8";
  }
}
