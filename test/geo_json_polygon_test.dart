import 'package:directus_api_manager/src/geo_json_polygon.dart';
import 'package:directus_api_manager/src/filter.dart';
import 'package:test/test.dart';

void main() {
  group('GeoJsonPolygon', () {
    group('polygon constructor', () {
      test('creates a polygon from coordinates', () {
        final coordinates = [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 1.0],
        ];

        final polygon = GeoJsonPolygon.polygon(points: coordinates);

        // Should automatically close the polygon
        expect(polygon.coordinates.length, 5);
        expect(polygon.coordinates.first[0], polygon.coordinates.last[0]);
        expect(polygon.coordinates.first[1], polygon.coordinates.last[1]);
      });

      test('accepts already-closed polygon', () {
        final coordinates = [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 1.0],
          [0.0, 0.0], // Already closed
        ];

        final polygon = GeoJsonPolygon.polygon(points: coordinates);

        // Should not add another closing point
        expect(polygon.coordinates.length, 5);
        expect(polygon.coordinates, coordinates);
      });

      test('throws error for empty coordinates', () {
        expect(() => GeoJsonPolygon.polygon(points: []), throwsArgumentError);
      });

      test('throws error for insufficient points', () {
        expect(
            () => GeoJsonPolygon.polygon(points: [
                  [0.0, 0.0],
                  [1.0, 1.0]
                ]),
            throwsArgumentError);
      });
    });

    group('rectangle constructor', () {
      test('creates a rectangle from top-left and bottom-right coordinates',
          () {
        final topLeft = [0.0, 1.0];
        final bottomRight = [1.0, 0.0];

        final polygon = GeoJsonPolygon.rectangle(
          topLeft: topLeft,
          bottomRight: bottomRight,
        );

        expect(polygon.coordinates.length, 5);
        expect(polygon.coordinates[0], [0.0, 1.0]); // Top-left
        expect(polygon.coordinates[1], [1.0, 1.0]); // Top-right
        expect(polygon.coordinates[2], [1.0, 0.0]); // Bottom-right
        expect(polygon.coordinates[3], [0.0, 0.0]); // Bottom-left
        expect(polygon.coordinates[4], [0.0, 1.0]); // Back to top-left (closed)
      });

      test('throws error for invalid coordinates', () {
        expect(
            () => GeoJsonPolygon.rectangle(
                  topLeft: [0.0],
                  bottomRight: [1.0, 0.0],
                ),
            throwsArgumentError);
        expect(
            () => GeoJsonPolygon.rectangle(
                  topLeft: [0.0, 1.0],
                  bottomRight: [1.0],
                ),
            throwsArgumentError);
      });
    });

    group('squareFromCenter constructor', () {
      test('creates a square centered at the given point', () {
        final center = [0.0, 0.0];
        final distanceInMeters = 1000.0;

        final polygon = GeoJsonPolygon.squareFromCenter(
          center: center,
          distanceInMeters: distanceInMeters,
        );

        // No need to check exact values as the conversion depends on latitude
        // Just verify we get a proper square with 5 points (closed polygon)
        expect(polygon.coordinates.length, 5);

        // Verify first and last points are the same (closed polygon)
        expect(polygon.coordinates.first[0], polygon.coordinates.last[0]);
        expect(polygon.coordinates.first[1], polygon.coordinates.last[1]);

        // Verify it's a square (opposite corners have same distance)
        final double dx1 =
            polygon.coordinates[0][0] - polygon.coordinates[2][0];
        final double dy1 =
            polygon.coordinates[0][1] - polygon.coordinates[2][1];
        final double dx2 =
            polygon.coordinates[1][0] - polygon.coordinates[3][0];
        final double dy2 =
            polygon.coordinates[1][1] - polygon.coordinates[3][1];

        // Diagonal distances should be approximately equal
        expect((dx1 * dx1 + dy1 * dy1), closeTo(dx2 * dx2 + dy2 * dy2, 0.001));
      });

      test('throws error for invalid center coordinates', () {
        expect(
            () => GeoJsonPolygon.squareFromCenter(
                  center: [0.0],
                  distanceInMeters: 1.0,
                ),
            throwsArgumentError);
      });

      test('throws error for non-positive distance', () {
        expect(
            () => GeoJsonPolygon.squareFromCenter(
                  center: [0.0, 0.0],
                  distanceInMeters: 0.0,
                ),
            throwsArgumentError);
        expect(
            () => GeoJsonPolygon.squareFromCenter(
                  center: [0.0, 0.0],
                  distanceInMeters: -1.0,
                ),
            throwsArgumentError);
      });
    });

    group('asJson', () {
      test('returns properly formatted GeoJSON', () {
        final polygon = GeoJsonPolygon.rectangle(
          topLeft: [0.0, 1.0],
          bottomRight: [1.0, 0.0],
        );
        final json = polygon.asJson;

        expect(json['type'], 'Feature');
        expect(json['geometry']['type'], 'Polygon');
        expect(json['geometry']['coordinates'].length, 1);
        expect(json['geometry']['coordinates'][0].length, 5);
      });
    });

    // Integration test with GeoFilter
    test('works with GeoFilter to create intersects_bbox filter', () {
      final polygon = GeoJsonPolygon.rectangle(
        topLeft: [168.2947501099543, -17.723682144590242],
        bottomRight: [168.29840874403044, -17.727328428851507],
      );

      // Create a filter using the GeoJsonPolygon
      final filter = GeoFilter(
        field: "location",
        operator: GeoFilterOperator.intersectsBbox,
        feature: polygon,
      );

      // Check that the filter correctly uses the polygon
      final map = filter.asMap;
      expect(map['location']['_intersects_bbox']['type'], 'Feature');
      expect(
          map['location']['_intersects_bbox']['geometry']['type'], 'Polygon');
    });
  });
}
