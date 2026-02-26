import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches schema information (collections, fields, relations) from a Directus instance.
class DirectusSchemaFetcher {
  final String baseUrl;
  final http.Client _httpClient;
  String? _accessToken;
  final String? _staticToken;

  DirectusSchemaFetcher({
    required this.baseUrl,
    String? staticToken,
    http.Client? httpClient,
  })  : _staticToken = staticToken,
        _httpClient = httpClient ?? http.Client();

  /// Authenticates with email/password and stores the access token.
  Future<void> authenticate(
      {required String email, required String password}) async {
    final url = _buildUrl("/auth/login");
    final response = await _httpClient.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Authentication failed (HTTP ${response.statusCode}): ${response.body}");
    }

    final data = jsonDecode(response.body)["data"];
    _accessToken = data["access_token"];
  }

  /// Fetches all user collections (excludes system collections starting with "directus_").
  Future<List<DirectusCollectionInfo>> fetchCollections() async {
    final response = await _get("/collections");
    final List<dynamic> data = response["data"];
    return data
        .map((json) => DirectusCollectionInfo.fromJson(json))
        .where((c) => !c.collection.startsWith("directus_"))
        .toList();
  }

  /// Fetches all fields for a specific collection.
  Future<List<DirectusFieldInfo>> fetchFieldsForCollection(
      String collection) async {
    final response = await _get("/fields/$collection");
    final List<dynamic> data = response["data"];
    return data.map((json) => DirectusFieldInfo.fromJson(json)).toList();
  }

  /// Fetches all relations.
  Future<List<DirectusRelationInfo>> fetchRelations() async {
    final response = await _get("/relations");
    final List<dynamic> data = response["data"];
    return data.map((json) => DirectusRelationInfo.fromJson(json)).toList();
  }

  Map<String, String> get _headers {
    final headers = <String, String>{};
    final token = _staticToken ?? _accessToken;
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  Uri _buildUrl(String path) {
    String base = baseUrl;
    if (base.endsWith("/")) {
      base = base.substring(0, base.length - 1);
    }
    return Uri.parse("$base$path");
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response =
        await _httpClient.get(_buildUrl(path), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception(
          "Failed to fetch $path (HTTP ${response.statusCode}): ${response.body}");
    }
    return jsonDecode(response.body);
  }
}

/// Information about a Directus collection.
class DirectusCollectionInfo {
  final String collection;
  final bool? isSingleton;

  DirectusCollectionInfo({
    required this.collection,
    this.isSingleton,
  });

  factory DirectusCollectionInfo.fromJson(Map<String, dynamic> json) {
    return DirectusCollectionInfo(
      collection: json["collection"],
      isSingleton: json["meta"]?["singleton"],
    );
  }
}

/// Information about a Directus field.
class DirectusFieldInfo {
  final String collection;
  final String field;
  final String? type;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool isRequired;
  final bool isReadonly;
  final String? interfaceName;
  final String? specialType;

  DirectusFieldInfo({
    required this.collection,
    required this.field,
    this.type,
    this.isNullable = true,
    this.isPrimaryKey = false,
    this.isRequired = false,
    this.isReadonly = false,
    this.interfaceName,
    this.specialType,
  });

  factory DirectusFieldInfo.fromJson(Map<String, dynamic> json) {
    final schema = json["schema"] as Map<String, dynamic>?;
    final meta = json["meta"] as Map<String, dynamic>?;

    // Extract special types (e.g., "file", "m2o", "o2m", "m2m")
    String? specialType;
    final special = meta?["special"];
    if (special is List && special.isNotEmpty) {
      specialType = special.first?.toString();
    }

    return DirectusFieldInfo(
      collection: json["collection"],
      field: json["field"],
      type: json["type"],
      isNullable: schema?["is_nullable"] ?? true,
      isPrimaryKey: schema?["is_primary_key"] ?? false,
      isRequired: meta?["required"] ?? false,
      isReadonly: meta?["readonly"] ?? false,
      interfaceName: meta?["interface"],
      specialType: specialType,
    );
  }

  /// Returns true if this field represents a file relation.
  bool get isFileRelation => specialType == "file";

  /// Returns true if this field represents a M2O relation.
  bool get isManyToOne =>
      specialType == "m2o" && !isFileRelation;

  /// Returns true if this field represents a O2M relation.
  bool get isOneToMany => specialType == "o2m";

  /// Returns true if this field represents a M2M relation.
  bool get isManyToMany => specialType == "m2m";

  /// Returns true if this field is an alias (virtual, no column in DB).
  bool get isAlias => type == "alias";
}

/// Information about a Directus relation.
class DirectusRelationInfo {
  final String collection;
  final String field;
  final String relatedCollection;

  DirectusRelationInfo({
    required this.collection,
    required this.field,
    required this.relatedCollection,
  });

  factory DirectusRelationInfo.fromJson(Map<String, dynamic> json) {
    return DirectusRelationInfo(
      collection: json["collection"] ?? "",
      field: json["field"] ?? "",
      relatedCollection: json["related_collection"] ?? "",
    );
  }
}
