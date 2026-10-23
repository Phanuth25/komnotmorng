import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('useremail', email);
  }

  // ignore: non_constant_identifier_names
  static Future<void> saveId(int user_id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user_id);
  }

  static Future<int> getId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 0;
  }

  static Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('useremail') ?? '';
  }

  static Future<void> removeEverything() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
  }

  static Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }
}
