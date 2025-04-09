import 'package:directus_api_manager/src/model/directus_data.dart';
import 'package:directus_api_manager/src/model/directus_file.dart';
import 'package:directus_api_manager/src/model/directus_geometry_type.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class TestDirectusData extends DirectusData {
  TestDirectusData(super.rawReceivedData);
}

main() {
  group('DirectusData', () {
    test('Creating an invalid item should throw', () {
      expect(() => TestDirectusData({}), throwsException);
      expect(() => TestDirectusData({"id": "123-abc"}), returnsNormally);
      expect(() => TestDirectusData({"id": 1}), returnsNormally);
    });

    test("Reading the id and intId getter", () {
      final sut1 = TestDirectusData({"id": 1});
      expect(sut1.id, "1");
      expect(sut1.intId, 1);
      expect(sut1.getRawData(), {"id": 1});

      final sut2 = TestDirectusData({"id": "abc-123"});
      expect(sut2.id, "abc-123");
      expect(sut2.intId, null);
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

    test('needsSaving and hasChangedIn on custom properties', () {
      final sut = TestDirectusData({"id": "abc-123", "name": "Darth Vader"});
      expect(sut.needsSaving, false);
      expect(sut.hasChangedIn(forKey: "name"), false);
      sut.setValue("endor", forKey: "location");
      expect(sut.needsSaving, true);
      sut.setValue("Darth Sidious", forKey: "name");
      expect(sut.hasChangedIn(forKey: "name"), true);
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
      expect(sut.getList<String>(forKey: "checkString"), []);
    });

    test(
        "getStringList should return an empty list if the property is not a list",
        () {
      final sut = TestDirectusData({"id": "abc", "checkString": "star wars"});
      expect(sut.getList<String>(forKey: "checkString"), []);
    });

    test("getStringList should return a list of string", () {
      final sut = TestDirectusData({
        "id": "abc",
        "checkString": ["star wars", "lord of the ring"]
      });
      expect(sut.getList<String>(forKey: "checkString"),
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

    test("Set optional Directus File", () {
      final DirectusFile file = DirectusFile({"id": "123"});
      final sut = TestDirectusData({"id": "abc"});
      sut.setOptionalDirectusFile(file, forKey: "file");
      DirectusFile? result = sut.getOptionalDirectusFile(forKey: "file");
      expect(result, isNotNull);
      expect(result!.id, "123");

      sut.setOptionalDirectusFile(null, forKey: "file");
      result = sut.getOptionalDirectusFile(forKey: "file");
      expect(result, isNull);
    });

    test("getList with a listof int", () {
      final sut = TestDirectusData({
        "id": "abc",
        "checkInt": <dynamic>[1, 2, 3]
      });
      final list = sut.getList<int>(forKey: "checkInt");
      expect(list, isA<List<int>>());
      expect(list, [1, 2, 3]);
    });

    test("getList with a listof string", () {
      final sut = TestDirectusData({
        "id": "abc",
        "checkString": <dynamic>["1", "2", "3"]
      });
      final list = sut.getList<String>(forKey: "checkString");
      expect(list, isA<List<String>>());
      expect(list, ["1", "2", "3"]);
    });

    test("getList with wrong value (not a list)", () {
      final sut = TestDirectusData({
        "id": "abc",
        "checkFile": "1",
      });
      final list = sut.getList<String>(forKey: "checkFile");

      expect(list, <String>[]);
    });

    test("getList with wrong value (not a list of string)", () {
      final sut = TestDirectusData({
        "id": "abc",
        "checkFile": <dynamic>[1, 2, 3],
      });
      expect(() => sut.getList<String>(forKey: "checkFile"),
          throwsA(isA<TypeError>()));
    });

    test("getObjectList with a list of DirectusData", () {
      final sut = TestDirectusData({
        "id": "abc",
        "checkObject": <dynamic>[
          {"id": "1"},
          {"id": "2"}
        ]
      });
      final list = sut.getObjectList<TestDirectusData>(
          forKey: "checkObject", fromMap: (map) => TestDirectusData(map));
      expect(list, isA<List<TestDirectusData>>());
      expect(list.length, 2);
      expect(list[0].id, "1");

      expect(list[1].id, "2");
    });

    test("getObjectList with an empty list", () {
      final sut = TestDirectusData({"id": "abc", "checkObject": null});
      final list = sut.getObjectList<TestDirectusData>(
          forKey: "checkObject", fromMap: (map) => TestDirectusData(map));
      expect(list, isA<List<TestDirectusData>>());
      expect(list.isEmpty, true);
    });

    test("getDateTime", () {
      final sut = TestDirectusData({"id": "abc", "creationDate": "2023-06-15"});
      final creationDate = sut.getDateTime(forKey: "creationDate");
      expect(creationDate, isA<DateTime>());
      expect(creationDate.year, 2023);
      expect(creationDate.month, 6);
      expect(creationDate.day, 15);
    });

    test("setOptionalDateTime", () {
      final sut = TestDirectusData({"id": "abc"});
      final creationDate = DateTime(2023, 6, 15);
      sut.setOptionalDateTime(creationDate, forKey: "creationDate");
      DateTime? saveDateTime = sut.getOptionalDateTime(forKey: "creationDate");
      expect(saveDateTime, isNotNull);
      expect(saveDateTime, isA<DateTime>());
      expect(saveDateTime!.year, 2023);
      expect(saveDateTime.month, 6);
      expect(saveDateTime.day, 15);

      sut.setOptionalDateTime(null, forKey: "creationDate");
      saveDateTime = sut.getOptionalDateTime(forKey: "creationDate");
      expect(saveDateTime, isNull);
    });

    test("getDirectusGeometryType", () {
      final sut = TestDirectusData({
        "id": "abc",
        "geometry": {
          "type": "Point",
          "coordinates": [2.345, 40.393837]
        }
      });
      final geometry = sut.getDirectusGeometryType(forKey: "geometry");
      expect(geometry, isA<DirectusGeometryType>());
      expect(geometry.type, "Point");
      expect(geometry.pointLatitude, 40.393837);
      expect(geometry.pointLongitude, 2.345);
    });

    test("getOptionalDirectusGeometryType with null value", () {
      final sut = TestDirectusData({"id": "abc"});
      final geometry = sut.getOptionalDirectusGeometryType(forKey: "geometry");
      expect(geometry, isNull);
    });

    test("getOptionalDirectusGeometryType with wrong value", () {
      final sut = TestDirectusData({"id": "abc", "geometry": 123});
      final geometry = sut.getOptionalDirectusGeometryType(forKey: "geometry");
      expect(geometry, isNull);
    });

    test("getOptionalDirectusGeometryType with valid value", () {
      final sut = TestDirectusData({
        "id": "abc",
        "geometry": {
          "type": "Point",
          "coordinates": [2.345, 40.393837]
        }
      });
      final geometry = sut.getOptionalDirectusGeometryType(forKey: "geometry");
      expect(geometry, isA<DirectusGeometryType>());
      expect(geometry?.type, "Point");
      expect(geometry?.pointLatitude, 40.393837);
      expect(geometry?.pointLongitude, 2.345);
    });

    test("toMap", () {
      final sut = TestDirectusData({"id": "abc", "title": "test"});
      Map<String, dynamic> map = sut.toMap();
      expect(map, isA<Map<String, dynamic>>());
      expect(map["id"], "abc");
      expect(map["title"], "test");
      sut.setValue("endor", forKey: "location");
      map = sut.toMap();
      expect(map["location"], "endor");
    });

    test("mapForObjectCreation", () {
      final sut = TestDirectusData({
        "id": "abc",
        "creator": {"id": "idCreator", "name": "creatorName"},
        "title": "test"
      });
      final map = sut.mapForObjectCreation();
      expect(map, isA<Map<String, dynamic>>());
      expect(map.containsKey("id"), false);
      expect(map["creationDate"], null);
      expect(map["title"], "test");
      expect(map["creator"], {"id": "idCreator", "name": "creatorName"});
    });
  });
}
