import 'dart:convert';
import 'package:directus_api_manager/directus_api_manager.dart';
import 'package:directus_api_manager/src/model/directus_data.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DirectusWebSocket {
  DirectusApiManager apiManager;
  Function(Object)? onError;
  Function()? onDone;
  List<DirectusWebSocketSubscription<DirectusData>> subscriptionDataList;
  late WebSocketChannel _channel;

  DirectusWebSocket({
    required this.apiManager,
    required this.subscriptionDataList,
    this.onError,
    this.onDone,
  }) {
    _channel = WebSocketChannel.connect(Uri.parse(apiManager.webSocketBaseUrl));
    _channel.stream.listen(listenSocket, onError: onError, onDone: onDone);

    if (apiManager.accessToken != null) {
      _authenticateWebSocket();
    } else {
      _subscribe();
    }
  }

  listenSocket(dynamic message) {
    final Map<String, dynamic> data = jsonDecode(message);

    // Handle the ping pong request to keep the connection alive
    if (data["type"] == "ping") {
      _channel.sink.add(jsonEncode({"type": "pong"}));
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
      final subscription = subscriptionDataList.firstWhere(
          (element) => element.uid == data["uid"],
          orElse: () =>
              throw Exception("No subscription found for uid ${data["uid"]}"));

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
    }
  }

  disconnect() {
    _channel.sink.close();
  }

  String _subscribe() {
    for (var subscriptionData in subscriptionDataList) {
      _channel.sink.add(subscriptionData.toJson());
    }

    return "subscription request sent";
  }

  String _authenticateWebSocket() {
    _channel.sink.add(jsonEncode({
      "type": "auth",
      "access_token": apiManager.accessToken,
    }));

    return "auth request sent";
  }

  String _sendRefreshTokenRequest() {
    _channel.sink.add(jsonEncode({
      "type": "auth",
      "refresh_token": apiManager.refreshToken,
    }));

    return "refresh token request sent";
  }
}
