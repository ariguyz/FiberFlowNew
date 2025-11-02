import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorageService {
  Future<void> saveOfflineData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getOfflineData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
