import 'dart:convert';

/// Configuration for the Directus entity generator.
/// Loaded from a `directus_api_manager_options.json` file at the project root.
class GeneratorConfig {
  static const String defaultConfigFileName =
      "directus_api_manager_options.json";
  static const String defaultOutputDirectory =
      "lib/directus_api_manager_models";
  static const String defaultClassSuffix = "DirectusModel";

  final String directusUrl;
  final String? staticToken;
  final String? email;
  final String? password;
  final String outputDirectory;
  final List<String> excludeCollections;
  final String classSuffix;
  final bool dryRun;

  /// Per-collection metadata overrides keyed by collection name.
  final Map<String, CollectionOptions> collectionOptions;

  const GeneratorConfig({
    required this.directusUrl,
    this.staticToken,
    this.email,
    this.password,
    this.outputDirectory = defaultOutputDirectory,
    this.excludeCollections = const [],
    this.classSuffix = defaultClassSuffix,
    this.dryRun = false,
    this.collectionOptions = const {},
  });

  /// Creates a [GeneratorConfig] from the contents of a JSON options file.
  /// [jsonString] is the raw JSON content of the file.
  /// [dryRun] can be set via CLI to override the file value.
  factory GeneratorConfig.fromJsonString(String jsonString,
      {bool dryRun = false}) {
    final Map<String, dynamic> json = jsonDecode(jsonString);

    final url = json["directus_url"] as String?;
    if (url == null || url.isEmpty) {
      throw ArgumentError(
          '"directus_url" is required in the options file.');
    }

    final staticToken = json["static_token"] as String?;
    final email = json["email"] as String?;
    final password = json["password"] as String?;

    if (staticToken == null && (email == null || password == null)) {
      throw ArgumentError(
          'Authentication is required. Provide "static_token", or both "email" and "password" in the options file.');
    }

    final outputDirectory =
        json["output_directory"] as String? ?? defaultOutputDirectory;
    final classSuffix =
        json["class_suffix"] as String? ?? defaultClassSuffix;

    final excludeCollections = <String>[];
    final excludeJson = json["exclude_collections"];
    if (excludeJson is List) {
      for (final item in excludeJson) {
        excludeCollections.add(item.toString());
      }
    }

    final collectionOptions = <String, CollectionOptions>{};
    final collectionsJson = json["collections"];
    if (collectionsJson is Map<String, dynamic>) {
      for (final entry in collectionsJson.entries) {
        if (entry.value is Map<String, dynamic>) {
          collectionOptions[entry.key] =
              CollectionOptions.fromJson(entry.value);
        }
      }
    }

    return GeneratorConfig(
      directusUrl: url,
      staticToken: staticToken,
      email: email,
      password: password,
      outputDirectory: outputDirectory,
      excludeCollections: excludeCollections,
      classSuffix: classSuffix,
      dryRun: dryRun,
      collectionOptions: collectionOptions,
    );
  }

  /// Returns the [CollectionOptions] for a given collection name,
  /// or a default instance if none was specified.
  CollectionOptions optionsForCollection(String collectionName) {
    return collectionOptions[collectionName] ??
        const CollectionOptions();
  }

  /// Returns true if a valid authentication method is configured.
  bool get hasAuthentication =>
      staticToken != null || (email != null && password != null);

  /// Parses minimal CLI arguments. Only `--config` path and `--dry-run` are accepted.
  /// Returns a record with the config file path and dry-run flag.
  static ({String configPath, bool dryRun}) parseCliArgs(List<String> args) {
    String configPath = defaultConfigFileName;
    bool dryRun = false;

    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '--config':
        case '-c':
          configPath = args[++i];
          break;
        case '--dry-run':
          dryRun = true;
          break;
        case '--help':
        case '-h':
          _printUsage();
          throw const HelpRequestedException();
      }
    }

    return (configPath: configPath, dryRun: dryRun);
  }

  static void _printUsage() {
    print("""
Directus Entity Generator
Generates Dart model classes from your Directus schema.

Usage: dart run directus_api_manager:generate [options]

Options:
  --config, -c       Path to the options JSON file
                     (default: $defaultConfigFileName)
  --dry-run          Show what would be generated without writing files
  --help, -h         Show this help message

All other options are configured in the JSON file.
See directus_api_manager_options.template.json for a documented example.
""");
  }
}

/// Per-collection options for the `@CollectionMetadata` annotation.
class CollectionOptions {
  final String defaultFields;
  final String? webSocketEndPoint;
  final String? defaultUpdateFields;

  const CollectionOptions({
    this.defaultFields = "*",
    this.webSocketEndPoint,
    this.defaultUpdateFields,
  });

  factory CollectionOptions.fromJson(Map<String, dynamic> json) {
    return CollectionOptions(
      defaultFields: json["defaultFields"] as String? ?? "*",
      webSocketEndPoint: json["webSocketEndPoint"] as String?,
      defaultUpdateFields: json["defaultUpdateFields"] as String?,
    );
  }
}

class HelpRequestedException implements Exception {
  const HelpRequestedException();
}
