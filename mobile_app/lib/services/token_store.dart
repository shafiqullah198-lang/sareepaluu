import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<String?> get access async =>
      (await SharedPreferences.getInstance()).getString(_accessKey);
  Future<String?> get refresh async =>
      (await SharedPreferences.getInstance()).getString(_refreshKey);

  Future<void> save(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  Future<void> saveAccess(String access) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}
