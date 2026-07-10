import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/user_model.dart';

/// Wraps every /api/auth endpoint — the Dart twin of the web `authApi`.
class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<(String token, AppUser user)> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? gender,
  }) async {
    final res = await _api.post('/auth/signup', body: {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      if (gender != null && gender.isNotEmpty) 'gender': gender,
    });
    return (res['token'] as String, AppUser.fromJson(res['user']));
  }

  Future<(String token, AppUser user)> login(
      String email, String password) async {
    final res = await _api
        .post('/auth/login', body: {'email': email, 'password': password});
    return (res['token'] as String, AppUser.fromJson(res['user']));
  }

  Future<AppUser> me() async {
    final res = await _api.get('/auth/me', auth: true);
    return AppUser.fromJson(res['user']);
  }

  Future<void> forgotPassword(String email) =>
      _api.post('/auth/forgot-password', body: {'email': email});

  Future<void> resetPassword(
          {required String email,
          required String code,
          required String newPassword}) =>
      _api.post('/auth/reset-password',
          body: {'email': email, 'code': code, 'newPassword': newPassword});

  Future<AppUser> updateProfile(
      {String? name, String? phone, String? gender, String? avatar}) async {
    final res = await _api.patch('/auth/profile', body: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (gender != null) 'gender': gender,
      if (avatar != null) 'avatar': avatar,
    });
    return AppUser.fromJson(res['user']);
  }

  Future<void> changePassword(
          {required String currentPassword, required String newPassword}) =>
      _api.patch('/auth/password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

  /// Selfie KYC — multipart field name `selfie`, exactly like the web form.
  Future<AppUser> submitSelfie(String filePath) async {
    final form = FormData.fromMap({
      'selfie': await MultipartFile.fromFile(filePath, filename: 'selfie.jpg'),
    });
    final res = await _api.post('/auth/kyc', body: form, auth: true);
    return AppUser.fromJson(res['user']);
  }

  Future<bool> requestEmailOtp() async {
    final res = await _api.post('/auth/email/request-otp', body: {}, auth: true);
    return res['delivered'] as bool? ?? false;
  }

  Future<AppUser> verifyEmailOtp(String code) async {
    final res =
        await _api.post('/auth/email/verify', body: {'code': code}, auth: true);
    return AppUser.fromJson(res['user']);
  }

  Future<bool> requestPhoneOtp(String phone) async {
    final res = await _api
        .post('/auth/phone/request-otp', body: {'phone': phone}, auth: true);
    return res['delivered'] as bool? ?? false;
  }

  Future<AppUser> verifyPhoneOtp(String code) async {
    final res =
        await _api.post('/auth/phone/verify', body: {'code': code}, auth: true);
    return AppUser.fromJson(res['user']);
  }

  /// Phone-OTP login (WhatsApp) — public two-step flow.
  Future<void> phoneLoginRequest(String phone) =>
      _api.post('/auth/phone/login/request', body: {'phone': phone});

  Future<(String token, AppUser user)> phoneLoginVerify(
      String phone, String code) async {
    final res = await _api
        .post('/auth/phone/login/verify', body: {'phone': phone, 'code': code});
    return (res['token'] as String, AppUser.fromJson(res['user']));
  }

  Future<void> persistToken(String token) => TokenStorage.instance.write(token);
  Future<void> clearToken() => TokenStorage.instance.clear();
  Future<String?> storedToken() => TokenStorage.instance.read();
}
