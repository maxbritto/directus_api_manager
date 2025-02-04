import 'package:http/http.dart';
import 'dart:convert';

class DirectusApiError extends Error {
  final Response? response;
  final String? customMessage;

  DirectusApiError({this.response, this.customMessage});

  @override
  String toString() {
    return "DirectusApiError : $customMessage : ${response?.statusCode} ${response?.body} ${response?.headers}";
  }

  String? get errorCodeFromJson {
    final body = response?.body;
    if (body == null) {
      return null;
    }
    final json = jsonDecode(body);
    final List errors = json["errors"];
    if (errors.isEmpty) {
      return null;
    }
    try {
      return errors.first["extensions"]["code"];
    } catch (_) {
      return null;
    }
  }

  String? get messageFromBody {
    final body = response?.body;
    if (body == null) {
      return null;
    }
    final json = jsonDecode(body);
    final List errors = json["errors"];
    if (errors.isEmpty) {
      return null;
    }
    try {
      return errors.first["message"];
    } catch (_) {
      return null;
    }
  }
}
