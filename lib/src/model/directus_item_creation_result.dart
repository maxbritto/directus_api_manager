import 'package:directus_api_manager/src/directus_api.dart';
import 'package:directus_api_manager/src/model/directus_api_error.dart';
import 'package:http/http.dart';

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
      required T Function(dynamic json) createItemFunction}) {
    final DirectusItemCreationResult<T> creationResult;
    if (response.statusCode == 200) {
      creationResult = DirectusItemCreationResult(isSuccess: true);
      creationResult.createdItemList
          .add(createItemFunction(api.parseCreateNewItemResponse(response)));
    } else if (response.statusCode == 204) {
      creationResult = DirectusItemCreationResult(isSuccess: true);
    } else {
      creationResult = DirectusItemCreationResult(
          isSuccess: false, error: DirectusApiError(response: response));
    }

    return creationResult;
  }
}
