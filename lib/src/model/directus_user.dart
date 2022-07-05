class DirectusUser {
  final String id;
  final Map<String, dynamic> allProperties;

  String get email => allProperties["email"];
  set email(String value) => allProperties["email"] = value;

  set password(String value) => allProperties["password"] = value;

  String? get firstname => allProperties["first_name"];
  set firstname(String? value) => allProperties["first_name"] = value;

  String? get lastname => allProperties["last_name"];
  set lastname(String? value) => allProperties["last_name"] = value;

  String? get description => allProperties["description"];
  set description(String? value) => allProperties["description"] = value;

  String? get roleUUID => allProperties["role"];
  set roleUUID(String? value) => allProperties["role"] = value;

  setValue(dynamic value, {required String forKey}) {
    allProperties[forKey] = value;
  }

  dynamic getValue({required String forKey}) => allProperties[forKey];

  /// Creates a new [DirectusUser]
  ///
  /// [allProperties] must contain at least an `"id"` and an `"email"` properties. Throws [Exception] if they are missing.
  ///
  /// Can support official properties listed here : https://docs.directus.io/reference/system/users/#the-user-object
  ///
  /// You can add any other custom property that you have added to your *directus_user* model on your server.
  DirectusUser(this.allProperties)
      : id = allProperties.containsKey("id")
            ? allProperties["id"]
            : throw Exception("id is required") {
    if (allProperties.containsKey("email") == false) {
      throw Exception("email is required");
    }
  }

  DirectusUser.from({required this.id, required String email})
      : allProperties = {"id": id, "email": email};

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
