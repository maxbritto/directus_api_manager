// coverage:ignore-file
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:mutex/mutex.dart';

enum IndexType { tags, allKeys }

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
  _TagsIndex? _tagsFileContent;
  _KeysIndex? _keysFileContent;
  final ReadWriteMutex _indexFileLock = ReadWriteMutex();

  JsonCacheEngine({required this.cachefolderPath}) {
    Timer.periodic(const Duration(minutes: 1), _onSaveTimerTicked);
  }

  void _onSaveTimerTicked(Timer timer) async {
    final tagsFileContent = _tagsFileContent;
    if (tagsFileContent != null &&
        tagsFileContent.hasBeenModifiedSinceLastSave) {
      await _saveIndexFile(
          indexType: IndexType.tags, content: tagsFileContent.toJson());
      tagsFileContent.hasBeenModifiedSinceLastSave = false;
    }

    final keysFileContent = _keysFileContent;
    if (keysFileContent != null &&
        keysFileContent.hasBeenModifiedSinceLastSave) {
      await _saveIndexFile(
          indexType: IndexType.allKeys, content: keysFileContent.toJson());
      keysFileContent.hasBeenModifiedSinceLastSave = false;
    }
  }

  Future<String> _getFilePath({required String key}) async {
    final fileName = key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '.');
    return "$cachefolderPath/$fileName.json";
  }

  @override
  Future<CacheEntry?> getCacheEntry({required String key}) async {
    CacheEntry? cacheEntry;
    try {
      final keysIndex = await _getKeysIndex();
      if (keysIndex.allKeys.contains(key)) {
        final filePath = await _getFilePath(key: key);
        final file = File(filePath);
        if (file.existsSync()) {
          final content = await file.readAsString();
          final json = jsonDecode(content);
          cacheEntry = CacheEntry.fromJson(json);
        }
      }
    } catch (e) {
      log("getCacheEntry error: $e");
    }
    return cacheEntry;
  }

  @override
  Future<void> setCacheEntry(
      {required CacheEntry cacheEntry, required List<String> tags}) async {
    try {
      final keysIndex = await _getKeysIndex();
      keysIndex.addKey(key: cacheEntry.key);
      final filePath = await _getFilePath(key: cacheEntry.key);
      final file = File(filePath);
      if (!file.existsSync()) {
        await file.create(recursive: true);
      }
      await file.writeAsString(jsonEncode(cacheEntry.toJson()));
      if (tags.isNotEmpty) {
        final tagsFileContent = await _getTagsIndex();
        for (final tag in tags) {
          tagsFileContent.addEntry(tag: tag, key: cacheEntry.key);
        }
      }
    } catch (e) {
      log("setCacheEntry error: $e");
    }
  }

  @override
  Future<void> removeCacheEntry({required String key}) async {
    try {
      final keysIndex = await _getKeysIndex();
      if (keysIndex.allKeys.contains(key)) {
        keysIndex.removeKey(key: key);
        final filePath = await _getFilePath(key: key);
        final file = File(filePath);
        if (file.existsSync()) {
          await file.delete();
        }
      }
    } catch (e) {
      log("removeCacheEntry error: $e");
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final directory = Directory(cachefolderPath);
      if (directory.existsSync()) {
        await for (var file in directory.list(recursive: false)) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      log("clearCache error: $e");
    }
  }

  @override
  Future<void> removeCacheEntriesWithTag({required String tag}) async {
    try {
      final tagsFileContent = await _getTagsIndex();
      final entries = tagsFileContent.getEntriesWithTag(tag: tag);
      for (final entry in entries) {
        await removeCacheEntry(key: entry);
      }
      tagsFileContent.removeAllEntriesWithTag(tag: tag);
    } catch (e) {
      log("removeCacheEntriesWithTag $tag error: $e");
    }
  }

  Future<_TagsIndex> _getTagsIndex() async {
    _TagsIndex? tagsFileContent = _tagsFileContent;
    if (tagsFileContent == null) {
      final content = await _readIndexFile(IndexType.tags);
      if (content != null) {
        final Map<String, dynamic> json = jsonDecode(content);
        final convertedMap = json.map((key, list) =>
            MapEntry<String, List<String>>(
                key,
                (list as List)
                    .map<String>((e) => e is String ? e : e.toString())
                    .toList()));
        tagsFileContent = _TagsIndex(taggedEntries: convertedMap);
      } else {
        tagsFileContent = _TagsIndex.empty();
      }
      _tagsFileContent = tagsFileContent;
    }
    return tagsFileContent;
  }

  Future<_KeysIndex> _getKeysIndex() async {
    _KeysIndex? keysFileContent = _keysFileContent;
    if (keysFileContent == null) {
      final content = await _readIndexFile(IndexType.allKeys);
      if (content != null) {
        final List<dynamic> json = jsonDecode(content);
        keysFileContent =
            _KeysIndex(allKeys: json.map<String>((e) => e.toString()).toSet());
      } else {
        keysFileContent = _KeysIndex.empty();
      }
      _keysFileContent = keysFileContent;
    }
    return keysFileContent;
  }

  Future<String?> _readIndexFile(IndexType indexType) async {
    await _indexFileLock.acquireRead();
    final String? content;
    final filePath = "$cachefolderPath/_${indexType.name}.json";
    final file = File(filePath);
    if (file.existsSync()) {
      content = await file.readAsString();
    } else {
      content = null;
    }
    _indexFileLock.release();
    return content == "" ? null : content;
  }

  Future<void> _saveIndexFile(
      {required IndexType indexType, required String content}) async {
    await _indexFileLock.acquireWrite();
    final filePath = "$cachefolderPath/_${indexType.name}.json";
    final file = File(filePath);
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(content);
    _indexFileLock.release();
  }
}

class _TagsIndex {
  final Map<String, List<String>> taggedEntries;
  bool hasBeenModifiedSinceLastSave = false;

  _TagsIndex({required this.taggedEntries});
  _TagsIndex.empty() : taggedEntries = <String, List<String>>{};

  void addEntry({required String tag, required String key}) {
    final existingEntriesForTag = taggedEntries[tag];
    if (existingEntriesForTag == null) {
      taggedEntries[tag] = [key];
    } else if (!existingEntriesForTag.contains(key)) {
      existingEntriesForTag.add(key);
    }
    hasBeenModifiedSinceLastSave = true;
  }

  List<String> getEntriesWithTag({required String tag}) {
    return taggedEntries[tag] ?? <String>[];
  }

  void removeAllEntriesWithTag({required String tag}) {
    taggedEntries.remove(tag);
    hasBeenModifiedSinceLastSave = true;
  }

  String toJson() {
    return jsonEncode(taggedEntries);
  }
}

class _KeysIndex {
  final Set<String> allKeys;
  bool hasBeenModifiedSinceLastSave = false;

  _KeysIndex({required this.allKeys});
  _KeysIndex.empty() : allKeys = <String>{};

  void addKey({required String key}) {
    if (!allKeys.contains(key)) {
      allKeys.add(key);
      hasBeenModifiedSinceLastSave = true;
    }
  }

  void removeKey({required String key}) {
    allKeys.remove(key);
    hasBeenModifiedSinceLastSave = true;
  }

  String toJson() {
    return jsonEncode(allKeys.toList());
  }
}
