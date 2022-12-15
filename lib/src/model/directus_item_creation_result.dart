import 'package:directus_api_manager/src/model/directus_api_error.dart';

class DirectusItemCreationResult<T> {
  final bool isSuccess;
  List<T> createdItemList = [];
  DirectusApiError? error;

  DirectusItemCreationResult({required this.isSuccess, this.error});
}
