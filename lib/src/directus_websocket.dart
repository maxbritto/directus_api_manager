import 'dart:convert';
import 'package:directus_api_manager/src/directus_websocket_subscription.dart';
import 'package:directus_api_manager/src/model/directus_data.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DirectusWebSocket {
  final String url;
  Function(dynamic) onListen;
  Function(Object)? onError;
  Function()? onDone;
  List<DirectusWebSocketSubscription<DirectusData>> subscriptionDataList;
  late WebSocketChannel _channel;

  String? accessToken;
  String? refreshToken;

  DirectusWebSocket(
      {required this.url,
      required this.onListen,
      required this.subscriptionDataList,
      this.refreshToken,
      this.onError,
      this.onDone,
      this.accessToken}) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel.stream.listen(listenSocket, onError: onError, onDone: onDone);
    // _sendRefreshTokenRequest();
    if (accessToken != null) {
      _authenticateWebSocket();
    } else {
      _subscribe();
    }
  }

  listenSocket(dynamic message) async {
    final Map<String, dynamic> data = jsonDecode(message);

    // Handle the ping pong request to keep the connection alive
    if (data["type"] == "ping") {
      _channel.sink.add(jsonEncode({"type": "pong"}));
    }

    // Handle the auth request
    if (refreshToken != null &&
        data["type"] == "auth" &&
        data["status"] == "error" &&
        data["error"]["code"] == "TOKEN_EXPIRED") {
      _sendRefreshTokenRequest();
    }

    // Handle the auth request
    if (data["type"] == "auth" && data["status"] == 'ok') {
      if (data.containsKey("refresh_token")) {
        refreshToken = data["refresh_token"];
      }

      _subscribe();
    }

    // Find the subscription that matches the data
    final subscription = subscriptionDataList.firstWhere(
        (element) => element.uid == data["uid"],
        orElse: () =>
            throw Exception("No subscription found for uid ${data["uid"]}"));

    if (data["type"] == "subscription" &&
        (data["event"] == "init" || data["event"] == "create")) {
      subscription.onCreate!(data);
    }

    if (data["type"] == "subscription" && data["event"] == "update") {
      subscription.onUpdate!(data);
    }

    if (data["type"] == "subscription" && data["event"] == "delete") {
      subscription.onDelete!(data);
    }
  }

  _subscribe() {
    for (var subscriptionData in subscriptionDataList) {
      _channel.sink.add(subscriptionData.toJson());
    }
  }

  _authenticateWebSocket() {
    _channel.sink.add(jsonEncode({
      "type": "auth",
      "access_token": accessToken,
    }));
  }

  _sendRefreshTokenRequest() {
    _channel.sink.add(jsonEncode({
      "type": "auth",
      "refresh_token": refreshToken,
    }));
  }
}
