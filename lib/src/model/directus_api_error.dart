import 'package:http/http.dart';

class DirectusApiError extends Error {
  final Response? response;
  final String? customMessage;

  DirectusApiError({this.response, this.customMessage});

  @override
  String toString() {
    return "DirectusApiError : $customMessage : ${response?.statusCode} ${response?.body} ${response?.headers}";
  }
}
