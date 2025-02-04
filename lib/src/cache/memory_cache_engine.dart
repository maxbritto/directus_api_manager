import 'package:directus_api_manager/directus_api_manager.dart';

/// A simple in-memory cache engine that will store all cache entries in memory
/// This engine is not persistent and will be cleared when the app is closed
/// It can be used for testing or as a memory cache engine for your projects when you want to lighten the load on the server for users using the app for extended periods of time
class MemoryCacheEngine implements ILocalDirectusCacheInterface {
  final Map<String, CacheEntry> _cacheEntries = {};
  final Map<String, List<String>> _tagsIndex = {};
  @override
  Future<void> clearCache() {
    _cacheEntries.clear();
    _tagsIndex.clear();
    return Future.value();
  }

  @override
  Future<CacheEntry?> getCacheEntry({required String key}) {
    return Future.value(_cacheEntries[key]);
  }

  @override
  Future<void> removeCacheEntriesWithTag({required String tag}) {
    final keys = _tagsIndex[tag];
    if (keys != null) {
      for (final key in keys) {
        _cacheEntries.remove(key);
      }
      _tagsIndex.remove(tag);
    }
    return Future.value();
  }

  @override
  Future<void> removeCacheEntry({required String key}) {
    _cacheEntries.remove(key);
    for (final tag in _tagsIndex.keys) {
      final allKeysForTag = _tagsIndex[tag];
      if (allKeysForTag != null) {
        if (allKeysForTag.remove(key)) {
          _tagsIndex[tag] = allKeysForTag;
        }
      }
    }
    return Future.value();
  }

  @override
  Future<void> setCacheEntry(
      {required CacheEntry cacheEntry, required List<String> tags}) {
    _cacheEntries[cacheEntry.key] = cacheEntry;
    for (final tag in tags) {
      final keys = _tagsIndex[tag];
      if (keys == null) {
        _tagsIndex[tag] = [cacheEntry.key];
      } else {
        keys.add(cacheEntry.key);
        _tagsIndex[tag] = keys;
      }
    }
    return Future.value();
  }
}
