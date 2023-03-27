import 'package:directus_api_manager/src/model/directus_data.dart';
import 'package:directus_api_manager/src/model/directus_file.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class TestDirectusData extends DirectusData {
  TestDirectusData(Map<String, dynamic> rawReceivedData)
      : super(rawReceivedData);
}

main() {
  group('DirectusData', () {
    test('Creating an invalid item should throw', () {
      expect(() => TestDirectusData({}), throwsException);
      expect(() => TestDirectusData({"id": "123-abc"}), returnsNormally);
      expect(() => TestDirectusData({"id": 1}), returnsNormally);
    });

    test('Extra properties can be added and read', () {
      final sut = TestDirectusData({"id": "abc-123"});
      sut.setValue("Sète", forKey: "location");
      expect(sut.getValue(forKey: "location"), "Sète");
    });

    test('Reading an undefined property returns null without crashing', () {
      final sut = TestDirectusData({"id": "abc-123"});
      expect(sut.getValue(forKey: "undefined_property"), null);
    });

    test('needsSaving on custom properties', () {
      final sut = TestDirectusData({
        "id": "abc-123",
      });
      expect(sut.needsSaving, false);
      sut.setValue("endor", forKey: "location");
      expect(sut.needsSaving, true);
    });

    test('Generate map of this object', () {
      final sut = TestDirectusData({"id": "abc"});
      sut.setValue("coruscant", forKey: "checkString");
      sut.setValue(true, forKey: "checkBool");
      sut.setValue(42, forKey: "checkInt");
      Map<String, dynamic> mapResult = sut.mapForObjectCreation();

      expect(mapResult["checkString"], "coruscant");
      expect(mapResult["checkBool"], true);
      expect(mapResult["checkInt"], 42);
    });

    test('Call setValue with same value must not need saving', () {
      final sut = TestDirectusData({"id": "abc", "checkString": "star wars"});
      sut.setValue("star wars", forKey: "checkString");
      expect(sut.needsSaving, false);
      sut.setValue("lord of the ring", forKey: "checkString");
      expect(sut.needsSaving, true);
    });

    test('null updated property must return null', () {
      final sut = TestDirectusData({"id": "abc", "checkString": "star wars"});
      sut.setValue(null, forKey: "checkString");

      expect(sut.getValue(forKey: "checkString"), null);
    });

    test("getStringList should return an empty list if the property is null",
        () {
      final sut = TestDirectusData({"id": "abc"});
      expect(sut.getStringList(forKey: "checkString"), []);
    });

    test(
        "getStringList should return an empty list if the property is not a list",
        () {
      final sut = TestDirectusData({"id": "abc", "checkString": "star wars"});
      expect(sut.getStringList(forKey: "checkString"), []);
    });

    test("getStringList should return a list of string", () {
      final sut = TestDirectusData({
        "id": "abc",
        "checkString": ["star wars", "lord of the ring"]
      });
      expect(sut.getStringList(forKey: "checkString"),
          ["star wars", "lord of the ring"]);
    });

    test("getDirectusFile should return a DirectusFile", () {
      final sut = TestDirectusData({
        "id": "abc",
        "fileData": {"id": "123", "title": "star wars"}
      });
      final file = sut.getDirectusFile(forKey: "fileData");
      expect(file, isNotNull);
      expect(file, isA<DirectusFile>());
      expect(file.id, "123");
      expect(file.title, "star wars");
    });

    test("getDirectusFile should throw if the property is null", () {
      final sut = TestDirectusData({"id": "abc"});
      expect(() => sut.getDirectusFile(forKey: "fileData"),
          throwsA(isA<AssertionError>()));
    });

    test(
        "getDirectusFile should throw if the property is not a map nor a string",
        () {
      final sut = TestDirectusData({"id": "abc", "fileData": 123});
      expect(() => sut.getDirectusFile(forKey: "fileData"),
          throwsA(isA<AssertionError>()));
    });

    test("getOptionalDirectusFile should return null if the property is null",
        () {
      final sut = TestDirectusData({"id": "abc"});
      final file = sut.getOptionalDirectusFile(forKey: "fileData");
      expect(file, null);
    });

    test(
        "getOptionalDirectusFile should return null if the property is not a map nor a string",
        () {
      final sut = TestDirectusData({"id": "abc", "fileData": 123});
      final file = sut.getOptionalDirectusFile(forKey: "fileData");
      expect(file, null);
    });
    test(
        "getOptionalDirectusFile should return a DirectusFile without title if the property is a string (id)",
        () {
      final sut = TestDirectusData({"id": "abc", "fileData": "file-123"});
      final file = sut.getOptionalDirectusFile(forKey: "fileData");
      expect(file, isNotNull);
      expect(file, isA<DirectusFile?>());
      expect(file?.id, "file-123");
      expect(file?.title, null);
    });

    test("getOptionalDirectusFile should return a DirectusFile if present", () {
      final sut = TestDirectusData({
        "id": "abc",
        "fileData": {"id": "123", "title": "star wars"}
      });
      final file = sut.getOptionalDirectusFile(forKey: "fileData");
      expect(file, isNotNull);
      expect(file, isA<DirectusFile?>());
      expect(file?.id, "123");
      expect(file?.title, "star wars");
    });
  });
}
