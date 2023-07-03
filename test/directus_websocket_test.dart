import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import 'directus_websocket_test.reflectable.dart';
import 'model/directus_item_test.dart';

main() {
  initializeReflectable();
  late DirectusWebSocket sut;

  onCallBack(Map<String, dynamic> message) {}

  group('DirectusWebSocket', () {
    setUp(() {
      sut = DirectusWebSocket(
          apiManager: DirectusApiManager(baseURL: "http://api.com:8055"),
          onListen: (dynamic message) {},
          subscriptionDataList: [
            DirectusWebSocketSubscription<DirectusItemTest>(
                uid: "itemTest", onCreate: onCallBack)
          ]);
    });

    test('Init value are set', () {
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
