class DirectusWriteItemResult<T> {
  final bool isSuccess;
  final T? createdItem;

  const DirectusWriteItemResult({required this.isSuccess, this.createdItem});
}
