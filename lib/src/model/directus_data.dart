abstract class DirectusData {
  final Map<String, dynamic> _rawReceivedData;
  final Map<String, dynamic> updatedProperties = {};

  DirectusData(this._rawReceivedData) {
    if (!_rawReceivedData.containsKey("id")) {
      throw Exception("id is required");
    }
  }

  String get id => getValue(forKey: "id");
  Map<String, dynamic> getRawData() => _rawReceivedData;
  bool get needsSaving => updatedProperties.isNotEmpty;

  setValue(dynamic value, {required String forKey}) {
    updatedProperties[forKey] = value;
  }

  dynamic getValue({required String forKey}) {
    return updatedProperties[forKey] ?? _rawReceivedData[forKey];
  }

  Map<String, dynamic> toMap() {
    return Map<String, dynamic>.of(_rawReceivedData)
      ..addAll(updatedProperties)
      ..remove("id");
  }
}
