import 'package:directus_api_manager/src/generator/generator_config.dart';
import 'package:test/test.dart';

void main() {
  group("GeneratorConfig", () {
    group("fromArgs", () {
      test("parses url and token", () {
        final config = GeneratorConfig.fromArgs([
          "--url",
          "http://localhost:8055",
          "--token",
          "my_token",
        ]);

        expect(config.directusUrl, "http://localhost:8055");
        expect(config.staticToken, "my_token");
        expect(config.email, isNull);
        expect(config.password, isNull);
      });

      test("parses short form arguments", () {
        final config = GeneratorConfig.fromArgs([
          "-u",
          "http://localhost:8055",
          "-t",
          "my_token",
        ]);

        expect(config.directusUrl, "http://localhost:8055");
        expect(config.staticToken, "my_token");
      });

      test("parses email and password", () {
        final config = GeneratorConfig.fromArgs([
          "--url",
          "http://localhost:8055",
          "--email",
          "admin@example.com",
          "--password",
          "secret",
        ]);

        expect(config.email, "admin@example.com");
        expect(config.password, "secret");
        expect(config.staticToken, isNull);
      });

      test("parses output directory", () {
        final config = GeneratorConfig.fromArgs([
          "--url",
          "http://localhost:8055",
          "--token",
          "tok",
          "--output",
          "lib/src/models",
        ]);

        expect(config.outputDirectory, "lib/src/models");
      });

      test("uses default output directory", () {
        final config = GeneratorConfig.fromArgs([
          "--url",
          "http://localhost:8055",
          "--token",
          "tok",
        ]);

        expect(config.outputDirectory, "lib/models/directus");
      });

      test("parses collection filters", () {
        final config = GeneratorConfig.fromArgs([
          "--url",
          "http://localhost:8055",
          "--token",
          "tok",
          "--collection",
          "player",
          "--collection",
          "game",
        ]);

        expect(config.includeCollections, ["player", "game"]);
      });

      test("parses exclude filters", () {
        final config = GeneratorConfig.fromArgs([
          "--url",
          "http://localhost:8055",
          "--token",
          "tok",
          "--exclude",
          "internal_logs",
        ]);

        expect(config.excludeCollections, ["internal_logs"]);
      });

      test("parses dry-run flag", () {
        final config = GeneratorConfig.fromArgs([
          "--url",
          "http://localhost:8055",
          "--token",
          "tok",
          "--dry-run",
        ]);

        expect(config.dryRun, isTrue);
      });

      test("parses custom suffix", () {
        final config = GeneratorConfig.fromArgs([
          "--url",
          "http://localhost:8055",
          "--token",
          "tok",
          "--suffix",
          "Model",
        ]);

        expect(config.classSuffix, "Model");
      });

      test("throws when url is missing", () {
        expect(
          () => GeneratorConfig.fromArgs(["--token", "tok"]),
          throwsA(isA<ArgumentError>()),
        );
      });

      test("throws when no authentication is provided", () {
        expect(
          () => GeneratorConfig.fromArgs(["--url", "http://localhost:8055"]),
          throwsA(isA<ArgumentError>()),
        );
      });

      test("throws when only email is provided without password", () {
        expect(
          () => GeneratorConfig.fromArgs([
            "--url",
            "http://localhost:8055",
            "--email",
            "admin@example.com",
          ]),
          throwsA(isA<ArgumentError>()),
        );
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
  });
}
