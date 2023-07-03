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
    final data = jsonDecode(message);

    if (data["type"] == "ping") {
      _channel.sink.add(jsonEncode({"type": "pong"}));
    }

    if (refreshToken != null &&
        data["type"] == "auth" &&
        data["status"] == "error" &&
        data["error"]["code"] == "TOKEN_EXPIRED") {
      _sendRefreshTokenRequest();
    }

    if (data["type"] == "auth" && data["status"] == 'ok') {
      if (data.containsKey("refresh_token")) {
        refreshToken = data["refresh_token"];
      }

      _subscribe();
    }
    onListen(message);
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
