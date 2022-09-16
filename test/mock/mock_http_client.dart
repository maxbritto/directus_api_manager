import 'dart:typed_data';

import 'dart:convert';
import 'package:http/http.dart';

import 'mock_mixin.dart';

class MockHTTPClient with MockMixin implements Client {
  addStreamResponse({required String body, int statusCode = 200}) {
    addNextReturnFutureObject(
        StreamedResponse(Stream.value(utf8.encode(body)), statusCode));
  }

  @override
  void close() {}

  @override
  Future<Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return popNextReturnedObject();
  }

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) async {
    return popNextReturnedObject();
  }

  @override
  Future<Response> head(Uri url, {Map<String, String>? headers}) async {
    return popNextReturnedObject();
  }

  @override
  Future<Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return popNextReturnedObject();
  }

  @override
  Future<Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return popNextReturnedObject();
  }

  @override
  Future<Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return popNextReturnedObject();
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) async {
    return popNextReturnedObject();
  }

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) async {
    return popNextReturnedObject();
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    calledFunctions.add("send");
    addReceivedObject(request, name: "send:request");
    final response = popNextReturnedObject();
    return response;
  }
}
