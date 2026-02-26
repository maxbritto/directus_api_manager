/// Configuration for the Directus entity generator.
class GeneratorConfig {
  final String directusUrl;
  final String? staticToken;
  final String? email;
  final String? password;
  final String outputDirectory;
  final List<String> excludeCollections;
  final List<String>? includeCollections;
  final String classSuffix;
  final bool generateReadonlySetters;
  final bool dryRun;

  const GeneratorConfig({
    required this.directusUrl,
    this.staticToken,
    this.email,
    this.password,
    this.outputDirectory = "lib/models/directus",
    this.excludeCollections = const [],
    this.includeCollections,
    this.classSuffix = "DirectusModel",
    this.generateReadonlySetters = false,
    this.dryRun = false,
  });

  /// Creates a [GeneratorConfig] from CLI arguments.
  factory GeneratorConfig.fromArgs(List<String> args) {
    String? url;
    String? token;
    String? email;
    String? password;
    String output = "lib/models/directus";
    String classSuffix = "DirectusModel";
    bool dryRun = false;
    final List<String> collections = [];
    final List<String> excludes = [];

    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '--url':
        case '-u':
          url = args[++i];
          break;
        case '--token':
        case '-t':
          token = args[++i];
          break;
        case '--email':
        case '-e':
          email = args[++i];
          break;
        case '--password':
        case '-p':
          password = args[++i];
          break;
        case '--output':
        case '-o':
          output = args[++i];
          break;
        case '--collection':
          collections.add(args[++i]);
          break;
        case '--exclude':
          excludes.add(args[++i]);
          break;
        case '--suffix':
          classSuffix = args[++i];
          break;
        case '--dry-run':
          dryRun = true;
          break;
        case '--help':
        case '-h':
          _printUsage();
          throw const _HelpRequestedException();
      }
    }

    if (url == null) {
      throw ArgumentError(
          "Directus URL is required. Use --url or -u to specify it.");
    }

    if (token == null && (email == null || password == null)) {
      throw ArgumentError(
          "Authentication is required. Use --token for a static token, or --email and --password for login.");
    }

    return GeneratorConfig(
      directusUrl: url,
      staticToken: token,
      email: email,
      password: password,
      outputDirectory: output,
      excludeCollections: excludes,
      includeCollections: collections.isEmpty ? null : collections,
      classSuffix: classSuffix,
      dryRun: dryRun,
    );
  }

  static void _printUsage() {
    print("""
Directus Entity Generator
Generates Dart model classes from your Directus schema.

Usage: dart run directus_api_manager:generate [options]

Options:
  --url, -u          Directus server URL (required)
  --token, -t        Static authentication token
  --email, -e        Email for authentication
  --password, -p     Password for authentication
  --output, -o       Output directory (default: lib/models/directus)
  --collection       Generate only for this collection (can be repeated)
  --exclude          Exclude this collection (can be repeated)
  --suffix           Class name suffix (default: DirectusModel)
  --dry-run          Show what would be generated without writing files
  --help, -h         Show this help message
""");
  }

  /// Returns true if a valid authentication method is configured.
  bool get hasAuthentication =>
      staticToken != null || (email != null && password != null);
}

class _HelpRequestedException implements Exception {
  const _HelpRequestedException();
}
