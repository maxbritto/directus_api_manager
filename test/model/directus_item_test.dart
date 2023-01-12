import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class DirectusItemUseCase extends DirectusItem {
  DirectusItemUseCase(Map<String, dynamic> rawReceivedData)
      : super(rawReceivedData);

  @override
  String get endpointName => "itemCollection";
}

main() {
  group('DirectusItem', () {
    test('Get the endPoint', () {
      final sut = DirectusItemUseCase({"id": "abc-123"});
      expect(sut.endpointName, "itemCollection");
    });
  });
}
