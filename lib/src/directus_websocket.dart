import 'dart:async';
import 'dart:convert';
import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DirectusWebSocket {
  bool isReady = false;
  Object? connectionError;
  final DirectusApiManager apiManager;
  Function(Object)? onError;
  Function()? onDone;
  final Map<String, DirectusWebSocketSubscription<DirectusData>>
      subscriptionDataMap;
  final WebSocketChannel channel;

  Timer? _nextNeededPingTimer;
  Timer? _sentPingTimer;

  List<DirectusWebSocketSubscription<DirectusData>> get subscriptionDataList =>
      subscriptionDataMap.values.toList();

  factory DirectusWebSocket({
    required DirectusApiManager apiManager,
    required List<DirectusWebSocketSubscription> subscriptionDataList,
    Function(Object)? onError,
    Function()? onDone,
  }) {
    final channel =
        WebSocketChannel.connect(Uri.parse(apiManager.webSocketBaseUrl));
    return DirectusWebSocket._init(
        channel: channel,
        apiManager: apiManager,
        subscriptionDataMap: {
          for (final subscription in subscriptionDataList)
            subscription.uid: subscription
        },
        onError: onError,
        onDone: onDone);
  }

  DirectusWebSocket._init({
    required this.channel,
    required this.apiManager,
    required this.subscriptionDataMap,
    this.onError,
    this.onDone,
  }) {
    _connect();
  }

  void _connect() {
    channel.ready.then((_) {
      isReady = true;
    }, onError: (error) {
      isReady = false;
      connectionError = error;
    });
    channel.stream
        .listen(listenSocket, onError: onSocketError, onDone: onSocketDone);

    if (apiManager.accessToken != null) {
      _authenticateWebSocket();
    } else {
      _subscribe();
    }
  }

  bool get hasSubscriptions => subscriptionDataMap.isNotEmpty;

  void onSocketError(Object error) {
    connectionError = error;
    for (final subscription in subscriptionDataMap.values) {
      final onError = subscription.onError;
      if (onError != null) {
        onError(error);
      }
    }
    onError?.call(error);
  }

  void onSocketDone() {
    while (subscriptionDataMap.isNotEmpty) {
      final subscription = subscriptionDataMap.values.first;
      _onUnsubscriptionConfirmed(subscription);
    }
    onDone?.call();
  }

  void _reschedulePing() {
    _sentPingTimer?.cancel();
    _nextNeededPingTimer?.cancel();
    _nextNeededPingTimer = Timer(Duration(seconds: 35), () {
      _sendPing();
    });
  }

  String? listenSocket(dynamic message) {
    // Reschedule the ping timer every time a message comes in from the server
    _reschedulePing();

    final Map<String, dynamic> data = jsonDecode(message);

    // Handle the ping pong request to keep the connection alive
    if (data["type"] == "ping") {
      channel.sink.add(jsonEncode({"type": "pong"}));
      return "pong sent";
    }

    // Handle the auth request
    if (data["type"] == "auth" &&
        data["status"] == "error" &&
        data["error"]["code"] == "TOKEN_EXPIRED") {
      return _sendRefreshTokenRequest();
    }

    // Handle the auth request
    if (data["type"] == "auth" && data["status"] == 'ok') {
      if (data.containsKey("refresh_token")) {
        apiManager.refreshToken = data["refresh_token"];
      } else {
        return _subscribe();
      }
    }

    if (data["type"] == "subscription") {
      // Find the subscription that matches the data
      final subscription = subscriptionDataMap[data["uid"]];
      if (subscription == null) {
        throw Exception("No subscription found for uid ${data["uid"]}");
      }

      if ((data["event"] == "init" || data["event"] == "create")) {
        final onCreate = subscription.onCreate;
        if (onCreate == null) {
          throw Exception("onCreate callback can not be null");
        } else {
          return onCreate(data);
        }
      }

      if (data["event"] == "update") {
        final onUpdate = subscription.onUpdate;
        if (onUpdate == null) {
          throw Exception("onUpdate callback can not be null");
        } else {
          return onUpdate(data);
        }
      }

      if (data["event"] == "delete") {
        final onDelete = subscription.onDelete;
        if (onDelete == null) {
          throw Exception("onDelete callback can not be null");
        } else {
          return onDelete(data);
        }
      }

      if (data["event"] == "unsubscribe") {
        _onUnsubscriptionConfirmed(subscription);
      }

      final error = data["error"];
      if (error != null) {
        _onError(subscription, error);
      }
    }
    return null;
  }

  Future disconnect({int code = 1000, String reason = "Normal Closure"}) async {
    _nextNeededPingTimer?.cancel();
    _sentPingTimer?.cancel();
    channel.sink.close(code, reason);
  }

  String _subscribe() {
    for (final subscriptionData in subscriptionDataMap.values) {
      channel.sink.add(subscriptionData.toJson());
    }

    return "subscription request sent";
  }

  String _authenticateWebSocket() {
    channel.sink.add(jsonEncode({
      "type": "auth",
      "access_token": apiManager.accessToken,
    }));

    return "auth request sent";
  }

  String _sendRefreshTokenRequest() {
    channel.sink.add(jsonEncode({
      "type": "auth",
      "refresh_token": apiManager.refreshToken,
    }));

    return "refresh token request sent";
  }

  void addSubscription(DirectusWebSocketSubscription subscription) {
    if (subscriptionDataMap.containsKey(subscription.uid) == false) {
      subscriptionDataMap[subscription.uid] = subscription;
      channel.sink.add(subscription.toJson());
    }
  }

  /// Sends an unsubscribe request to the server. The actual removal of the subscription will be done in the listenSocket method
  void removeSubscription({required String uid}) {
    channel.sink.add(jsonEncode({
      "type": "unsubscribe",
      "uid": uid,
    }));
  }

  void _onUnsubscriptionConfirmed(
      DirectusWebSocketSubscription<DirectusData> subscription) {
    final onDone = subscription.onDone;
    if (onDone != null) {
      onDone();
    }
    subscriptionDataMap.remove(subscription.uid);
    apiManager.subscriptionWasRemoved(subscription.uid);
  }

  void _onError(
      DirectusWebSocketSubscription<DirectusData> subscription, error) {
    final onError = subscription.onError;
    if (onError != null) {
      onError(error);
    }
  }

  void _sendPing() {
    _reschedulePing();
    channel.sink.add(jsonEncode({"type": "ping"}));
    _sentPingTimer = Timer(Duration(seconds: 10), _pingDidNotReceivePong);
  }

  void _pingDidNotReceivePong() {
    onSocketDone();
  }
}
