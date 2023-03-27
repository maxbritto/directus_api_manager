import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'mock/mock_directus_api.dart';
import 'mock/mock_http_client.dart';
import 'directus_api_manager_test.reflectable.dart';
import 'model/directus_item_test.dart';

main() {
  initializeReflectable();
  group("DirectusApiManager", () {
    late DirectusApiManager sut;
    late MockHTTPClient mockClient;
    late MockDirectusApi mockDirectusApi;

    setUp(() {
      mockClient = MockHTTPClient();
      mockClient.addStreamResponse(body: "", statusCode: 200);
      mockDirectusApi = MockDirectusApi();
      sut = DirectusApiManager(
        baseURL: "http://api.com",
        httpClient: mockClient,
        api: mockDirectusApi,
      );
    });

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
    test('Manager should only load current user once.', () async {
      final mockClient = MockHTTPClient();
      const successLoginResponse = """
    {"data":{"access_token":"ABCD.1234.ABCD","expires":900000,"refresh_token":"REFRESH.TOKEN.5678"}}
    """;
      mockClient.addStreamResponse(body: successLoginResponse);
      final sut =
          DirectusApiManager(baseURL: "http://api.com", httpClient: mockClient);
      await sut.loginDirectusUser("l", "p");
      expect(await sut.hasLoggedInUser(), true);
      const userJson = """
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
""";
      mockClient.addStreamResponse(body: userJson);
      mockClient.calledFunctions.clear();

      var currentUser = await sut.currentDirectusUser();
      expect(currentUser, isNotNull);
      expect(currentUser?.email, "will@acn.com");
      expect(mockClient.calledFunctions.contains("send"), true,
          reason:
              "First call to currentDirectusUser() should trigger a fetch for user data");
      mockClient.calledFunctions.clear();

      mockClient.addStreamResponse(
          body:
              userJson); //we add this to have a nicer fail on the test. Usually the trigger should not be launched at all.P
      currentUser = await sut.currentDirectusUser();
      expect(currentUser, isNotNull);
      expect(currentUser?.email, "will@acn.com");
      expect(mockClient.calledFunctions.contains("send"), false,
          reason:
              "Subsequent calls to currentDirectusUser() should not trigger a fetch for user data");
    });
    test('Discarding current user cache', () async {
      final mockClient = MockHTTPClient();
      const successLoginResponse = """
    {"data":{"access_token":"ABCD.1234.ABCD","expires":900000,"refresh_token":"REFRESH.TOKEN.5678"}}
    """;
      mockClient.addStreamResponse(body: successLoginResponse);
      final sut =
          DirectusApiManager(baseURL: "http://api.com", httpClient: mockClient);
      await sut.loginDirectusUser("l", "p");
      expect(await sut.hasLoggedInUser(), true);
      const userJson = """
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
""";
      mockClient.addStreamResponse(body: userJson);
      mockClient.calledFunctions.clear();

      var currentUser = await sut.currentDirectusUser();
      expect(currentUser, isNotNull);
      expect(mockClient.calledFunctions.contains("send"), true,
          reason:
              "First call to currentDirectusUser() should trigger a fetch for user data");
      mockClient.calledFunctions.clear();

      sut.discardCurrentUserCache();
      mockClient.addStreamResponse(body: userJson);
      currentUser = await sut.currentDirectusUser();
      expect(currentUser, isNotNull);
      expect(currentUser?.email, "will@acn.com");
      expect(mockClient.calledFunctions.contains("send"), true,
          reason:
              "Since the cache was discarded, current user should have been refetched on last call");
    });
    test('Logged out user should not be fetchable', () async {
      final mockClient = MockHTTPClient();
      const successLoginResponse = """
    {"data":{"access_token":"ABCD.1234.ABCD","expires":900000,"refresh_token":"REFRESH.TOKEN.5678"}}
    """;
      mockClient.addStreamResponse(body: successLoginResponse);
      final sut =
          DirectusApiManager(baseURL: "http://api.com", httpClient: mockClient);
      await sut.loginDirectusUser("l", "p");
      expect(await sut.hasLoggedInUser(), true);
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

      var currentUser = await sut.currentDirectusUser();
      expect(currentUser, isNotNull);
      expect(currentUser?.email, "will@acn.com");

      mockClient.addStreamResponse(body: "", statusCode: 200); //logout response
      await sut.logoutDirectusUser();

      currentUser = await sut.currentDirectusUser();
      expect(currentUser, isNull,
          reason: "Logged out user should not be fetchable");
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

    test("getSpecificItem with no item", () async {
      mockDirectusApi.addNextReturnFutureObject(DirectusApiError());
      final item = await sut.getSpecificItem<DirectusItemTest>(id: "element1");
      expect(item, isNull);
    });

    test("getSpecificItem with item", () async {
      mockDirectusApi
          .addNextReturnFutureObject({"id": "element1", "name": "element1"});
      final item = await sut.getSpecificItem<DirectusItemTest>(id: "element1");
      expect(item, isNotNull);
      expect(item, isA<DirectusItemTest>());
      expect(item?.id, "element1");
    });
  });
}
