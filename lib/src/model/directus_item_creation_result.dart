class DirectusItemCreationResult<T> {
  final bool isSuccess;
  final T? createdItem;

  const DirectusItemCreationResult({required this.isSuccess, this.createdItem});
}
