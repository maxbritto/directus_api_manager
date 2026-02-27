import 'dart:convert';

import 'package:directus_api_manager/src/generator/generator_config.dart';
import 'package:test/test.dart';

void main() {
  group("GeneratorConfig", () {
    group("fromJsonString", () {
      test("parses minimal config with static token", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "static_token": "my_token",
        });

        final config = GeneratorConfig.fromJsonString(json);

        expect(config.directusUrl, "http://localhost:8055");
        expect(config.staticToken, "my_token");
        expect(config.email, isNull);
        expect(config.password, isNull);
      });

      test("parses email and password authentication", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "email": "admin@example.com",
          "password": "secret",
        });

        final config = GeneratorConfig.fromJsonString(json);

        expect(config.email, "admin@example.com");
        expect(config.password, "secret");
        expect(config.staticToken, isNull);
      });

      test("uses default output directory", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "static_token": "tok",
        });

        final config = GeneratorConfig.fromJsonString(json);
        expect(config.outputDirectory, "lib/directus_api_manager_models");
      });

      test("parses custom output directory", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "static_token": "tok",
          "output_directory": "lib/src/models",
        });

        final config = GeneratorConfig.fromJsonString(json);
        expect(config.outputDirectory, "lib/src/models");
      });

      test("uses default class suffix", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "static_token": "tok",
        });

        final config = GeneratorConfig.fromJsonString(json);
        expect(config.classSuffix, "DirectusModel");
      });

      test("parses custom class suffix", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "static_token": "tok",
          "class_suffix": "Model",
        });

        final config = GeneratorConfig.fromJsonString(json);
        expect(config.classSuffix, "Model");
      });

      test("parses exclude collections", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "static_token": "tok",
          "exclude_collections": ["internal_logs", "temp_data"],
        });

        final config = GeneratorConfig.fromJsonString(json);
        expect(config.excludeCollections, ["internal_logs", "temp_data"]);
      });

      test("defaults to empty exclude list", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "static_token": "tok",
        });

        final config = GeneratorConfig.fromJsonString(json);
        expect(config.excludeCollections, isEmpty);
      });

      test("parses per-collection options", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "static_token": "tok",
          "collections": {
            "player": {
              "defaultFields": "id,nickname,best_score",
              "webSocketEndPoint": "player_ws",
              "defaultUpdateFields": "id,nickname",
            },
            "game": {
              "defaultFields": "id,title",
            },
          },
        });

        final config = GeneratorConfig.fromJsonString(json);

        expect(config.collectionOptions.length, 2);

        final playerOpts = config.collectionOptions["player"]!;
        expect(playerOpts.defaultFields, "id,nickname,best_score");
        expect(playerOpts.webSocketEndPoint, "player_ws");
        expect(playerOpts.defaultUpdateFields, "id,nickname");

        final gameOpts = config.collectionOptions["game"]!;
        expect(gameOpts.defaultFields, "id,title");
        expect(gameOpts.webSocketEndPoint, isNull);
        expect(gameOpts.defaultUpdateFields, isNull);
      });

      test("defaults collection options when not specified", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "static_token": "tok",
        });

        final config = GeneratorConfig.fromJsonString(json);
        expect(config.collectionOptions, isEmpty);

        final opts = config.optionsForCollection("unknown");
        expect(opts.defaultFields, "*");
        expect(opts.webSocketEndPoint, isNull);
        expect(opts.defaultUpdateFields, isNull);
      });

      test("passes dry-run flag", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "static_token": "tok",
        });

        final config = GeneratorConfig.fromJsonString(json, dryRun: true);
        expect(config.dryRun, isTrue);
      });

      test("throws when directus_url is missing", () {
        final json = jsonEncode({
          "static_token": "tok",
        });

        expect(
          () => GeneratorConfig.fromJsonString(json),
          throwsA(isA<ArgumentError>()),
        );
      });

      test("throws when directus_url is empty", () {
        final json = jsonEncode({
          "directus_url": "",
          "static_token": "tok",
        });

        expect(
          () => GeneratorConfig.fromJsonString(json),
          throwsA(isA<ArgumentError>()),
        );
      });

      test("throws when no authentication is provided", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
        });

        expect(
          () => GeneratorConfig.fromJsonString(json),
          throwsA(isA<ArgumentError>()),
        );
      });

      test("throws when only email is provided without password", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "email": "admin@example.com",
        });

        expect(
          () => GeneratorConfig.fromJsonString(json),
          throwsA(isA<ArgumentError>()),
        );
      });

      test("ignores comment fields in JSON", () {
        final json = jsonEncode({
          "_comment": "This is a comment",
          "directus_url": "http://localhost:8055",
          "static_token": "tok",
          "_comment_auth": "Another comment",
        });

        final config = GeneratorConfig.fromJsonString(json);
        expect(config.directusUrl, "http://localhost:8055");
      });
    });

    group("optionsForCollection", () {
      test("returns configured options for known collection", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "static_token": "tok",
          "collections": {
            "player": {
              "defaultFields": "id,name",
            },
          },
        });

        final config = GeneratorConfig.fromJsonString(json);
        final opts = config.optionsForCollection("player");
        expect(opts.defaultFields, "id,name");
      });

      test("returns default options for unknown collection", () {
        final json = jsonEncode({
          "directus_url": "http://localhost:8055",
          "static_token": "tok",
        });

        final config = GeneratorConfig.fromJsonString(json);
        final opts = config.optionsForCollection("anything");
        expect(opts.defaultFields, "*");
        expect(opts.webSocketEndPoint, isNull);
        expect(opts.defaultUpdateFields, isNull);
      });
    });

    group("hasAuthentication", () {
      test("returns true with static token", () {
        final config = GeneratorConfig(
          directusUrl: "http://localhost:8055",
          staticToken: "tok",
        );
        expect(config.hasAuthentication, isTrue);
      });

      test("returns true with email and password", () {
        final config = GeneratorConfig(
          directusUrl: "http://localhost:8055",
          email: "admin@example.com",
          password: "secret",
        );
        expect(config.hasAuthentication, isTrue);
      });

      test("returns false without any auth", () {
        final config = GeneratorConfig(
          directusUrl: "http://localhost:8055",
        );
        expect(config.hasAuthentication, isFalse);
      });
    });

    group("parseCliArgs", () {
      test("returns default config path", () {
        final result = GeneratorConfig.parseCliArgs([]);
        expect(result.configPath,
            GeneratorConfig.defaultConfigFileName);
        expect(result.dryRun, isFalse);
      });

      test("parses custom config path", () {
        final result = GeneratorConfig.parseCliArgs(
            ["--config", "custom_config.json"]);
        expect(result.configPath, "custom_config.json");
      });

      test("parses short form config path", () {
        final result =
            GeneratorConfig.parseCliArgs(["-c", "my_config.json"]);
        expect(result.configPath, "my_config.json");
      });

      test("parses dry-run flag", () {
        final result = GeneratorConfig.parseCliArgs(["--dry-run"]);
        expect(result.dryRun, isTrue);
      });

      test("throws HelpRequestedException on --help", () {
        expect(
          () => GeneratorConfig.parseCliArgs(["--help"]),
          throwsA(isA<HelpRequestedException>()),
        );
      });
    });
  });

  group("CollectionOptions", () {
    test("uses default values", () {
      const opts = CollectionOptions();
      expect(opts.defaultFields, "*");
      expect(opts.webSocketEndPoint, isNull);
      expect(opts.defaultUpdateFields, isNull);
    });

    test("parses from JSON with all fields", () {
      final opts = CollectionOptions.fromJson({
        "defaultFields": "id,title",
        "webSocketEndPoint": "my_ws",
        "defaultUpdateFields": "id,title,status",
      });

      expect(opts.defaultFields, "id,title");
      expect(opts.webSocketEndPoint, "my_ws");
      expect(opts.defaultUpdateFields, "id,title,status");
    });

    test("parses from JSON with partial fields", () {
      final opts = CollectionOptions.fromJson({
        "webSocketEndPoint": "my_ws",
      });

      expect(opts.defaultFields, "*");
      expect(opts.webSocketEndPoint, "my_ws");
      expect(opts.defaultUpdateFields, isNull);
    });

    test("parses from empty JSON", () {
      final opts = CollectionOptions.fromJson({});

      expect(opts.defaultFields, "*");
      expect(opts.webSocketEndPoint, isNull);
      expect(opts.defaultUpdateFields, isNull);
    });
  });
}
