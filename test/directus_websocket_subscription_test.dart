import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'directus_websocket_subscription_test.reflectable.dart';
import 'model/directus_item_test.dart';

void main() {
  initializeReflectable();
  late DirectusWebSocketSubscription sut;

  String? callBack(Map<String, dynamic> data) => null;

  group('DirectusWebSocketSubscription', () {
    setUp(() {
      sut = DirectusWebSocketSubscription<DirectusItemTest>(
          uid: "itemTest", fields: ["id", "name"], onCreate: callBack);
    });

    test("Init with no call back must throw an exception", () {
      expect(
          () => DirectusWebSocketSubscription<DirectusItemTest>(
              uid: "itemTest", fields: ["id", "name"]),
          throwsException);
    });

    test("Init with at least one call back must return normaly", () {
      expect(
          () => DirectusWebSocketSubscription<DirectusItemTest>(
              uid: "itemTest", fields: ["id", "name"], onCreate: callBack),
          returnsNormally);
      expect(
          () => DirectusWebSocketSubscription<DirectusItemTest>(
              uid: "itemTest", fields: ["id", "name"], onUpdate: callBack),
          returnsNormally);
      expect(
          () => DirectusWebSocketSubscription<DirectusItemTest>(
              uid: "itemTest", fields: ["id", "name"], onDelete: callBack),
          returnsNormally);
    });

    test('Init value are set', () {
      expect(sut.collection, "itemTest");
    });

    test('Fields json generator', () {
      expect(sut.fieldsToJson, ["id", "name"]);
      final DirectusWebSocketSubscription<DirectusItemTest> temp =
          DirectusWebSocketSubscription<DirectusItemTest>(
              uid: "itemTest", onCreate: callBack);
      expect(temp.fieldsToJson, ["*"]);
    });

    test('Filter json generator', () {
      expect(sut.filterToJson, null);
      final filter = PropertyFilter(
          field: "id", operator: FilterOperator.equals, value: "123-abc");
      final DirectusWebSocketSubscription temp =
          DirectusWebSocketSubscription<DirectusItemTest>(
              uid: "itemTest", filter: filter, onCreate: callBack);
      expect(temp.filterToJson, {
        'id': {'_eq': '123-abc'}
      });
    });

    test("toJson", () {
      expect(sut.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"]},"uid":"itemTest"}');
      final filter = PropertyFilter(
          field: "id", operator: FilterOperator.equals, value: "123-abc");
      final List<SortProperty> sort = [SortProperty("id", ascending: true)];

      DirectusWebSocketSubscription temp =
          DirectusWebSocketSubscription<DirectusItemTest>(
              uid: "itemTest", filter: filter, onCreate: callBack);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["*"],"filter":{"id":{"_eq":"123-abc"}}},"uid":"itemTest"}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          uid: "itemTest", fields: ["id", "name"], onCreate: callBack);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"]},"uid":"itemTest"}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          uid: "itemTest",
          sort: sort,
          fields: ["id", "name"],
          onCreate: callBack);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"],"sort":["id"]},"uid":"itemTest"}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          uid: "itemTest",
          fields: ["id", "name"],
          sort: [SortProperty("id", ascending: false)],
          onCreate: callBack);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"],"sort":["-id"]},"uid":"itemTest"}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          uid: "itemTest",
          fields: ["id", "name"],
          limit: 2,
          onCreate: callBack);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"],"limit":2},"uid":"itemTest"}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          uid: "itemTest",
          fields: ["id", "name"],
          offset: 2,
          onCreate: callBack);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"],"offset":2},"uid":"itemTest"}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          uid: "itemTest", fields: ["id", "name"], onCreate: callBack);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"]},"uid":"itemTest"}');

      temp = DirectusWebSocketSubscription<DirectusItemTest>(
          fields: ["id", "name"],
          filter: filter,
          sort: sort,
          limit: 2,
          offset: 2,
          uid: "itemTest",
          onCreate: callBack);
      expect(temp.toJson(),
          '{"type":"subscribe","collection":"itemTest","query":{"fields":["id","name"],"filter":{"id":{"_eq":"123-abc"}},"sort":["id"],"limit":2,"offset":2},"uid":"itemTest"}');
    });

    test("toJson for directus_files end point", () {
      sut = DirectusWebSocketSubscription<DirectusFile>(
          uid: "itemTest", fields: ["id", "name"], onCreate: callBack);
      expect(sut.toJson(),
          '{"type":"subscribe","collection":"directus_files","query":{"fields":["id","name"]},"uid":"itemTest"}');
    });

    test("toJson for directus_users end point", () {
      sut = DirectusWebSocketSubscription<DirectusUser>(
          uid: "itemTest", fields: ["id", "name"], onCreate: callBack);
      expect(sut.toJson(),
          '{"type":"subscribe","collection":"directus_users","query":{"fields":["id","name"]},"uid":"itemTest"}');
    });
  });
}
