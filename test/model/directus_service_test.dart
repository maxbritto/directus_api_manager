import 'package:directus_api_manager/src/directus_api_manager_base.dart';
import 'package:directus_api_manager/src/model/directus_item.dart';
import 'package:directus_api_manager/src/model/directus_service.dart';
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
}

class DirectusServiceTest extends DirectusService<DirectusItemUseCase> {
  DirectusServiceTest(
      {required DirectusApiManager apiManager,
      required String typeName,
      String fields = "*"})
      : super(apiManager: apiManager, typeName: typeName, fields: fields);

  @override
  DirectusItemUseCase fromDirectus(rawData) {
    return DirectusItemUseCase.fromDirectus({"id": "123-abc"});
  }
}

main() {
  group('DirectusData', () {
    test('TypeName', () {
      final sut = DirectusServiceTest(
        apiManager: DirectusApiManager(
            baseURL: 'htttp://toto.com', httpClient: Client()),
        typeName: "itemCollection",
      );
      expect(sut.typeName, "itemCollection");
      expect(sut.fields, "*");
    });

    test('Fields', () {
      final sut = DirectusServiceTest(
          apiManager: DirectusApiManager(
              baseURL: 'htttp://toto.com', httpClient: Client()),
          typeName: "itemCollection",
          fields: "*.*");
      expect(sut.fields, "*.*");
    });
  });
}
