/// Maps Directus field types to Dart types and provides accessor method names.
class FieldTypeMapper {
  /// Information about how a Directus field maps to Dart.
  static FieldTypeInfo mapFieldType({
    required String directusType,
    bool isNullable = true,
    bool isFileRelation = false,
  }) {
    if (isFileRelation) {
      return isNullable
          ? const FieldTypeInfo(
              dartType: "DirectusFile?",
              getter: GetterMethod.getOptionalDirectusFile,
            )
          : const FieldTypeInfo(
              dartType: "DirectusFile",
              getter: GetterMethod.getDirectusFile,
            );
    }

    switch (directusType) {
      case "string":
      case "text":
      case "uuid":
      case "hash":
      case "csv":
        return FieldTypeInfo(
          dartType: isNullable ? "String?" : "String",
          getter: GetterMethod.getValue,
        );

      case "integer":
      case "bigInteger":
        return FieldTypeInfo(
          dartType: isNullable ? "int?" : "int",
          getter: GetterMethod.getValue,
        );

      case "float":
      case "decimal":
        return FieldTypeInfo(
          dartType: isNullable ? "double?" : "double",
          getter: GetterMethod.getValue,
        );

      case "boolean":
        return FieldTypeInfo(
          dartType: isNullable ? "bool?" : "bool",
          getter: GetterMethod.getValue,
        );

      case "dateTime":
      case "date":
      case "timestamp":
        return isNullable
            ? const FieldTypeInfo(
                dartType: "DateTime?",
                getter: GetterMethod.getOptionalDateTime,
              )
            : const FieldTypeInfo(
                dartType: "DateTime",
                getter: GetterMethod.getDateTime,
              );

      case "time":
        return FieldTypeInfo(
          dartType: isNullable ? "String?" : "String",
          getter: GetterMethod.getValue,
        );

      case "json":
        return const FieldTypeInfo(
          dartType: "dynamic",
          getter: GetterMethod.getValue,
        );

      case "geometry":
        return isNullable
            ? const FieldTypeInfo(
                dartType: "DirectusGeometryType?",
                getter: GetterMethod.getOptionalDirectusGeometryType,
              )
            : const FieldTypeInfo(
                dartType: "DirectusGeometryType",
                getter: GetterMethod.getDirectusGeometryType,
              );

      default:
        return FieldTypeInfo(
          dartType: isNullable ? "dynamic" : "dynamic",
          getter: GetterMethod.getValue,
        );
    }
  }

  /// Generates the getter code for a field.
  static String generateGetter({
    required String propertyName,
    required String fieldKey,
    required FieldTypeInfo typeInfo,
    required String keyConstantName,
  }) {
    switch (typeInfo.getter) {
      case GetterMethod.getValue:
        return "$propertyName => getValue(forKey: $keyConstantName)";
      case GetterMethod.getDateTime:
        return "$propertyName => getDateTime(forKey: $keyConstantName)";
      case GetterMethod.getOptionalDateTime:
        return "$propertyName => getOptionalDateTime(forKey: $keyConstantName)";
      case GetterMethod.getDirectusFile:
        return "$propertyName => getDirectusFile(forKey: $keyConstantName)";
      case GetterMethod.getOptionalDirectusFile:
        return "$propertyName => getOptionalDirectusFile(forKey: $keyConstantName)";
      case GetterMethod.getDirectusGeometryType:
        return "$propertyName => getDirectusGeometryType(forKey: $keyConstantName)";
      case GetterMethod.getOptionalDirectusGeometryType:
        return "$propertyName => getOptionalDirectusGeometryType(forKey: $keyConstantName)";
    }
  }

  /// Generates the setter code for a field.
  static String? generateSetter({
    required String propertyName,
    required String fieldKey,
    required FieldTypeInfo typeInfo,
    required String keyConstantName,
  }) {
    switch (typeInfo.getter) {
      case GetterMethod.getOptionalDateTime:
        return "$propertyName => setOptionalDateTime($propertyName, forKey: $keyConstantName)";
      case GetterMethod.getDateTime:
        return "$propertyName => setOptionalDateTime($propertyName, forKey: $keyConstantName)";
      case GetterMethod.getDirectusFile:
      case GetterMethod.getOptionalDirectusFile:
        return "$propertyName => setOptionalDirectusFile($propertyName, forKey: $keyConstantName)";
      case GetterMethod.getValue:
        return "$propertyName => setValue($propertyName, forKey: $keyConstantName)";
      case GetterMethod.getDirectusGeometryType:
      case GetterMethod.getOptionalDirectusGeometryType:
        // No built-in setter for geometry types
        return null;
    }
  }
}

/// Describes how a Directus field type maps to a Dart type.
class FieldTypeInfo {
  final String dartType;
  final GetterMethod getter;

  const FieldTypeInfo({
    required this.dartType,
    required this.getter,
  });
}

/// The method to use for reading a field value.
enum GetterMethod {
  getValue,
  getDateTime,
  getOptionalDateTime,
  getDirectusFile,
  getOptionalDirectusFile,
  getDirectusGeometryType,
  getOptionalDirectusGeometryType,
}
