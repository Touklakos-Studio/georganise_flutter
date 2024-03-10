import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageManager {
  static final _storage = FlutterSecureStorage();

  static Future<void> storeAuthCookie(String authCookie) async {
    await _storage.write(key: 'authCookie', value: authCookie);
  }

  static Future<String?> getAuthCookie() async {
    return await _storage.read(key: 'authCookie');
  }

  static Future<void> deleteAuthCookie() async {
    await _storage.delete(key: 'authCookie');
  }
}
