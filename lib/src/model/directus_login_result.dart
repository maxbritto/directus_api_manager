/// The type of login result.
enum DirectusLoginResultType {
  /// The login was successful.
  success,

  /// The login failed because the user credentials were invalid.
  invalidCredentials,

  /// The login failed because OTP is required.
  invalidOTP,

  /// The login failed because of a server orror or an unknown error, unrelated to the user credentials.
  error
}

/// The result of a login attempt.
class DirectusLoginResult {
  /// The type of login result.
  final DirectusLoginResultType type;

  /// An additional error message, if any.
  final String? message;

  const DirectusLoginResult(this.type, {this.message});
}
