import 'dart:math';

import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:directus_api_manager/src/directus_api.dart';
import 'package:http/http.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class DirectusItemUseCase extends DirectusItem {
  DirectusItemUseCase(Map<String, dynamic> rawReceivedData)
      : super(rawReceivedData);
  DirectusItemUseCase.newItem() : super.newItem();
  factory DirectusItemUseCase.fromDirectus(dynamic rawReceivedData) {
    return DirectusItemUseCase(rawReceivedData);
  }

  @override
  String get endpointName => "itemCollection";

  String get title => getValue(forKey: "title");
  set title(String value) => setValue(value, forKey: "title");
}

class DirectusServiceTest extends DirectusService<DirectusItemUseCase> {
  DirectusServiceTest(
      {required DirectusApiManager apiManager,
      required String typeName,
      String fields = "*"})
      : super(apiManager: apiManager, typeName: typeName, fields: fields);

  @override
  DirectusItemUseCase fromDirectus(rawData) {
    return DirectusItemUseCase(rawData);
  }
}

class DirectusUserServiceTest {
  final DirectusApiManager apiManager;
  DirectusUserServiceTest({required this.apiManager});

  DirectusUser fromDirectus(rawData) {
    return DirectusUser(rawData);
  }
}

main() {
  group('DirectusItemCreationResult', () {
    test('Creating DirectusItemCreationResult', () {
      expect(
          () => DirectusItemCreationResult(isSuccess: true), returnsNormally);
      expect(
          () => DirectusItemCreationResult(
              isSuccess: false,
              error: DirectusApiError(customMessage: "hello world")),
          returnsNormally);
      expect(
          () => DirectusItemCreationResult(isSuccess: false), throwsException);
    });

    test("CreatedList empty", () {
      final DirectusItemCreationResult sut =
          DirectusItemCreationResult(isSuccess: true);
      expect(sut.createdItem, null);
    });

    test("CreatedList contains one item", () {
      final DirectusItemCreationResult sut =
          DirectusItemCreationResult(isSuccess: true);
      sut.createdItemList.add("a");
      expect(sut.createdItem, "a");
    });

    test("CreatedList contains more than on item", () {
      final DirectusItemCreationResult sut =
          DirectusItemCreationResult(isSuccess: true);
      sut.createdItemList.add("a");
      sut.createdItemList.add("b");
      expect(sut.createdItem, "a");
    });

    test("From Directus Test single item creation with response", () {
      final String responseBody =
          '{"data": {"id": "abc-123","title": "title"}}';
      final DirectusAPI api = DirectusAPI("https://www.api.com");
      final Response response = Response(responseBody, 200);
      final DirectusApiManager apiManager =
          DirectusApiManager(baseURL: "https://api.com", httpClient: Client());
      final DirectusServiceTest service =
          DirectusServiceTest(apiManager: apiManager, typeName: "test");

      final DirectusItemCreationResult<DirectusItemUseCase> sut =
          DirectusItemCreationResult.fromDirectus(
              api: api,
              response: response,
              createItemFunction: service.fromDirectus);

      expect(sut.isSuccess, true);
      expect(sut.createdItem != null, true);
      expect(sut.createdItemList.length, 1);
      expect(sut.createdItem!.id, "abc-123");
      expect(sut.createdItem!.title, "title");
    });

    test("From Directus Test single item creation no content return", () {
      final String responseBody = '';
      final DirectusAPI api = DirectusAPI("https://www.api.com");
      final Response response = Response(responseBody, 204);
      final DirectusApiManager apiManager =
          DirectusApiManager(baseURL: "https://api.com", httpClient: Client());
      final DirectusServiceTest service =
          DirectusServiceTest(apiManager: apiManager, typeName: "test");

      final DirectusItemCreationResult<DirectusItemUseCase> sut =
          DirectusItemCreationResult.fromDirectus(
              api: api,
              response: response,
              createItemFunction: service.fromDirectus);

      expect(sut.isSuccess, true);
      expect(sut.createdItem == null, true);
    });

    test("From Directus Test single item creation in error", () {
      final String responseBody = '';
      final DirectusAPI api = DirectusAPI("https://www.api.com");
      final Response response = Response(responseBody, 503);
      final DirectusApiManager apiManager =
          DirectusApiManager(baseURL: "https://api.com", httpClient: Client());
      final DirectusServiceTest service =
          DirectusServiceTest(apiManager: apiManager, typeName: "test");

      final DirectusItemCreationResult<DirectusItemUseCase> sut =
          DirectusItemCreationResult.fromDirectus(
              api: api,
              response: response,
              createItemFunction: service.fromDirectus);

      expect(sut.isSuccess, false);
      expect(sut.createdItem == null, true);
      expect(sut.error != null, true);
      expect(sut.error!.response!.statusCode, 503);
    });

    test("From Directus Test user creation", () {
      final String responseBody =
          '{"data": {"id": "abc-123","first_name": "Will","last_name": "McAvoy","email": "will@acn.com"}}';
      final DirectusAPI api = DirectusAPI("https://www.api.com");
      final Response response = Response(responseBody, 200);
      final DirectusApiManager apiManager =
          DirectusApiManager(baseURL: "https://api.com", httpClient: Client());
      final DirectusUserServiceTest service =
          DirectusUserServiceTest(apiManager: apiManager);

      final DirectusItemCreationResult<DirectusUser> sut =
          DirectusItemCreationResult.fromDirectus(
              api: api,
              response: response,
              createItemFunction: service.fromDirectus);

      expect(sut.isSuccess, true);
      expect(sut.createdItemList.length, 1);
      expect(sut.createdItem!.id, "abc-123");
      expect(sut.createdItem!.firstname, "Will");
      expect(sut.createdItem!.lastname, "McAvoy");
      expect(sut.createdItem!.email, "will@acn.com");
    });

    test("From Directus Test user creation no content return", () {
      final String responseBody = '';
      final DirectusAPI api = DirectusAPI("https://www.api.com");
      final Response response = Response(responseBody, 204);
      final DirectusApiManager apiManager =
          DirectusApiManager(baseURL: "https://api.com", httpClient: Client());
      final DirectusUserServiceTest service =
          DirectusUserServiceTest(apiManager: apiManager);

      final DirectusItemCreationResult<DirectusUser> sut =
          DirectusItemCreationResult.fromDirectus(
              api: api,
              response: response,
              createItemFunction: service.fromDirectus);

      expect(sut.isSuccess, true);
      expect(sut.createdItem == null, true);
      expect(sut.createdItemList.length, 0);
    });

    test("From Directus Test user creation in error", () {
      final String responseBody = '';
      final DirectusAPI api = DirectusAPI("https://www.api.com");
      final Response response = Response(responseBody, 503);
      final DirectusApiManager apiManager =
          DirectusApiManager(baseURL: "https://api.com", httpClient: Client());
      final DirectusUserServiceTest service =
          DirectusUserServiceTest(apiManager: apiManager);

      final DirectusItemCreationResult<DirectusUser> sut =
          DirectusItemCreationResult.fromDirectus(
              api: api,
              response: response,
              createItemFunction: service.fromDirectus);

      expect(sut.isSuccess, false);
      expect(sut.createdItem == null, true);
      expect(sut.error != null, true);
      expect(sut.error!.response!.statusCode, 503);
    });
  });
}
