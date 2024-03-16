import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageManager {
  static final _storage = FlutterSecureStorage();

  static Future<void> storeAuthToken(String authToken) async {
    await _storage.write(key: 'authToken', value: authToken);
  }

  static Future<String?> getAuthToken() async {
    return await _storage.read(key: 'authToken');
  }

  static Future<void> deleteAuthToken() async {
    await _storage.delete(key: 'authToken');
  }
}
