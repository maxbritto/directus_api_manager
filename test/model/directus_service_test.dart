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
      DirectusApiManager apiManager, String typeName, String fields)
      : super(apiManager, typeName, fields);

  @override
  DirectusItemUseCase fromDirectus(rawData) {
    return DirectusItemUseCase.fromDirectus({"id": "123-abc"});
  }
}

main() {
  group('DirectusData', () {
    test('TypeName', () {
      final sut = DirectusServiceTest(
          DirectusApiManager(baseURL: 'htttp://toto.com', httpClient: Client()),
          "itemCollection",
          "*");
      expect(sut.typeName, "itemCollection");
    });

    test('Fields', () {
      final sut = DirectusServiceTest(
          DirectusApiManager(baseURL: 'htttp://toto.com', httpClient: Client()),
          "itemCollection",
          "*.*");
      expect(sut.fields, "*.*");
    });
  });
}
