import 'dart:convert';
import 'dart:developer';

import 'package:directus_api_manager/src/filter.dart';
import 'package:directus_api_manager/src/model/directus_api_error.dart';
import 'package:directus_api_manager/src/model/directus_file.dart';
import 'package:directus_api_manager/src/model/directus_login_result.dart';
import 'package:directus_api_manager/src/sort_property.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';

abstract class IDirectusAPI {
  bool get hasLoggedInUser;
  bool get shouldRefreshToken;
  String? get accessToken;
  String? get currentAuthToken;
  String? get refreshToken;
  set refreshToken(String? value);
  String get baseUrl;

  BaseRequest authenticateRequest(BaseRequest request);
  BaseRequest prepareGetCurrentUserRequest({String fields = "*"});

  BaseRequest prepareGetListOfItemsRequest(
      {required String endpointName,
      required String endpointPrefix,
      String fields = "*",
      Filter? filter,
      List<SortProperty>? sortBy,
      int? limit,
      int? offset});
  Iterable<dynamic> parseGetListOfItemsResponse(Response response);

  BaseRequest prepareGetSpecificItemRequest(
      {String fields = "*",
      required String endpointPrefix,
      required String endpointName,
      required String itemId});
  dynamic parseGetSpecificItemResponse(Response response);

  Request prepareCreateNewItemRequest(
      {required String endpointName,
      required String endpointPrefix,
      required dynamic objectData,
      String fields = "*"});
  dynamic parseCreateNewItemResponse(Response response);

  Request prepareUpdateItemRequest(
      {required String endpointName,
      required String endpointPrefix,
      required String itemId,
      required Map<String, dynamic> objectData,
      String fields = "*"});
  dynamic parseUpdateItemResponse(Response response);

  BaseRequest prepareDeleteItemRequest(
      {required String endpointName,
      required String itemId,
      required String endpointPrefix,
      bool mustBeAuthenticated = false});
  BaseRequest prepareDeleteMultipleItemRequest(
      {required String endpointName,
      required String endpointPrefix,
      required List<dynamic> itemIdList,
      required bool mustBeAuthenticated});
  bool parseGenericBoolResponse(Response response);

  Future<Request?> prepareRefreshTokenRequest();
  bool parseRefreshTokenResponse(Response response);

  BaseRequest? prepareLogoutRequest();
  bool parseLogoutResponse(Response response);

  Request prepareLoginRequest(String username, String password);
  DirectusLoginResult parseLoginResponse(Response response);

  Request prepareUserInviteRequest(String email, String roleId);
  bool parseUserInviteResponse(Response response);

  Request prepareFileImportRequest(
      {required String url, String? title, String? folder});
  BaseRequest prepareFileDeleteRequest({required String fileId});
  BaseRequest prepareNewFileUploadRequest(
      {required List<int> fileBytes,
      String? title,
      String? contentType,
      required String filename,
      String? folder,
      String storage = "local"});
  BaseRequest prepareUpdateFileRequest(
      {required fileId,
      List<int>? fileBytes,
      String? title,
      String? contentType,
      required String filename});
  DirectusFile parseFileUploadResponse(Response response);

  String convertPathToFullURL({required String path});

  Request preparePasswordResetRequest(
      {required String email, String? resetUrl});
  Request preparePasswordChangeRequest(
      {required String token, required String newPassword});
}

class DirectusAPI implements IDirectusAPI {
  String _baseURL;
  @override
  String get baseUrl => _baseURL;

  String? _accessToken;
  String? _refreshToken;
  @override
  set refreshToken(String? value) => _refreshToken = value;

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
  @override
  String? get accessToken => _accessToken;
  @override
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
    final request = Request("POST", Uri.parse("$_baseURL/auth/login"));
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
      request = Request("POST", Uri.parse("$_baseURL/auth/refresh"));
      request.body = jsonEncode({"refresh_token": refreshToken});
      request.addJsonHeaders();
    }
    return request;
  }

  @override
  BaseRequest authenticateRequest(BaseRequest request) {
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
      logoutRequest = Request("POST", Uri.parse("$_baseURL/auth/logout"));
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
  BaseRequest prepareGetListOfItemsRequest(
      {required String endpointName,
      required String endpointPrefix,
      String fields = "*",
      Filter? filter,
      List<SortProperty>? sortBy,
      int? limit,
      int? offset}) {
    return _prepareGetRequest("$endpointPrefix$endpointName",
        filter: filter,
        fields: fields,
        sortBy: sortBy,
        limit: limit,
        offset: offset);
  }

  @override
  parseGetSpecificItemResponse(Response response) {
    return _parseGenericResponse(response);
  }

  BaseRequest _prepareGetRequest(String path,
      {String fields = "*",
      Filter? filter,
      List<SortProperty>? sortBy,
      int? limit,
      int? offset}) {
    final urlBuilder = StringBuffer("$_baseURL$path?fields=$fields");
    if (filter != null) {
      urlBuilder.write("&filter=${Uri.encodeQueryComponent(filter.asJSON)}");
    }
    if (limit != null) {
      urlBuilder.write("&limit=$limit");
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      urlBuilder.write("&sort=${sortBy.join(",")}");
    }

    if (offset != null) {
      urlBuilder.write("&offset=$offset");
    }
    Request request = Request("GET", Uri.parse(urlBuilder.toString()));
    return authenticateRequest(request);
  }

  @override
  BaseRequest prepareGetSpecificItemRequest(
      {String fields = "*",
      required String endpointPrefix,
      required String endpointName,
      required String itemId}) {
    return _prepareGetRequest("$endpointPrefix$endpointName/$itemId",
        fields: fields);
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
      {required String endpointName,
      required String endpointPrefix,
      required dynamic objectData,
      String fields = "*"}) {
    Request request = Request("POST",
        Uri.parse("$_baseURL$endpointPrefix$endpointName?fields=$fields"));
    request.body = jsonEncode(
      objectData,
      toEncodable: (nonEncodable) => _toEncodable(nonEncodable),
    );
    request.addJsonHeaders();
    return authenticateRequest(request) as Request;
  }

  @override
  Request prepareUpdateItemRequest(
      {required String endpointName,
      required String endpointPrefix,
      required String itemId,
      required Map<String, dynamic> objectData,
      String fields = "*"}) {
    Request request = Request(
        "PATCH",
        Uri.parse(
            "$_baseURL$endpointPrefix$endpointName/$itemId?fields=$fields"));
    request.body = jsonEncode(
      objectData,
      toEncodable: (nonEncodable) => _toEncodable(nonEncodable),
    );
    request.addJsonHeaders();
    return authenticateRequest(request) as Request;
  }

  @override
  BaseRequest prepareGetCurrentUserRequest({String fields = "*"}) {
    return prepareGetSpecificItemRequest(
        endpointName: "users",
        endpointPrefix: "/",
        itemId: "me",
        fields: fields);
  }

  Object? _toEncodable(Object? nonEncodable) {
    if (nonEncodable is DateTime) {
      return nonEncodable.toIso8601String();
    }

    return null;
  }

  @override
  bool parseGenericBoolResponse(Response response) {
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
      {required String endpointName,
      required String itemId,
      required String endpointPrefix,
      bool mustBeAuthenticated = false}) {
    Request request = Request(
        "DELETE", Uri.parse("$_baseURL$endpointPrefix$endpointName/$itemId"));
    if (mustBeAuthenticated) {
      return authenticateRequest(request);
    }

    return request;
  }

  @override
  BaseRequest prepareDeleteMultipleItemRequest(
      {required String endpointName,
      required String endpointPrefix,
      required List<dynamic> itemIdList,
      required bool mustBeAuthenticated}) {
    Request request =
        Request("DELETE", Uri.parse("$_baseURL$endpointPrefix$endpointName"));
    request.body = jsonEncode(itemIdList);
    request.addJsonHeaders();
    log(request.body);
    if (mustBeAuthenticated) {
      return authenticateRequest(request);
    } else {
      return request;
    }
  }

  @override
  DirectusFile parseFileUploadResponse(Response response) {
    _throwIfServerDeniedRequest(response);
    return DirectusFile(jsonDecode(response.body)["data"]);
  }

  @override
  BaseRequest prepareNewFileUploadRequest({
    required List<int> fileBytes,
    String? title,
    String? contentType,
    required String filename,
    String? folder,
    String storage = "local",
  }) {
    return _prepareMultipartFileRequest(
        "POST", "$_baseURL/files", fileBytes, title,
        contentType: contentType,
        filename: filename,
        folder: folder,
        storage: storage);
  }

  MultipartRequest _prepareMultipartFileRequest(
      String method, String url, List<int>? fileBytes, String? title,
      {String? contentType,
      required String filename,
      String? folder,
      String storage = "local"}) {
    final request = MultipartRequest(method, Uri.parse(url));
    if (title != null) {
      request.fields["title"] = title;
    }

    if (folder != null) {
      request.fields["folder"] = folder;
    }

    request.fields["storage"] = storage;

    if (fileBytes != null) {
      request.files.add(MultipartFile.fromBytes("file", fileBytes,
          filename: filename,
          contentType:
              contentType != null ? MediaType.parse(contentType) : null));
    }
    return authenticateRequest(request) as MultipartRequest;
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
  Request prepareFileImportRequest(
      {required String url, String? title, String? folder}) {
    final request = Request("POST", Uri.parse("$_baseURL/files/import"));
    request.body = jsonEncode({
      "url": url,
      "data": {"title": title, "folder": folder}
    });
    request.addJsonHeaders();
    return request;
  }

  @override
  BaseRequest prepareFileDeleteRequest({required String fileId}) {
    final request = Request("DELETE", Uri.parse("$_baseURL/files/$fileId"));

    return authenticateRequest(request);
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

  @override
  String? get currentAuthToken => _accessToken;

  @override
  Request preparePasswordResetRequest(
      {required String email, String? resetUrl}) {
    final request =
        Request("POST", Uri.parse("$_baseURL/auth/password/request"));
    request.body = jsonEncode(
        {"email": email, if (resetUrl != null) "reset_url": resetUrl});
    request.addJsonHeaders();
    return request;
  }

  @override
  Request preparePasswordChangeRequest(
      {required String token, required String newPassword}) {
    final request = Request("POST", Uri.parse("$_baseURL/auth/password/reset"));
    request.body = jsonEncode({"token": token, "password": newPassword});
    request.addJsonHeaders();
    return request;
  }
}

extension RequestJson on Request {
  addJsonHeaders() {
    headers["Content-Type"] = "application/json; charset=utf-8";
  }
}
