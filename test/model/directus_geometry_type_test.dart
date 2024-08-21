import 'package:directus_api_manager/src/model/directus_geometry_type.dart';
import 'package:test/test.dart';

void main() {
  group('DirectusGeometryType', () {
    test('from json', () {
      final jsonData = {
        "type": "Point",
        "coordinates": [2.345, 40.393837]
      };
      final geometry = DirectusGeometryType.fromJSON(jsonData);
      expect(geometry.type, "Point");
      expect(geometry.coordinates, [2.345, 40.393837]);
      expect(geometry.pointLatitude, 40.393837);
      expect(geometry.pointLongitude, 2.345);
    });

    test('to json', () {
      final geometry = DirectusGeometryType("Point", [2.345, 40.393837]);
      final jsonData = geometry.toJSON();
      expect(jsonData["type"], "Point");
      expect(jsonData["coordinates"], [2.345, 40.393837]);
    });

    test('mapPoint', () {
      final geometry =
          DirectusGeometryType.mapPoint(latitude: 40.393837, longitude: 2.345);
      expect(geometry.type, "Point");
      expect(geometry.coordinates, [2.345, 40.393837]);
      expect(geometry.pointLatitude, 40.393837);
      expect(geometry.pointLongitude, 2.345);
    });

    test('point', () {
      final geometry = DirectusGeometryType.point(x: 2.345, y: 40.393837);
      expect(geometry.type, "Point");
      expect(geometry.coordinates, [2.345, 40.393837]);
      expect(geometry.pointX, 2.345);
      expect(geometry.pointY, 40.393837);
    });
  });
}
