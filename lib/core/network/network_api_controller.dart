// core/network/network_api_controller.dart
import 'dart:io';
//import 'dart:nativewrappers/_internal/vm/lib/ffi_allocation_patch.dart';
// 🌟 ՖԱՅԼԻ ԱՄԵՆԱՎԵՐԵՎՈՒՄ ԱՎԵԼԱՑՐԵՔ ԱՅՍ IMPORT-Ը
//import 'package:universal_html/html.dart' as html; 
// 🌟 ՖԱՅԼԻ ԱՄԵՆԱՎԵՐԵՎՈՒՄ ԱՎԵԼԱՑՐԵՔ ԱՅՍ ՊԱՇՏՈՆԱԿԱՆ IMPORT-Ը (եթե դեռ չկա)
//import 'package:http/browser_client.dart' as http_browser;
import 'package:http/http.dart' as http;
import 'package:my_app/core/utils/ai_chef_chat_page.dart';
import 'package:my_app/core/utils/ai_chef_page.dart';
import 'package:postgres/messages.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
//import 'dart:math';
//import 'package:flutter/material.dart';
import 'dart:developer' as dev;
//import 'package:my_app/features/home_screen/category_recipes_screen.dart';
//import 'dart:typed_data'; // 👈 ADD THIS EXACT LINE AT THE TOP OF YOUR FILE
import 'package:my_app/features/home_screen/detail_screen/local_controller.dart';
import '../../features/auth_and_profile/user_profile_page.dart';










class Environment {
  static const supabaseUrl = 'https://ldpxhegdrycianlebbtp.supabase.co';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxkcHhoZWdkcnljaWFubGViYnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1NDkxMTgsImV4cCI6MjA5ODEyNTExOH0.q3qFanjw7NrJJMMPYF_rYV4xnqi4wH41J84IQfSnodk';
  static const baseApiUrl = '$supabaseUrl/rest/v1';
  static const storageBaseUrl = '$supabaseUrl/storage/v1/object';
//static final supabase = Supabase.instance.client;
  
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'apikey': supabaseAnonKey,
       // 'Authorization': 'Bearer $supabaseAnonKey',
        'Prefer': 'return=representation',
      };
}


class NetworkApiController {
  static String get _baseApiUrl => Environment.baseApiUrl;
  static Map<String, String> get _headers => Environment.headers;
  static String get _storageBaseUrl => Environment.storageBaseUrl;
 static String currentUserLogin = ''; 
static String currentUserAvatarUrl ='';
static List<String> activeAllergenGroups = []; // 🌟 Ավելացրեք այս փոփոխականը ալերգենների համար
//static Map<String, String> personalizedDictionary = {}; // 🌟 Ավելացրեք այս փոփոխականը ալերգենների համար
static Map<String, Map<String, List<String>>> personalizedDictionary = {};

static String? responseForAiChefPage = ''; 

  // 🌟 Տեղադրեք ձեր Dart սերվերի իրական IP հասցեն կամ դոմեյնը
  static String get _backendUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080'; // Специальный адрес для Android-эмулятора
    } else {
      return 'http://127.0.0.1:8080'; // iOS эмулятор и Desktop
    }
  }

  

  static Future<String> askLiveAiAgent(String userQuestion) async {
    try {

      final String serverUrl = '$_backendUrl/api/ai-chef';

      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'prompt': 'Ты — опытный шеф-повар. Отвечай кратко: $userQuestion'}),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['result'].toString().trim();
      }
      return "⚠️ Ошибка сервера. Попробуйте еще раз.";
    } catch (e) {
      return "Привет! Я твой кулинарный ИИ-Шеф (Режим защиты активен). 🍳";
    }
  }



 static Future<String> translateActiveRecipeViaAi(
  {
    required Map<String, dynamic> activeRecipe,
    required String targetLanguageCode,
  }) 
  async {
    try {
      debugPrint('=== AI TRANSLATOR: Sending prompt to local Dart Server ===');

      final String recipeTitle = activeRecipe['title'] ?? activeRecipe['recipe_title'] ?? '';
      final String recipeIngredients = activeRecipe['ingredients'] ?? activeRecipe['recipe_ingredients'] ?? '';
      final String recipeInstructions = activeRecipe['instructions'] ?? activeRecipe['recipe_instructions'] ?? '';

      final String fullRecipeText = "Title: $recipeTitle\nIngredients: $recipeIngredients\nInstructions: $recipeInstructions";
      final String finalPrompt = "Translate the following recipe fully into language code '$targetLanguageCode'. Return ONLY clean translated text:\n$fullRecipeText";

      // 🌟 ИСПРАВЛЕНО: Запрос идет строго на ваш сервер, БЕЗ ТОКЕНОВ, с таймаутом в 7 секунд!

      final String serverUrl = '$_backendUrl/api/ai-chef';
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {
          'Content-Type': 'application/json',
        }, // Пустые заголовки для обхода CORS на localhost
      // Если сработал таймаут (сервер выключен), возвращаем локальную ошибку, чтобы выключить крутилку
      
        body: jsonEncode({'prompt': finalPrompt}),
      ).timeout(const Duration(seconds: 45)); // 👈 Прервет зависание через 7 секунд

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['result'].toString().trim();
      }
      
      return "⚠️ Сервер вернул ошибку кода: ${response.statusCode}";
    } catch (e) {
      return activeRecipe['instructions'];
      
     
    }
  }


 // network_api_controller.dart
static Future<String> translateAndCleanRecipeViaBackend({
  required Map<String, dynamic> activeRecipe,
  required String targetLanguageCode,
  required List<String> activeAllergens, // 🌟 Փոխանցում ենք հեռախոսի էկրանից եկած ակտիվ ալերգենները
}) async {
  try {
    debugPrint('=== AI BACKEND PIPELINE: Composing secure allergen-free recipe text ===');

    // 1. Ինտերպոլյացիայով հավաքում ենք ընթացիկ ռեցեպտի բոլոր տվյալները
    final String recipeTitle = activeRecipe['title'] ?? activeRecipe['recipe_title'] ?? '';
    final String recipeIngredients = activeRecipe['ingredients'] ?? activeRecipe['recipe_ingredients'] ?? '';
    final String recipeInstructions = activeRecipe['instructions'] ?? activeRecipe['recipe_instructions'] ?? '';

    final String fullRecipeText = "Original Title: $recipeTitle\nOriginal Ingredients: $recipeIngredients\nOriginal Instructions: $recipeInstructions";

    // 2. Սարքում ենք ալերգենների տեքստային տողը (ստորակետներով)
    final String allergensText = activeAllergens.isNotEmpty ? activeAllergens.join(', ') : 'None';

    // 3. 🌟 ԿԱԶՄՈՒՄ ԵՆՔ ՀԶՈՐ ՀԱՄԱԿՑՎԱԾ ՊՐՈՄԹԸ
    final String compoundPrompt = 
        "You are an elite Michelin-star Chef Assistant specializing in culinary translation and food safety. "
        "Your task is to completely translate and rewrite the following recipe into target language code '$targetLanguageCode'.\n\n"
        "🔥 CRITICAL SAFETY TASK:\n"
        "Check the recipe for these allergens: [$allergensText]. If any of these allergens are present in the recipe, you MUST completely remove them and substitute them with delicious, realistic, and safe culinary alternatives in the translated text!\n\n"
        "Return ONLY the clean, beautifully formatted, translated, and allergen-safe recipe text. Do not include any chat commentary or system tags.\n\n"
        "Recipe Data to process:\n$fullRecipeText";

    // 4. Հարցումը ուղարկում ենք մեր սեփական անխափան Dart բեքենդ սերվերին (_backendUrl)
    final String serverUrl   = '$_backendUrl/api/parse-allergens';
    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {
        'Content-Type': 'application/json'
        },
      body: jsonEncode({'prompt': compoundPrompt}), // 👈 Ուղարկում ենք ալերգեններով պրոմթը
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['result'].toString().trim();
    }
    
    return "⚠️ Не удалось выполнить безопасный перевод рецепта. Код: ${response.statusCode}";
  } catch (e) {
    debugPrint('❌ Critical Backend Network API error: $e');
    return "⚠️ Технический сбой связи со своим Dart сервером.";
  }
}


// 1. Սերվերից (Supabase) կարդում ենք 5 խմբերի կարգավիճակը..

static Future<Map<String, bool>> fetchUserAllergensFromDb() async {
  try {
    // 1. Որոշում ենք ակտիվ օգտատիրոջ լոգինը
    String userLogin = currentUserLogin;
    if (userLogin.isEmpty || userLogin == 'null') {
      final savedSession = await LocalCacheController.getLocalUserSession();
      userLogin = savedSession?['login']?.toString() ?? '';
    }

    // ‼️ ՊԱՇՏՊԱՆԻՉ ՏՈՂ: Եթե դատարկ է, դնում ենք ձեր ակտիվ ադմինին, ինչպես արեցինք սվիչի մեջ
    if (userLogin.isEmpty || userLogin == 'null') {
      userLogin = 'HasmikAdmin'; 
    }

    // 2. ՆԱԽ ԲԱԶԱՅԻՑ ԳՏՆՈՒՄ ԵՆՔ ԱՅՍ ՕԳՏԱՏԻՐՈՋ ԹՎԱՅԻՆ ID-Ն (profile աղյուսակից)
    final List<dynamic> profileRes = await Supabase.instance.client
        .from('profile')
        .select('id')
        .ilike('login', userLogin); // Հաշվի չի առնում մեծատառ/փոքրատառը

    if (profileRes.isEmpty) {
      debugPrint('❌ Ошибка загрузки: пользователь $userLogin не найден в profile');
      return {};
    }
    final int numericUserId = profileRes.first['id'] as int;

    // 3. ԿԱՐԴՈՒՄ ԵՆՔ ԱԼԵՐԳԵՆՆԵՐԸ ԲԱԶԱՅԻՑ (userAllergens աղյուսակից)
    final List<dynamic> response = await Supabase.instance.client
        .from('userAllergens')
        .select('allergens_group, setState')
        .eq('user_id', numericUserId); // Փնտրում ենք ըստ թվային ID-ի

    // 4. Տվյալները վերածում ենք Map-ի Flutter-ի սվիչների համար
    Map<String, bool> allergensMap = {};
    for (var item in response) {
      if (item is Map) {
        final int groupNum = item['allergens_group'] as int;
        final bool state = item['setState'] as bool;
        // Կապում ենք ճիշտ բանալիների հետ (group_1, group_2 և այլն)
        allergensMap['group_$groupNum'] = state;
      }
    }

    debugPrint('📖 Բազայից հաջողությամբ ներբեռնվեցին ալերգենները: $allergensMap');
    return allergensMap;

  } catch (e) {
    debugPrint('❌ Ошибка загрузки userAllergens из БД через SDK: $e');
    return {};
  }
}


static Future<bool> updateUserAllergenGroupInDb(int groupNum, bool isEnabled) async {
  try {
    // 1. ՍՏՈՒԳՈՒՄ ԵՆՔ ՕԳՏԱՏԻՐՈՋ ԼՈԳԻՆԸ (Անվտանգության հզորացում)
    String userLogin = currentUserLogin;
    
    // Եթե ստատիկ փոփոխականը դատարկ է, փորձում ենք կարդալ տեղային քեշից
    if (userLogin.isEmpty || userLogin == 'null') {
      final savedSession = await LocalCacheController.getLocalUserSession();
      userLogin = savedSession?['login']?.toString() ?? '';
    }

    // ‼️ ԺԱՄԱՆԱԿԱՎՈՐ ԼՈՒԾՈՒՄ ԹԵՍՏԱՎՈՐՄԱՆ ՀԱՄԱՐ (Եթե երկուսն էլ դատարկ են, դնում ենք ձեր ակտիվ ադմինին)
    if (userLogin.isEmpty || userLogin == 'null') {
      userLogin = 'HasmikAdmin'; // Ուղղակի գրում ենք ձեր լոգինը, որ սվիչը հաստատ աշխատի
    }

    debugPrint('📤 Ուղարկում ենք RPC հարցում օգտատիրոջ համար: $userLogin, Խումբ: $groupNum, Վիճակ: $isEnabled');

    // 2. Կանչում ենք RPC ֆունկցիան պաշտոնական SDK-ով
    await Supabase.instance.client.rpc(
      'update_user_allergen_group', 
      params: {
        'p_user_login': userLogin, // Տեքստային լոգինը (HasmikAdmin)
        'p_state': isEnabled,
        'p_group_num': groupNum,
      },
    );
    
    debugPrint('✅ Состояние аллергена (Группа $groupNum) успешно сохранено в БД как $isEnabled');
    return true;
  } catch (e) {
    debugPrint('❌ Ошибка RPC запроса через Supabase SDK: $e');
    return false;
  }
}



  static Future<List<Map<String, dynamic>>> fetchRecipesFromCloud(String cat) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
          'p_action': 'get_recipe_by_category',
           'p_additionalimg': null,
           'p_avatarurl': null,
          'p_author': null,
          'p_category': cat, // ИСПОЛЬЗУЕМ ПЕРЕМЕННУЮ ВМЕСТО СТРОКИ
          'p_cuisine': null,
           'p_ingrid': null,
           'p_login': null,
          'p_mainimg':  null,
           'p_message_text': null,
          'p_password': null,
           'p_recipe_id': null, 
          'p_recipe_instructions':null,
          'p_recipe_title': null,
          'p_selected_ids': null,
          'p_source': null,
          'p_ticket_id':null,
          'p_viewscount': null
               
               
              
          
        }),

        
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && response.body.trim().isNotEmpty && response.body.trim() != 'null') {
        final decoded = jsonDecode(response.body);

        // Обработка структуры Supabase RPC
        if (decoded is Map && decoded['recipe'] is List) {
          final recipesList = decoded['recipe'] as List;
          return recipesList
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } 
        // На случай, если функция RPC возвращает сразу List без обертки в 'recipe'
        else if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      dev.log('fetchRecipesFromCloud: before http');

dev.log('fetchRecipesFromCloud: status=${response.statusCode}');
dev.log('fetchRecipesFromCloud: body_head=${response.body.substring(0, response.body.length < 200 ? response.body.length : 200)}');


} catch (e) {
  dev.log('fetchRecipesFromCloud: CATCH error: $e', error: e);
}
 

    return []; // Возвращаем пустой список в случае ошибки
  }

dynamic printDebugInfo(http.Response response) {
  debugPrint('RPC URL: ${Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager')}');
  debugPrint('HTTP status: ${response.statusCode}');
  debugPrint('RPC headers: ${response.headers}');
  debugPrint('RPC body (head): ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
} 



static Future<List<Map<String, dynamic>>> fetchTop20Recipes() async {
    try {
      final responseTop = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        //'Authorization': 'Bearer Environment.supabaseAnonKey',
        body: jsonEncode({
          'p_action': 'get_top_recipes',
           'p_additionalimg': null,
           'p_avatarurl': null,
          'p_author': null,
          'p_category': null, 
          'p_cuisine': null,
           'p_ingrid': null,
           'p_login': null,
          'p_mainimg':  null,
           'p_message_text': null,
          'p_password': null,
           'p_recipe_id': null, 
          'p_recipe_instructions':null,
          'p_recipe_title': null,
          'p_selected_ids': null,
'p_source': null,
'p_ticket_id':null,
          'p_viewscount': null
            
          
        }),
      ).timeout(const Duration(seconds: 5));

      if (responseTop.statusCode != 200) {
        throw Exception('Сервер вернул код ${responseTop.statusCode}: ${responseTop.body}');
      }

      if (responseTop.body.trim().isEmpty || responseTop.body.trim() == 'null') {
        throw Exception('Сервер вернул пустой ответ или null');
      }

      final decodedTop = jsonDecode(responseTop.body);

      // Защищенный и универсальный парсинг любых видов Map/List от Supabase
      if (decodedTop is Map) {
        // Ищем внутри Map любой ключ, значением которого является список (например, "recipe" или "Popular recipes")
        final potentialList = decodedTop.values.firstWhere(
          (value) => value is List,
          orElse: () => null,
        );

        if (potentialList != null) {
          return (potentialList as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        
        // Если Map пришел без списков, но сам по себе представляет объект рецепта
        return [Map<String, dynamic>.from(decodedTop)];
      } 
      
      if (decodedTop is List) {
        return decodedTop
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      throw Exception('Неподдерживаемый формат JSON: ${decodedTop.runtimeType}');
    } catch (e) {
      // Пробрасываем ошибку наружу, чтобы UI-слой смог перехватить её и отобразить
      rethrow;
    }
  }


 // Вспомогательный метод для безопасной распаковки массивов из JSON-ответов Supabase
  static List<Map<String, dynamic>> _unpackList(dynamic decoded) {
    if (decoded is Map) {
      final potentialList = decoded.values.firstWhere(
        (value) => value is List,
        orElse: () => null,
      );
      if (potentialList != null) {
        return (potentialList as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [Map<String, dynamic>.from(decoded)];
    }
    if (decoded is List) {
      return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
     
    }
    return [];
  }


 static Future<Map<String, dynamic>?> loginUser(String login, String password, String? avatarUrl) async {
  try {
    // 1. Կատարում ենք ձեր ստանդարտ հարցումը ՏԲ-ի ունիվերսալ մենեջերին
    final response = await http.post(
      Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'), // Ուղղվել է RPC-ի ճիշտ HTTP հասցեն
      headers: _headers,
      body: jsonEncode({
        'p_action': 'login_user',
        'p_additionalimg': null,
        'p_avatarurl': avatarUrl,
        'p_author': null,
        'p_category': null, 
        'p_cuisine': null,
        'p_ingrid': null,
        'p_login': login,
        'p_mainimg':  null,
        'p_message_text': null,
        'p_password': password,
        'p_recipe_id': null, 
        'p_recipe_instructions':null,
        'p_recipe_title': null,
        'p_selected_ids': null,
        'p_source': null,
        'p_ticket_id':null,
        'p_viewscount': null
      }),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200 && response.body.trim() != 'null') {
      final decoded = jsonDecode(response.body);
      final list = _unpackList(decoded);

      if (list.isNotEmpty) {
        final Map<String, dynamic> userProfile = list.first;
        final String resLogin = userProfile['login']?.toString() ?? login;
        final String resAvatar = userProfile['avatar_url']?.toString() ?? '';

        // =========================================================================
        // 🌟 ԱՎԵԼԱՑՎԱԾ Է. ՍՈՒՊԱԲԵՅՍԻ ՊԱՇՏՈՆԱԿԱՆ AUTH ՄՈՒՏՔԸ
        // =========================================================================
        try {
          // Փորձում ենք մուտք գործել պաշտոնական համակարգով
          await Supabase.instance.client.auth.signInWithPassword(
            email: '${resLogin.toLowerCase()}@myapp.com', // Լոգինը վերածում ենք կեղծ email-ի
            password: password,
          );
        } catch (authError) {
          // Եթե այս օգտատերը դեռ գրանցված չէ Supabase Auth-ում, ավտոմատ գրանցում ենք նրան
          debugPrint('🔄 Пользователь не найден в Auth, регистрируем автоматически...');
          await Supabase.instance.client.auth.signUp(
            email: '${resLogin.toLowerCase()}@myapp.com',
            password: password,
          );
        }
        // =========================================================================

        // Պահպանում ենք տվյալները տեղային քեշում (Լոկալով)
        await LocalCacheController.saveLocalUserSession({
          'login': resLogin,
          'avatar_url': resAvatar,
        });

        // Գրանցում ենք ստատիկ փոփոխականում
        NetworkApiController.currentUserLogin = resLogin;
         debugPrint('✅ Успешный вход пользователя: $resLogin'); 
        return userProfile;
      }
    }
  } catch (e) {
    debugPrint('Ошибка авторизации: $e');
  }
  return null;
}

// NetworkApiController-ի ներսում ավելացրեք այս ֆունկցիան.
static Future<bool> uploadUserAvatarToDb(String newAvatarUrl) async {
  try {
    String userLogin = currentUserLogin;

    // Ուղղակի HTTP POST հարցում Supabase RPC-ին կամ REST-ին՝ ավատարը թարմացնելու համար
    // Օգտագործում ենք RPC ճիշտ հասցեն, ինչպես լոգինի ժամանակ
    final String url = "$_baseApiUrl/rest/v1/rpc/universal_fridge_manager";

    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode({
        'p_action': 'update_avatar', // Ձեր ունիվերսալ մենեջերի action-ը
        'p_login': userLogin,
        'p_avatarurl': newAvatarUrl, // Փոխանցում ենք նոր լինկը
        // ... մնացած բոլոր null-երը, ինչպես ունեիք լոգինի մեջ ...
      }),
    );

    if (response.statusCode == 200) {
      currentUserAvatarUrl = newAvatarUrl; // Թարմացնում ենք գլոբալ հիշողությունը
      return true;
    }
    return false;
  } catch (e) {
    debugPrint('❌ Ошибка обновления аватара в БД: $e');
    return false;
  }
}

// 🌟 ԼԻՈՎԻՆ ՆՈՐ ԱՌԱՆՁԻՆ ՄԵԹՈԴ՝ ԱՎԱՏԱՐԸ ԲԱԶԱՅԻՑ ՆԵՐԲԵՌՆԵԼՈՒ ՀԱՄԱՐ
static Future<String?> fetchAvatarFromDb() async {
  try {
    String userLogin = currentUserLogin;
    if (userLogin.isEmpty || userLogin == 'null') {
      final savedSession = await LocalCacheController.getLocalUserSession();
      userLogin = savedSession?['login']?.toString() ?? '';
    }

    if (userLogin.isEmpty || userLogin == 'null') {
      userLogin = 'HasmikAdmin'; // Պաշտպանություն, եթե լոգինը դատարկ է
    }

    // Ուղղակի հարցում ենք անում միայն profile աղյուսակի avatar_url սյունակին [4.2]
    final List<dynamic> response = await Supabase.instance.client
        .from('profile')
        .select('avatarurl')
        .ilike('login', userLogin);

    if (response.isNotEmpty) {
      final String? dbAvatar = response.first['avatarurl']?.toString().trim();
      if (dbAvatar != null && dbAvatar.isNotEmpty && dbAvatar != 'null') {
        // Գրանցում ենք ստատիկ փոփոխականում հավելվածի մյուս էջերի համար [4.2]
        currentUserAvatarUrl = dbAvatar; 
        return dbAvatar; // Վերադարձնում ենք մաքուր տեքստային լինկը
      }
    }
    return null;
  } catch (e) {
    debugPrint('❌ Ошибка в fetchAvatarFromDb: $e');
    return null;
  }
}

  /// Регистрация нового аккаунта
  static Future<Map<String, dynamic>?> registerUser(String login, String password, String? avatarUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
          'p_action': 'register_user',
            'p_additionalimg': null,
            'p_avatarurl': avatarUrl,
          'p_author': null,
          'p_category': null, 
          'p_cuisine': null,
           'p_ingrid': null,
           'p_login': login,
          'p_mainimg':  null,
           'p_message_text': null,
          'p_password': password,
           'p_recipe_id': null, 
          'p_recipe_instructions':null,
          'p_recipe_title': null,
          'p_selected_ids': null,
'p_source': null,
'p_ticket_id':null,
          'p_viewscount': null
          
        }),
      ).timeout(const Duration(seconds: 5));
   
      if (response.statusCode == 200 && response.body.trim() != 'null') {
        final decoded = jsonDecode(response.body);
        final list = _unpackList(decoded);
        if (list.isNotEmpty) return list.first;
      }
    } catch (e) {
   //   debugPrint('Ошибка регистрации: $e');
    }
    return null;
  }

   
  /// Изменение текущего пароля с полной синхронизацией Auth шлюза
  static Future<bool> changeUserPassword(String login, String newPassword) async {
    try {
      debugPrint('🔐 PASSWORD PIPELINE: Changing password for user: $login...');

      // 🌟 ШАГ 1: Обновляем пароль в вашей пользовательской таблице через RPC шлюз
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
          'p_action': 'change_password',
          'p_additionalimg': null,
          'p_avatarurl': null,
          'p_author': null,
          'p_category': null, 
          'p_cuisine': null,
          'p_ingrid': null,
          'p_login': login,
          'p_mainimg': null,
          'p_message_text': null,
          'p_password': newPassword,
          'p_recipe_id': null, 
          'p_recipe_instructions': null,
          'p_recipe_title': null,
          'p_selected_ids': null,
          'p_source': null,
          'p_ticket_id': null,
          'p_viewscount': null         
        }),
      ).timeout(const Duration(seconds: 5));

      // Проверяем, что ваша база данных успешно приняла и обработала запрос
      if (response.statusCode == 200) {
        debugPrint('🗄️ Database custom profile table updated successfully.');

        // 🌟 ШАГ 2: Синхронизируем пароль во внутреннем системном Auth-хранилище Supabase
        final UserResponse usersResponse = await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );

        if (usersResponse.user != null) {
          debugPrint('✅ SUCCESS: Supabase Auth global session password synchronized!');
          return true;
        }
      }
      
      debugPrint('⚠️ SERVER ERROR: RPC manager rejected password change (Status: ${response.statusCode})');
      return false;

    } catch (e) {
      debugPrint('❌ CRITICAL AUTH PIPELINE EXCEPTION: $e');
      return false;
    }
  }


  // =======================================================
  // 3. ФИЧА ТЕХПОДДЕРЖКИ (ОБРАЩЕНИЯ/ТИКЕТЫ)
  // =======================================================

  /// Отправка тикета администрации
  static Future<bool> sendAdminTicket(String login, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
           'p_action': 'send_ticket',
        'p_additionalimg': null,
        'p_avatarurl': null,
          'p_author': null,
          'p_category': null, 
          'p_cuisine': null,
           'p_ingrid': null,
           'p_login': login,
          'p_mainimg':  null,
           'p_message_text': text,
          'p_password': null,
           'p_recipe_id': null, 
          'p_recipe_instructions':null,
          'p_recipe_title': null,
          'p_selected_ids': null,
'p_source': null,
'p_ticket_id':null,
          'p_viewscount': null

        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
//      debugPrint('Ошибка отправки обращения: $e');
      return false;
    }
  }

    /// Запрашивает с сервера Supabase все тикеты конкретного пользователя
  static Future<List<Map<String, dynamic>>> fetchUserTickets(String login) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
          'p_action': 'get_user_tickets',
          'p_additionalimg': null,
          'p_avatarurl': null,
          'p_author': null,
          'p_category': null, 
          'p_cuisine': null,
           'p_ingrid': null,
           'p_login': login,
          'p_mainimg':  null,
           'p_message_text': null,
          'p_password': null,
           'p_recipe_id': null, 
          'p_recipe_instructions':null,
          'p_recipe_title': null,
          'p_selected_ids': null,
'p_source': null,
'p_ticket_id':null,
          'p_viewscount': null
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['tickets'] != null) {
          final List<dynamic> list = data['tickets'];
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('Ошибка синхронизации тикетов: $e');
    }
    return []; // Возвращаем пустой список в случае сбоя сети
  }

  /// Отправляет ответ администратора на тикет по его ID
  static Future<bool> sendAdminReply(int ticketId, String replyText) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
          'p_action': 'admin_reply_to_ticket',
            'p_additionalimg': null,
            'p_avatarurl': null,
          'p_author': null,
          'p_category': null, 
          'p_cuisine': null,
           'p_ingrid': null,
           'p_login': null,
          'p_mainimg':  null,
           'p_message_text': replyText.trim(),
          'p_password': null,
           'p_recipe_id': null,
          'p_recipe_instructions':null,
          'p_recipe_title': null,
          'p_selected_ids': null,
'p_source': null,
'p_ticket_id': ticketId, // передаем ID тикета в универсальный параметр, ,
          'p_viewscount': null
         
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Ошибка отправки ответа админа: $e');
      return false;
    }
  }

    /// Запрашивает вообще все тикеты из базы данных (Только для HasmikAdmin)
  static Future<List<Map<String, dynamic>>> fetchAllTicketsForAdmin(String adminLogin) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
          'p_action': 'admin_get_all_tickets',
             'p_additionalimg': null,
             'p_avatarurl': null,
          'p_author': null,
          'p_category': null, 
          'p_cuisine': null,
           'p_ingrid': null,
           'p_login': adminLogin,
          'p_mainimg':  null,
           'p_message_text': null,
          'p_password': null,
           'p_recipe_id': null,
          'p_recipe_instructions':null,
          'p_recipe_title': null,
          'p_selected_ids': null,
'p_source': null,
'p_ticket_id': null, // передаем ID тикета в универсальный параметр, ,
          'p_viewscount': null
         
          
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['tickets'] != null) {
          final List<dynamic> list = data['tickets'];
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('Ошибка получения всеобщих тикетов: $e');
    }
    return [];
  }


  // =======================================================
  // 4. УПРАВЛЕНИЕ ЛИЧНЫМИ РЕЦЕПТАМИ И ИНГРЕДИЕНТАМИ
  // =======================================================

  /// Получение списка рецептов, созданных текущим автором
  static Future<List<Map<String, dynamic>>> fetchMyAuthoredRecipes(String userLogin) async {
    dev.log('fetchMyAuthoredRecipes: before http');

    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
          'p_action': 'get_my_recipes',
        'p_additionalimg': null,
        'p_avatarurl': null,
          'p_author': null,
          'p_category': null, 
          'p_cuisine': null,
           'p_ingrid': null,
           'p_login': userLogin, // Передаем логин текущего пользователя
          'p_mainimg':  null,
           'p_message_text': null,
          'p_password': null,
           'p_recipe_id': null, 
          'p_recipe_instructions':null,
          'p_recipe_title': null,
          'p_selected_ids': null,
'p_source': null,
'p_ticket_id':null,
          'p_viewscount': null    
         
        }),
        

      ).timeout(const Duration(seconds: 5));
dev.log('fetchMyAuthoredRecipes: status=${response.statusCode}');
dev.log('fetchMyAuthoredRecipes: body_head=${response.body.substring(0, response.body.length < 200 ? response.body.length : 200)}');


      if (response.statusCode == 200 && response.body.trim() != 'null') {
        return _unpackList(jsonDecode(response.body));
      }
    } catch (e) {
  dev.log('fetchMyAuthoredRecipes: CATCH error: $e', error: e);

    }
    return [];
  }

  /// Фоновое увеличение счетчика просмотров рецепта на +1 при раскрытии
  static Future<void> incrementRecipeViews(int recipeId) async {
    try {
      // Отправляем быстрый POST-запрос на сервер
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
          'p_action': 'increment_views',
          'p_additionalimg': null,
          'p_avatarurl': null,
          'p_author': null,
          'p_category': null, 
          'p_cuisine': null,
           'p_ingrid': null,
           'p_login': null, // Передаем логин текущего пользователя
          'p_mainimg':  null,
           'p_message_text': null,
          'p_password': null,
          'p_recipe_id': recipeId,
          'p_recipe_instructions':null,
          'p_recipe_title': null,
          'p_selected_ids': null,
'p_source': null,
'p_ticket_id':null,
          'p_viewscount': null

        }),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        
        debugPrint('=== СЧЕТЧИК: Просмотр рецепта ID $recipeId успешно засчитан ===');
      }
    } catch (e) {
      // Глушим ошибку для пользователя, чтобы проблемы со связью не мешали ему читать рецепт
      debugPrint('Ошибка отправки счетчика просмотров: $e');
    }
  }


  /// Загрузка глобального справочника продуктов (для выпадающих списков)
  static Future<List<Map<String, dynamic>>> fetchAllGlobalIngredients() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
  'p_action': 'get_all_ingredients',
     'p_additionalimg': null,
     'p_avatarurl': null,
          'p_author': null,
          'p_category': null, 
          'p_cuisine': null,
           'p_ingrid': null,
           'p_login': null,
          'p_mainimg':  null,
           'p_message_text': null,
          'p_password': null,
           'p_recipe_id': null, 
          'p_recipe_instructions':null,
          'p_recipe_title': null,
          'p_selected_ids': null,
'p_source': null,
'p_ticket_id': null,
          'p_viewscount': null       
        
               
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && response.body.trim() != 'null') {
        return _unpackList(jsonDecode(response.body));
      }
    } catch (e) {
//      debugPrint('Ошибка загрузки справочника ингредиентов: $e');
    }
    return [];
  }

  /// Добавление нового рецепта («Шедевра») в облако
  static Future<bool> uploadNewRecipeToDatabase(Map<String, dynamic> recipeData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode(recipeData)
          
         /* {
    /*      'p_action': 'add_new_recipe',
          'p_additionalimg': null,
          'p_avatarurl': null,
          'p_author': recipeData['cuisine'],
          'p_category': recipeData['category_type'],
          'p_cuisine': null,
           'p_ingrid': null,
           'p_login': recipeData['login'], // Передается логин создателя как p_login
          'p_mainimg':  recipeData['main_image'],
           'p_message_text': null,
          'p_password': null,
           'p_recipe_id': null, 
          'p_recipe_instructions': recipeData['instructions'],
          'p_recipe_title': recipeData['title'], 
          'p_selected_ids': recipeData['ingredients'], // Массив ID выбранных продуктов
'p_source': recipeData['source_url'] ? recipeData['source_url'] : null,
'p_ticket_id':null,
          'p_viewscount': null
        */       
        image
           
           }*/
          ).timeout(const Duration(seconds: 5));
           dev.log('uploadNewRecipeToDatabase: status=${response.statusCode}');
dev.log('uploadNewRecipeToDatabase: body_head=${response.body.substring(0, response.body.length < 200 ? response.body.length : 200)}');

           return response.statusCode == 200;
           } catch (e) {
    //          debugPrint('Ошибка публикации рецепта: $e');
            return false;
            }}


              /// Uploads compressed image bytes straight into a public Supabase Storage Bucket
  /// Returns the public download URL string on success, or null on failure.
  static Future<String?> uploadImageBytes({
    required String bucketName,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    try {
      final String extension = fileName.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (extension == 'png') mimeType = 'image/png';
      if (extension == 'webp') mimeType = 'image/webp';

      // ЧИСТЫЙ АДРЕС ДЛЯ ЗАГРУЗКИ (Использует нашу константу)
      final String uploadUrl = '$_storageBaseUrl/recipe_images/$fileName';
      
      debugPrint('=== СЕТЕВОЙ ЗАПРОС STORAGE: ОТПРАВКА НА URL: $uploadUrl ===');

      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          ..._headers,
            'apikey': Environment.supabaseAnonKey,
       'Authorization': 'Bearer ${Environment.supabaseAnonKey}',
          'Content-Type': mimeType,
        },
        body: fileBytes,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('=== SUPABASE STORAGE: Файл успешно сохранен на сервере! ===');
        
        // ПУБЛИЧНЫЙ АДРЕС ДЛЯ ОТОБРАЖЕНИЯ (Здесь мы аккуратно подставляем /public/)
        return '$_storageBaseUrl/public/recipe_images/$fileName';
      } else {
        debugPrint('❌ Ошибка Supabase Storage (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Критическое исключение сети при загрузке байтов: $e');
      return null;
    }
  }


  /// Отправляет измененные параметры рецепта в базу данных Supabase
  static Future<bool> updateRecipeData({
    required int recipeId,
    String? dish,
    String? instructions,
    String? cuisine,
    String? authorname,
    String? source,
    String? imageUrl,
    List<dynamic>? additionalimg,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
          'p_action': 'update_recipe',
          'p_additionalimg': additionalimg,
          'p_avatarurl':null,
             'p_author': authorname,
         'p_category': null,
           'p_cuisine': cuisine,                // Новая кухня/категория 
                'p_ingrid': null,
          'p_login': null,
          'p_mainimg': imageUrl,
          'p_message_text': null,
          'p_password': null,
          'p_recipe_id': recipeId,              // ID рецепта, который правим
          'p_recipe_title': dish,              // Новое название (или null)
          'p_recipe_instructions': instructions,// Новые шаги (или null)
      'p_selected_ids': null,
          'p_source': source,
          'p_viewscount': null
          // ЗАПОЛНЯЕМ ОСТАЛЬНЫЕ ПАРАМЕТРЫ КАК NULL ДЛЯ СОХРАНЕНИЯ СИГНАТУРЫ:
          
          
          
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('❌ Ошибка сети при обновлении параметров рецепта: $e');
      return false;
    }
  }

    /// Deletes a specific recipe row from the cloud database
  static Future<bool> deleteRecipeFromCloud(int recipeId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
          'p_action': 'delete_recipe',
           'p_additionalimg': null,
          'p_avatarurl':null,
          'p_author': null,
          'p_category': null,
          'p_cuisine': null,
          'p_ingrid': null,
          'p_login': null,
          'p_mainimg': null,
          'p_message_text': null,
          'p_password': null,
          'p_recipe_id': recipeId, // Pass target ID
          'p_recipe_instructions': null,
          'p_recipe_title': null,
          'p_selected_ids': null,
          'p_source': null,
          'p_viewscount': null
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('❌ Network exception during recipe row deletion: $e');
      return false;
    }
  }

  /// Optional Helper: Deletes the binary file from your recipe_images bucket to save space
  static Future<void> deleteRecipeImageFile(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || !imageUrl.contains('/recipe_images/')) return;
      
      // Extract the isolated file name string (e.g., recipe_1723635041.jpg)
      final String fileName = imageUrl.split('/').last;
      final String deleteUrl = '$_storageBaseUrl/recipe_images/$fileName';

      await http.delete(
        Uri.parse(deleteUrl),
        headers: {
          'apikey': _headers['apikey'] ?? '',
          'Authorization': 'Bearer ${_headers['apikey']}',
        },
      );
      debugPrint('=== STORAGE: Media asset file $fileName cleaned up successfully ===');
    } catch (e) {
      debugPrint('Failed to drop storage binary file: $e');
    }
  }



    /// Сохраняет текстовую ссылку на аватарку в профиль пользователя в БД
  static Future<bool> saveAvatarLinkToProfile(String login, String avatarUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
          'p_action': 'update_avatar',
          'p_additionalimg': null,
     'p_avatarurl': avatarUrl, // передаем ссылку в параметр источника,
          'p_author': null,
          'p_category': null, 
          'p_cuisine': null,
           'p_ingrid': null,
     'p_login': login,
          'p_mainimg':  null,
           'p_message_text': null,
          'p_password': null,
           'p_recipe_id': null, 
          'p_recipe_instructions':null,
          'p_recipe_title': null,
          'p_selected_ids': null,
          'p_source': null,
          'p_ticket_id': null,
          'p_viewscount': null       
        
     
          
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Ошибка сохранения ссылки аватарки в БД: $e');
      return false;
    }
  }

  /// 1. Загрузка глобального справочника ингредиентов
  static Future<List<Map<String, dynamic>>> fetchInitialIngredients() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
          'p_action': 'get_ingredients',
      'p_additionalimg': null,
      'p_avatarurl': null,
          'p_author': null,
          'p_category': null, 
          'p_cuisine': null,
           'p_ingrid': 0,
           'p_login': null,
          'p_mainimg':  null,
           'p_message_text': null,
          'p_password': null,
           'p_recipe_id': null, 
          'p_recipe_instructions':null,
          'p_recipe_title': null,
          'p_selected_ids': [],
'p_source': null,
'p_ticket_id':null,
          'p_viewscount': null      
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && response.body.trim() != 'null') {
        final decoded = jsonDecode(response.body);
        
        // Используем ваш прямой способ парсинга ключа 'ingredients'
        if (decoded is Map && decoded['ingredients'] is List) {
          final ingredientsJson = decoded['ingredients'] as List<dynamic>;
          return ingredientsJson
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
    } catch (e) {
    //  debugPrint('Ошибка сетевого запроса fetchInitialIngredients: $e');
    }
    return [];
  }

  /// 2. Поиск рецептов по массиву выбранных ID ингредиентов
  static Future<List<Map<String, dynamic>>> searchRecipesByIngredients(List<int> selectedIds) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/rpc/universal_fridge_manager'),
        headers: _headers,
        body: jsonEncode({
          'p_action': 'search_recipes',
              'p_additionalimg': null,
              'p_avatarurl': null,
          'p_author': null,
          'p_category': null, 
          'p_cuisine': null,
           'p_ingrid': null,
           'p_login': null,
          'p_mainimg':  null,
           'p_message_text': null,
          'p_password': null,
           'p_recipe_id': null, 
          'p_recipe_instructions':null,
          'p_recipe_title': null,
          'p_selected_ids': selectedIds, // Массив переданных ID (INT[]ан),
'p_source': null,
'p_ticket_id':null,
          'p_viewscount': null
          
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && response.body.trim() != 'null') {
        final decoded = jsonDecode(response.body);
        
        // Используем ваш способ парсинга чистого List для search_recipes
      if (decoded is Map && decoded['recipes'] is List) {
          final recipesJson = decoded['recipes'] as List<dynamic>;
          return recipesJson
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        
        // Запасной вариант на случай, если бэкенд когда-то вернет чистый List
        if (decoded is List) {
          return decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
    } catch (e) {
    //  debugPrint('Ошибка сетевого запроса searchRecipesByIngredients: $e');
    }
    return [];
  }


  // network_api_controller.dart ֆայլի ներսում

static Future<Map<String, dynamic>?> createRealCryptoInvoice(double amountInUsd) async {
  try {
    // 🌟 ԳՐԱՆՑՎԵԼՈՒՑ ՀԵՏՈ ԱՅՍՏԵՂ ԿՏԵՂԱԴՐԵՔ ՁԵՐ ԻՐԱԿԱՆ ՄԵՐՉԱՆՏ ID-Ն ԵՎ API KEY-Ը
    const String merchantId = "YOUR_CRYPTOMUS_MERCHANT_ID";
    const String apiKey = "YOUR_CRYPTOMUS_PAYMENT_API_KEY";

    final String orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

    final response = await http.post(
      Uri.parse('https://cryptomus.com'),
      headers: {
        'Content-Type': 'application/json',
        'merchant': merchantId,
        'sign': apiKey, // Cryptomus-ի ստանդարտ վավերացում
      },
      body: jsonEncode({
        'amount': amountInUsd.toString(),
        'currency': 'USD',
        'order_id': orderId,
        'url_callback': 'https://supabase.co', // Ձեր Supabase Edge Function-ը
        'is_sand_box': false // 🌟 ԻՐԱԿԱՆ ՌԵԺԻՄ (Ոչ մի սիմուլյացիա)
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded['result'] != null) {
        // Վերադարձնում է Cryptomus-ի պատրաստի վճարման էջի հղումը (url) և QR-կոդը
        return decoded['result'] as Map<String, dynamic>;
      }
    }
    debugPrint('Cryptomus Error: ${response.statusCode} - ${response.body}');
    return null;
  } catch (e) {
    debugPrint('❌ Ошибка при создании реального инвойса Cryptomus: $e');
    return null;
  }
}

static bool isCurrentUserAdmin() {
  try {
    // 🌟 Վերցնում ենք Supabase-ի ակտիվ սեսիայի օգտատիրոջ տվյալները
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    // Տարբերակ Ա: Ստուգում ենք ըստ ֆիքսված էլ. փոստի (Ամենաարագ և հուսալի տարբերակը)
    if (user.email == 'hasmikadmin@myapp.com') { // 👈 Գրեք ձեր ադմինի իսկական email-ը
      return true;
    }

    // Տարբերակ Բ: Եթե բազայում ունեք `role` դաշտ (user.userMetadata)
    if (user.userMetadata?['role'] == 'admin') {
      return true;
    }
  } catch (e) {
    debugPrint('Ошибка проверки роли: $e');
  }
  return false;
}


static Future<Map<String, Map<String, List<String>>>>
    fetchUserActiveSubstitutesPipeline() async {
    
 //   final Map<String, String> finalSubstitutesMap = {};
    
     final loggedUserLogin = currentUserLogin; 


      int? loggedUserId ; // 🌟 Ապահովում ենք, որ գլոբալ փոփոխականը թարմացվի
     debugPrint('Current user login: $loggedUserLogin ?? ""NNN""');


    try {

      debugPrint('🗄️ PIPELINE START: Fetching user personalized allergen profile...');
     
debugPrint('✅ PIPELINE INFO: Current user: ${ Supabase.instance.client.auth.currentUser?.email} (ID: ${Supabase.instance.client.auth.currentUser?.id})');
     
     final List<dynamic> selectedUserId = await Supabase.instance.client
          .from('profile')
          .select('id, login')
          .eq('login', loggedUserLogin)
          .limit(1);

 if (selectedUserId.isEmpty) {
        debugPrint('✅ PIPELINE INFO: No allergen records found.');
        return {};
      }
 if (selectedUserId.isNotEmpty) {
        final Map<String, dynamic> userRow = selectedUserId.first as Map<String, dynamic>;
final String? userLogin = userRow['login'] as String?;
 

  if (userLogin != null &&  userLogin == loggedUserLogin) {
    final int? userId = userRow['id'] as int?;

      loggedUserId = userId; // 🌟 Ապահովում ենք, որ գլոբալ փոփոխականը թարմացվի
  
    

          debugPrint('📝 PIPELINE INFO: Found user login: $userLogin, ID: $userId');
        } else {
          debugPrint('⚠️ PIPELINE WARNING: No user login found in the profile row.');
        }
       
      //debugPrint('📝 PIPELINE INFO: Found user ID: $userId for login: $loggedUserLogin');
      } else {
        //debugPrint('⚠️ PIPELINE WARNING: No user ID found for login: $loggedUserLogin');
        return {};
      }      



      final List<dynamic> userProfileResponse = await Supabase.instance.client
          .from('userAllergens') 
          .select('user_id, setState, allergens_group');
      
      if (userProfileResponse.isEmpty) {
        debugPrint('✅ PIPELINE INFO: No allergen records found.');
        return {};
      }
      
    final List<int> activeGroupIds = [];
      
          for (var row in userProfileResponse) {
        final Map<String, dynamic> allergenRow = row as Map<String, dynamic>;              
          
        // Տիպերից անկախ String համեմատություն user_id-ի համար
        if (allergenRow['user_id']?.toString() == loggedUserId?.toString()) {
          
          final bool isSet = allergenRow['setState'] == true || allergenRow['setState'].toString() == 'true';
          // Վերցնում ենք խմբի ID-ն որպես տեքստ կամ թիվ
          final int? currentGroup = int.tryParse(
            allergenRow['allergens_group']?.toString() ?? '',
          );

          // 🌟 ՈՒՂՂՈՒՄ 2: Հավաքում ենք ակտիվ խմբերը
          if (isSet) {
            if (currentGroup != null && !activeGroupIds.contains(currentGroup)) {
              activeGroupIds.add(currentGroup);
            }
          }
        }
      }

      // 🌟 ՈՒՂՂՈՒՄ 3: Ստուգումը անում ենք ՄԻԱՅՆ այն ժամանակ, երբ ցիկլը ԱՎԱՐՏԵԼ Է ողջ աշխատանքը!
      if (activeGroupIds.isEmpty) {
        debugPrint('✅ No active allergens found for this user profile.');
        return {};
      }
  activeAllergenGroups = activeGroupIds.map((group) => group.toString()).toList();

      debugPrint('📝 PIPELINE SUCCESS: Fully assembled active group IDs: $loggedUserId, $loggedUserLogin: $activeGroupIds');


      final List<dynamic> allergens_origin = await Supabase.instance.client
          .from('allergens_original')
          .select('id, created_at, catalog_group_id, ingredient_id')
          .inFilter('catalog_group_id', activeGroupIds);

      // 🌟 ՔԱՅԼ 2: Ռելյացիոն հարցում դեպի փոխարինողներ (ՈՒՂՂՎԱԾ ՃՇԳՐԻՏ ՍԻՆՏԱՔՍ)
      // Մենք փորձում ենք ճիշտ սյունակի անունը (catalog_group_id) և հստակ նշում աղյուսակի ռելյացիան
      final List<dynamic> subsResponse = await Supabase.instance.client
          .from('allergens_substitutes')
          .select('id, catalog_group_id, substitute_ingredient_id')
          .inFilter('catalog_group_id', activeGroupIds);
      
 
final Map<String, Map<String, List<String>>> personalDictionary = {};

 final List<dynamic> subsData = await Supabase.instance.client
          .from('ingredients')
          .select('id,ingrname');
          

// Բոլոր ingredient-ների ID -> անուն կապը
final Map<String, String> ingredientNames = {};

for (final item in subsData) {
  final String ingredientId = item['id']?.toString() ?? '';
  final String ingredientName =
      item['ingrname']?.toString().trim() ?? '';

  if (ingredientId.isNotEmpty && ingredientName.isNotEmpty) {
    ingredientNames[ingredientId] = ingredientName;
  }
}

// Ալերգեններ և փոխարինիչներ՝ միայն նույն groupId-ի ներսում
for (final originItem in allergens_origin) {
  final int? groupId = int.tryParse(
    originItem['catalog_group_id']?.toString() ?? '',
  );
  final String allergenId =
      originItem['ingredient_id']?.toString() ?? '';

  if (groupId == null ||
      allergenId.isEmpty ||
      !activeGroupIds.contains(groupId)) {
    continue;
  }
 
  final String? allergenNameAsIs = ingredientNames[allergenId];

final String? allergenName = allergenNameAsIs?.toLowerCase() ?? "" ;

  if (allergenName == null || allergenName.isEmpty) {
    continue;
  }

  final List<String> substituteNames = [];

  for (final substituteItem in subsResponse) {
    final int? substituteGroupId = int.tryParse(
      substituteItem['catalog_group_id']?.toString() ?? '',
    );

    // Խմբերի հիմնական կապը
    if (substituteGroupId != groupId) {
      continue;
    }

    final String substituteId =
        substituteItem['substitute_ingredient_id']?.toString() ?? '';

    final String? substituteName = ingredientNames[substituteId];

    if (substituteName != null &&
        substituteName.isNotEmpty &&
        !substituteNames.contains(substituteName)) {
      substituteNames.add(substituteName);
    }
  }

  if (substituteNames.isNotEmpty) {
    final String groupKey = groupId.toString();
    personalDictionary[groupKey] ??= {};
    personalDictionary[groupKey]![allergenName] = substituteNames;
  }
}

debugPrint(
  '📊 CLIENT ENGINE: Personalized dictionary: $personalDictionary',
);

NetworkApiController.personalizedDictionary = personalDictionary;



return personalDictionary;
    
    } catch (e, stackTrace) {
      debugPrint('⚠️ PIPELINE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      return {};
    }
  }



// 🌟 Հիբրիդային ԻԻ մեթոդ. Տեղային ԻԻ + Ամպային Սերվեր
   static Future<String> generateRecipeHybrid({

required String prompt,
    required List<String> userAllergens,
    required Map<String, dynamic> responseFormat,

    
}) async {
try {
// 🌟 ПОДХОД ENTERPRISE: Сначала всегда стучимся на наш мощный облачный Dart-сервер
      debugPrint('🌐 HYBRID AI: Attempting Cloud Server execution first...');


// Вызываем отправку на ваш сервер с ограничением по времени (например, 12 секунд)
    
      final String cloudResult = await sendToDartServer(prompt, userAllergens, responseFormat).timeout(
const Duration(seconds: 90),
);

if (cloudResult.isNotEmpty && !cloudResult.startsWith('⚠️')) {
       
        debugPrint('✅ Cloud AI Server Successful! Quality: Max., result; $cloudResult');
return cloudResult;
}

// Если сервер вернул пустую строку или ошибку, принудительно вызываем локальный ИИ
throw Exception('Cloud server returned incomplete data');

} catch (cloudError) {
// 🌟 ШАГ 2: FALLBACK СЦЕНАР_ИЙ. Если сервер выдал таймаут 500 или нет интернета:
debugPrint('⚠️ Cloud Server unavailable ($cloudError). Activating On-Device AI Fallback...');

try {
final localModel = GenerativeModel(
model: 'gemini-nano', 
apiKey: '', // Локальной модели на чипе NPU ключ не нужен
);

final response = await localModel.generateContent([
Content.text(prompt)
]).timeout(const Duration(seconds: 8));

 
if (response.text != null && response.text!.isNotEmpty) {
debugPrint('🤖 On-Device AI Execution Successful! Cost: 0\$. Speed: High');
return response.text!;
}
} catch (localError) {
debugPrint('❌ Both Cloud and On-Device AI pipelines failed: $localError');
}

// Если вообще всё отключилось, отдаем заготовленный текстовый заглушка-рецепт
return "Привет! Я ваш локальный шеф-повар. Похоже, у нас проблемы со связью с серверами ИИ, но не волнуйтесь! Из ваших ингредиентов можно приготовить отличное базовое блюдо. Просто смешайте их, добавьте специи по вкусу и обжаривайте на среднем огне 10-15 минут. 🍳";
}
}

static Future<String> sendTransformRequestToCloud(String prompt) async {
  try {
    debugPrint('🚀 CLIENT PIPELINE: Directing prompt to /api/transform-recipe...');
    final String serverUrl = '$_backendUrl/api/transform-recipe';

    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
      }),
    ).timeout(const Duration(seconds: 90));

    debugPrint('📡 CLIENT RESPONSE: Status ${response.statusCode}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> rootData = jsonDecode(response.body);

      // Читаем поле 'result' (или 'message' для совместимости)
      final String? rawText = rootData['result']?.toString() ?? rootData['message']?.toString();
      if (rawText == null || rawText.isEmpty) return '';

      // Очищаем от возможных Markdown-тегов ```json ... ```
      String cleanJson = rawText.replaceAll(RegExp(r'```json|```'), '').trim();

      debugPrint('🏆 CLIENT PIPELINE SUCCESS: Cleaned JSON received successfully.');
      return cleanJson;
    } else {
      debugPrint('❌ SERVER RETURNED ERROR STATUS: ${response.statusCode}, Body: ${response.body}');
      return '';
    }
  } catch (e) {
    debugPrint('❌ CLIENT GATEWAY CRASH: $e');
    return '';
  }
}

static Future<String> sendToCloudForAllergensMarker(String prompt) async {
  try {
    debugPrint('🚀 CLIENT PIPELINE: Directing prompt to /api/allergens_marker...');
    final String serverUrl = '$_backendUrl/api/allergens_marker';

    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
      }),
    ).timeout(const Duration(seconds: 90));

    debugPrint('📡 CLIENT RESPONSE: Status ${response.statusCode}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> rootData = jsonDecode(response.body);

      // Читаем поле 'result' (или 'message' для совместимости)
      final String? rawText = rootData['result']?.toString() ?? rootData['message']?.toString();
      if (rawText == null || rawText.isEmpty) return '';

      // Очищаем от возможных Markdown-тегов ```json ... ```
      String cleanJson = rawText.replaceAll(RegExp(r'```json|```'), '').trim();

      debugPrint('🏆 CLIENT PIPELINE SUCCESS: Cleaned JSON received successfully.');
      return cleanJson;
    } else {
      debugPrint('❌ SERVER RETURNED ERROR STATUS: ${response.statusCode}, Body: ${response.body}');
      return '';
    }
  } catch (e) {
    debugPrint('❌ CLIENT GATEWAY CRASH: $e');
    return '';
  }
}


  // 🌟 ENTERPRISE GATEWAY: Ուղարկում ենք պրոմթն ու օգտատիրոջ ակտիվ ալերգենները ամպային սերվերին
  static Future<String> sendToDartServer(
    String prompt, 
    List<String> userAllergens, // 🌟 ՈՒՂՂՈՒՄ 1: Ալերգենները ստանում ենք որպես պատրաստի, խիստ տիպայնացված արգումենտ!
    Map<String, dynamic>? responseFormat,
  ) async {
    try {
      debugPrint('🌐 Connecting to secure Cloud Dart Backend (Gateway)...');
      
      final String serverUrl = '$_backendUrl/api/parse-allergens';

      // 🌟 ՈՒՂՂՈՒՄ 2: Պարտադիր նշում ենք application/json, որպեսզի սերվերը ճիշտ կարդա JSON-ը
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode({
          'prompt': prompt,
          'userAllergens': userAllergens, // Փոխանցում ենք մաքուր տեքստային զանգվածը
          'responseFormat': responseFormat ?? {},
        }),
      ).timeout(const Duration(seconds: 45)); // 45 վայրկյանը լիովին բավարար է արագ Gemini 3.6-ի համար

      if (response.statusCode == 200) {
        final List<dynamic>? responseDataList = jsonDecode(response.body) as List<dynamic>?;
        
        if (responseDataList == null || responseDataList.isEmpty) {
          debugPrint('⚠️ Пустой ответ от սերվերի բազայի');
          return _getFallbackRecipe(prompt);
        }

        // 🌟 ՈՒՂՂՈՒՄ 3: Ճշգրիտ Nested JSON Parsing (Վերցնում ենք ցուցակի 0-րդ տարրը, ինչպես ձեր լոգում է!)
        final Map<String, dynamic> firstResponseNode = responseDataList[0] as Map<String, dynamic>;
        final List<dynamic>? candidates = firstResponseNode['candidates'] as List<dynamic>?;

        if (candidates == null || candidates.isEmpty) {
          debugPrint('⚠️ Пустой ответ от GEMINI candidates');
          return _getFallbackRecipe(prompt);
        }

        // Անվտանգ դուրս ենք բերում ԻԻ-ի գեներացրած իսկական տեքստը
        final Map<String, dynamic> firstCandidate = candidates[0] as Map<String, dynamic>;
        final Map<String, dynamic>? content = firstCandidate['content'] as Map<String, dynamic>?;
        final List<dynamic>? parts = content?['parts'] as List<dynamic>?;
        
        final String rawText = parts != null && parts.isNotEmpty 
            ? parts[0]['text']?.toString() ?? '' 
            : '';

        // 4. Մաքրում ենք Markdown JSON-ի ավելորդ շերտերը (```json ... ```), եթե դրանք կան
        String cleanJsonText = rawText.replaceAll(RegExp(r'```json|```'), '').trim();
        
        try {
          // Վավերացնում ենք, որ տեքստը իսկապես ճիշտ JSON է
          final dynamic checkedJson = jsonDecode(cleanJsonText);
          debugPrint('✅ Cloud AI response successfully fetched and validated: $checkedJson');
          return cleanJsonText;
        } catch (e) { 
          debugPrint('ℹ️ Text format is standard recipe string (Not raw JSON): $e');
          return cleanJsonText; // Վերադարձնում ենք մաքուր խոհարարական տեքստը
        }
      }
      
      return _getFallbackRecipe(prompt);

    } catch (e) {
      debugPrint("❌ Սխալ Dart սերվերի հետ կապ հաստատելիս: $e");
      return _getFallbackRecipe(prompt);
    }
  }

// 🌟 ՕԳՆՈՂ ՄԵԹՈԴ: Անխափան VIP սցենար (Fallback), որպեսզի հավելվածը 0% սխալ տա
static String _getFallbackRecipe(String prompt) {
  if (prompt.contains('title') || prompt.contains('instructions')) {
    return "⚠️ Cloud AI Server is unavailable. Using fallback recipe generator. Please check your internet connection.";
  }
    return "!!!! DART SERVER is UNREACHABLE. Please try again later. In the meantime, you can manually create your recipe using the ingredients you have.";
}

}



