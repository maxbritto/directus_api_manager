import 'package:http/http.dart';

class CacheEntry {
  final String key;
  final DateTime dateCreated;
  final DateTime validUntil;
  final Map<String, String> headers;
  final String body;
  final int statusCode;
  CacheEntry(
      {required this.dateCreated,
      required this.validUntil,
      required this.headers,
      required this.body,
      required this.statusCode,
      required this.key});

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'dateCreated': dateCreated.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'headers': headers,
      'body': body,
      'statusCode': statusCode,
    };
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['key'],
      dateCreated: DateTime.parse(json['dateCreated']),
      validUntil: DateTime.parse(json['validUntil']),
      headers: Map<String, String>.from(json['headers']),
      body: json['body'],
      statusCode: json['statusCode'],
    );
  }

  factory CacheEntry.fromResponse(Response response,
      {required String key, required Duration maxCacheAge}) {
    final now = DateTime.now();
    return CacheEntry(
      key: key,
      dateCreated: now,
      validUntil: now.add(maxCacheAge),
      headers: response.headers,
      body: response.body,
      statusCode: response.statusCode,
    );
  }

  Response toResponse() {
    return Response(
      body,
      statusCode,
      headers: headers,
    );
  }
}
