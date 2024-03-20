import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageManager {
  static const _storage = FlutterSecureStorage();

  // Store the authentication token in secure storage
  static Future<void> storeAuthToken(String authToken) async {
    await _storage.write(key: 'authToken', value: authToken);
  }

  // Retrieve the authentication token from secure storage
  static Future<String?> getAuthToken() async {
    return await _storage.read(key: 'authToken');
  }

  // Delete the authentication token from secure storage
  static Future<void> deleteAuthToken() async {
    await _storage.delete(key: 'authToken');
  }
}
