
// main.dart
import 'package:flutter/material.dart';
import 'package:my_app/core/network/network_api_controller.dart';
import 'features/home_screen/detail_screen/local_controller.dart';
import 'features/home_screen/category_recipes_screen.dart'; 
import 'features/auth_and_profile/auth_screen.dart';
import 'features/auth_and_profile/user_profile_page.dart';
import 'features/fridge_search/ingredient_search_tab.dart';
import 'features/auth_and_profile/admin_tickets_manager_screen.dart';
//import 'core/utils/ai_chef_service.dart';
//import 'core/utils/ai_chef_page.dart';
import 'core/utils/ai_chef_chat_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/utils/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert';




void main() async {
  // 1. Սա պարտադիր է ցանկացած ասինխրոն կանչից առաջ main-ում
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Ակտիվացնում ենք Supabase պաշտոնական ինստանսը
  await Supabase.initialize(
    url: 'https://ldpxhegdrycianlebbtp.supabase.co', // Ձեր Supabase URL-ը
    publishableKey:  'sb_publishable_6tfHRi9SZZusoQ1aGcaHtw_4DORfmyc',
  );

  // 3. Գործարկում ենք հավելվածը
  runApp(const MyApp());
}


// =========================================================================
// 🔥 COMPLETE STABLE UPDATE FOR YOUR _MyAppState (REPLACE THE UPPER CLASS BODY)
// =========================================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  
  // 🌟 ԱՎԵԼԱՑՎԱԾ Է. Հնարավորություն է տալիս ցանկացած էջից փոխել գլխավոր լեզուն
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.changeLanguage(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isSessionChecking = true;
  bool _isUserAuthenticated = false;
  bool _isDarkMode = false;
  
  // 🌟 ԱՎԵԼԱՑՎԱԾ Է. Լեզվի ընթացիկ կարգավիճակը (Դեֆոլտ՝ ռուսերեն)
  Locale _currentLocale = const Locale('ru'); 

  // 🌟 ԱՎԵԼԱՑՎԱԾ Է. Լեզվի LIVE փոփոխման մեթոդը
  void changeLanguage(Locale locale) {
    setState(() {
      _currentLocale = locale;
    });
  }
 
   @override
  void initState() {
    super.initState();
    _initializeAppState();
    
    
  }


void _toggleTheme(bool value)  {
    setState((){
        _isDarkMode = value;
      });
      LocalCacheController.saveLocalThemeMode(value).then((_) {debugPrint('Кэш темы: зафиксировано');});
      debugPrint('=== КЭШ ТЕМЫ: Успешно зафиксировано на диске: $value ===');
  }


    /// Combined diagnostic loading script for both configurations
  Future<void> _initializeAppState() async {
    try {
      debugPrint('=== ЛОГ СТАРТ: Инициализация настроек приложения ===');
    
      final bool savedTheme = await LocalCacheController.getLocalThemeMode();
    
      // Pull full dynamic payload map data parameters from disk cache memory
      final Map<String, String>? savedSession = await LocalCacheController.getSavedUserSession();

      if (!mounted) return;

      setState(() {
        _isDarkMode = savedTheme; 
        if (savedSession != null && savedSession['login']!.isNotEmpty) {
          final String login = savedSession['login']!;
          NetworkApiController.currentUserLogin = login;
          
          debugPrint('=== ЛОГ СТАРТ: Авторизация подтверждена для: $login ===');
          _isUserAuthenticated = true;
        } else {
          debugPrint('=== ЛОГ СТАРТ: Сессионный кэш пуст ===');
          _isUserAuthenticated = false;
        }
        _isSessionChecking = false; // Disable loading spinner screen loop
      });
    } catch (e, stackTrace) {
      debugPrint('!!! ОШИБКА ИНИЦИАЛИЗАЦИИ В MAIN !!!: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _isUserAuthenticated = false;
          _isSessionChecking = false;
        });
      }
    }
  }
  

  
   

  @override
  Widget build(BuildContext context) {
    // 🌟 1. ՍԵՍԻԱՅԻ ՍՏՈՒԳՄԱՆ ՊԱՀ (Քանի դեռ հավելվածը ստուգում է լոգինը բազայում)
    if (_isSessionChecking) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Colors.orange),
          ),
        ),
      );
    }

    // 🌟 2. ԳԼԽԱՎՈՐ ՄԻԱՑՈՒՄ (Երբ սեսիան արդեն ստուգված է)
    return MaterialApp(
      // Դինամիկ բազմալեզու անվանում բրաուզերի տաբի համար
      onGenerateTitle: (context) => AppLocalizations.of(context).translate('cookbook_lbl'),
      
      debugShowCheckedModeBanner: false,
      
      // Լեզվի LIVE կապումը գլխավոր ցանցին
      locale: _currentLocale, 
      supportedLocales: const [Locale('ru'), Locale('en'), Locale('hy')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Թեմայի LIVE փոփոխում (Dark/Light)
      theme: ThemeData(
                  brightness: Brightness.light,
                      ),
  darkTheme: ThemeData(
                  brightness: Brightness.dark,
                      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // 🌟 ԱՎՏՈՄԱՏ ՌՈՒՏԵՐ (Եթե լոգին եղած է՝ տանում է MainScreen, եթե ոչ՝ AuthScreen)
    // main.dart ֆայլի build մեթոդի ներսում (և՛ home-ի, և՛ routes-ի մեջ)

home: _isUserAuthenticated 
    ? MainScreen(
        isDarkMode: _isDarkMode, 
     onThemeChanged: (value) => _toggleTheme(value), 
      )
    : const AuthScreen(),


      // Էջերի համակարգային հասցեները
      routes: {
        '/home': (context) => MainScreen(
              isDarkMode: _isDarkMode,
              
              onThemeChanged: (value) => _toggleTheme(value),
            ),
        '/login': (context) => const AuthScreen(),
        '/admin_tickets': (context) => const AdminTicketsManagerScreen(),
      },
    );
  }
}


class MainScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  
  const MainScreen({
    super.key, 
    required this.isDarkMode, 
    required this.onThemeChanged,
    
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentBottomIndex = -1; 
  List<Map<String, dynamic>> _topRecipes = [];
  bool isLoading = true;
  Map<String, dynamic>? _currentUserProfile;
  final Map<String, bool> _activeAllergens = {'nuts': false, 'lactose': false, 'gluten': false};
  


  @override 
  void initState() {
    super.initState();
    _loadSavedAllergens();
    _checkSavedUserSession();
    _loadTopRecipesFeed();
  }

  Future<void> _loadSavedAllergens() async {
    final saved = await LocalCacheController.getLocalAllergens();
    if (mounted) {
      setState(() => _activeAllergens.addAll(saved));
    }
  }

  Future<void> _checkSavedUserSession() async {
    
     final cachedSession = await LocalCacheController.getLocalUserSession();
    
    // 2. Clear Guard: Everything inside this block guarantees cachedSession is NOT null
    if (cachedSession != null && mounted) {
      setState(() {
        _currentUserProfile = cachedSession; // Instantly restores both login and avatar_url
      });
      
      // 3. THE FIX: Use safe navigation ?. to avoid the unconditional invocation error
      final savedLogin = cachedSession['login']?.toString();
      if (savedLogin != null && savedLogin.isNotEmpty) {
        NetworkApiController.currentUserLogin = savedLogin;
      }
    }

    final cached = await LocalCacheController.getLocalUserSession();
    if (cached != null && mounted) {
      setState(() {
        _currentUserProfile = cached;
      });
    }
  }

  Future<void> _loadTopRecipesFeed() async {

    
    try {
      List<Map<String, dynamic>> data = await NetworkApiController.fetchTop20Recipes();
      if (data.isEmpty) {
        data = await LocalCacheController.getLocalTopRecipes();
      } else {
        await LocalCacheController.saveLocalTopRecipes(data);
      }
      if (mounted) {
        setState(() {
          _topRecipes = data;
          isLoading = false;
        });
      }
    } catch (e) {
      final cachedData = await LocalCacheController.getLocalTopRecipes();
      if (mounted) {
        setState(() {
          _topRecipes = cachedData;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_currentBottomIndex != -1)
              IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () => setState(() => _currentBottomIndex = -1),
              ),
            Text(
              _getAppBarTitle(), 
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        actions: [
          // РАБОТАЮЩАЯ КНОПКА ТЕМЫ: теперь она дергает живую функцию изменения состояния
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny, 
            color: Colors.white),
            //tooltip: widget.isDarkMode ? 'Включить светлую тему' : 'Включить темную тему',
            onPressed: () async {
               widget.onThemeChanged(!widget.isDarkMode);
               },
          ),
          IconButton(
            icon: Icon(_currentUserProfile != null ? Icons.account_circle : Icons.lock_outline, size: 28, color: Colors.white),
            onPressed: () async {
              if (_currentUserProfile != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfilePage(
                      userProfile: _currentUserProfile!,
                      activeAllergens: _activeAllergens,
                      onLogout: () => setState(() => _currentUserProfile = null),
                    ),
                  ),
                );
              } else {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
                if (result != null && result is Map<String, dynamic>) {
                  setState(() => _currentUserProfile = result);
                }
              }
            },
          ),
        ],
      ),
      body: _buildBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.orange,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _currentBottomIndex == -1 ? 0 : _currentBottomIndex + 1,
        onTap: (index) {
          setState(() {
            if (index == 0) {
              _currentBottomIndex = -1; 
            } else {
              _currentBottomIndex = index - 1; 
            }
          });
        },
       // 🌟 ИСПРАВЛЕНО: Убран const перед items, а текстовые метки заменены на ключи локализации
items: [
  BottomNavigationBarItem(
    icon: const Icon(Icons.grid_view), 
    label: AppLocalizations.of(context).translate('tab_categories'), // 🇷🇺 Категории / 🇦🇲 Կատեգորիաներ
  ),
  BottomNavigationBarItem(
    icon: const Icon(Icons.star), 
    label: AppLocalizations.of(context).translate('tab_top20'),      // 🇷🇺 Топ-20 / 🇦🇲 Թոփ-20
  ),
  BottomNavigationBarItem(
    icon: const Icon(Icons.kitchen), 
    label: AppLocalizations.of(context).translate('fridge_search'),   // Օգտագործում ենք պատրաստի սառնարանի բանալին
  ),
  BottomNavigationBarItem(
    icon: const Icon(Icons.psychology), 
    label: AppLocalizations.of(context).translate('tab_ai_chef'),    // 🇷🇺 ИИ Шеф / 🇦🇲 ԻԻ Շեֆ
  ),
],

      ),
    );
  }


String _getAppBarTitle() {
  // Проверяем, готов ли контекст локализации
  final localizations = AppLocalizations.of(context);

  switch (_currentBottomIndex) {
    case 0: 
      return localizations.translate('popular_recipes'); // 🌟 Из базы ru/en/hy
    case 1: 
      return localizations.translate('fridge_search');   // 🌟 Из базы ru/en/hy
    case 2: 
      return localizations.translate('ai_chat_title');   // 🌟 Наш готовый ключ для ИИ Чат страницы
    default: 
      return localizations.translate('default_app_title');
  }
}

  Widget _buildBodyContent() {
    switch (_currentBottomIndex) {
      case 0: return _buildTopRecipesTab();
      case 1: return const IngredientSearchTab();
      case 2: return AiChefChatPage();
      default: return _buildCategoriesGrid(); 
    }
  }

  Widget _buildTopRecipesTab() {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Colors.orange));

    if (_topRecipes.isEmpty) return  Center(child: Text(AppLocalizations.of(context).translate('recipe_notfound_label')));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    
    return ListView.builder(
                        itemCount: _topRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _topRecipes[index];
                          
                          // Безопасное чтение данных
                          final title = recipe['title']?.toString() ?? recipe['dish']?.toString() ?? 'Без названия';
                          final author = recipe['author_name']?.toString() ?? recipe['p_author']?.toString() ?? 'Не указан';
                          final views = recipe['viewscount'] ?? recipe['viewsCount'] ?? 0;
                          final instructions = (recipe['instructions'] ?? recipe['recipe_instructions'] ?? 'Инструкция отсутствует') as String;
                          final cuisine = recipe['cuisine']?.toString() ?? recipe['p_cuisine']?.toString();
                          // 1. Safe extraction of the source data at the top of your itemBuilder:
final rawSource = recipe['source'] ?? recipe['source_url'] ?? recipe['p_source'];
// Ensure it is a valid, non-zero string and doesn't equal stringified "null" or "0"
final String? source = (rawSource != null && 
                        rawSource.toString().trim() != '0' && 
                        rawSource.toString().trim().toLowerCase() != 'null' && 
                        rawSource.toString().trim().isNotEmpty)
    ? rawSource.toString().trim()
    : null;
                          final imageUrl = recipe['photo_url']?.toString() ?? recipe['p_mainimg']?.toString();
                          final imageSize = MediaQuery.of(context).size.width / 3;

                           // 🌟 ԼՐԱՑՈՒՑԻՉ ԼՈՒՍԱՆԿԱՐՆԵՐԻ ՆԵՐԲԵՌՆՈՒՄԸ ԲԱԶԱՅԻՑ
                    
final dynamic rawAdditionalImg = recipe['p_additionalimg'] ?? recipe['additionalimg'] ?? recipe['additionalImg'];
List<String> additionalImages = [];

if (rawAdditionalImg != null) {
  if (rawAdditionalImg is List) {
    additionalImages = rawAdditionalImg.map((e) => e.toString().trim()).where((e) => e.isNotEmpty && e != 'null').toList();
  } else if (rawAdditionalImg is String && rawAdditionalImg.isNotEmpty && rawAdditionalImg != 'null') {
    final String cleanStr = rawAdditionalImg.trim();
    // Проверяем, если строка пришла в формате JSON-массива ["url", "url"]
    if (cleanStr.startsWith('[') && cleanStr.endsWith(']')) {
      try {
        final List<dynamic> decoded = jsonDecode(cleanStr);
        additionalImages = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      } catch (e) {
        // Если jsonDecode не сработал, чистим скобки вручную
        additionalImages = cleanStr
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .replaceAll("'", "")
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } else {
      // Обычная строка со ссылками через запятую
      additionalImages = cleanStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
  }
}


                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: isDark ? Colors.grey[850] : Colors.white,
                            child: Theme(
                              // Убираем дефолтные разделительные линии ExpansionTile при раскрытии
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                // Фиксируем событие раскрытия и отправляем RPC-запрос счетчика на бэкенд
                                onExpansionChanged: (bool isExpanded) {
                                  if (isExpanded && recipe['id'] != null) {
                                    NetworkApiController.incrementRecipeViews(recipe['id'] as int);
                                    
                                  }
                                },
                                // ШАПКА КАРТОЧКИ: Картинка слева, текст справа
                                title: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
        // АДАПТИВНОЕ ПРЕВЬЮ (1/3 экрана)
        GestureDetector(
          onTap: () {
            if (imageUrl != null && imageUrl.isNotEmpty) {
              showDialog(
                context: context,
                builder: (context) => Dialog.fullscreen(
                  backgroundColor: Colors.black.withValues(alpha:0.9),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(imageUrl, fit: BoxFit.contain),
                      ),
                      Positioned(
                        top: 40,
                        right: 20,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
                                      // 1. контейнер для фото с сохранением пропорций
            child: Container(
            height: imageSize, // Адаптивная высота (1/3 экрана)
            width: imageSize,  // Адаптивная ширина (1/3 экрана)
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
    child: FittedBox(
      // 🌟 ШАГ 1: FittedBox берет любой дочерний виджет и насильно масштабирует его
      fit: BoxFit.cover,
      // 🌟 ШАГ 2: Принудительно обрезаем всё, что вылазит за рамки квадрата imageSize
      clipBehavior: Clip.hardEdge, 
      alignment: Alignment.center,

                  
                  child: Image.network(
                    imageUrl, 
                    fit: BoxFit.cover, // Пропорции фото не искажаются
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                  ),
               ) ,
                )
              : const Center(child: Icon(Icons.restaurant, size: 30, color: Colors.grey)),
          ),
        ),
        const SizedBox(width: 16),
                                      
                                      // 2. Колонка текстовых данных (название, автор, просмотры)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 18, 
                                                fontWeight: FontWeight.bold, 
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                           
                                            Row(
                                              children: [
                                                const Icon(Icons.visibility, size: 14, color: Colors.grey),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${AppLocalizations.of(context).translate('recipe_veiws_label')} $views',
                                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                               // Опциональный вывод Кухни
                                        if (cuisine != null && cuisine.isNotEmpty) ...[
Row(
children: [
const Icon(Icons.flag_outlined, size: 14, color: Colors.blueGrey),
const SizedBox(width: 6),
Expanded(
  child: Text('${AppLocalizations.of(context).translate('recipe_cuisine_label')} $cuisine', 
style: const TextStyle(fontSize: 13, 
color: Colors.blueGrey),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  ),
),
],
),
const SizedBox(height: 8),
],

   if (source != null) ...[
  Row(
    children: [
      const Icon(Icons.link, size: 16, color: Colors.blueGrey),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          '${AppLocalizations.of(context).translate('recipe_source_label')} $source', 
          style: const TextStyle(
            fontSize: 13, 
            color: Colors.blueGrey,
            decoration: TextDecoration.none,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  ),
  const SizedBox(height: 8),
],

 Row(
                                              children: [
                                                const Icon(Icons.person, size: 14, color: Colors.blueGrey),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    '${AppLocalizations.of(context).translate('recipe_author_label')} $author',
                                                    style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),



                                            
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // ВНУТРЕННЕЕ СОДЕРЖИМОЕ (Раскрывающийся блок рецепта)
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const Divider(height: 1, color: Colors.grey),
                                        const SizedBox(height: 12),
                                        
                                       
// Раздел Инструкции
Text(  AppLocalizations.of(context).translate('prep_method_title'), 
style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
const SizedBox(height: 6),
Text(instructions, style: const TextStyle(height: 1.4, fontSize: 12)),


// 🌟 ЖИВАЯ КНОПКА ИИ-ПЕРЕВОДЧИКА
// 🌟 ИСПРАВЛЕНО: Безопасная кнопка ИИ-Переводчика с защитой от бесконечной крутилки
Align(
  alignment: Alignment.centerLeft,
  child: TextButton.icon(
    style: TextButton.styleFrom(foregroundColor: Colors.orange),
    
    // Динамическая иконка загрузки
    icon: (recipe['isTranslating'] == true)
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
          )
        : const Icon(Icons.g_translate, size: 18),
        
    label: Text(
      AppLocalizations.of(context).translate('btn_ai_translate'),
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    
    // Если перевод уже запущен, полностью блокируем кнопку от повторных кликов
    onPressed: (recipe['isTranslating'] == true) 
        ? null 
        : () async {
            // Если рецепт уже переведен, по второму клику мгновенно возвращаем оригинал
            if (recipe['is_translated'] == true) {
              setState(() {
                recipe['instructions'] = recipe['original_instructions'];
                recipe['recipe_instructions'] = recipe['original_instructions'];
                recipe['is_translated'] = false;
              });
              return;
            }

            // Запоминаем исходный текст в резервную память перед отправкой
            recipe['original_instructions'] = recipe['instructions'] ?? recipe['recipe_instructions'] ?? '';

            // Включаем крутилку лоадера
            setState(() {
              recipe['isTranslating'] = true;
            });
            
            try {
              // Отправляем запрос через контроллер на наш сервер
              final String translatedResult = await NetworkApiController.translateActiveRecipeViaAi(
                activeRecipe: recipe,
                targetLanguageCode: Localizations.localeOf(context).languageCode,
              );
              
              // Выводим результат перевода на экран
              setState(() {
                recipe['instructions'] = translatedResult; 
                recipe['recipe_instructions'] = translatedResult;
                
                if (!translatedResult.startsWith('⚠️')) {
                  recipe['is_translated'] = true;
                }
              });
            } finally {
              // 🌟 ИСПРАВЛЕНО: Блок finally сработает ВСЕԳԴԱ! 
              // Крутилка гарантированно отключится ровно через 7 секунд, даже если сервер упал!
              setState(() {
                recipe['isTranslating'] = false;
              });
            }
          },
  ),
),


// 🌟 ԻՍՊՐԱՎԼԵՆՈ: ԼՐԱՑՈՒՑԻՉ ԼՈՒՍԱՆԿԱՐՆԵՐԻ ՀՈՐԻԶՈՆԱԿԱՆ ՑՈՒՑԱԴՐՈՒՄԸ ՔԱՐՏԻ ՄԵՋ
if (additionalImages.isNotEmpty) ...[

const SizedBox(height: 16),

Text(AppLocalizations.of(context).translate('recipe_adtnl_img_label'), 
style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),

const SizedBox(height: 8),
SizedBox(
height: 80,
child: ListView.builder(
scrollDirection: Axis.horizontal,
itemCount: additionalImages.length,
itemBuilder: (context, imgIdx) {
final url = additionalImages[imgIdx];
return Padding(
padding: const EdgeInsets.only(right: 8.0),
child: ClipRRect(
borderRadius: BorderRadius.circular(8),
child: Image.network(
url,
width: 80,
height: 80,
fit: BoxFit.cover,
errorBuilder: (c, e, s) =>  Container(width: 80, color: Colors.grey, 
child: Icon(Icons.broken_image, color: Colors.white)),
),
), 
);
},
),
),
],
],
),
),
],
),
),
);
},
);
  }



Widget _buildCategoriesGrid() {
final categories = [
{'title': AppLocalizations.of(context).translate('cat_hot_dishes'), 'type': 'горячее', 'color': Colors.red.shade400, 'icon': Icons.local_fire_department},
    {'title': AppLocalizations.of(context).translate('cat_salads'), 'type': 'салаты', 'color': Colors.green.shade400, 'icon': Icons.eco},
    {'title': AppLocalizations.of(context).translate('cat_desserts'), 'type': 'десерты', 'color': Colors.pink.shade400, 'icon': Icons.cake},
    {'title': AppLocalizations.of(context).translate('cat_vegetables'), 'type': 'овощи', 'color': Colors.orange.shade400, 'icon': Icons.lunch_dining},
  ];
return GridView.builder(
padding: const EdgeInsets.all(16),
itemCount: categories.length,
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 2,
crossAxisSpacing: 16,
mainAxisSpacing: 16,
),
itemBuilder: (context, index) {
final cat = categories[index];
return InkWell(
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => CategoryRecipesScreen(
categoryTitle: cat['title'] as String,
categoryType: cat['type'] as String,
),
),
);
},
child: Container(
decoration: BoxDecoration(color: cat['color'] as Color, borderRadius: BorderRadius.circular(16)),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(cat['icon'] as IconData, size: 45, color: Colors.white),
const SizedBox(height: 10),
Text(cat['title'] as String, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
],
),
),
);
},
);
}


}
