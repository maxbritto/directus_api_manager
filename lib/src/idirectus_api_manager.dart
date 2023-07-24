import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:directus_api_manager/src/model/directus_data.dart';
import 'package:http/http.dart';

abstract class IDirectusApiManager {
  Future<DirectusLoginResult> loginDirectusUser(
      String username, String password);
  Future<bool> logoutDirectusUser();
  Future<bool> hasLoggedInUser();
  Future<DirectusUser?> currentDirectusUser({String fields = "*"});

  Future<bool> requestPasswordReset({required String email, String? resetUrl});
  Future<bool> confirmPasswordReset(
      {required String token, required String password});

  Future<Iterable<Type>> findListOfItems<Type extends DirectusData>(
      {Filter? filter,
      List<SortProperty>? sortBy,
      String? fields,
      int? limit,
      int? offset});
  Future<Type?> getSpecificItem<Type extends DirectusData>(
      {required String id, String? fields});

  Future<DirectusItemCreationResult<Type>>
      createNewItem<Type extends DirectusData>({
    required Type objectToCreate,
    String? fields,
  });
  Future<DirectusItemCreationResult<Type>>
      createMultipleItems<Type extends DirectusData>(
          {String? fields, required Iterable<Type> objectList});

  Future<Type> updateItem<Type extends DirectusData>(
      {required Type objectToUpdate, String? fields});
  Future<bool> deleteItem<Type extends DirectusData>(
      {required String objectId, bool mustBeAuthenticated = true});
  Future<bool> deleteMultipleItems<Type extends DirectusData>(
      {required Iterable<dynamic> objectIdsToDelete,
      bool mustBeAuthenticated = true});
  Future<DirectusFile> uploadFileFromUrl(
      {required String remoteUrl, String? title, String? folder});
  Future<DirectusFile> uploadFile(
      {required List<int> fileBytes,
      required String filename,
      String? title,
      String? contentType,
      String? folder,
      String storage});
  Future<DirectusFile> updateExistingFile(
      {required List<int> fileBytes,
      required String fileId,
      required String filename,
      String? contentType});
  Future<bool> deleteFile({required String fileId});
  Future<T> sendRequestToEndpoint<T>(
      {required BaseRequest Function() prepareRequest,
      required T Function(Response) jsonConverter});
  bool get shouldRefreshToken;
  String? get accessToken;
  String? get refreshToken;
  Future<bool> tryAndRefreshToken();
  String get webSocketBaseUrl;
}
