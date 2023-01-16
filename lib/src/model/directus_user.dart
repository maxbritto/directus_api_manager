import 'package:directus_api_manager/src/model/directus_data.dart';

class DirectusUser extends DirectusData {
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

  /// Creates a new [DirectusUser]
  ///
  /// [_rawReceivedData] must contain at least an `"id"` and an `"email"` properties. Throws [Exception] if they are missing.
  ///
  /// Can support official properties listed here : https://docs.directus.io/reference/system/users/#the-user-object
  ///
  /// You can add any other custom property that you have added to your *directus_user* model on your server.
  DirectusUser(Map<String, dynamic> rawReceivedData) : super(rawReceivedData) {
    if (rawReceivedData.containsKey("email") == false) {
      throw Exception("email is required");
    }
  }

  DirectusUser.newDirectusUser() : super.newDirectusData();

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
}
