import 'package:directus_api_manager/src/model/directus_data.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class TestDiretusData extends DirectusData {
  TestDiretusData(Map<String, dynamic> rawReceivedData)
      : super(rawReceivedData);
}

main() {
  group('DirectusData', () {
    test('Creating an invalid item should throw', () {
      expect(() => TestDiretusData({}), throwsException);
      expect(() => TestDiretusData({"id": "123-abc"}), returnsNormally);
    });

    test('Extra properties can be added and read', () {
      final sut = TestDiretusData({"id": "abc-123"});
      sut.setValue("Sète", forKey: "location");
      expect(sut.getValue(forKey: "location"), "Sète");
    });

    test('Reading an undefined property returns null without crashing', () {
      final sut = TestDiretusData({"id": "abc-123"});
      expect(sut.getValue(forKey: "undefined_property"), null);
    });

    test('needsSaving on custom properties', () {
      final sut = TestDiretusData({
        "id": "abc-123",
      });
      expect(sut.needsSaving, false);
      sut.setValue("endor", forKey: "location");
      expect(sut.needsSaving, true);
    });

    test('Generate map of this object', () {
      final sut = TestDiretusData({"id": "abc"});
      sut.setValue("coruscant", forKey: "checkString");
      sut.setValue(true, forKey: "checkBool");
      sut.setValue(42, forKey: "checkInt");
      Map<String, dynamic> mapResult = sut.toMap();

      expect(mapResult["checkString"], "coruscant");
      expect(mapResult["checkBool"], true);
      expect(mapResult["checkInt"], 42);
    });
  });
}
