import 'dart:convert';

import 'package:directus_api_manager/src/generator/directus_schema_fetcher.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group("DirectusSchemaFetcher", () {
    group("fetchCollections", () {
      test("fetches and parses collections, excluding system collections", () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, "/collections");
          expect(request.headers["Authorization"], "Bearer my_token");
          return http.Response(
            jsonEncode({
              "data": [
                {
                  "collection": "player",
                  "meta": {"singleton": false}
                },
                {
                  "collection": "directus_users",
                  "meta": {"singleton": false}
                },
                {
                  "collection": "game",
                  "meta": {"singleton": false}
                },
                {
                  "collection": "directus_files",
                  "meta": {"singleton": false}
                },
              ]
            }),
            200,
          );
        });

        final fetcher = DirectusSchemaFetcher(
          baseUrl: "http://localhost:8055",
          staticToken: "my_token",
          httpClient: mockClient,
        );

        final collections = await fetcher.fetchCollections();
        expect(collections.length, 2);
        expect(collections[0].collection, "player");
        expect(collections[1].collection, "game");
      });

      test("throws on non-200 response", () async {
        final mockClient = MockClient((request) async {
          return http.Response("Forbidden", 403);
        });

        final fetcher = DirectusSchemaFetcher(
          baseUrl: "http://localhost:8055",
          staticToken: "bad_token",
          httpClient: mockClient,
        );

        expect(() => fetcher.fetchCollections(), throwsException);
      });
    });

    group("fetchFieldsForCollection", () {
      test("fetches and parses fields for a collection", () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, "/fields/player");
          return http.Response(
            jsonEncode({
              "data": [
                {
                  "collection": "player",
                  "field": "id",
                  "type": "integer",
                  "schema": {
                    "is_nullable": false,
                    "is_primary_key": true,
                  },
                  "meta": {
                    "required": true,
                    "readonly": true,
                    "interface": "input",
                    "special": null,
                  }
                },
                {
                  "collection": "player",
                  "field": "nickname",
                  "type": "string",
                  "schema": {
                    "is_nullable": false,
                    "is_primary_key": false,
                  },
                  "meta": {
                    "required": true,
                    "readonly": false,
                    "interface": "input",
                    "special": null,
                  }
                },
                {
                  "collection": "player",
                  "field": "avatar",
                  "type": "uuid",
                  "schema": {
                    "is_nullable": true,
                    "is_primary_key": false,
                  },
                  "meta": {
                    "required": false,
                    "readonly": false,
                    "interface": "file",
                    "special": ["file"],
                  }
                },
              ]
            }),
            200,
          );
        });

        final fetcher = DirectusSchemaFetcher(
          baseUrl: "http://localhost:8055",
          staticToken: "my_token",
          httpClient: mockClient,
        );

        final fields = await fetcher.fetchFieldsForCollection("player");
        expect(fields.length, 3);

        // ID field
        expect(fields[0].field, "id");
        expect(fields[0].type, "integer");
        expect(fields[0].isPrimaryKey, isTrue);
        expect(fields[0].isReadonly, isTrue);
        expect(fields[0].isNullable, isFalse);

        // Nickname field
        expect(fields[1].field, "nickname");
        expect(fields[1].type, "string");
        expect(fields[1].isRequired, isTrue);
        expect(fields[1].isReadonly, isFalse);
        expect(fields[1].isNullable, isFalse);

        // Avatar field (file relation)
        expect(fields[2].field, "avatar");
        expect(fields[2].isFileRelation, isTrue);
        expect(fields[2].isNullable, isTrue);
      });
    });

    group("fetchRelations", () {
      test("fetches and parses relations", () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, "/relations");
          return http.Response(
            jsonEncode({
              "data": [
                {
                  "collection": "article",
                  "field": "author",
                  "related_collection": "directus_users",
                },
                {
                  "collection": "article",
                  "field": "cover_image",
                  "related_collection": "directus_files",
                },
              ]
            }),
            200,
          );
        });

        final fetcher = DirectusSchemaFetcher(
          baseUrl: "http://localhost:8055",
          staticToken: "my_token",
          httpClient: mockClient,
        );

        final relations = await fetcher.fetchRelations();
        expect(relations.length, 2);
        expect(relations[0].collection, "article");
        expect(relations[0].field, "author");
        expect(relations[0].relatedCollection, "directus_users");
      });
    });

    group("authenticate", () {
      test("authenticates with email and password", () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == "/auth/login") {
            final body = jsonDecode(request.body);
            expect(body["email"], "admin@example.com");
            expect(body["password"], "secret");
            return http.Response(
              jsonEncode({
                "data": {
                  "access_token": "access_123",
                  "refresh_token": "refresh_456",
                  "expires": 900000,
                }
              }),
              200,
            );
          }
          // After auth, verify token is used
          expect(request.headers["Authorization"], "Bearer access_123");
          return http.Response(
            jsonEncode({"data": []}),
            200,
          );
        });

        final fetcher = DirectusSchemaFetcher(
          baseUrl: "http://localhost:8055",
          httpClient: mockClient,
        );

        await fetcher.authenticate(
            email: "admin@example.com", password: "secret");
        // Should use the token for subsequent requests
        await fetcher.fetchCollections();
      });

      test("throws on authentication failure", () async {
        final mockClient = MockClient((request) async {
          return http.Response("Unauthorized", 401);
        });

        final fetcher = DirectusSchemaFetcher(
          baseUrl: "http://localhost:8055",
          httpClient: mockClient,
        );

        expect(
          () => fetcher.authenticate(
              email: "bad@example.com", password: "wrong"),
          throwsException,
        );
      });
    });

    group("DirectusFieldInfo", () {
      test("detects file relation from special", () {
        final field = DirectusFieldInfo(
          collection: "test",
          field: "avatar",
          type: "uuid",
          specialType: "file",
        );
        expect(field.isFileRelation, isTrue);
        expect(field.isManyToOne, isFalse);
      });

      test("detects M2O relation from special", () {
        final field = DirectusFieldInfo(
          collection: "test",
          field: "author",
          type: "uuid",
          specialType: "m2o",
        );
        expect(field.isManyToOne, isTrue);
        expect(field.isFileRelation, isFalse);
      });

      test("detects O2M relation", () {
        final field = DirectusFieldInfo(
          collection: "test",
          field: "posts",
          type: "alias",
          specialType: "o2m",
        );
        expect(field.isOneToMany, isTrue);
        expect(field.isAlias, isTrue);
      });

      test("detects M2M relation", () {
        final field = DirectusFieldInfo(
          collection: "test",
          field: "tags",
          type: "alias",
          specialType: "m2m",
        );
        expect(field.isManyToMany, isTrue);
        expect(field.isAlias, isTrue);
      });
    });
  });
}
