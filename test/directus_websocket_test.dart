import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:test/test.dart';

import 'directus_websocket_test.reflectable.dart';
import 'model/directus_item_test.dart';

main() {
  initializeReflectable();
  late DirectusWebSocket sut;

  onCreate(Map<String, dynamic> message) {
    return "onCreate triggered";
  }

  onUpdate(Map<String, dynamic> message) {
    return "onUpdate triggered";
  }

  onDelete(Map<String, dynamic> message) {
    return "onDelete triggered";
  }

  group('DirectusWebSocket', () {
    late bool onDoneForSubscriptionCalled;
    late bool onDoneForSocketCalled;
    setUp(() {
      onDoneForSubscriptionCalled = false;
      sut = DirectusWebSocket(
          apiManager: DirectusApiManager(baseURL: "http://api.com:8055"),
          subscriptionDataList: [
            DirectusWebSocketSubscription<DirectusItemTest>(
                uid: "itemTest",
                onCreate: onCreate,
                onUpdate: onUpdate,
                onDelete: onDelete,
                onDone: () => onDoneForSubscriptionCalled = true)
          ],
          onDone: () => onDoneForSocketCalled = true);
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

    test('Socket receive init subscription message', () {
      final String message =
          '{"type":"subscription","event":"init","data":[{"id":"abc-123","uploaded_by":{"id":"123456"}},{"id":"abc-123","uploaded_by":{"id":"123456"}}],"uid":"itemTest"}';
      expect(sut.listenSocket(message), "onCreate triggered");
    });

    test('Socket receive create subscription message', () {
      final String message =
          '{"type":"subscription","event":"create","data":[{"id":"abc-123","uploaded_by":{"id":"123456"}},{"id":"abc-123","uploaded_by":{"id":"123456"}}],"uid":"itemTest"}';
      expect(sut.listenSocket(message), "onCreate triggered");
    });

    test('Socket receive update subscription message', () {
      final String message =
          '{"type":"subscription","event":"update","data":[{"id":"abc-123","uploaded_by":{"id":"123456"}},{"id":"abc-123","uploaded_by":{"id":"123456"}}],"uid":"itemTest"}';
      expect(sut.listenSocket(message), "onUpdate triggered");
    });

    test('Socket receive delete subscription message', () {
      final String message =
          '{"type":"subscription","event":"delete","data":["abc-123"],"uid":"itemTest"}';
      expect(sut.listenSocket(message), "onDelete triggered");
    });

    test('No Uid in message throw an exception', () {
      final String message =
          '{"type":"subscription","event":"delete","data":["abc-123"]}';
      expect(() => sut.listenSocket(message), throwsException);
    });

    test('Socket receive auth success message', () {
      final String message = '{"type":"auth","status":"ok"}';
      expect(sut.listenSocket(message), "subscription request sent");
    });

    test('Socket receive token expired message', () {
      final String message =
          '{"type":"auth","status":"error","error":{"code":"TOKEN_EXPIRED"}}';
      expect(sut.listenSocket(message), "refresh token request sent");
    });

    test("Socket receive refresh token success message", () {
      final String message =
          '{"type":"auth","status":"ok","refresh_token":"newRefreshToken"}';
      sut.listenSocket(message);
      expect(sut.apiManager.refreshToken, "newRefreshToken");
    });

    test("Socket receive init message with no onCreated must throw an error",
        () {
      sut = DirectusWebSocket(
          apiManager: DirectusApiManager(baseURL: "http://api.com:8055"),
          subscriptionDataList: [
            DirectusWebSocketSubscription<DirectusItemTest>(
                uid: "itemTest", onDelete: onDelete)
          ]);
      final String message =
          '{"type":"subscription","event":"init","data":[{"id":"abc-123","uploaded_by":{"id":"123456"}},{"id":"abc-123","uploaded_by":{"id":"123456"}}],"uid":"itemTest"}';
      expect(() => sut.listenSocket(message), throwsException);
    });

    test("Socket receive create message with no onCreated must throw an error",
        () {
      sut = DirectusWebSocket(
          apiManager: DirectusApiManager(baseURL: "http://api.com:8055"),
          subscriptionDataList: [
            DirectusWebSocketSubscription<DirectusItemTest>(
                uid: "itemTest", onDelete: onDelete)
          ]);
      final String message =
          '{"type":"subscription","event":"create","data":[{"id":"abc-123","uploaded_by":{"id":"123456"}},{"id":"abc-123","uploaded_by":{"id":"123456"}}],"uid":"itemTest"}';
      expect(() => sut.listenSocket(message), throwsException);
    });

    test("Socket receive update message with no onUpdate must throw an error",
        () {
      sut = DirectusWebSocket(
          apiManager: DirectusApiManager(baseURL: "http://api.com:8055"),
          subscriptionDataList: [
            DirectusWebSocketSubscription<DirectusItemTest>(
                uid: "itemTest", onCreate: onCreate)
          ]);
      final String message =
          '{"type":"subscription","event":"update","data":[{"id":"abc-123","uploaded_by":{"id":"123456"}},{"id":"abc-123","uploaded_by":{"id":"123456"}}],"uid":"itemTest"}';
      expect(() => sut.listenSocket(message), throwsException);
    });

    test("Socket receive delete message with no onDelete must throw an error",
        () {
      final String message =
          '{"type":"subscription","event":"delete","data":[{"id":"abc-123","uploaded_by":{"id":"123456"}},{"id":"abc-123","uploaded_by":{"id":"123456"}}],"uid":"itemTest"}';
      sut = DirectusWebSocket(
          apiManager: DirectusApiManager(baseURL: "http://api.com:8055"),
          subscriptionDataList: [
            DirectusWebSocketSubscription<DirectusItemTest>(
                uid: "itemTest", onCreate: onCreate)
          ]);
      expect(() => sut.listenSocket(message), throwsException);
    });

    test("Socket receive unsubscribe message", () {
      final String message =
          '{"type":"subscription","event":"unsubscribe","data":[{"id":"abc-123","uploaded_by":{"id":"123456"}},{"id":"abc-123","uploaded_by":{"id":"123456"}}],"uid":"itemTest"}';
      sut.listenSocket(message);
      expect(sut.subscriptionDataList.length, 0);
      expect(onDoneForSubscriptionCalled, true);
    });

    test("Add subscription", () {
      sut.addSubscription(DirectusWebSocketSubscription<DirectusItemTest>(
          uid: "itemTest2", onCreate: onCreate));
      expect(sut.subscriptionDataMap.length, 2);
      expect(sut.subscriptionDataMap["itemTest2"], isNotNull);
    });
    test("Add multiple subscriptions", () {
      sut.addSubscription(DirectusWebSocketSubscription<DirectusItemTest>(
          uid: "itemTest2", onCreate: onCreate));
      sut.addSubscription(DirectusWebSocketSubscription<DirectusItemTest>(
          uid: "itemTest3", onCreate: onCreate));
      expect(sut.subscriptionDataMap.length, 3);
      expect(sut.subscriptionDataMap["itemTest2"], isNotNull);
      expect(sut.subscriptionDataMap["itemTest3"], isNotNull);
    });
    test("Add same subscription twice", () {
      sut.addSubscription(DirectusWebSocketSubscription<DirectusItemTest>(
          uid: "itemTest2", onCreate: onCreate));
      sut.addSubscription(DirectusWebSocketSubscription<DirectusItemTest>(
          uid: "itemTest2", onCreate: onCreate));
      expect(sut.subscriptionDataMap.length, 2);
      expect(sut.subscriptionDataMap["itemTest2"], isNotNull);
    });

    test("onSocketDone", () {
      sut.onSocketDone();
      expect(onDoneForSubscriptionCalled, true);
      expect(onDoneForSocketCalled, true);
      expect(sut.subscriptionDataMap.length, 0,
          reason: "All subscriptions should be removed");
    });
  });
}
