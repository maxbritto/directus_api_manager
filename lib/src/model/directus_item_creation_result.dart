import 'package:directus_api_manager/src/model/directus_api_error.dart';

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
}
