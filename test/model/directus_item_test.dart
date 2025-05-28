import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

@DirectusCollection()
@CollectionMetadata(endpointName: "itemTest")
class DirectusItemTest extends DirectusItem {
  DirectusItemTest(super.rawReceivedData);
  DirectusItemTest.newItem() : super.newItem();
}

@DirectusCollection()
@CollectionMetadata(endpointName: "itemTest", defaultUpdateFields: "id,name")
class DirectusItemTestWithUpdateField extends DirectusItem {
  DirectusItemTestWithUpdateField(super.rawReceivedData);
  DirectusItemTestWithUpdateField.newItem() : super.newItem();

  String get name => getValue(forKey: "name");
  bool get canBeChanged => getValue(forKey: "canBeChanged");
}

void main() {
  group('DirectusItem', () {
    test('New Item', () {
      expect(() => DirectusItemTest.newItem(), returnsNormally);
    });

    test('Exisitng Item', () {
      final item = DirectusItemTest({"id": "123-abc"});
      expect(item.id, "123-abc");
    });
  });
}
