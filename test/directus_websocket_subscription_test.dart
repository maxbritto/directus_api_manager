import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'directus_websocket_subscription_test.reflectable.dart';
import 'model/directus_item_test.dart';

main() {
  initializeReflectable();
  late DirectusWebSocketSubscription sut;

  group('DirectusWebSocketSubscription', () {
    setUp(() {
      sut = DirectusWebSocketSubscription<DirectusItemTest>(
          fields: ["id", "name"], collection: "collectionName");
    });

    test('Init value are set', () {
      expect(sut.collection, "collectionName");
    });

    test('Fields json generator', () {
      expect(sut.fieldsToJson, ["id", "name"]);
      final DirectusWebSocketSubscription<DirectusItemTest> temp =
          DirectusWebSocketSubscription<DirectusItemTest>(
              collection: "testCollection");
      expect(temp.fieldsToJson, ["*"]);
    });

    test('Filter json generator', () {
      expect(sut.filterToJson, null);
      final filter = PropertyFilter(
          field: "id", operator: FilterOperator.equals, value: "123-abc");
      final DirectusWebSocketSubscription temp =
          DirectusWebSocketSubscription<DirectusItemTest>(
              collection: "testCollection", filter: filter);
      expect(temp.filterToJson, {
        'id': {'_eq': '123-abc'}
      });
    });

    test("toJson", () {
      expect(sut.toJson(),
          '{"type":"subscribe","collection":"collectionName","query":{"fields":["id","name"]}}');
      final filter = PropertyFilter(
          field: "id", operator: FilterOperator.equals, value: "123-abc");
      final List<SortProperty> sort = [SortProperty("id", ascending: true)];

      DirectusWebSocketSubscription temp =
          DirectusWebSocketSubscription<DirectusItemTest>(
              collection: "collectionName", filter: filter);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"collectionName","query":{"fields":["*"],"filter":{"id":{"_eq":"123-abc"}}}}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          collection: "collectionName", fields: ["id", "name"]);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"collectionName","query":{"fields":["id","name"]}}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          collection: "collectionName", sort: sort, fields: ["id", "name"]);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"collectionName","query":{"fields":["id","name"],"sort":["id"]}}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          collection: "collectionName",
          fields: ["id", "name"],
          sort: [SortProperty("id", ascending: false)]);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"collectionName","query":{"fields":["id","name"],"sort":["-id"]}}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          collection: "collectionName", fields: ["id", "name"], limit: 2);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"collectionName","query":{"fields":["id","name"],"limit":2}}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          collection: "collectionName", fields: ["id", "name"], offset: 2);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"collectionName","query":{"fields":["id","name"],"offset":2}}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          collection: "collectionName", fields: ["id", "name"], uid: "testUid");
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"collectionName","query":{"fields":["id","name"]},"uid":"testUid"}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          collection: "collectionName",
          fields: ["id", "name"],
          filter: filter,
          sort: sort,
          limit: 2,
          offset: 2,
          uid: "testUid");
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"collectionName","query":{"fields":["id","name"],"filter":{"id":{"_eq":"123-abc"}},"sort":["id"],"limit":2,"offset":2},"uid":"testUid"}');
    });
  });
}
