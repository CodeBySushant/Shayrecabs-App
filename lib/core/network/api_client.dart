import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Central API client — the Dart equivalent of the web app's `src/lib/api.js`.
///
/// Contract with the shayrecabs backend:
///  • Auth via `Authorization: Bearer <jwt>`
///  • Every JSON body carries `ok: true|false`; failures carry `error`
///  • Multipart uploads (selfie KYC) send FormData without a JSON content type
class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Accept': 'application/json'},
      // We decode `ok:false` bodies ourselves — don't throw on 4xx.
      validateStatus: (s) => s != null && s < 500 || s == 500 || s == 503,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra['auth'] == true) {
          final token = await TokenStorage.instance.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
    ));
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  /// Called by the auth layer when a 401 arrives with a stored token
  /// (expired/invalid session) so the app can log out gracefully.
  void Function()? onUnauthorized;

  Future<Map<String, dynamic>> get(String path,
          {bool auth = false, Map<String, dynamic>? query}) =>
      _request('GET', path, auth: auth, query: query);

  Future<Map<String, dynamic>> post(String path,
          {Object? body, bool auth = false}) =>
      _request('POST', path, body: body, auth: auth);

  Future<Map<String, dynamic>> patch(String path,
          {Object? body, bool auth = true}) =>
      _request('PATCH', path, body: body, auth: auth);

  Future<Map<String, dynamic>> delete(String path, {bool auth = true}) =>
      _request('DELETE', path, auth: auth);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? body,
    bool auth = false,
    Map<String, dynamic>? query,
  }) async {
    if (await _offline()) throw const NoConnectionException();
    try {
      final res = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method, extra: {'auth': auth}),
      );

      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      final ok = (res.statusCode ?? 500) < 400 && data['ok'] != false;

      if (!ok) {
        if (res.statusCode == 401 && auth) onUnauthorized?.call();
        throw ApiException(
          (data['error'] as String?) ??
              'Request failed (${res.statusCode ?? '—'})',
          statusCode: res.statusCode,
        );
      }
      return data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const ApiException('The server took too long to respond. Please try again.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NoConnectionException();
      }
      throw ApiException(e.message ?? 'Something went wrong. Please try again.');
    }
  }

  Future<bool> _offline() async {
    final results = await Connectivity().checkConnectivity();
    return results.every((r) => r == ConnectivityResult.none);
  }
}
