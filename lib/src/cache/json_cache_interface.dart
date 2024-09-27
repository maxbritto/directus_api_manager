// coverage:ignore-file
import 'dart:convert';
import 'dart:io';

import 'package:directus_api_manager/directus_api_manager.dart';

import 'cache_entry.dart';

/// The JSON engine is a provided cache engine to be used as is in your project.
/// It will use regular .json files to store and load response from a directus instance
///
/// on set : The engine will automatically create new json file for each specific entry.
///   The name for the file will match the entry key.
///   The content will be encoded as json within the file
/// on read : The engine will try to find a file for the provided key
///   if found:  it will load the content of the file and parse the json to return a [CacheEntry] object
///   if not found : it will return null
class JsonCacheEngine implements ILocalDirectusCacheInterface {
  /// The base folder path for all json cache files to be stored and loaded
  final String cachefolderPath;

  const JsonCacheEngine({required this.cachefolderPath});

  Future<String> _getFilePath({required String key}) async {
    final fileName = key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '.');
    return "$cachefolderPath/$fileName.json";
  }

  @override
  Future<CacheEntry?> getCacheEntry({required String key}) async {
    final filePath = await _getFilePath(key: key);
    final file = File(filePath);
    if (file.existsSync()) {
      final content = await file.readAsString();
      final json = jsonDecode(content);
      return CacheEntry.fromJson(json);
    } else {
      return null;
    }
  }

  @override
  Future<void> setCacheEntry({required CacheEntry cacheEntry}) async {
    final filePath = await _getFilePath(key: cacheEntry.key);
    final file = File(filePath);
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(jsonEncode(cacheEntry.toJson()));
  }

  @override
  Future<void> removeCacheEntry({required String key}) async {
    final filePath = await _getFilePath(key: key);
    final file = File(filePath);
    if (!file.existsSync()) {
      await file.delete();
    }
  }
}
