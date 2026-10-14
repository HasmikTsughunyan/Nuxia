// core/network/session_manager.dart

import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyUserLogin = 'NetworkApiController.currentUserLogin';
  static const String _keyUserAllergens = 'user_allergens';

  /// 1. Сохранение логина при успешной авторизации
  static Future<void> saveUserLogin(String login) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserLogin, login);
  }

  /// 2. Чтение логина при старте приложения
  static Future<String?> getUserLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserLogin);
  }

  /// 3. Сохранение локального массива аллергенов юзера (Array)
  static Future<void> saveLocalAllergens(List<int> allergenIds) async {
    final prefs = await SharedPreferences.getInstance();
    // SharedPreferences не хранит List<int>, поэтому переводим в List<String>
    final stringIds = allergenIds.map((id) => id.toString()).toList();
    await prefs.setStringList(_keyUserAllergens, stringIds);
  }

  /// 4. Чтение локального массива аллергенов юзера
  static Future<List<int>> getLocalAllergens() async {
    final prefs = await SharedPreferences.getInstance();
    final stringIds = prefs.getStringList(_keyUserAllergens) ?? [];
    return stringIds.map(int.parse).toList();
  }

  /// 5. Сброс сессии (кнопка "Выйти из аккаунта")
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserLogin);
    await prefs.remove(_keyUserAllergens);
  }
}
