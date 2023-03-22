import 'package:directus_api_manager/src/directus_api.dart';
import 'package:directus_api_manager/src/model/directus_api_error.dart';
import 'package:http/http.dart';
import 'package:reflectable/mirrors.dart';

class DirectusItemCreationResult<T> {
  final bool isSuccess;
  List<T> createdItemList = [];
  DirectusApiError? error;

  DirectusItemCreationResult({required this.isSuccess, this.error}) {
    if (!isSuccess && error == null) {
      throw Exception("error must be initialized");
    }
  }

  T? get createdItem {
    return createdItemList.isEmpty ? null : createdItemList.first;
  }

  factory DirectusItemCreationResult.fromDirectus(
      {required IDirectusAPI api,
      required Response response,
      required ClassMirror classMirror}) {
    final DirectusItemCreationResult<T> creationResult;
    if (response.statusCode == 200) {
      creationResult = DirectusItemCreationResult(isSuccess: true);
      final objectData = api.parseCreateNewItemResponse(response);
      creationResult.createdItemList
          .add(classMirror.newInstance('', [objectData]) as T);
    } else if (response.statusCode == 204) {
      creationResult = DirectusItemCreationResult(isSuccess: true);
    } else {
      creationResult = DirectusItemCreationResult(
          isSuccess: false, error: DirectusApiError(response: response));
    }

    return creationResult;
  }
}
