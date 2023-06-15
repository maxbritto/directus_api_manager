import 'package:directus_api_manager/src/directus_api.dart';
import 'package:extension_dart_tools/extension_tools.dart';
import 'package:http/src/response.dart';
import 'package:http/src/request.dart';
import 'package:http/src/base_request.dart';
import 'package:directus_api_manager/src/sort_property.dart';
import 'package:directus_api_manager/src/model/directus_login_result.dart';
import 'package:directus_api_manager/src/model/directus_file.dart';
import 'package:directus_api_manager/src/filter.dart';

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

  Request nextReturnedRequest = Request("GET", Uri.parse("http://localhost"));

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
  Request prepareCreateNewItemRequest(
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
  BaseRequest prepareDeleteItemRequest(
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
  BaseRequest prepareDeleteMultipleItemRequest(
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
  BaseRequest prepareFileDeleteRequest({required String fileId}) {
    addCalledFunction(named: "prepareFileDeleteRequest");
    addReceivedObject(fileId, name: "fileId");
    return nextReturnedRequest;
  }

  @override
  Request prepareFileImportRequest(
      {required String url, String? title, String? folder}) {
    addCalledFunction(named: "prepareFileImportRequest");
    addReceivedObject(url, name: "url");
    addReceivedObject(title, name: "title");
    addReceivedObject(folder, name: "folder");
    return nextReturnedRequest;
  }

  @override
  BaseRequest prepareGetCurrentUserRequest({String fields = "*"}) {
    addCalledFunction(named: "prepareGetCurrentUserRequest");
    addReceivedObject(fields, name: "fields");
    return nextReturnedRequest;
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
  BaseRequest prepareGetSpecificItemRequest(
      {String fields = "*",
      required String endpointPrefix,
      required String endpointName,
      required String itemId}) {
    addCalledFunction(named: "prepareGetSpecificItemRequest");
    addReceivedObject(endpointName, name: "endpointName");
    addReceivedObject(endpointPrefix, name: "endpointPrefix");
    addReceivedObject(itemId, name: "itemId");
    addReceivedObject(fields, name: "fields");
    return nextReturnedRequest;
  }

  @override
  Request prepareLoginRequest(String username, String password) {
    addCalledFunction(named: "prepareLoginRequest");
    addReceivedObject(username, name: "username");
    addReceivedObject(password, name: "password");
    return nextReturnedRequest;
  }

  @override
  BaseRequest? prepareLogoutRequest() {
    addCalledFunction(named: "prepareLogoutRequest");
    return nextReturnedRequest;
  }

  @override
  BaseRequest prepareNewFileUploadRequest(
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
  Request preparePasswordChangeRequest(
      {required String token, required String newPassword}) {
    addCalledFunction(named: "preparePasswordChangeRequest");
    addReceivedObject(token, name: "token");
    addReceivedObject(newPassword, name: "newPassword");
    return nextReturnedRequest;
  }

  @override
  Request preparePasswordResetRequest(
      {required String email, String? resetUrl}) {
    addCalledFunction(named: "preparePasswordResetRequest");
    addReceivedObject(email, name: "email");
    addReceivedObject(resetUrl, name: "resetUrl");
    return nextReturnedRequest;
  }

  @override
  Future<Request?> prepareRefreshTokenRequest() {
    addCalledFunction(named: "prepareRefreshTokenRequest");
    return Future.value(nextReturnedRequest);
  }

  @override
  BaseRequest prepareUpdateFileRequest(
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
  Request prepareUpdateItemRequest(
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
  Request prepareUserInviteRequest(String email, String roleId) {
    addCalledFunction(named: "prepareUserInviteRequest");
    addReceivedObject(email, name: "email");
    addReceivedObject(roleId, name: "roleId");
    return nextReturnedRequest;
  }

  @override
  bool shouldRefreshToken = false;

  @override
  String? get accessToken => "accessToken";
}
