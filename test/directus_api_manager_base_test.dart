import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'directus_api_manager_base_test.reflectable.dart';
import 'mock/mock_directus_api.dart';
import 'mock/mock_http_client.dart';
import 'model/directus_item_test.dart';

void main() {
  initializeReflectable();
  group("DirectusApiManager", () {
    late DirectusApiManager sut;
    late MockHTTPClient mockClient;
    late MockDirectusApi mockDirectusApi;
    late MockCacheEngine mockCacheEngine;

    setUp(() {
      mockClient = MockHTTPClient();
      mockClient.addStreamResponse(body: "", statusCode: 200);
      mockDirectusApi = MockDirectusApi();
      mockCacheEngine = MockCacheEngine();
      sut = DirectusApiManager(
        baseURL: "http://api.com",
        httpClient: mockClient,
        api: mockDirectusApi,
        cacheEngine: mockCacheEngine,
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

    test('URL for websocket must return', () async {
      final mockClient = MockHTTPClient();
      DirectusApiManager sut =
          DirectusApiManager(baseURL: "http://api.com", httpClient: mockClient);
      expect(sut.webSocketBaseUrl, "ws://api.com/websocket");

      sut = DirectusApiManager(
          baseURL: "http://api.com/", httpClient: mockClient);
      expect(sut.webSocketBaseUrl, "ws://api.com/websocket");

      sut = DirectusApiManager(
          baseURL: "https://api.com", httpClient: mockClient);
      expect(sut.webSocketBaseUrl, "wss://api.com/websocket");
      sut = DirectusApiManager(
          baseURL: "https://api.com/", httpClient: mockClient);
      expect(sut.webSocketBaseUrl, "wss://api.com/websocket");
    });

    test("Base Url must return", () {
      final mockClient = MockHTTPClient();
      DirectusApiManager sut =
          DirectusApiManager(baseURL: "http://api.com", httpClient: mockClient);
      expect(sut.baseUrl, "http://api.com");

      sut = DirectusApiManager(
          baseURL: "http://api.com/", httpClient: mockClient);
      expect(sut.baseUrl, "http://api.com");

      sut = DirectusApiManager(
          baseURL: "https://api.com", httpClient: mockClient);
      expect(sut.baseUrl, "https://api.com");
      sut = DirectusApiManager(
          baseURL: "https://api.com/", httpClient: mockClient);
      expect(sut.baseUrl, "https://api.com");
    });

    test("URL for websocket with invalid url", () {
      final mockClient = MockHTTPClient();
      DirectusApiManager sut =
          DirectusApiManager(baseURL: "invalidUrl", httpClient: mockClient);
      expect(() => sut.webSocketBaseUrl, throwsException);
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
      final sut = DirectusApiManager(
          baseURL: "http://api.com",
          httpClient: mockClient,
          cacheEngine: mockCacheEngine);
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
      expect(mockCacheEngine.calledFunctions, contains("setCacheEntry"),
          reason:
              "First call to currentDirectusUser should cache the user data");

      sut.discardCurrentUserCache();
      mockClient.addStreamResponse(body: userJson);
      expect(mockCacheEngine.calledFunctions, contains("removeCacheEntry"),
          reason: "Discarding the cache should remove the user data");
      expect(mockCacheEngine.receivedObjects["key"], "currentDirectusUser");
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

    test("Manager with logged in user must give the access token", () async {
      final mockClient = MockHTTPClient();
      const successLoginResponse = """
    {"data":{"access_token":"ABCD.1234.ABCD","expires":900000,"refresh_token":"REFRESH.TOKEN.5678"}}
    """;
      mockClient.addStreamResponse(body: successLoginResponse);
      final sut =
          DirectusApiManager(baseURL: "http://api.com", httpClient: mockClient);
      await sut.loginDirectusUser("l", "p");
      expect(sut.accessToken, "ABCD.1234.ABCD");
      expect(sut.shouldRefreshToken, false);
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

    test("registerDirectusUser", () async {
      mockDirectusApi.addNextReturnFutureObject(true);
      final result = await sut.registerDirectusUser(
          email: "will@acn.com",
          password: "password",
          firstname: "Will",
          lastname: "McAvoy");
      expect(mockDirectusApi.calledFunctions,
          contains("prepareRegisterUserRequest"));
      expect(mockDirectusApi.receivedObjects["email"], "will@acn.com");
      expect(mockDirectusApi.receivedObjects["password"], "password");
      expect(mockDirectusApi.receivedObjects["firstname"], "Will");
      expect(mockDirectusApi.receivedObjects["lastname"], "McAvoy");

      expect(mockDirectusApi.calledFunctions,
          contains("parseGenericBoolResponse"));
      expect(result, isTrue);
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
    test(
        'Empty manager with successfull refresh token load should refresh the token before fetching data',
        () async {
      bool hasUsedRefreshToken = false;
      final mockClient = MockHTTPClient();
      mockClient.addStreamResponse(
          body:
              '{"data":{"access_token":"NEW.ACCESS.TOKEN","expires":900000,"refresh_token":"NEW.REFRESH.TOKEN"}}');
      const successLoginResponse = '{"data":[]}';
      mockClient.addStreamResponse(body: successLoginResponse);
      final sut = DirectusApiManager(
          baseURL: "http://api.com",
          httpClient: mockClient,
          loadRefreshTokenCallback: () {
            hasUsedRefreshToken = true;
            return Future.delayed(
                Duration(milliseconds: 100), () => "SAVED.TOKEN");
          });
      await sut.findListOfItems<DirectusUser>();
      expect(hasUsedRefreshToken, true,
          reason: "Refresh token should be used to fetch data");
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
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetSpecificItemRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["endpointPrefix"], "/items/");

      expect(mockDirectusApi.receivedObjects["itemId"], "element1");
      expect(mockDirectusApi.receivedObjects["fields"], "*");

      expect(mockDirectusApi.calledFunctions,
          contains("parseGetSpecificItemResponse"));
      expect(item, isNotNull);
      expect(item, isA<DirectusItemTest>());
      expect(item?.id, "element1");
    });

    test("getSpecificItem with item and fields", () async {
      mockDirectusApi
          .addNextReturnFutureObject({"id": "element1", "name": "element1"});
      await sut.getSpecificItem<DirectusItemTest>(
          id: "element1", fields: "name,description");
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetSpecificItemRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["itemId"], "element1");
      expect(mockDirectusApi.receivedObjects["fields"], "name,description");
    });

    test("getSpecificItem without specifying the type", () async {
      mockDirectusApi
          .addNextReturnFutureObject({"id": "element1", "name": "element1"});
      // ignore: unused_local_variable
      final DirectusItemTest? item = await sut.getSpecificItem(id: "element1");
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetSpecificItemRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
    });

    test("getSpecificItem with a DirectusUser", () async {
      mockDirectusApi.addNextReturnFutureObject(
          {"id": "user-123", "email": "will@acn.com"});
      // ignore: unused_local_variable
      final DirectusUser? user = await sut.getSpecificItem(id: "user-123");
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetSpecificItemRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "users");
      expect(mockDirectusApi.receivedObjects["endpointPrefix"], "/");
    });

    test("findListOfItems", () async {
      mockDirectusApi.addNextReturnFutureObject([
        {"id": "element1", "name": "element1"}
      ]);
      final items = await sut.findListOfItems<DirectusItemTest>();
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetListOfItemsRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["fields"], "*");
      expect(mockDirectusApi.receivedObjects["filters"], isNull);
      expect(mockDirectusApi.receivedObjects["limit"], isNull);
      expect(mockDirectusApi.receivedObjects["offset"], isNull);
      expect(mockDirectusApi.receivedObjects["sortBy"], isNull);

      expect(mockDirectusApi.calledFunctions,
          contains("parseGetListOfItemsResponse"));
      expect(items, isNotNull);
      expect(items.length, 1);
      expect(items.first.id, "element1");
    });

    test("findListOfItems with filters", () async {
      mockDirectusApi.addNextReturnFutureObject([
        {"id": "element1", "name": "element1"}
      ]);
      final filters = PropertyFilter(
          field: "field", operator: FilterOperator.equals, value: "value");
      await sut.findListOfItems<DirectusItemTest>(filter: filters);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetListOfItemsRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["filter"], filters);
    });

    test("findListOfItems with limit", () async {
      mockDirectusApi.addNextReturnFutureObject([
        {"id": "element1", "name": "element1"}
      ]);
      await sut.findListOfItems<DirectusItemTest>(limit: 10);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetListOfItemsRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["limit"], 10);
    });

    test("findListOfItems with offset", () async {
      mockDirectusApi.addNextReturnFutureObject([
        {"id": "element1", "name": "element1"}
      ]);
      await sut.findListOfItems<DirectusItemTest>(offset: 10);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetListOfItemsRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["offset"], 10);
    });

    test("findListOfItems with sortBy", () async {
      mockDirectusApi.addNextReturnFutureObject([
        {"id": "element1", "name": "element1"}
      ]);
      await sut
          .findListOfItems<DirectusItemTest>(sortBy: [SortProperty("name")]);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetListOfItemsRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(
          mockDirectusApi.receivedObjects["sortBy"], isA<List<SortProperty>>());
    });

    test("findListOfItems without specifying the type", () async {
      mockDirectusApi.addNextReturnFutureObject([
        {"id": "element1", "name": "element1"}
      ]);
      // ignore: unused_local_variable
      final Iterable<DirectusItemTest> items = await sut.findListOfItems();
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetListOfItemsRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
    });

    test("createNewItem", () async {
      mockDirectusApi.addNextReturnFutureObject({"id": "element1"});
      final newItem = DirectusItemTest.newItem();
      final item =
          await sut.createNewItem<DirectusItemTest>(objectToCreate: newItem);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareCreateNewItemRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["objectData"],
          newItem.mapForObjectCreation());

      expect(mockDirectusApi.calledFunctions,
          contains("parseCreateNewItemResponse"));
      expect(item, isNotNull);
      expect(item, isA<DirectusItemCreationResult>());
    });

    test("createNewItem without specifying the type", () async {
      mockDirectusApi.addNextReturnFutureObject({"id": "element1"});
      final newItem = DirectusItemTest.newItem();
      // ignore: unused_local_variable
      final DirectusItemCreationResult<DirectusItemTest> item =
          await sut.createNewItem(objectToCreate: newItem);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareCreateNewItemRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
    });

    test("createMultipleItems", () async {
      mockDirectusApi.addNextReturnFutureObject([
        {"id": "element1"},
        {"id": "element2"}
      ]);
      final newItem1 = DirectusItemTest.newItem();
      newItem1.setValue("name 1", forKey: "name");
      final newItem2 = DirectusItemTest.newItem();
      newItem2.setValue("name 2", forKey: "name");
      final items = await sut.createMultipleItems<DirectusItemTest>(
          objectList: [newItem1, newItem2]);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareCreateNewItemRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["objectData"],
          [newItem1.mapForObjectCreation(), newItem2.mapForObjectCreation()]);

      expect(mockDirectusApi.calledFunctions,
          contains("parseCreateNewItemResponse"));
      expect(items, isNotNull);
      expect(items, isA<DirectusItemCreationResult>());
      final result = items;
      expect(result.createdItemList.length, 2);
      expect(result.createdItemList.first.id, "element1");
      expect(result.createdItemList.last.id, "element2");
    });

    test("createMultipleItems with an empty list should throw", () async {
      expect(() async {
        await sut.createMultipleItems<DirectusItemTest>(objectList: []);
      }, throwsException);
    });

    test("updateItem", () async {
      mockDirectusApi
          .addNextReturnFutureObject({"id": "element1", "name": "name 2"});
      final newItem = DirectusItemTest({"id": "element1", "name": "name 1"});
      newItem.setValue("name 2", forKey: "name");
      final item =
          await sut.updateItem<DirectusItemTest>(objectToUpdate: newItem);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareUpdateItemRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["objectData"], {"name": "name 2"},
          reason: "Only the changed fields should be sent");

      expect(
          mockDirectusApi.calledFunctions, contains("parseUpdateItemResponse"));
      expect(item, isNotNull);
      expect(item, isA<DirectusItemTest>());
    });

    test("updateItem force saving", () async {
      mockDirectusApi
          .addNextReturnFutureObject({"id": "element1", "name": "name 1"});
      final newItem = DirectusItemTest({"id": "element1", "name": "name 1"});

      final item = await sut.updateItem<DirectusItemTest>(
          objectToUpdate: newItem, force: true);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareUpdateItemRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["objectData"],
          {'id': 'element1', 'name': 'name 1'},
          reason: "As force saving is true, all fields should be sent");

      expect(
          mockDirectusApi.calledFunctions, contains("parseUpdateItemResponse"));
      expect(item, isNotNull);
      expect(item, isA<DirectusItemTest>());
    });

    test("UpdateItem with forbiden fields for saving", () async {
      mockDirectusApi
          .addNextReturnFutureObject({"id": "element1", "name": "name 1"});
      final newItem = DirectusItemTestWithUpdateField(
          {"id": "element1", "name": "name 1", "canBeChanged": true});

      final item = await sut.updateItem<DirectusItemTestWithUpdateField>(
          objectToUpdate: newItem, force: true);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareUpdateItemRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["objectData"],
          {'id': 'element1', 'name': 'name 1'},
          reason: "the field canBeChanged should not be sent");

      expect(
          mockDirectusApi.calledFunctions, contains("parseUpdateItemResponse"));
      expect(item, isNotNull);
      expect(item, isA<DirectusItemTestWithUpdateField>());
      expect(item.id, "element1");
      expect(item.name, "name 1");
      expect(item.canBeChanged, true);
    });

    test("updateItem with the current directus user", () async {
      mockDirectusApi.addNextReturnFutureObject(
          {"id": "user-123", "email": "will@acn.com"});
      final user = await sut.currentDirectusUser();
      expect(user, isNotNull);
      expect(sut.cachedCurrentUser, user);

      final updatedUser =
          DirectusUser({"id": "user-123", "email": "will@acn.com"});
      updatedUser.email = "updated@acn.com";

      mockClient.addStreamResponse(body: "", statusCode: 200);
      mockDirectusApi.addNextReturnFutureObject(
          {"id": "user-123", "email": "updated@acn.com"});
      await sut.updateItem<DirectusUser>(objectToUpdate: updatedUser);
      expect(sut.cachedCurrentUser?.email, "updated@acn.com",
          reason: "The cached user should be updated");
      expect(mockCacheEngine.calledFunctions, contains("removeCacheEntry"),
          reason: "The cache for the current user should be removed");
      expect(mockCacheEngine.receivedObjects["key"], "currentDirectusUser");
    });

    test("deleteItem", () async {
      mockDirectusApi.addNextReturnFutureObject(true);
      final item = await sut.deleteItem<DirectusItemTest>(objectId: "element1");
      expect(mockDirectusApi.calledFunctions,
          contains("prepareDeleteItemRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["itemId"], "element1");

      expect(mockDirectusApi.calledFunctions,
          contains("parseGenericBoolResponse"));
      expect(item, isTrue);
    });

    test("deleteMultipleItems", () async {
      mockDirectusApi.addNextReturnFutureObject(true);
      final item = await sut.deleteMultipleItems<DirectusItemTest>(
          objectIdsToDelete: ["element1", "element2"]);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareDeleteMultipleItemRequest"));
      expect(mockDirectusApi.receivedObjects["endpointName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["itemIdList"],
          ["element1", "element2"]);

      expect(mockDirectusApi.calledFunctions,
          contains("parseGenericBoolResponse"));
      expect(item, isTrue);
    });

    group("Cache engine", () {
      test("getSpecificItem should save by default responses", () async {
        mockDirectusApi
            .addNextReturnFutureObject({"id": "element1", "name": "element1"});
        await sut.getSpecificItem<DirectusItemTest>(id: "element1");
        expect(mockCacheEngine.calledFunctions, contains("setCacheEntry"));
      });

      test("getSpecificItem should not save responses if cache is disabled",
          () async {
        mockDirectusApi
            .addNextReturnFutureObject({"id": "element1", "name": "element1"});
        await sut.getSpecificItem<DirectusItemTest>(
            id: "element1", canSaveResponseToCache: false);
        expect(
            mockCacheEngine.calledFunctions, isNot(contains("setCacheEntry")));
      });

      test(
          "getSpecificItem should load from cache if allowed, available and unexpired",
          () async {
        mockCacheEngine.addNextReturnFutureObject(
            makeCacheEntry(validUntil: DateTime.now().add(Duration(days: 1))));
        await sut.getSpecificItem<DirectusItemTest>(
            id: "element1", canUseCacheForResponse: true);
        expect(mockDirectusApi.calledFunctions,
            contains("prepareGetSpecificItemRequest"));
        expect(mockCacheEngine.calledFunctions, contains("getCacheEntry"));
        expect(mockClient.calledFunctions, isNot(contains("send")),
            reason: "No network call should be made");
        expect(mockDirectusApi.calledFunctions,
            contains("parseGetSpecificItemResponse"),
            reason: "We should still have a response to parse (from cache)");
      });

      test(
          "getSpecificItem should not load from cache if allowed, available but expired",
          () async {
        mockCacheEngine.addNextReturnFutureObject(makeCacheEntry(
            validUntil: DateTime.now().subtract(Duration(days: 2))));
        mockDirectusApi
            .addNextReturnFutureObject({"id": "element1", "name": "element1"});
        await sut.getSpecificItem<DirectusItemTest>(
            id: "element1",
            canUseCacheForResponse: true,
            maxCacheAge: const Duration(days: 1));
        expect(mockDirectusApi.calledFunctions,
            contains("prepareGetSpecificItemRequest"));
        expect(mockCacheEngine.calledFunctions, contains("getCacheEntry"));
        expect(mockClient.calledFunctions, contains("send"),
            reason: "A network call should be made");
        expect(mockDirectusApi.calledFunctions,
            contains("parseGetSpecificItemResponse"),
            reason: "We should still have a response to parse (from network)");
      });

      test(
          "getSpecificItem should not load from cache if allowed, but not available",
          () async {
        mockCacheEngine.addNextReturnFutureObject(null);
        mockDirectusApi
            .addNextReturnFutureObject({"id": "element1", "name": "element1"});
        await sut.getSpecificItem<DirectusItemTest>(
            id: "element1", canUseCacheForResponse: true);
        expect(mockDirectusApi.calledFunctions,
            contains("prepareGetSpecificItemRequest"));
        expect(mockCacheEngine.calledFunctions, contains("getCacheEntry"));
        expect(mockClient.calledFunctions, contains("send"),
            reason: "A network call should be made");
        expect(mockDirectusApi.calledFunctions,
            contains("parseGetSpecificItemResponse"),
            reason: "We should still have a response to parse (from network)");
      });

      test("getSpecificItem should not load from cache if not allowed",
          () async {
        mockCacheEngine.addNextReturnFutureObject(
            makeCacheEntry(validUntil: DateTime.now().add(Duration(days: 1))));
        mockDirectusApi
            .addNextReturnFutureObject({"id": "element1", "name": "element1"});
        await sut.getSpecificItem<DirectusItemTest>(
            id: "element1", canUseCacheForResponse: false);
        expect(mockDirectusApi.calledFunctions,
            contains("prepareGetSpecificItemRequest"));
        expect(
            mockCacheEngine.calledFunctions, isNot(contains("getCacheEntry")));
        expect(mockClient.calledFunctions, contains("send"),
            reason: "A network call should be made");
        expect(mockDirectusApi.calledFunctions,
            contains("parseGetSpecificItemResponse"),
            reason: "We should still have a response to parse (from network)");
      });

      test(
          "getSpecificItem should use cache when allowed only as fallback and network failed",
          () async {
        mockCacheEngine.addNextReturnFutureObject(
            makeCacheEntry(validUntil: DateTime(2000)));
        mockClient.resetAllTestValues();
        mockClient.addNextReturnFutureObject(Exception("Network error"));
        await sut.getSpecificItem<DirectusItemTest>(
            id: "element1",
            canUseCacheForResponse: false,
            canUseOldCachedResponseAsFallback: true);
        expect(mockClient.calledFunctions, contains("send"),
            reason: "A network call should be made");
        expect(mockCacheEngine.calledFunctions, contains("getCacheEntry"),
            reason:
                "after a failed network call, we should try to get the cache");
        expect(mockDirectusApi.calledFunctions,
            contains("parseGetSpecificItemResponse"),
            reason: "We should still have a response to parse (from cache)");
      });

      test("logoutDirectusUser should clear the cache", () async {
        sut.cachedCurrentUser = DirectusUser({"id": "user-123"});
        await sut.logoutDirectusUser();
        expect(mockCacheEngine.calledFunctions, contains("clearCache"));
        expect(sut.cachedCurrentUser, isNull);
      });
    });
  });
}
