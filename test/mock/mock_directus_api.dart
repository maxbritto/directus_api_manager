import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:directus_api_manager/src/directus_api.dart';
import 'package:extension_dart_tools/extension_tools.dart';
import 'package:http/src/response.dart';
import 'package:http/src/request.dart';
import 'package:http/src/base_request.dart';

class MockDirectusApi with MockMixin implements IDirectusAPI {
  @override
  BaseRequest authenticateRequest(BaseRequest request) {
    addCalledFunction(named: "authenticateRequest");
    addReceivedObject(request, name: "request");
    return request;
  }

  @override
  String convertPathToFullURL({required String path}) {
    addCalledFunction(named: "convertPathToFullURL");
    addReceivedObject(path, name: "path");
    return popNextReturnedObject();
  }

  PreparedRequest nextReturnedRequest =
      PreparedRequest(request: Request("GET", Uri.parse("http://localhost")));

  @override
  String? currentAuthToken;

  @override
  bool hasLoggedInUser = false;

  @override
  parseCreateNewItemResponse(Response response) {
    addCalledFunction(named: "parseCreateNewItemResponse");
    addReceivedObject(response, name: "response");
    return popNextReturnedObject();
  }

  @override
  DirectusFile parseFileUploadResponse(Response response) {
    addCalledFunction(named: "parseFileUploadResponse");
    addReceivedObject(response, name: "response");
    return popNextReturnedObject();
  }

  @override
  bool parseGenericBoolResponse(Response response) {
    addCalledFunction(named: "parseGenericBoolResponse");
    addReceivedObject(response, name: "response");
    return popNextReturnedObject();
  }

  @override
  Iterable parseGetListOfItemsResponse(Response response) {
    addCalledFunction(named: "parseGetListOfItemsResponse");
    addReceivedObject(response, name: "response");
    return popNextReturnedObject();
  }

  @override
  parseGetSpecificItemResponse(Response response) {
    addCalledFunction(named: "parseGetSpecificItemResponse");
    addReceivedObject(response, name: "response");
    return popNextReturnedObject();
  }

  @override
  DirectusLoginResult parseLoginResponse(Response response) {
    addCalledFunction(named: "parseLoginResponse");
    addReceivedObject(response, name: "response");
    return popNextReturnedObject();
  }

  @override
  bool parseLogoutResponse(Response response) {
    addCalledFunction(named: "parseLogoutResponse");
    addReceivedObject(response, name: "response");
    return popNextReturnedObject();
  }

  @override
  bool parseRefreshTokenResponse(Response response) {
    addCalledFunction(named: "parseRefreshTokenResponse");
    addReceivedObject(response, name: "response");
    return popNextReturnedObject();
  }

  @override
  parseUpdateItemResponse(Response response) {
    addCalledFunction(named: "parseUpdateItemResponse");
    addReceivedObject(response, name: "response");
    return popNextReturnedObject();
  }

  @override
  bool parseUserInviteResponse(Response response) {
    addCalledFunction(named: "parseUserInviteResponse");
    addReceivedObject(response, name: "response");
    return popNextReturnedObject();
  }

  @override
  PreparedRequest prepareCreateNewItemRequest(
      {required String endpointName,
      required String endpointPrefix,
      required dynamic objectData,
      String fields = "*"}) {
    addCalledFunction(named: "prepareCreateNewItemRequest");
    addReceivedObject(endpointName, name: "endpointName");
    addReceivedObject(objectData, name: "objectData");
    addReceivedObject(fields, name: "fields");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest prepareDeleteItemRequest(
      {required String endpointName,
      required String itemId,
      required String endpointPrefix,
      bool mustBeAuthenticated = false}) {
    addCalledFunction(named: "prepareDeleteItemRequest");
    addReceivedObject(endpointName, name: "endpointName");
    addReceivedObject(itemId, name: "itemId");
    addReceivedObject(endpointPrefix, name: "endpointPrefix");
    addReceivedObject(mustBeAuthenticated, name: "mustBeAuthenticated");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest prepareDeleteMultipleItemRequest(
      {required String endpointName,
      required String endpointPrefix,
      required List<dynamic> itemIdList,
      required bool mustBeAuthenticated}) {
    addCalledFunction(named: "prepareDeleteMultipleItemRequest");
    addReceivedObject(endpointName, name: "endpointName");
    addReceivedObject(itemIdList, name: "itemIdList");
    addReceivedObject(mustBeAuthenticated, name: "mustBeAuthenticated");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest prepareFileDeleteRequest({required String fileId}) {
    addCalledFunction(named: "prepareFileDeleteRequest");
    addReceivedObject(fileId, name: "fileId");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest prepareFileImportRequest(
      {required String url, String? title, String? folder}) {
    addCalledFunction(named: "prepareFileImportRequest");
    addReceivedObject(url, name: "url");
    addReceivedObject(title, name: "title");
    addReceivedObject(folder, name: "folder");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest prepareGetCurrentUserRequest({String fields = "*"}) {
    addCalledFunction(named: "prepareGetCurrentUserRequest");
    addReceivedObject(fields, name: "fields");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest prepareGetListOfItemsRequest(
      {required String endpointName,
      required String endpointPrefix,
      String fields = "*",
      Filter? filter,
      List<SortProperty>? sortBy,
      int? limit,
      int? offset}) {
    addCalledFunction(named: "prepareGetListOfItemsRequest");
    addReceivedObject(endpointName, name: "endpointName");
    addReceivedObject(endpointPrefix, name: "endpointPrefix");
    addReceivedObject(fields, name: "fields");
    addReceivedObject(filter, name: "filter");
    addReceivedObject(sortBy, name: "sortBy");
    addReceivedObject(limit, name: "limit");
    addReceivedObject(offset, name: "offset");

    return nextReturnedRequest;
  }

  @override
  PreparedRequest prepareGetSpecificItemRequest(
      {String fields = "*",
      required String endpointPrefix,
      required String endpointName,
      required String itemId,
      List<String> tags = const []}) {
    addCalledFunction(named: "prepareGetSpecificItemRequest");
    addReceivedObject(endpointName, name: "endpointName");
    addReceivedObject(endpointPrefix, name: "endpointPrefix");
    addReceivedObject(itemId, name: "itemId");
    addReceivedObject(fields, name: "fields");
    addReceivedObject(tags, name: "tags");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest prepareLoginRequest(String username, String password,
      {String? oneTimePassword}) {
    addCalledFunction(named: "prepareLoginRequest");
    addReceivedObject(username, name: "username");
    addReceivedObject(password, name: "password");
    if (oneTimePassword != null) {
      addReceivedObject(oneTimePassword, name: "otp");
    }
    return nextReturnedRequest;
  }

  @override
  PreparedRequest? prepareLogoutRequest() {
    addCalledFunction(named: "prepareLogoutRequest");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest prepareNewFileUploadRequest(
      {required List<int> fileBytes,
      String? title,
      String? contentType,
      required String filename,
      String? folder,
      String storage = "local"}) {
    addCalledFunction(named: "prepareNewFileUploadRequest");
    addReceivedObject(fileBytes, name: "fileBytes");
    addReceivedObject(title, name: "title");
    addReceivedObject(contentType, name: "contentType");
    addReceivedObject(filename, name: "filename");
    addReceivedObject(folder, name: "folder");
    addReceivedObject(storage, name: "storage");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest preparePasswordChangeRequest(
      {required String token, required String newPassword}) {
    addCalledFunction(named: "preparePasswordChangeRequest");
    addReceivedObject(token, name: "token");
    addReceivedObject(newPassword, name: "newPassword");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest preparePasswordResetRequest(
      {required String email, String? resetUrl}) {
    addCalledFunction(named: "preparePasswordResetRequest");
    addReceivedObject(email, name: "email");
    addReceivedObject(resetUrl, name: "resetUrl");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest prepareRefreshTokenRequest() {
    addCalledFunction(named: "prepareRefreshTokenRequest");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest prepareUpdateFileRequest(
      {required fileId,
      List<int>? fileBytes,
      String? title,
      String? contentType,
      required String filename}) {
    addCalledFunction(named: "prepareUpdateFileRequest");
    addReceivedObject(fileId, name: "fileId");
    addReceivedObject(fileBytes, name: "fileBytes");
    addReceivedObject(title, name: "title");
    addReceivedObject(contentType, name: "contentType");
    addReceivedObject(filename, name: "filename");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest prepareUpdateItemRequest(
      {required String endpointName,
      required String endpointPrefix,
      required String itemId,
      required Map<String, dynamic> objectData,
      String fields = "*"}) {
    addCalledFunction(named: "prepareUpdateItemRequest");
    addReceivedObject(endpointName, name: "endpointName");
    addReceivedObject(itemId, name: "itemId");
    addReceivedObject(objectData, name: "objectData");
    addReceivedObject(fields, name: "fields");
    return nextReturnedRequest;
  }

  @override
  PreparedRequest prepareUserInviteRequest(String email, String roleId) {
    addCalledFunction(named: "prepareUserInviteRequest");
    addReceivedObject(email, name: "email");
    addReceivedObject(roleId, name: "roleId");
    return nextReturnedRequest;
  }

  @override
  bool shouldRefreshToken = false;

  @override
  String? get accessToken => "accessToken";

  @override
  String? get refreshToken => "refreshToken";

  @override
  String get baseUrl => "http://api.com";

  @override
  set refreshToken(String? value) {}
}
