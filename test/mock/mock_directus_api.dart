import 'package:directus_api_manager/src/directus_api.dart';
import 'package:extension_dart_tools/extension_tools.dart';
import 'package:http/src/response.dart';
import 'package:http/src/request.dart';
import 'package:http/src/base_request.dart';
import 'package:directus_api_manager/src/sort_property.dart';
import 'package:directus_api_manager/src/model/directus_user.dart';
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
  bool parseDeleteUserResponse(Response response) {
    addCalledFunction(named: "parseDeleteUserResponse");
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
  Iterable<DirectusUser> parseUserListResponse(Response response) {
    addCalledFunction(named: "parseUserListResponse");
    addReceivedObject(response, name: "response");
    return popNextReturnedObject();
  }

  @override
  DirectusUser parseUserResponse(Response response) {
    addCalledFunction(named: "parseUserResponse");
    addReceivedObject(response, name: "response");
    return popNextReturnedObject();
  }

  @override
  Request prepareCreateNewItemRequest(String itemName, objectData,
      {String fields = "*"}) {
    addCalledFunction(named: "prepareCreateNewItemRequest");
    addReceivedObject(itemName, name: "itemName");
    addReceivedObject(objectData, name: "objectData");
    addReceivedObject(fields, name: "fields");
    return nextReturnedRequest;
  }

  @override
  BaseRequest prepareCreateUserRequest(
      {required String email,
      required String password,
      String? firstname,
      String? lastname,
      String? roleUUID,
      Map<String, dynamic> otherProperties = const {}}) {
    addCalledFunction(named: "prepareCreateUserRequest");
    addReceivedObject(email, name: "email");
    addReceivedObject(password, name: "password");
    addReceivedObject(firstname, name: "firstname");
    addReceivedObject(lastname, name: "lastname");
    addReceivedObject(roleUUID, name: "roleUUID");
    addReceivedObject(otherProperties, name: "otherProperties");
    return nextReturnedRequest;
  }

  @override
  BaseRequest prepareDeleteItemRequest(
      String itemName, String itemId, bool mustBeAuthenticated) {
    addCalledFunction(named: "prepareDeleteItemRequest");
    addReceivedObject(itemName, name: "itemName");
    addReceivedObject(itemId, name: "itemId");
    addReceivedObject(mustBeAuthenticated, name: "mustBeAuthenticated");
    return nextReturnedRequest;
  }

  @override
  BaseRequest prepareDeleteMultipleItemRequest(
      String itemName, List itemIdList, bool mustBeAuthenticated) {
    addCalledFunction(named: "prepareDeleteMultipleItemRequest");
    addReceivedObject(itemName, name: "itemName");
    addReceivedObject(itemIdList, name: "itemIdList");
    addReceivedObject(mustBeAuthenticated, name: "mustBeAuthenticated");
    return nextReturnedRequest;
  }

  @override
  BaseRequest? prepareDeleteUserRequest(
      DirectusUser user, bool mustBeAuthenticated) {
    addCalledFunction(named: "prepareDeleteUserRequest");
    addReceivedObject(user, name: "user");
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
  BaseRequest prepareGetListOfItemsRequest(String itemName,
      {String fields = "*",
      Filter? filter,
      List<SortProperty>? sortBy,
      int? limit,
      int? offset}) {
    addCalledFunction(named: "prepareGetListOfItemsRequest");
    addReceivedObject(itemName, name: "itemName");
    addReceivedObject(fields, name: "fields");
    addReceivedObject(filter, name: "filter");
    addReceivedObject(sortBy, name: "sortBy");
    addReceivedObject(limit, name: "limit");
    addReceivedObject(offset, name: "offset");

    return nextReturnedRequest;
  }

  @override
  BaseRequest prepareGetSpecificItemRequest(String itemName, String itemId,
      {String fields = "*"}) {
    addCalledFunction(named: "prepareGetSpecificItemRequest");
    addReceivedObject(itemName, name: "itemName");
    addReceivedObject(itemId, name: "itemId");
    addReceivedObject(fields, name: "fields");
    return nextReturnedRequest;
  }

  @override
  BaseRequest prepareGetSpecificUserRequest(String userId,
      {String fields = "*"}) {
    addCalledFunction(named: "prepareGetSpecificUserRequest");
    addReceivedObject(userId, name: "userId");
    addReceivedObject(fields, name: "fields");
    return nextReturnedRequest;
  }

  @override
  BaseRequest prepareGetUserListRequest(
      {Filter? filter,
      int limit = -1,
      String? fields,
      List<SortProperty>? sortBy,
      int? offset}) {
    addCalledFunction(named: "prepareGetUserListRequest");
    addReceivedObject(filter, name: "filter");
    addReceivedObject(limit, name: "limit");
    addReceivedObject(fields, name: "fields");
    addReceivedObject(sortBy, name: "sortBy");
    addReceivedObject(offset, name: "offset");
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
      String? folder}) {
    addCalledFunction(named: "prepareNewFileUploadRequest");
    addReceivedObject(fileBytes, name: "fileBytes");
    addReceivedObject(title, name: "title");
    addReceivedObject(contentType, name: "contentType");
    addReceivedObject(filename, name: "filename");
    addReceivedObject(folder, name: "folder");
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
      String itemName, String itemId, Map<String, dynamic> objectData,
      {String fields = "*"}) {
    addCalledFunction(named: "prepareUpdateItemRequest");
    addReceivedObject(itemName, name: "itemName");
    addReceivedObject(itemId, name: "itemId");
    addReceivedObject(objectData, name: "objectData");
    addReceivedObject(fields, name: "fields");
    return nextReturnedRequest;
  }

  @override
  BaseRequest? prepareUpdateUserRequest(DirectusUser updatedUser,
      {String fields = "*"}) {
    addCalledFunction(named: "prepareUpdateUserRequest");
    addReceivedObject(updatedUser, name: "updatedUser");
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
}
