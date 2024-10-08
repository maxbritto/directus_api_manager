import 'package:directus_api_manager/src/cache/cache_entry.dart';
import 'package:extension_dart_tools/extension_tools.dart';

import '../src/directus_api_manager_base.dart';

class MockCacheEngine with MockMixin implements ILocalDirectusCacheInterface {
  @override
  Future<CacheEntry?> getCacheEntry({required String key}) {
    addCall(named: 'getCacheEntry', arguments: {'key': key});
    return Future.value(popNextReturnedObject());
  }

  @override
  Future<void> removeCacheEntry({required String key}) {
    addCall(named: 'removeCacheEntry', arguments: {'key': key});
    return Future.value();
  }

  @override
  Future<void> setCacheEntry(
      {required CacheEntry cacheEntry, required List<String> tags}) {
    addCall(
        named: 'setCacheEntry',
        arguments: {'cacheEntry': cacheEntry, 'tags': tags});
    return Future.value();
  }

  @override
  Future<void> clearCache() {
    addCall(named: 'clearCache');
    return Future.value();
  }

  @override
  Future<void> removeCacheEntriesWithTag({required String tag}) {
    addCall(named: 'removeCacheEntriesWithTag', arguments: {'tag': tag});
    return Future.value();
  }
}

CacheEntry makeCacheEntry({
  String key = 'key',
  String value = 'value',
  DateTime? dateCreated,
  DateTime? validUntil,
  Map<String, String> headers = const {},
  String body = 'body',
  int statusCode = 200,
}) {
  return CacheEntry(
    key: key,
    dateCreated: dateCreated ?? DateTime(2024),
    validUntil: validUntil ?? DateTime(2024),
    headers: headers,
    body: body,
    statusCode: statusCode,
  );
}
