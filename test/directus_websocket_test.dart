import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'directus_websocket_test.reflectable.dart';
import 'model/directus_item_test.dart';

main() {
  initializeReflectable();
  late DirectusWebSocket sut;

  group('DirectusWebSocket', () {
    setUp(() {
      sut = DirectusWebSocket(
          url: "ws://localhost:8080",
          onListen: (dynamic message) {},
          subscriptionDataList: [
            DirectusWebSocketSubscription<DirectusItemTest>()
          ]);
    });

    test('Init value are set', () {
      expect(sut.url, "ws://localhost:8080");
      expect(sut.subscriptionDataList.length, 1);
    });

    test('Listen receive a ping message', () {
      //TODO
    });

    test('Request auth', () {
      //TODO
    });

    test('Request token refresh', () {
      //TODO
    });
  });
}
