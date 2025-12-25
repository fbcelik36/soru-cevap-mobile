import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStore {
  static const _s = FlutterSecureStorage();

  static Future<void> saveToken(String token) => _s.write(key: 'jwt', value: token);
  static Future<String?> readToken() => _s.read(key: 'jwt');
  static Future<void> clear() async {
    await _s.delete(key: 'jwt');
  }
}
