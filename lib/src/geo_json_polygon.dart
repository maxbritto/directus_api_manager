import 'dart:math' as math;

/// A helper class to create GeoJSON polygon features for geospatial filtering
class GeoJsonPolygon {
  /// The list of coordinate points that form the polygon.
  ///
  /// Each point is represented as a list of two doubles [longitude, latitude].
  /// The first and last points must be the same to form a closed polygon.
  final List<List<double>> coordinates;

  /// Creates a GeoJsonPolygon with the given coordinates.
  ///
  /// The coordinates should be in the format [[lng1, lat1], [lng2, lat2], ...].
  /// The first and last points must be the same to form a closed polygon.
  GeoJsonPolygon.polygon({required List<List<double>> points})
      : coordinates = _ensureClosedPolygon(points);

  /// Creates a rectangular GeoJsonPolygon from top-left and bottom-right coordinates.
  ///
  /// Parameters:
  /// - topLeft: The [longitude, latitude] of the top-left corner
  /// - bottomRight: The [longitude, latitude] of the bottom-right corner
  GeoJsonPolygon.rectangle({
    required List<double> topLeft,
    required List<double> bottomRight,
  }) : coordinates = _createRectangle(topLeft, bottomRight);

  /// Creates a square GeoJsonPolygon centered at the given point.
  ///
  /// Parameters:
  /// - center: The [longitude, latitude] of the center point
  /// - distanceInMeters: The distance from the center to each side (in meters)
  GeoJsonPolygon.squareFromCenter({
    required List<double> center,
    required double distanceInMeters,
  }) : coordinates = _createSquareFromCenter(center, distanceInMeters);

  /// Ensures the polygon is closed (first and last points are the same)
  static List<List<double>> _ensureClosedPolygon(List<List<double>> points) {
    if (points.isEmpty) {
      throw ArgumentError('Points list cannot be empty');
    }

    // Make a deep copy to avoid modifying the original list
    final List<List<double>> polygon =
        List.from(points.map((point) => List<double>.from(point)));

    // Check if the first and last points are the same
    if (polygon.length < 3) {
      throw ArgumentError('A polygon must have at least 3 distinct points');
    }

    final firstPoint = polygon.first;
    final lastPoint = polygon.last;

    // If the polygon isn't closed, close it by adding the first point again
    if (firstPoint[0] != lastPoint[0] || firstPoint[1] != lastPoint[1]) {
      polygon.add(List<double>.from(firstPoint));
    }

    return polygon;
  }

  /// Creates a rectangle from top-left and bottom-right coordinates
  static List<List<double>> _createRectangle(
      List<double> topLeft, List<double> bottomRight) {
    if (topLeft.length != 2 || bottomRight.length != 2) {
      throw ArgumentError('Coordinates must be [longitude, latitude]');
    }

    final double topLeftLng = topLeft[0];
    final double topLeftLat = topLeft[1];
    final double bottomRightLng = bottomRight[0];
    final double bottomRightLat = bottomRight[1];

    return [
      [topLeftLng, topLeftLat], // Top-left
      [bottomRightLng, topLeftLat], // Top-right
      [bottomRightLng, bottomRightLat], // Bottom-right
      [topLeftLng, bottomRightLat], // Bottom-left
      [topLeftLng, topLeftLat], // Back to top-left to close the polygon
    ];
  }

  /// Creates a square centered at the given point
  static List<List<double>> _createSquareFromCenter(
      List<double> center, double distanceInMeters) {
    if (center.length != 2) {
      throw ArgumentError('Center must be [longitude, latitude]');
    }

    if (distanceInMeters <= 0) {
      throw ArgumentError('Distance must be positive');
    }

    final double centerLng = center[0];
    final double centerLat = center[1];

    // Convert meters to degrees at this latitude
    // Earth's radius in meters at the equator
    const double earthRadius = 6378137.0;

    // Latitude conversion: 1 meter = 1/(Earth's circumference/360) degrees
    // 1 meter = 1/(2πR/360) degrees = 360/(2πR) degrees = 180/(πR) degrees
    final double metersToDegreesLat = 180.0 / (math.pi * earthRadius);

    // Longitude conversion depends on latitude due to Earth being a spheroid
    // 1 meter = 1/(Earth's circumference at this latitude/360) degrees
    // At a given latitude, the radius is: R * cos(latitude)
    final double metersToDegreesLng =
        metersToDegreesLat / math.cos(centerLat * math.pi / 180.0);

    // Convert the distance from meters to degrees for both directions
    final double distanceInDegreesLat = distanceInMeters * metersToDegreesLat;
    final double distanceInDegreesLng = distanceInMeters * metersToDegreesLng;

    // Calculate half-distances for creating the square
    final double halfDistanceLat = distanceInDegreesLat / 2;
    final double halfDistanceLng = distanceInDegreesLng / 2;

    // Create the corners of the square
    return [
      [centerLng - halfDistanceLng, centerLat + halfDistanceLat], // Top-left
      [centerLng + halfDistanceLng, centerLat + halfDistanceLat], // Top-right
      [
        centerLng + halfDistanceLng,
        centerLat - halfDistanceLat
      ], // Bottom-right
      [centerLng - halfDistanceLng, centerLat - halfDistanceLat], // Bottom-left
      [
        centerLng - halfDistanceLng,
        centerLat + halfDistanceLat
      ], // Back to top-left to close the polygon
    ];
  }

  /// Returns the GeoJSON representation of this polygon as a Map.
  ///
  /// This format is compatible with the intersectsBbox filter.
  Map<String, dynamic> get asJson => {
        "type": "Feature",
        "geometry": {
          "coordinates": [coordinates],
          "type": "Polygon"
        }
      };
}
