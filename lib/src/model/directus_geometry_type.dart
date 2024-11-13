/// Represents data stored in Postgres geometry type.
class DirectusGeometryType {
  final String type;
  final List<double> coordinates;

  const DirectusGeometryType(this.type, this.coordinates);
  DirectusGeometryType.mapPoint(
      {required double latitude, required double longitude})
      : this("Point", [longitude, latitude]);
  DirectusGeometryType.point({required double x, required double y})
      : this("Point", [x, y]);

  factory DirectusGeometryType.fromJSON(Map<String, dynamic> jsonData) {
    return DirectusGeometryType(
      jsonData["type"],
      List<double>.from(jsonData["coordinates"]),
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      "type": type,
      "coordinates": coordinates,
    };
  }

  double? get pointLatitude {
    if (type != "Point") {
      return null;
    }
    return coordinates[1];
  }

  double? get pointLongitude {
    if (type != "Point") {
      return null;
    }
    return coordinates[0];
  }

  double? get pointX {
    if (type != "Point") {
      return null;
    }
    return coordinates[0];
  }

  double? get pointY {
    if (type != "Point") {
      return null;
    }
    return coordinates[1];
  }
}
