/// Central app configuration. No secrets live here — the Razorpay KEY_ID is
/// public and is returned by the backend with each order anyway.
class AppConfig {
  AppConfig._();

  /// Backend base URL. Override at build time:
  ///   flutter run --dart-define=API_URL=https://api.shayrecabs.com/api
  static const String apiBaseUrl = String.fromEnvironment(
    "API_URL",
    defaultValue: "https://shayrecabs.com/api",
  );

  static const String appName = "shayreCabs";
  static const String supportEmail = "contact@shayrecabs.com";
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
