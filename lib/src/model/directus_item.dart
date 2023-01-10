class DirectusItem {
  final String id;
  final Map<String, dynamic> _rawReceivedData;
  Map<String, dynamic> getRawData() => _rawReceivedData;
  final Map<String, dynamic> updatedProperties = {};
  bool get needsSaving => updatedProperties.isNotEmpty;

  setValue(dynamic value, {required String forKey}) {
    updatedProperties[forKey] = value;
  }

  dynamic getValue({required String forKey}) {
    return updatedProperties[forKey] ?? _rawReceivedData[forKey];
  }

  /// Creates a new [DirectusItem]
  DirectusItem(this._rawReceivedData)
      : id = _rawReceivedData.containsKey("id")
            ? _rawReceivedData["id"]
            : throw Exception("id is required");
}
