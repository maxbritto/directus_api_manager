import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:directus_api_manager/src/model/directus_data.dart';
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
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetSpecificItemRequest"));
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
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
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["itemId"], "element1");
      expect(mockDirectusApi.receivedObjects["fields"], "name,description");
    });

    test("getSpecificItem without specifying the type", () async {
      mockDirectusApi
          .addNextReturnFutureObject({"id": "element1", "name": "element1"});
      final DirectusItemTest? item = await sut.getSpecificItem(id: "element1");
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetSpecificItemRequest"));
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
    });

    test("findListOfItems", () async {
      mockDirectusApi.addNextReturnFutureObject([
        {"id": "element1", "name": "element1"}
      ]);
      final items = await sut.findListOfItems<DirectusItemTest>();
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetListOfItemsRequest"));
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
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
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["filter"], filters);
    });

    test("findListOfItems with limit", () async {
      mockDirectusApi.addNextReturnFutureObject([
        {"id": "element1", "name": "element1"}
      ]);
      await sut.findListOfItems<DirectusItemTest>(limit: 10);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetListOfItemsRequest"));
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["limit"], 10);
    });

    test("findListOfItems with offset", () async {
      mockDirectusApi.addNextReturnFutureObject([
        {"id": "element1", "name": "element1"}
      ]);
      await sut.findListOfItems<DirectusItemTest>(offset: 10);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetListOfItemsRequest"));
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
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
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
      expect(
          mockDirectusApi.receivedObjects["sortBy"], isA<List<SortProperty>>());
    });

    test("findListOfItems without specifying the type", () async {
      mockDirectusApi.addNextReturnFutureObject([
        {"id": "element1", "name": "element1"}
      ]);
      final Iterable<DirectusItemTest> items = await sut.findListOfItems();
      expect(mockDirectusApi.calledFunctions,
          contains("prepareGetListOfItemsRequest"));
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
    });

    test("createNewItem", () async {
      mockDirectusApi.addNextReturnFutureObject({"id": "element1"});
      final newItem = DirectusItemTest.newItem();
      final item =
          await sut.createNewItem<DirectusItemTest>(objectToCreate: newItem);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareCreateNewItemRequest"));
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
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
      final DirectusItemCreationResult<DirectusItemTest> item =
          await sut.createNewItem(objectToCreate: newItem);
      expect(mockDirectusApi.calledFunctions,
          contains("prepareCreateNewItemRequest"));
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
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
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
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
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["objectData"], {"name": "name 2"},
          reason: "Only the changed fields should be sent");

      expect(
          mockDirectusApi.calledFunctions, contains("parseUpdateItemResponse"));
      expect(item, isNotNull);
      expect(item, isA<DirectusItemTest>());
    });

    test("deleteItem", () async {
      mockDirectusApi.addNextReturnFutureObject(true);
      final item = await sut.deleteItem<DirectusItemTest>(objectId: "element1");
      expect(mockDirectusApi.calledFunctions,
          contains("prepareDeleteItemRequest"));
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
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
      expect(mockDirectusApi.receivedObjects["itemName"], "itemTest");
      expect(mockDirectusApi.receivedObjects["itemIdList"],
          ["element1", "element2"]);

      expect(mockDirectusApi.calledFunctions,
          contains("parseGenericBoolResponse"));
      expect(item, isTrue);
    });
  });
}
