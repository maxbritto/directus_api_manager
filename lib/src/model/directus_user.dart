class DirectusUser {
  final String id;
  final Map<String, dynamic> _rawReceivedData;
  Map<String, dynamic> getRawData() => _rawReceivedData;
  final Map<String, dynamic> updatedProperties = {};
  bool get needsSaving => updatedProperties.isNotEmpty;

  String get email => getValue(forKey: "email");
  set email(String value) => setValue(value, forKey: "email");

  set password(String value) => setValue(value, forKey: "password");

  String? get firstname => getValue(forKey: "first_name");
  set firstname(String? value) => setValue(value, forKey: "first_name");

  String? get lastname => getValue(forKey: "last_name");
  set lastname(String? value) => setValue(value, forKey: "last_name");

  String? get description => getValue(forKey: "description");
  set description(String? value) => setValue(value, forKey: "description");

  String? get roleUUID => getValue(forKey: "role");
  set roleUUID(String? value) => setValue(value, forKey: "role");

  setValue(dynamic value, {required String forKey}) {
    updatedProperties[forKey] = value;
  }

  dynamic getValue({required String forKey}) {
    return updatedProperties[forKey] ?? _rawReceivedData[forKey];
  }

  /// Creates a new [DirectusUser]
  ///
  /// [_rawReceivedData] must contain at least an `"id"` and an `"email"` properties. Throws [Exception] if they are missing.
  ///
  /// Can support official properties listed here : https://docs.directus.io/reference/system/users/#the-user-object
  ///
  /// You can add any other custom property that you have added to your *directus_user* model on your server.
  DirectusUser(this._rawReceivedData)
      : id = _rawReceivedData.containsKey("id")
            ? _rawReceivedData["id"]
            : throw Exception("id is required") {
    if (_rawReceivedData.containsKey("email") == false) {
      throw Exception("email is required");
    }
  }

  DirectusUser.from({required this.id, required String email})
      : _rawReceivedData = {"id": id, "email": email};

  String get fullName {
    String result = "";

    final String currentFirstName = firstname ?? "";
    final String currentLastName = lastname ?? "";

    result = currentFirstName;

    if (currentFirstName != "" && currentLastName != "") {
      result = result + " ";
    }

    result = result + currentLastName;

    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstname,
      'last_name': lastname
    };
  }
}
