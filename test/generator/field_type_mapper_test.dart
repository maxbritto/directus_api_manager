import 'package:directus_api_manager/src/generator/field_type_mapper.dart';
import 'package:test/test.dart';

void main() {
  group("FieldTypeMapper", () {
    group("mapFieldType", () {
      test("string type maps to String", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "string", isNullable: false);
        expect(info.dartType, "String");
        expect(info.getter, GetterMethod.getValue);
      });

      test("nullable string type maps to String?", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "string", isNullable: true);
        expect(info.dartType, "String?");
      });

      test("text type maps to String", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "text", isNullable: false);
        expect(info.dartType, "String");
      });

      test("uuid type maps to String", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "uuid", isNullable: false);
        expect(info.dartType, "String");
      });

      test("hash type maps to String", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "hash", isNullable: true);
        expect(info.dartType, "String?");
      });

      test("integer type maps to int", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "integer", isNullable: false);
        expect(info.dartType, "int");
        expect(info.getter, GetterMethod.getValue);
      });

      test("nullable integer maps to int?", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "integer", isNullable: true);
        expect(info.dartType, "int?");
      });

      test("bigInteger type maps to int", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "bigInteger", isNullable: false);
        expect(info.dartType, "int");
      });

      test("float type maps to double", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "float", isNullable: false);
        expect(info.dartType, "double");
        expect(info.getter, GetterMethod.getValue);
      });

      test("decimal type maps to double", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "decimal", isNullable: true);
        expect(info.dartType, "double?");
      });

      test("boolean type maps to bool", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "boolean", isNullable: false);
        expect(info.dartType, "bool");
        expect(info.getter, GetterMethod.getValue);
      });

      test("dateTime type maps to DateTime with correct getter", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "dateTime", isNullable: false);
        expect(info.dartType, "DateTime");
        expect(info.getter, GetterMethod.getDateTime);
      });

      test("nullable dateTime uses getOptionalDateTime", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "dateTime", isNullable: true);
        expect(info.dartType, "DateTime?");
        expect(info.getter, GetterMethod.getOptionalDateTime);
      });

      test("date type maps to DateTime", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "date", isNullable: false);
        expect(info.dartType, "DateTime");
        expect(info.getter, GetterMethod.getDateTime);
      });

      test("timestamp type maps to DateTime", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "timestamp", isNullable: true);
        expect(info.dartType, "DateTime?");
        expect(info.getter, GetterMethod.getOptionalDateTime);
      });

      test("time type maps to String", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "time", isNullable: false);
        expect(info.dartType, "String");
        expect(info.getter, GetterMethod.getValue);
      });

      test("json type maps to dynamic", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "json", isNullable: true);
        expect(info.dartType, "dynamic");
        expect(info.getter, GetterMethod.getValue);
      });

      test("geometry type maps to DirectusGeometryType", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "geometry", isNullable: false);
        expect(info.dartType, "DirectusGeometryType");
        expect(info.getter, GetterMethod.getDirectusGeometryType);
      });

      test("nullable geometry uses getOptionalDirectusGeometryType", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "geometry", isNullable: true);
        expect(info.dartType, "DirectusGeometryType?");
        expect(info.getter, GetterMethod.getOptionalDirectusGeometryType);
      });

      test("file relation maps to DirectusFile", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "uuid", isNullable: false, isFileRelation: true);
        expect(info.dartType, "DirectusFile");
        expect(info.getter, GetterMethod.getDirectusFile);
      });

      test("nullable file relation maps to DirectusFile?", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "uuid", isNullable: true, isFileRelation: true);
        expect(info.dartType, "DirectusFile?");
        expect(info.getter, GetterMethod.getOptionalDirectusFile);
      });

      test("unknown type maps to dynamic", () {
        final info = FieldTypeMapper.mapFieldType(
            directusType: "unknown_type", isNullable: true);
        expect(info.dartType, "dynamic");
        expect(info.getter, GetterMethod.getValue);
      });
    });

    group("generateGetter", () {
      test("generates getValue getter", () {
        const typeInfo =
            FieldTypeInfo(dartType: "String", getter: GetterMethod.getValue);
        final code = FieldTypeMapper.generateGetter(
          propertyName: "nickname",
          fieldKey: "nickname",
          typeInfo: typeInfo,
          keyConstantName: "nicknameKey",
        );
        expect(code, 'nickname => getValue(forKey: nicknameKey)');
      });

      test("generates getOptionalDateTime getter", () {
        const typeInfo = FieldTypeInfo(
            dartType: "DateTime?", getter: GetterMethod.getOptionalDateTime);
        final code = FieldTypeMapper.generateGetter(
          propertyName: "createdAt",
          fieldKey: "created_at",
          typeInfo: typeInfo,
          keyConstantName: "createdAtKey",
        );
        expect(
            code, 'createdAt => getOptionalDateTime(forKey: createdAtKey)');
      });

      test("generates getOptionalDirectusFile getter", () {
        const typeInfo = FieldTypeInfo(
            dartType: "DirectusFile?",
            getter: GetterMethod.getOptionalDirectusFile);
        final code = FieldTypeMapper.generateGetter(
          propertyName: "avatar",
          fieldKey: "avatar",
          typeInfo: typeInfo,
          keyConstantName: "avatarKey",
        );
        expect(
            code, 'avatar => getOptionalDirectusFile(forKey: avatarKey)');
      });
    });

    group("generateSetter", () {
      test("generates setValue setter for simple types", () {
        const typeInfo =
            FieldTypeInfo(dartType: "String", getter: GetterMethod.getValue);
        final code = FieldTypeMapper.generateSetter(
          propertyName: "nickname",
          fieldKey: "nickname",
          typeInfo: typeInfo,
          keyConstantName: "nicknameKey",
        );
        expect(code,
            'nickname(String value) => setValue(value, forKey: nicknameKey)');
      });

      test("generates setOptionalDateTime setter", () {
        const typeInfo = FieldTypeInfo(
            dartType: "DateTime?", getter: GetterMethod.getOptionalDateTime);
        final code = FieldTypeMapper.generateSetter(
          propertyName: "createdAt",
          fieldKey: "created_at",
          typeInfo: typeInfo,
          keyConstantName: "createdAtKey",
        );
        expect(code,
            'createdAt(DateTime? value) => setOptionalDateTime(value, forKey: createdAtKey)');
      });

      test("generates setOptionalDirectusFile setter", () {
        const typeInfo = FieldTypeInfo(
            dartType: "DirectusFile?",
            getter: GetterMethod.getOptionalDirectusFile);
        final code = FieldTypeMapper.generateSetter(
          propertyName: "avatar",
          fieldKey: "avatar",
          typeInfo: typeInfo,
          keyConstantName: "avatarKey",
        );
        expect(code,
            'avatar(DirectusFile? value) => setOptionalDirectusFile(value, forKey: avatarKey)');
      });

      test("returns null for geometry setter", () {
        const typeInfo = FieldTypeInfo(
            dartType: "DirectusGeometryType?",
            getter: GetterMethod.getOptionalDirectusGeometryType);
        final code = FieldTypeMapper.generateSetter(
          propertyName: "location",
          fieldKey: "location",
          typeInfo: typeInfo,
          keyConstantName: "locationKey",
        );
        expect(code, isNull);
      });
    });
  });
}
