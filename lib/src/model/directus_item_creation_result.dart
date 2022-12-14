class DirectusItemCreationResult<T> {
  final bool isSuccess;
  List<T> createdItemList = [];

  DirectusItemCreationResult({required this.isSuccess});
}
