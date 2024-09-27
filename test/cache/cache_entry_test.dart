import 'package:directus_api_manager/src/cache/cache_entry.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  group('CacheEntry', () {
    test('toJson and from json', () {
      final cacheEntry = makeCacheEntry();
      final json = cacheEntry.toJson();
      final newCacheEntry = CacheEntry.fromJson(json);
      expect(newCacheEntry.key, cacheEntry.key);
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

CacheEntry makeCacheEntry({
  String key = 'key',
  DateTime? dateCreated,
  DateTime? validUntil,
  Map<String, String> headers = const {"Header-1": "Value-1"},
  String body = 'body example',
  int statusCode = 200,
}) {
  return CacheEntry(
    key: key,
    dateCreated: dateCreated ?? DateTime(2021),
    validUntil: validUntil ?? DateTime(2022),
    headers: headers,
    body: body,
    statusCode: statusCode,
  );
}
