import 'package:directus_api_manager/src/annotations.dart';
import 'package:directus_api_manager/src/model/directus_data.dart';

@DirectusCollection()
@CollectionMetadata(
    endpointName: "users",
    endpointPrefix: "/",
    webSocketEndPoint: "directus_users")
class DirectusUser extends DirectusData {
  static const String emailKey = "email";
  static const String passwordKey = "password";
  static const String firstnameKey = "first_name";
  static const String lastnameKey = "last_name";
  static const String descriptionKey = "description";
  static const String roleKey = "role";
  static const String avatarKey = "avatar";
  static const String statusKey = "status";

  String? get email => getValue(forKey: emailKey);
  set email(String? value) => setValue(value, forKey: emailKey);

  set password(String value) => setValue(value, forKey: passwordKey);

  String? get firstname => getValue(forKey: firstnameKey);
  set firstname(String? value) => setValue(value, forKey: firstnameKey);

  String? get lastname => getValue(forKey: lastnameKey);
  set lastname(String? value) => setValue(value, forKey: lastnameKey);

  String? get description => getValue(forKey: descriptionKey);
  set description(String? value) => setValue(value, forKey: descriptionKey);

  String? get roleUUID => getValue(forKey: roleKey);
  set roleUUID(String? value) => setValue(value, forKey: roleKey);

  String? get avatar => getValue(forKey: avatarKey);
  set avatar(String? value) => setValue(value, forKey: avatarKey);

  UserStatus? get status {
    final value = getValue(forKey: statusKey);
    if (value == null) {
      return null;
    }
    return UserStatus.values.firstWhere((e) => e.name == value);
  }

  set status(UserStatus? value) => setValue(value?.name, forKey: statusKey);

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
