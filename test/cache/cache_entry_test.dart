import 'package:directus_api_manager/src/cache/cache_entry.dart';
import 'package:directus_api_manager/test/mock_cache_engine.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('CacheEntry', () {
    test('toJson and from json', () {
      final cacheEntry = makeCacheEntry();
      final json = cacheEntry.toJson();
      final newCacheEntry = CacheEntry.fromJson(json);
      expect(newCacheEntry.key, cacheEntry.key);
      expect(newCacheEntry.requestedUrl, cacheEntry.requestedUrl);
      expect(newCacheEntry.dateCreated, cacheEntry.dateCreated);
      expect(newCacheEntry.validUntil, cacheEntry.validUntil);
      expect(newCacheEntry.headers, cacheEntry.headers);
      expect(newCacheEntry.body, cacheEntry.body);
      expect(newCacheEntry.statusCode, cacheEntry.statusCode);
    });

    test('toResponse', () {
      final cacheEntry = makeCacheEntry();
      final response = cacheEntry.toResponse();
      expect(response.statusCode, cacheEntry.statusCode);
      expect(response.body, cacheEntry.body);
      expect(response.headers, cacheEntry.headers);
    });

    test('fromResponse', () {
      final response = Response('body', 200, headers: {"Header-1": "Value-1"});
      final cacheEntry = CacheEntry.fromResponse(response,
          key: "key", maxCacheAge: const Duration(days: 1));
      expect(cacheEntry.statusCode, response.statusCode);
      expect(cacheEntry.body, response.body);
      expect(cacheEntry.headers, response.headers);
    });
  });
}
