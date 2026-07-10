/// A user-presentable API failure. `message` is always safe to show.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class NoConnectionException extends ApiException {
  const NoConnectionException()
      : super("No internet connection. Check your network and try again.");
}
