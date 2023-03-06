abstract class DirectusData {
  final Map<String, dynamic> _rawReceivedData;
  final Map<String, dynamic> updatedProperties = {};

  DirectusData(this._rawReceivedData) {
    if (!_rawReceivedData.containsKey("id")) {
      throw Exception("id is required");
    }
  }

  DirectusData.newDirectusData([this._rawReceivedData = const {}]);

  String? get id {
    dynamic idData = getValue(forKey: "id");
    if (idData is int) {
      return idData.toString();
    }

    return idData;
  }

  Map<String, dynamic> getRawData() => _rawReceivedData;
  bool get needsSaving => updatedProperties.isNotEmpty;

  setValue(dynamic value, {required String forKey}) {
    if (value != getValue(forKey: forKey)) {
      updatedProperties[forKey] = value;
    }
  }

  dynamic getValue({required String forKey}) {
    return updatedProperties.containsKey(forKey)
        ? updatedProperties[forKey]
        : _rawReceivedData[forKey];
  }
}

extension DirectusDataExtension on DirectusData {
  Map<String, dynamic> mapForObjectCreation() {
    return Map<String, dynamic>.of(_rawReceivedData)
      ..addAll(updatedProperties)
      ..remove("id");
  }
}
