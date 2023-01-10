import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

main() {
  group('DirectusItem', () {
    test('Creating an invalid item should throw', () {
      expect(() => DirectusItem({}), throwsException);
      expect(() => DirectusItem({"id": "123-abc"}), returnsNormally);
    });

    test('Extra properties can be added and read', () {
      final sut = DirectusItem({"id": "abc-123"});
      sut.setValue("Sète", forKey: "location");
      expect(sut.getValue(forKey: "location"), "Sète");
    });

    test('Reading an undefined property returns null without crashing', () {
      final sut = DirectusItem({"id": "abc-123"});
      expect(sut.getValue(forKey: "undefined_property"), null);
    });

    test('needsSaving on custom properties', () {
      final sut = DirectusItem({
        "id": "abc-123",
      });
      expect(sut.needsSaving, false);
      sut.setValue("endor", forKey: "location");
      expect(sut.needsSaving, true);
    });
  });
}
