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
          fields: ["id", "name"]);
    });

    test('Init value are set', () {
      expect(sut.collection, "itemTest");
    });

    test('Fields json generator', () {
      expect(sut.fieldsToJson, ["id", "name"]);
      final DirectusWebSocketSubscription<DirectusItemTest> temp =
          DirectusWebSocketSubscription<DirectusItemTest>();
      expect(temp.fieldsToJson, ["*"]);
    });

    test('Filter json generator', () {
      expect(sut.filterToJson, null);
      final filter = PropertyFilter(
          field: "id", operator: FilterOperator.equals, value: "123-abc");
      final DirectusWebSocketSubscription temp =
          DirectusWebSocketSubscription<DirectusItemTest>(filter: filter);
      expect(temp.filterToJson, {
        'id': {'_eq': '123-abc'}
      });
    });

    test("toJson", () {
      expect(sut.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"]}}');
      final filter = PropertyFilter(
          field: "id", operator: FilterOperator.equals, value: "123-abc");
      final List<SortProperty> sort = [SortProperty("id", ascending: true)];

      DirectusWebSocketSubscription temp =
          DirectusWebSocketSubscription<DirectusItemTest>(filter: filter);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["*"],"filter":{"id":{"_eq":"123-abc"}}}}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          fields: ["id", "name"]);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"]}}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          sort: sort, fields: ["id", "name"]);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"],"sort":["id"]}}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          fields: ["id", "name"], sort: [SortProperty("id", ascending: false)]);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"],"sort":["-id"]}}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          fields: ["id", "name"], limit: 2);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"],"limit":2}}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          fields: ["id", "name"], offset: 2);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"],"offset":2}}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          fields: ["id", "name"], uid: "testUid");
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"]},"uid":"testUid"}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          fields: ["id", "name"],
          filter: filter,
          sort: sort,
          limit: 2,
          offset: 2,
          uid: "testUid");
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"],"filter":{"id":{"_eq":"123-abc"}},"sort":["id"],"limit":2,"offset":2},"uid":"testUid"}');
    });
  });
}
