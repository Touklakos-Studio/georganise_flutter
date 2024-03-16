import 'package:shared_preferences/shared_preferences.dart';

class GlobalConfig {
  static final GlobalConfig _singleton = GlobalConfig._internal();
  String _serverUrl = "http://10.0.2.2:8080"; // Default value

  GlobalConfig._internal() {
    _loadFromPrefs();
  }

  factory GlobalConfig() {
    return _singleton;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('serverUrl') ?? _serverUrl;
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverUrl', _serverUrl);
  }

  String get serverUrl => _serverUrl;

  set serverUrl(String value) {
    _serverUrl = value;
    _saveToPrefs();
  }
}
