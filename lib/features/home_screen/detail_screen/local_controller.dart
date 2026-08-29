// features/home_screen/detail_screen/local_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;


class LocalCacheController {
  static const String _keySession = 'user_session';
  static const String _keyTopRecipes = 'top_recipes';
  static const String _keyIngredients = 'ingredients_list';
  static const String _keyTickets = 'user_tickets';
  static const String _keyLocalRecipes = 'my_local_recipes';
  static const String _keyAvatarUrl =  'avatar_Url';

  // =========================================================================
  // НОВЫЙ МЕТОД: Быстрое чтение логина для функции main() и автологина
  // =========================================================================
    // =========================================================================
  // НАДЕЖНЫЙ МЕТОД: Чтение логина, защищенное от жесткой перезагрузки F5
  // =========================================================================
  
 static Future<String?> getSavedLoginOnly() async {//новый метод
    try {
      String? rawJson;
       debugPrint('=== КЭШ ДИАГНОСТИКА: Сырая строка из localStorage: "$rawJson" ===');
      if (kIsWeb) {
        rawJson = html.window.localStorage[_keySession];
      } else {
        final prefs = await SharedPreferences.getInstance();
        rawJson = prefs.getString(_keySession);
      }

      if (rawJson == null || rawJson.isEmpty || rawJson == 'null') return null;

      final Map<String, dynamic> decoded = jsonDecode(rawJson);
      return decoded['login']?.toString();
    } catch (e) {
      debugPrint('Ошибка чтения сессии из локального кэша: $e');
      return null;
    }
  }


  // =========================================================================
  // ИСПРАВЛЕННЫЕ СТАРЫЕ МЕТОДЫ (Теперь работают и в Web, и на Смартфоне)
  // =========================================================================

   // Найдите и замените эти два метода внутри класса LocalCacheController:

  static Future<void> saveLocalAllergens(Map<String, bool> data) async {
    try {
      final String rawText = jsonEncode(data);
      if (kIsWeb) {
        html.window.localStorage['allergens_map'] = rawText;
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('allergens_map', rawText);
      }
      debugPrint('=== ЛОКАЛЬНЫЙ КЭШ: Аллергены успешно обновлены на диске ===');
    } catch (e) {
      debugPrint('Ошибка сохранения аллергенов: $e');
    }
  }

  static Future<Map<String, bool>> getLocalAllergens() async {
    try {
      String? rawText;
      if (kIsWeb) {
        rawText = html.window.localStorage['allergens_map'];
      } else {
        final prefs = await SharedPreferences.getInstance();
        rawText = prefs.getString('allergens_map');
      }

      if (rawText != null && rawText.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(rawText);
        return decoded.map((key, value) => MapEntry(key, value as bool));
      }
    } catch (e) {
      debugPrint('Ошибка чтения аллергенов: $e');
    }
    // Дефолтные значения, если кэш пуст
    return {'nuts': false, 'lactose': false, 'gluten': false};
  }

  static Future<Map<String, dynamic>?> getLocalUserSession() async {
    if (kIsWeb) {
      final String? raw = html.window.localStorage[_keySession];
      return raw != null ? jsonDecode(raw) as Map<String, dynamic> : null;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_keySession);
      return raw != null ? jsonDecode(raw) as Map<String, dynamic> : null;
    }
  }

  
    /// 1. БЕЗОПАСНОЕ АСИНХРОННОЕ СОХРАНЕНИЕ ТЕМЫ НА ДИСК
  static Future<void> saveLocalThemeMode(bool isDark) async {
    try {
      // Упаковываем булевое значение в чистую JSON-строку
      final String rawJsonText = jsonEncode({'is_dark_mode': isDark});
      
      if (kIsWeb) {
        // Прямая запись в физический Local Storage браузера Chrome
        html.window.localStorage['app_theme_mode_key'] = rawJsonText;
      } else {
        // Запись в XML-файл настроек на смартфонах Android/iOS
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_theme_mode_key', rawJsonText);
      }
      debugPrint('=== ЛОКАЛЬНЫЙ КЭШ ТЕМЫ: Успешно записано на диск: $isDark ===');
    } catch (e) {
      debugPrint('❌ Ошибка сохранения режима темы на физический диск: $e');
    }
  }

  /// 2. АСИНХРОННОЕ ЧТЕНИЕ ТЕМЫ ПРИ СТАРТЕ ПРИЛОЖЕНИЯ
  static Future<bool> getLocalThemeMode() async {
    try {
      String? rawJsonText;
      
      if (kIsWeb) {
        rawJsonText = html.window.localStorage['app_theme_mode_key'];
      } else {
        final prefs = await SharedPreferences.getInstance();
        rawJsonText = prefs.getString('app_theme_mode_key');
      }

      // Если кэш пуст или равен строке 'null', возвращаем тему по умолчанию (светлую -> false)
      if (rawJsonText == null || rawJsonText.isEmpty || rawJsonText == 'null') {
        return false;
      }

      // Распаковываем JSON и вытаскиваем точное булевое состояние
      final Map<String, dynamic> decoded = jsonDecode(rawJsonText);
      return decoded['is_dark_mode'] as bool? ?? false;
    } catch (e) {
      debugPrint('❌ Ошибка чтения режима темы с диска: $e');
      return false; // Возврат по умолчанию в случае сбоя
    }
  }


      // 1. UNIVERSAL COMPREHENSIVE SESSION WRITER
  static Future<void> saveLocalUserSession(Map<String, dynamic> sessionData) async {
    try {
      final String rawJson = jsonEncode(sessionData);
      if (kIsWeb) {
        html.window.localStorage[_keySession] = rawJson;
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keySession, rawJson);
      }
      debugPrint('=== КЭШ СЕССИИ: Запись завершена! ===');
    } catch (e) {
      debugPrint('Ошибка записи сессии в локальный кэш: $e');
    }
  }

  // 2. NEW STRATEGIC METHOD: FETCH ENTIRE SAVED MAP
  static Future<Map<String, String>?> getSavedUserSession() async {
    try {
      String? rawJson;
      if (kIsWeb) {
        rawJson = html.window.localStorage[_keySession];
      } else {
        final prefs = await SharedPreferences.getInstance();
        rawJson = prefs.getString(_keySession);
      }

      if (rawJson == null || rawJson.isEmpty || rawJson == 'null') return null;

      final Map<String, dynamic> decoded = jsonDecode(rawJson);
      return {
        'login': decoded['login']?.toString() ?? '',
        'avatar_url': decoded['avatar_url']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint('Ошибка чтения карты сессии: $e');
      return null;
    }
  }


  // 2. SAFE SESSION READ METHOD
 

  static Future<void> clearLocalSession() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_keySession);
      html.window.localStorage.remove(_keyTopRecipes);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySession);
      await prefs.remove(_keyTopRecipes);
    }
  }

  static Future<List<Map<String, dynamic>>> getLocalTopRecipes() async {
    if (kIsWeb) {
      final String? raw = html.window.localStorage[_keyTopRecipes];
      if (raw == null) return [];
      return List<Map<String, dynamic>>.from(jsonDecode(raw));
    } else {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_keyTopRecipes);
      if (raw == null) return [];
      return List<Map<String, dynamic>>.from(jsonDecode(raw));
    }
  }

  static Future<void> saveLocalTopRecipes(List<Map<String, dynamic>> data) async {
    if (kIsWeb) {
      html.window.localStorage[_keyTopRecipes] = jsonEncode(data);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTopRecipes, jsonEncode(data));
    }
  }

  static Future<List<Map<String, dynamic>>> getLocalIngredientsList() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_keyIngredients);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<void> saveLocalIngredientsList(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIngredients, jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>> getLocalTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_keyTickets);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<void> saveLocalTicket(Map<String, dynamic> ticket) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> current = await getLocalTickets();
    current.insert(0, ticket);
    await prefs.setString(_keyTickets, jsonEncode(current));
  }

  static Future<void> saveMyNewLocalRecipe(Map<String, dynamic> recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_keyLocalRecipes);
    final List<Map<String, dynamic>> current = raw != null ? List<Map<String, dynamic>>.from(jsonDecode(raw)) : [];
    current.insert(0, recipe);
    await prefs.setString(_keyLocalRecipes, jsonEncode(current));
  }

  static Future<void> updateLocalPasswordInSession(String pass) async {
    final cached = await getLocalUserSession();
    if (cached != null) {
      cached['password'] = base64Encode(utf8.encode(pass.trim()));
      await saveLocalUserSession(cached);
    }
  }
}
