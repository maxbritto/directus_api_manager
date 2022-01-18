enum DirectusLoginResultType { success, invalidCredentials, error }

class DirectusLoginResult {
  final DirectusLoginResultType type;
  final String? message;

  const DirectusLoginResult(this.type, {this.message});
}
