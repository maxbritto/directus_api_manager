import 'package:directus_api_manager/src/generator/directus_schema_fetcher.dart';
import 'package:directus_api_manager/src/generator/entity_class_generator.dart';
import 'package:directus_api_manager/src/generator/generator_config.dart';
import 'package:test/test.dart';

void main() {
  late EntityClassGenerator generator;

  setUp(() {
    generator = EntityClassGenerator(
      classSuffix: "DirectusModel",
      generateReadonlySetters: false,
    );
  });

  DirectusFieldInfo _idField(String collection) => DirectusFieldInfo(
        collection: collection,
        field: "id",
        type: "integer",
        isPrimaryKey: true,
        isReadonly: true,
        isNullable: false,
      );

  group("EntityClassGenerator", () {
    group("generateFileName", () {
      test("generates correct file name from collection name", () {
        expect(
            generator.generateFileName("player"), "player_directus_model.dart");
      });

      test("generates correct file name for multi-word collection", () {
        expect(generator.generateFileName("game_session"),
            "game_session_directus_model.dart");
      });
    });

    group("generateClassFile", () {
      test("generates header with collection name", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "player"),
          fields: [_idField("player")],
          relations: [],
        );

        expect(source, contains("// GENERATED CODE - DO NOT MODIFY BY HAND"));
        expect(source, contains("// Source collection: player"));
      });

      test("generates correct import", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "player"),
          fields: [_idField("player")],
          relations: [],
        );

        expect(source,
            contains("import 'package:directus_api_manager/directus_api_manager.dart';"));
      });

      group("CollectionMetadata annotation", () {
        test("generates default annotation with only endpointName", () {
          final source = generator.generateClassFile(
            collection: DirectusCollectionInfo(collection: "player"),
            fields: [_idField("player")],
            relations: [],
          );

          expect(source, contains("@DirectusCollection()"));
          expect(
              source, contains('@CollectionMetadata(endpointName: "player")'));
        });

        test("generates annotation with custom defaultFields", () {
          final source = generator.generateClassFile(
            collection: DirectusCollectionInfo(collection: "player"),
            fields: [_idField("player")],
            relations: [],
            collectionOptions: const CollectionOptions(
              defaultFields: "id,nickname,best_score",
            ),
          );

          expect(
              source,
              contains(
                  '@CollectionMetadata(endpointName: "player", defaultFields: "id,nickname,best_score")'));
        });

        test("generates annotation with webSocketEndPoint", () {
          final source = generator.generateClassFile(
            collection: DirectusCollectionInfo(collection: "player"),
            fields: [_idField("player")],
            relations: [],
            collectionOptions: const CollectionOptions(
              webSocketEndPoint: "player_ws",
            ),
          );

          expect(
              source,
              contains(
                  '@CollectionMetadata(endpointName: "player", webSocketEndPoint: "player_ws")'));
        });

        test("generates annotation with defaultUpdateFields", () {
          final source = generator.generateClassFile(
            collection: DirectusCollectionInfo(collection: "player"),
            fields: [_idField("player")],
            relations: [],
            collectionOptions: const CollectionOptions(
              defaultUpdateFields: "id,nickname",
            ),
          );

          expect(
              source,
              contains(
                  '@CollectionMetadata(endpointName: "player", defaultUpdateFields: "id,nickname")'));
        });

        test("generates annotation with all metadata params", () {
          final source = generator.generateClassFile(
            collection: DirectusCollectionInfo(collection: "player"),
            fields: [_idField("player")],
            relations: [],
            collectionOptions: const CollectionOptions(
              defaultFields: "id,nickname",
              webSocketEndPoint: "player_ws",
              defaultUpdateFields: "id,nickname,score",
            ),
          );

          expect(source, contains('@CollectionMetadata(endpointName: "player"'));
          expect(source, contains('defaultFields: "id,nickname"'));
          expect(source, contains('webSocketEndPoint: "player_ws"'));
          expect(
              source, contains('defaultUpdateFields: "id,nickname,score"'));
        });

        test("does not add defaultFields when value is *", () {
          final source = generator.generateClassFile(
            collection: DirectusCollectionInfo(collection: "player"),
            fields: [_idField("player")],
            relations: [],
            collectionOptions: const CollectionOptions(
              defaultFields: "*",
            ),
          );

          expect(
              source, contains('@CollectionMetadata(endpointName: "player")'));
          expect(source, isNot(contains("defaultFields")));
        });
      });

      test("generates PascalCase class name from snake_case collection", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "game_session"),
          fields: [_idField("game_session")],
          relations: [],
        );

        expect(source,
            contains("class GameSessionDirectusModel extends DirectusItem"));
      });

      test("generates constructors", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "player"),
          fields: [_idField("player")],
          relations: [],
        );

        expect(
            source, contains("PlayerDirectusModel(super.rawReceivedData);"));
        expect(source,
            contains("PlayerDirectusModel.newItem() : super.newItem();"));
      });

      test("generates string property with getter and setter", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "player"),
          fields: [
            _idField("player"),
            DirectusFieldInfo(
              collection: "player",
              field: "nickname",
              type: "string",
              isNullable: false,
              isRequired: true,
            ),
          ],
          relations: [],
        );

        expect(source,
            contains('static const String nicknameKey = "nickname";'));
        expect(source,
            contains("String get nickname => getValue(forKey: nicknameKey);"));
        expect(
            source,
            contains(
                "set nickname(String value) => setValue(value, forKey: nicknameKey);"));
      });

      test("generates nullable integer property", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "player"),
          fields: [
            _idField("player"),
            DirectusFieldInfo(
              collection: "player",
              field: "best_score",
              type: "integer",
              isNullable: true,
            ),
          ],
          relations: [],
        );

        expect(source,
            contains('static const String bestScoreKey = "best_score";'));
        expect(source,
            contains("int? get bestScore => getValue(forKey: bestScoreKey);"));
        expect(
            source,
            contains(
                "set bestScore(int? value) => setValue(value, forKey: bestScoreKey);"));
      });

      test("generates DateTime property with correct accessor", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "player"),
          fields: [
            _idField("player"),
            DirectusFieldInfo(
              collection: "player",
              field: "created_at",
              type: "timestamp",
              isNullable: true,
              isReadonly: true,
            ),
          ],
          relations: [],
        );

        expect(
            source,
            contains(
                "DateTime? get createdAt => getOptionalDateTime(forKey: createdAtKey);"));
        // Readonly, so no setter
        expect(source, isNot(contains("set createdAt")));
      });

      test("skips primary key field in properties", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "player"),
          fields: [
            _idField("player"),
            DirectusFieldInfo(
              collection: "player",
              field: "name",
              type: "string",
              isNullable: false,
            ),
          ],
          relations: [],
        );

        // ID should not appear in keys or properties (inherited from DirectusData)
        expect(source, isNot(contains('static const String idKey')));
        expect(source, isNot(contains("get id =>")));
      });

      test("generates file relation property", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "player"),
          fields: [
            _idField("player"),
            DirectusFieldInfo(
              collection: "player",
              field: "avatar",
              type: "uuid",
              isNullable: true,
              specialType: "file",
            ),
          ],
          relations: [
            DirectusRelationInfo(
              collection: "player",
              field: "avatar",
              relatedCollection: "directus_files",
            ),
          ],
        );

        expect(
            source,
            contains(
                "DirectusFile? get avatar => getOptionalDirectusFile(forKey: avatarKey);"));
        expect(
            source,
            contains(
                "set avatar(DirectusFile? value) => setOptionalDirectusFile(value, forKey: avatarKey);"));
      });

      test("generates M2O relation as String id", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "article"),
          fields: [
            _idField("article"),
            DirectusFieldInfo(
              collection: "article",
              field: "author",
              type: "uuid",
              isNullable: true,
              specialType: "m2o",
            ),
          ],
          relations: [
            DirectusRelationInfo(
              collection: "article",
              field: "author",
              relatedCollection: "directus_users",
            ),
          ],
        );

        expect(
            source, contains("/// author (relation M2O -> directus_users)"));
        expect(source,
            contains("String? get author => getValue(forKey: authorKey);"));
      });

      test("skips alias (virtual) fields", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "player"),
          fields: [
            _idField("player"),
            DirectusFieldInfo(
              collection: "player",
              field: "games",
              type: "alias",
              isNullable: true,
              specialType: "o2m",
            ),
          ],
          relations: [
            DirectusRelationInfo(
              collection: "game",
              field: "player_id",
              relatedCollection: "player",
            ),
          ],
        );

        // O2M relations should be commented, not as properties
        expect(source, contains("// games: One-to-Many relation"));
        expect(source, isNot(contains("get games =>")));
      });

      test("does not generate setter for readonly fields", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "player"),
          fields: [
            _idField("player"),
            DirectusFieldInfo(
              collection: "player",
              field: "date_updated",
              type: "timestamp",
              isNullable: true,
              isReadonly: true,
            ),
          ],
          relations: [],
        );

        expect(
            source,
            contains(
                "DateTime? get dateUpdated => getOptionalDateTime(forKey: dateUpdatedKey);"));
        expect(source, isNot(contains("set dateUpdated")));
      });

      test("generates readonly setters when configured", () {
        final generatorWithSetters = EntityClassGenerator(
          classSuffix: "DirectusModel",
          generateReadonlySetters: true,
        );

        final source = generatorWithSetters.generateClassFile(
          collection: DirectusCollectionInfo(collection: "player"),
          fields: [
            _idField("player"),
            DirectusFieldInfo(
              collection: "player",
              field: "date_updated",
              type: "timestamp",
              isNullable: true,
              isReadonly: true,
            ),
          ],
          relations: [],
        );

        expect(source, contains("set dateUpdated"));
      });

      test("uses custom class suffix", () {
        final customGenerator = EntityClassGenerator(
          classSuffix: "Model",
        );

        final source = customGenerator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "player"),
          fields: [_idField("player")],
          relations: [],
        );

        expect(source, contains("class PlayerModel extends DirectusItem"));
      });

      test("all setters have typed parameter declaration", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "player"),
          fields: [
            _idField("player"),
            DirectusFieldInfo(
              collection: "player",
              field: "nickname",
              type: "string",
              isNullable: false,
              isRequired: true,
            ),
            DirectusFieldInfo(
              collection: "player",
              field: "best_score",
              type: "integer",
              isNullable: true,
            ),
            DirectusFieldInfo(
              collection: "player",
              field: "rating",
              type: "float",
              isNullable: true,
            ),
            DirectusFieldInfo(
              collection: "player",
              field: "active",
              type: "boolean",
              isNullable: false,
            ),
            DirectusFieldInfo(
              collection: "player",
              field: "last_login",
              type: "dateTime",
              isNullable: true,
            ),
            DirectusFieldInfo(
              collection: "player",
              field: "avatar",
              type: "uuid",
              isNullable: true,
              specialType: "file",
            ),
            DirectusFieldInfo(
              collection: "player",
              field: "team",
              type: "uuid",
              isNullable: true,
              specialType: "m2o",
            ),
          ],
          relations: [
            DirectusRelationInfo(
              collection: "player",
              field: "avatar",
              relatedCollection: "directus_files",
            ),
            DirectusRelationInfo(
              collection: "player",
              field: "team",
              relatedCollection: "teams",
            ),
          ],
        );

        // Extract all setter lines from the generated source
        final setterLines = source
            .split('\n')
            .where((line) => line.trimLeft().startsWith('set '))
            .toList();

        // Every setter must have a typed parameter: set name(Type value) =>
        for (final line in setterLines) {
          final trimmed = line.trim();
          expect(
            trimmed,
            matches(RegExp(r'^set \w+\(\w[\w<>?]* value\) =>')),
            reason: 'Setter has invalid syntax: $trimmed',
          );
        }

        // Verify we actually found setters for the expected fields
        expect(setterLines.length, 7,
            reason:
                'Expected 7 setters: nickname, bestScore, rating, active, lastLogin, avatar, team');
      });

      test("generates complete file for realistic collection", () {
        final source = generator.generateClassFile(
          collection: DirectusCollectionInfo(collection: "blog_post"),
          fields: [
            DirectusFieldInfo(
              collection: "blog_post",
              field: "id",
              type: "uuid",
              isPrimaryKey: true,
              isReadonly: true,
              isNullable: false,
            ),
            DirectusFieldInfo(
              collection: "blog_post",
              field: "title",
              type: "string",
              isNullable: false,
              isRequired: true,
            ),
            DirectusFieldInfo(
              collection: "blog_post",
              field: "content",
              type: "text",
              isNullable: true,
            ),
            DirectusFieldInfo(
              collection: "blog_post",
              field: "published",
              type: "boolean",
              isNullable: false,
            ),
            DirectusFieldInfo(
              collection: "blog_post",
              field: "view_count",
              type: "integer",
              isNullable: true,
            ),
            DirectusFieldInfo(
              collection: "blog_post",
              field: "rating",
              type: "float",
              isNullable: true,
            ),
            DirectusFieldInfo(
              collection: "blog_post",
              field: "cover_image",
              type: "uuid",
              isNullable: true,
              specialType: "file",
            ),
            DirectusFieldInfo(
              collection: "blog_post",
              field: "author",
              type: "uuid",
              isNullable: true,
              specialType: "m2o",
            ),
            DirectusFieldInfo(
              collection: "blog_post",
              field: "date_created",
              type: "timestamp",
              isNullable: true,
              isReadonly: true,
            ),
            DirectusFieldInfo(
              collection: "blog_post",
              field: "tags",
              type: "alias",
              isNullable: true,
              specialType: "m2m",
            ),
          ],
          relations: [
            DirectusRelationInfo(
              collection: "blog_post",
              field: "cover_image",
              relatedCollection: "directus_files",
            ),
            DirectusRelationInfo(
              collection: "blog_post",
              field: "author",
              relatedCollection: "directus_users",
            ),
          ],
          collectionOptions: const CollectionOptions(
            defaultFields: "id,title,content,published",
            webSocketEndPoint: "blog_posts_ws",
            defaultUpdateFields: "id,title,date_created",
          ),
        );

        // Class structure
        expect(source,
            contains("class BlogPostDirectusModel extends DirectusItem"));

        // Annotation with metadata
        expect(source, contains('endpointName: "blog_post"'));
        expect(source,
            contains('defaultFields: "id,title,content,published"'));
        expect(source, contains('webSocketEndPoint: "blog_posts_ws"'));
        expect(source,
            contains('defaultUpdateFields: "id,title,date_created"'));

        // String field
        expect(source, contains("String get title"));
        expect(source, contains("set title(String value)"));

        // Text field (nullable)
        expect(source, contains("String? get content"));
        expect(source, contains("set content(String? value)"));

        // Boolean field
        expect(source, contains("bool get published"));
        expect(source, contains("set published(bool value)"));

        // Integer field (nullable)
        expect(source, contains("int? get viewCount"));

        // Float field (nullable)
        expect(source, contains("double? get rating"));

        // File relation
        expect(source, contains("DirectusFile? get coverImage"));

        // M2O relation
        expect(source, contains("String? get author"));
        expect(
            source, contains("/// author (relation M2O -> directus_users)"));

        // Readonly DateTime
        expect(source, contains("DateTime? get dateCreated"));
        expect(source, isNot(contains("set dateCreated")));

        // M2M as comment
        expect(source, contains("// tags: Many-to-Many relation"));
      });
    });
  });
}
