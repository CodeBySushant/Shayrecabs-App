import "package:flutter_secure_storage/flutter_secure_storage.dart";

/// JWT lives in the platform keystore/keychain — never SharedPreferences.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _key = "shayrecabs-token";
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _cached;

  Future<String?> read() async => _cached ??= await _storage.read(key: _key);

  Future<void> write(String token) async {
    _cached = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}
