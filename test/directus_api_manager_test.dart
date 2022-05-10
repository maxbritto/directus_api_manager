import 'dart:typed_data';

import 'dart:convert';

import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:http/http.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class MockHTTPClient implements Client {
  final List<dynamic> _responses = [];

  dynamic _popNextResponse() {
    if (_responses.isEmpty) {
      return Response("", 200);
    }
    return _responses.removeAt(0);
  }

  addStreamResponse({required String body, int statusCode = 200}) {
    _responses
        .add(StreamedResponse(Stream.value(utf8.encode(body)), statusCode));
  }

  @override
  void close() {}

  @override
  Future<Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return _popNextResponse();
  }

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) async {
    return _popNextResponse();
  }

  @override
  Future<Response> head(Uri url, {Map<String, String>? headers}) async {
    return _popNextResponse();
  }

  @override
  Future<Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return _popNextResponse();
  }

  @override
  Future<Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return _popNextResponse();
  }

  @override
  Future<Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    return _popNextResponse();
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) async {
    return _popNextResponse();
  }

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) async {
    return _popNextResponse();
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final response = _popNextResponse();
    return response;
  }
}

main() {
  test('Empty manager does not have a logged in user', () async {
    final mockClient = MockHTTPClient();
    final sut =
        DirectusApiManager(baseURL: "http://api.com", httpClient: mockClient);
    expect(await sut.hasLoggedInUser(), false);
    mockClient.addStreamResponse(body: "", statusCode: 401);
    expect(await sut.currentDirectusUser(), isNull);
  });

  test(
      'Empty manager with successfull refresh token load should be able to load current user',
      () async {
    final mockClient = MockHTTPClient();
    final sut = DirectusApiManager(
      baseURL: "http://api.com",
      httpClient: mockClient,
      loadRefreshTokenCallback: () =>
          Future.delayed(Duration(milliseconds: 100), () => "SAVED.TOKEN"),
    );
    expect(await sut.hasLoggedInUser(), true);
    mockClient.addStreamResponse(
        body:
            '{"data":{"access_token":"NEW.ACCESS.TOKEN","expires":900000,"refresh_token":"NEW.REFRESH.TOKEN"}}');
    mockClient.addStreamResponse(body: """
{
  "data": {
    "id": "d0ac583c-aa0c-444e-afe6-4e6c31f6fd02",
    "first_name": "Will",
    "last_name": "McAvoy",
    "email": "will@acn.com",
    "password": "**********",
    "description": null,
    "status": "active",
    "role": "abc-123-abc",
    "token": null,
    "external_identifier": null,
    "schools": [
      1
    ]
  }
}
""");
    final currentUser = await sut.currentDirectusUser();
    expect(currentUser, isNotNull);
    expect(currentUser?.email, "will@acn.com");
  });

  test('Manager with logged in user', () async {
    final mockClient = MockHTTPClient();
    const successLoginResponse = """
    {"data":{"access_token":"ABCD.1234.ABCD","expires":900000,"refresh_token":"REFRESH.TOKEN.5678"}}
    """;
    mockClient.addStreamResponse(body: successLoginResponse);
    final sut =
        DirectusApiManager(baseURL: "http://api.com", httpClient: mockClient);
    await sut.loginDirectusUser("l", "p");
    expect(await sut.hasLoggedInUser(), true);
  });

  test('Empty manager with successfull refresh token load', () async {
    final mockClient = MockHTTPClient();
    final sut = DirectusApiManager(
      baseURL: "http://api.com",
      httpClient: mockClient,
      loadRefreshTokenCallback: () =>
          Future.delayed(Duration(milliseconds: 100), () => "SAVED.TOKEN"),
    );
    expect(await sut.hasLoggedInUser(), true);
  });

  test('Empty manager with NOT successfull refresh token load', () async {
    final mockClient = MockHTTPClient();
    final sut = DirectusApiManager(
      baseURL: "http://api.com",
      httpClient: mockClient,
      loadRefreshTokenCallback: () =>
          Future.delayed(Duration(milliseconds: 100), () => null),
    );
    expect(await sut.hasLoggedInUser(), false);
  });
}
