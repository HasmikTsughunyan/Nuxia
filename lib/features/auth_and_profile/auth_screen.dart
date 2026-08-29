// features/auth_and_profile/auth_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:my_app/features/auth_and_profile/user_profile_page.dart';
import '../../../core/network/network_api_controller.dart';
import 'package:my_app/main.dart';
import '../home_screen/detail_screen/local_controller.dart'; // Проверьте правильность этого импорта у себя



class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  bool _isHidden = true;
  bool _isLoading = false;

  Future<void> _writeToDebugFile(String action, String login, String pass) async {
    try {
      final file = File('auth_debug_log.txt');
      final String timestamp = DateTime.now().toIso8601String();
      final bytes = utf8.encode(pass);
      final encodedPass = base64Encode(bytes);
      await file.writeAsString(
        "--- Попытка [$action] ($timestamp) ---\n"
        "Введенный Логин: $login\n"
        "Введенный Пароль (Текст): $pass\n"
        "Захешированный Пароль (Base64): $encodedPass\n\n",
        mode: FileMode.append,
      );
      debugPrint("💾 Данные успешно записаны в auth_debug_log.txt");
    } catch (e) {
      debugPrint("❌ Ошибка регистрации в файл: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход в систему'), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _loginCtrl, 
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-_.]'))], 
                    decoration: const InputDecoration(labelText: 'Логин (только английский)', border: OutlineInputBorder())
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl, 
                    obscureText: _isHidden,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"""[a-zA-Z0-9!@#$%^&*()_+=\[{\]};:<>|./?,\-~`"'\\]"""))],
                    decoration: InputDecoration(
                      labelText: 'Пароль', 
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isHidden ? Icons.visibility_off : Icons.visibility), 
                        onPressed: () => setState(() => _isHidden = !_isHidden)
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight, 
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => ChangePasswordScreen(userLogin: _loginCtrl.text.isNotEmpty ? _loginCtrl.text : 'Повар'))
                      ), 
                      child: const Text('Забыли пароль?', style: TextStyle(color: Colors.orange))
                    )
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45), backgroundColor: Colors.orange),
                                        onPressed: () async {
                      // 1. Проверяем, что поля не пустые
                      if (_loginCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('⚠️ Введите логин и пароль!'))
                        );
                        return;
                      }

                      // 2. Безопасное логирование в консоль (без падения Flutter Web)
                      final bytes = utf8.encode(_passwordCtrl.text.trim());
                      final encodedPass = base64Encode(bytes);
                      debugPrint("💾 Попытка входа: Логин: ${_loginCtrl.text.trim()}, Хэш: $encodedPass");

                      // 3. Включаем крутилятор загрузки
                      setState(() => _isLoading = true);

                      // 4. ВЫЗЫВАЕМ СЕТЕВОЙ КОНТРОЛЛЕР ДЛЯ ПРОВЕРКИ В SUPABASE
                      final profile = await NetworkApiController.loginUser(
                        _loginCtrl.text.trim(), 
                        _passwordCtrl.text.trim(),
                        _avatarCtrl.text.trim(),
                      );

                      // 5. Выключаем крутилятор загрузки
                      setState(() => _isLoading = false);

                      // 6. ОБРАБОТКА РЕЗУЛЬТАТА И СОХРАНЕНИЕ В КЭШ
                      if (profile != null) {
                        // Записываем логин в глобальную переменную контроллера для RPC-запросов
                        NetworkApiController.currentUserLogin = _loginCtrl.text.trim();
                        
                        // УНИФИЦИРОВАННЫЙ КЭШ: Сохраняем сессию в оригинальный контроллер
                        await LocalCacheController.saveLocalUserSession({
                          'login': _loginCtrl.text.trim(),
                          'password': _passwordCtrl.text.trim(),
                        });

                        if (context.mounted) {
                          // Переходим на главный экран хаба
                          Navigator.pushReplacement(context,                           
    MaterialPageRoute(builder: (context) {
          return MainScreen(isDarkMode: false, onThemeChanged: (value) {},);
        },),
  
                          
                          
                          );
                        }
                      } else {
                        // Если профиль пустой (неверные данные)
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('❌ Неверный логин или пароль!'))
                          );
                        }
                      }
                    },

                    
                    child: const Text('Войти', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(45), side: const BorderSide(color: Colors.orange)),
                    onPressed: () async {
                      if (_loginCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Заполните поля для регистрации!')));
                        return;
                      }
                      await _writeToDebugFile("РЕГИСТРАЦИЯ/REG", _loginCtrl.text, _passwordCtrl.text);
                      setState(() => _isLoading = true);
                      final newProfile = await NetworkApiController.registerUser(_loginCtrl.text, _passwordCtrl.text, _avatarCtrl.text);
                      setState(() => _isLoading = false);
                     // =========================================================================
// 1. ИСПРАВЛЕННЫЙ БЛОК ДЛЯ КНОПКИ "ВОЙТИ" (Строки 84-106)
// =========================================================================
if (newProfile != null) {
  // Записываем логин в глобальную переменную контроллера для RPC-запросов
  NetworkApiController.currentUserLogin = _loginCtrl.text.trim();
  
  // УНИФИЦИРОВАННЫЙ КЭШ: Сохраняем сессию (и логин, и пароль) в оригинальный контроллер
  await LocalCacheController.saveLocalUserSession({
    'login': _loginCtrl.text.trim(),
    'password': _passwordCtrl.text.trim(),
  });

  if (context.mounted) {
  // Прямой переход на MainScreen без регистрации имени '/home' в main.dart
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) {
          return MainScreen(
            isDarkMode: false,
            onThemeChanged: (value) {},
          );
        },),
  );
}

} else {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ Неверный логин или пароль!'))
    );
  }
}

// =========================================================================
// 2. ИСПРАВЛЕННЫЙ БЛОК ДЛЯ КНОПКИ "СОЗДАТЬ АККАУНТ (РЕГИСТРАЦИЯ)" (Строки 118-130)
// =========================================================================
if (newProfile != null) {
  // ИСПРАВЛЕНИЕ: Автоматически авторизуем пользователя сразу после успешной регистрации
  NetworkApiController.currentUserLogin = _loginCtrl.text.trim();
  
  await LocalCacheController.saveLocalUserSession({
    'login': _loginCtrl.text.trim(),
    'password': _passwordCtrl.text.trim(),
  });

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Аккаунт успешно создан и активирован!'), backgroundColor: Colors.green)
    );
    // Сразу перекидываем пользователя на главный экран, чтобы ему не пришлось заново логиниться
    
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) {return  MainScreen(isDarkMode: false,
     onThemeChanged: (value) {});
    },
    )
    
  );

  }
} else {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ Ошибка регистрации в шлюзе Supabase'))
    );
  }
}},

                    child: const Text('Создать аккаунт (Регистрация)', style: TextStyle(color: Colors.orange)),
                  )
                ],
              ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  final String userLogin;
  const ChangePasswordScreen({super.key, required this.userLogin});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passwordCtrl = TextEditingController();
  bool _isHidden = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Смена пароля'), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Введите ваш новый пароль для доступа к аккаунту:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _isHidden,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"""[a-zA-Z0-9!@#$%^&*()_+=\[{\]};:<>|./?,\-~`"'\\]"""))],
                    decoration: InputDecoration(
                      labelText: 'Новый пароль (только английский)',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isHidden ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _isHidden = !_isHidden),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45), backgroundColor: Colors.orange),
                    onPressed: () async {
                      if (_passwordCtrl.text.isEmpty) return;
                      setState(() => _isLoading = true);
                      await LocalCacheController.updateLocalPasswordInSession(_passwordCtrl.text);
                      bool isServerUpdated = await NetworkApiController.changeUserPassword(widget.userLogin, _passwordCtrl.text);
                      setState(() => _isLoading = false);
                      if (context.mounted) {
                        if (isServerUpdated) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Пароль успешно синхронизирован с облачным сервером!'), backgroundColor: Colors.green));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💾 Сервер недоступен. Пароль обновлен локально в памяти этого устройства!'), backgroundColor: Colors.blue));
                        }
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Обновить пароль', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
      ),
    );
  }
}
