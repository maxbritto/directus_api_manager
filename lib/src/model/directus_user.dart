import 'package:directus_api_manager/src/annotations.dart';
import 'package:directus_api_manager/src/model/directus_data.dart';

@DirectusCollection()
@CollectionMetadata(
    endpointName: "users",
    endpointPrefix: "/",
    webSocketEndPoint: "directus_users")
class DirectusUser extends DirectusData {
  String? get email => getValue(forKey: "email");
  set email(String? value) => setValue(value, forKey: "email");

  set password(String value) => setValue(value, forKey: "password");

  String? get firstname => getValue(forKey: "first_name");
  set firstname(String? value) => setValue(value, forKey: "first_name");

  String? get lastname => getValue(forKey: "last_name");
  set lastname(String? value) => setValue(value, forKey: "last_name");

  String? get description => getValue(forKey: "description");
  set description(String? value) => setValue(value, forKey: "description");

  String? get roleUUID => getValue(forKey: "role");
  set roleUUID(String? value) => setValue(value, forKey: "role");

  String? get avatar => getValue(forKey: "avatar");
  set avatar(String? value) => setValue(value, forKey: "avatar");

  UserStatus? get status {
    final value = getValue(forKey: "status");
    if (value == null) {
      return null;
    }
    return UserStatus.values.firstWhere((e) => e.name == value);
  }

  set status(UserStatus? value) => setValue(value?.name, forKey: "status");

  /// Creates a new [DirectusUser]
  ///
  /// [_rawReceivedData] must contain at least an `"id"`. Throws [Exception] if it is missing.
  ///
  /// Can support official properties listed here : https://docs.directus.io/reference/system/users/#the-user-object
  ///
  /// You can add any other custom property that you have added to your *directus_user* model on your server.
  DirectusUser(super.rawReceivedData);

  DirectusUser.newDirectusUser(
      {required String email,
      required String password,
      String? firstname,
      String? lastname,
      String? roleUUID,
      Map<String, dynamic> otherProperties = const {}})
      : super.newDirectusData() {
    this.email = email;
    this.password = password;
    this.firstname = firstname;
    this.lastname = lastname;
    this.roleUUID = roleUUID;
    for (final key in otherProperties.keys) {
      setValue(otherProperties[key], forKey: key);
    }
  }

  String get fullName {
    final String currentFirstName = firstname ?? "";
    final String currentLastName = lastname ?? "";

    final buffer = StringBuffer(currentFirstName);

    if (currentFirstName != "" && currentLastName != "") {
      buffer.write(" ");
    }

    buffer.write(currentLastName);

    return buffer.toString();
  }
}

enum UserStatus {
  draft,
  invited,
  unverified,
  active,
  suspended,
  archived;
}
