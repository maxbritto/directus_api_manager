// coverage:ignore-file
import 'dart:convert';
import 'dart:io';

import 'package:directus_api_manager/directus_api_manager.dart';

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
  _TagsFileContent? _tagsFileContent;

  JsonCacheEngine({required this.cachefolderPath});

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
  Future<void> setCacheEntry(
      {required CacheEntry cacheEntry, required List<String> tags}) async {
    final filePath = await _getFilePath(key: cacheEntry.key);
    final file = File(filePath);
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(jsonEncode(cacheEntry.toJson()));
    if (tags.isNotEmpty) {
      final tagsFileContent = await _getTagsFileContent();
      for (final tag in tags) {
        tagsFileContent.addEntry(tag: tag, key: cacheEntry.key);
      }
      await _saveTagsFileContent(tagsFileContent);
    }
  }

  String get _tagsFilePath => "$cachefolderPath/tags.json";

  Future<void> _saveTagsFileContent(_TagsFileContent tagsFileContent) async {
    final tagsFile = File(_tagsFilePath);
    if (!tagsFile.existsSync()) {
      await tagsFile.create(recursive: true);
    }
    await tagsFile.writeAsString(jsonEncode(tagsFileContent.taggedEntries));
  }

  @override
  Future<void> removeCacheEntry({required String key}) async {
    final filePath = await _getFilePath(key: key);
    final file = File(filePath);
    if (!file.existsSync()) {
      await file.delete();
    }
  }

  @override
  Future<void> clearCache() async {
    final directory = Directory(cachefolderPath);
    if (directory.existsSync()) {
      await for (var file in directory.list(recursive: false)) {
        if (file is File) {
          await file.delete();
        }
      }
    }
  }

  @override
  Future<void> removeCacheEntriesWithTag({required String tag}) async {
    final tagsFileContent = await _getTagsFileContent();
    final entries = tagsFileContent.getEntriesWithTag(tag: tag);
    for (final entry in entries) {
      await removeCacheEntry(key: entry);
    }
    tagsFileContent.removeAllEntriesWithTag(tag: tag);
    await _saveTagsFileContent(tagsFileContent);
  }

  Future<_TagsFileContent> _getTagsFileContent() async {
    _TagsFileContent? tagsFileContent = _tagsFileContent;
    if (tagsFileContent == null) {
      final filePath = "$cachefolderPath/tags.json";
      final file = File(filePath);
      if (file.existsSync()) {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        tagsFileContent = _TagsFileContent(taggedEntries: json);
      } else {
        tagsFileContent = const _TagsFileContent.empty();
      }
    }
    return tagsFileContent;
  }
}

class _TagsFileContent {
  final Map<String, List<String>> taggedEntries;

  const _TagsFileContent({required this.taggedEntries});
  const _TagsFileContent.empty() : taggedEntries = const {};

  void addEntry({required String tag, required String key}) {
    final existingEntriesForTag = taggedEntries[tag];
    if (existingEntriesForTag == null) {
      taggedEntries[tag] = [key];
    } else if (!existingEntriesForTag.contains(key)) {
      existingEntriesForTag.add(key);
    }
  }

  List<String> getEntriesWithTag({required String tag}) {
    return taggedEntries[tag] ?? const [];
  }

  void removeAllEntriesWithTag({required String tag}) {
    taggedEntries.remove(tag);
  }
}
