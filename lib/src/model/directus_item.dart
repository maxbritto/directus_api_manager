import 'package:directus_api_manager/src/model/directus_data.dart';

abstract class DirectusItem extends DirectusData {
  // Creates a new [DirectusItem]
  DirectusItem(super.rawReceivedData);
  DirectusItem.newItem() : super.newDirectusData();
  DirectusItem.withId(dynamic id) : super.withId(id);
}
