import 'package:directus_api_manager/src/model/copyable.dart';

abstract class DirectusItem implements Copyable {
  fromMap(Map<String, dynamic> data);
}
