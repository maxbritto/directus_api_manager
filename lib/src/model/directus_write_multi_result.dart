class DirectusMultiWriteItemResult<T> {
  final bool isSuccess;
  final List<T> createdItemsList;

  const DirectusMultiWriteItemResult(
      {required this.isSuccess, required this.createdItemsList});
}
