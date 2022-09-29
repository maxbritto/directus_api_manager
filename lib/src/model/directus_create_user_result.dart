import 'package:directus_api_manager/directus_api_manager.dart';

class DirectusCreateUserResult {
  final bool isSuccess;
  DirectusUser? userCreated;

  DirectusCreateUserResult({required this.isSuccess, this.userCreated});
}
