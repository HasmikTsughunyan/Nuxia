import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../network/network_api_controller.dart';
import 'dart:convert';
//import 'package:google_generative_ai/google_generative_ai.dart';
//import 'package:http/http.dart' as http;
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/foundation.dart';
//import 'package:dotenv/dotenv.dart';
//import 'package:shelf/shelf.dart';
//import 'package:shelf/shelf_io.dart' as io;
//import 'package:shelf_router/shelf_router.dart';





class AiChefPage extends StatefulWidget {
  // ИСПРАВЛЕНО: Конструктор теперь строго соответствует camelCase синтаксису Dart
  final String recipeTitle;       
  final String originalRecipe;    
 final List<String> userAllergensGroups; // 🌟 ԱՎԵԼԱՑՎԱԾ Է. Օգտատիրոջ ալերգենների ցուցակը

  const AiChefPage({
    super.key,
    required this.recipeTitle,
    required this.originalRecipe,
    required this.userAllergensGroups, // 🌟 ԱՎԵԼԱՑՎԱԾ Է. Օգտատիրոջ ալերգենների ցուցակը
  });


  @override
  State<AiChefPage> createState() => _AiChefPageState();
}



class _AiChefPageState extends State<AiChefPage> {
  bool _isAiGenerating = false;
  bool isLocalAnalyzing = false;
  String _generatedResultText = '';
  
  // 🌟 Տվյալների բազայի գլոբալ քարտեզը
  Map<String, String> _globalSubstitutesDictionary = {};
static  List<String> _detectedAllergensInText = [];
  String _visualAnalysisNotes = '';

  // Состояние загрузки и результат от ИИ
bool _isTransforming = false;
Map<String, dynamic>? _adaptedRecipeResult;
String? _transformError;


  @override
  void initState() {
    
    super.initState();
    _generatedResultText = widget.originalRecipe;
    _runLocalTextAnalysis(); // 🌟 Ակնթարթորեն գործարկում ենք տեքստի սկանավորումը!
  }

  // 🌟 ՔԱՅԼ 1 և 2: Տեքստի ավտոմատ սկանավորում և ալերգենների հայտնաբերում


Widget _buildHighlightedRecipeText(String fullText) {
  if (_detectedAllergensInText.isEmpty) {
    return Text(fullText, style: const TextStyle(fontSize: 14, height: 1.5));
  }
     


  List<TextSpan> spans = [];

  // Словарь паттернов для армянского языка
  final Map<String, String> dynamicExceptions = {
         'ձու':   r'ձու|ձվ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
      'միս': r'միս|մս(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
 'ջուր': r'ջուր|ջր(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
 'յուղ': r'յուղ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  // Группа 2
  'կաթ': r'կաթ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'հաց': r'հաց(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'աղ': r'աղ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'թեյ': r'թեյ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'սոխ': r'սոխ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
'սեխ':   r'սեխ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
 'սունկ': r'սունկ|սնկ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'ձուկ': r'ձուկ|ձկ(?:ան|անը|նից|նով|ներ|ների)?ն?',
  'թուզ': r'թուզ|թզ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'նուշ': r'նուշ|նշ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'մեղր': r'մեղր(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'мука': r'мук|муч(?:и|ой|у|е|ной|ная|ное|ные|ным|ному)',
  'Яйцо': r'Яйц|Яйца|яйца|яйц|яиц|яич(?:о|е|у|ам|ами|а|ом|ный|ная|ное|ные|ным|ному)',

  };

  // Выделяем именно слова (буквенные последовательности)
  // \p{L} находит любые буквы (включая армянский алфавит)
  final RegExp wordRegexp = RegExp(r'\p{L}+', unicode: true);
  final Iterable<Match> matches = wordRegexp.allMatches(fullText);

  int lastMatchEnd = 0;

  for (final Match match in matches) {
    // 1. Добавляем обычный текст (пробелы, знаки препинания), который шел ДО слова
    if (match.start > lastMatchEnd) {
      spans.add(TextSpan(
        text: fullText.substring(lastMatchEnd, match.start),
        style: const TextStyle(color: Colors.black87, fontSize: 14),
      ));
    }

    final String word = match.group(0)!;
    final String cleanWord = word.toLowerCase();
    bool isAllergen = false;

    if (cleanWord.length >= 2) {
for (var detectedAllergen in _detectedAllergensInText) {
  final String allergenLower = detectedAllergen.trim().toLowerCase();
  bool isMatch = false;
  String? exceptionPattern;

  // 1. Տրոհում ենք ՏԲ-ից եկած բառակապակցությունը (օրինակ՝ "կովի կաթ" -> ["կովի", "կաթ"])
  final List<String> allergenWords = allergenLower.split(RegExp(r'\s+'));

  // 2. Ամեն մի բառի համար փորձում ենք գտնել Regex բացառություն մեր Map-ից
  for (var dbWord in allergenWords) {
      if (dbWord == detectedAllergen || (dbWord.contains(detectedAllergen) && detectedAllergen.length >= 2)) {
      exceptionPattern = dynamicExceptions[detectedAllergen];
      break;
    }/*
    if (dynamicExceptions.containsKey(dbWord)) {
      exceptionPattern = dynamicExceptions[dbWord]; // Այստեղ dbWord="կաթ"-ի դեպքում կվերցնի ճիշտ Regex-ը
      break;
    }*/
  }

  // 3. Եթե Regex-ը հաջողությամբ գտնվեց (օրինակ՝ կաթի համար), կիրառում ենք այն տեքստի բառի վրա
    // 3. Եթե Regex-ը հաջողությամբ գտնվեց, կատարում ենք ճկուն ստուգում
  if (exceptionPattern != null) {
    // 💡 Հեռացրել ենք ^ և $ նշանները, որպեսզի Regex-ը ճիշտ աշխատի Dart-ում
    isMatch = RegExp(exceptionPattern, caseSensitive: false).hasMatch(cleanWord);
  } else {
    // 4. Եթե Map-ում չկա, կատարում ենք սովորական արմատական ստուգում
    for (var dbWord in allergenWords) {
      if (dbWord.length >= 3) {
        String baseRoot = dbWord;
        if (dbWord.length > 4) {
          baseRoot = dbWord.substring(0, dbWord.length - 1);
        }
        // 💡 Փնտրում ենք, թե արդյոք տեքստի բառը պարունակում է ՏԲ-ի բառի արմատը
        if (cleanWord.contains(baseRoot)) {
          isMatch = true;
          break;
        }
      }
    }
  }


  if (isMatch) {
    isAllergen = true;
    break;
  }
}
      
    }

    // 2. Добавляем само слово (с подсветкой или без)
    if (isAllergen) {
      spans.add(TextSpan(
        text: word,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade100,
          backgroundColor: Colors.pink.withValues(alpha: 0.9),
        ),
      ));
    } else {
      spans.add(TextSpan(
        text: word,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
      ));
    }

    lastMatchEnd = match.end;
  }

  // 3. Добавляем оставшийся хвост текста, если он есть
  if (lastMatchEnd < fullText.length) {
    spans.add(TextSpan(
      text: fullText.substring(lastMatchEnd),
      style: const TextStyle(color: Colors.black87, fontSize: 14),
    ));
  }

  return RichText(
    text: TextSpan(children: spans),
  );
}



    void _runLocalTextAnalysis() async {
    setState(() => isLocalAnalyzing = true);

    // 1. Բեռնում ենք օգտատիրոջ ակտիվ ալերգենների ողջ բազան (126 տող)
    final Map<String, Map<String, List<String>>> rawDictionary = await NetworkApiController.fetchUserActiveSubstitutesPipeline();
    
  final Map<String, String> flattenedDictionary = {};

for (final group in rawDictionary.values) {
  for (final entry in group.entries) {
    final String allergenName = entry.key.trim().toLowerCase();
    final String substitutes = entry.value.join(' | ');

    if (allergenName.isNotEmpty && substitutes.isNotEmpty) {
      flattenedDictionary[allergenName] = substitutes;
    }
  }
}

_globalSubstitutesDictionary = flattenedDictionary;

debugPrint(
  '📊 CLIENT ENGINE: Fetched dictionary = $_globalSubstitutesDictionary',
);

    List<String> found = [];
    String notes = "⚠️ Внимание! В тексте рецепта обнаружены ваши allergic բաղադրիչները:\n";
    final String textToScan = widget.originalRecipe.toLowerCase();

    // 🌟 ԲԱՑԱՌՈՒԹՅՈՒՆՆԵՐԻ ՓՈՔՐԻԿ ՔԱՐՏԵԶ (Միայն այն 5 բառերի համար, որոնց արմատը փոխվում է)
    final Map<String, String> dynamicExceptions = {
      'ձու':   r'ձու|ձվ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
      'միս': r'միս|մս(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
 'ջուր': r'ջուր|ջր(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
 'յուղ': r'յուղ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  // Группа 2
  'կաթ': r'կաթ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'հաց': r'հաց(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'աղ': r'աղ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'թեյ': r'թեյ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'սոխ': r'սոխ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
'սեխ':   r'սեխ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
 'սունկ': r'սունկ|սնկ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'ձուկ': r'ձուկ|ձկ(?:ան|անը|նից|նով|ներ|ների)?ն?',
  'թուզ': r'թուզ|թզ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'նուշ': r'նուշ|նշ(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'մեղր': r'մեղր(?:ի|ից|ով|ում|եր|երով|երի|երից)?ն?',
  'мука': r'мук|муч(?:и|ой|у|е|ной|ная|ное|ные|ным|ному)',
  'яйца': r'яйц|яиц|яич(?:о|е|у|ам|ами|а|ом|ный|ная|ное|ные|ным|ному)',
  // 'ալյուր': r'(ալյուր|ալրով|ալրից|ալյուրը)',
   //'սերուցք': r'(սերուցք|սերուցքով|սլիվկի)',
       };

     //  final finalRegexPattern = allProductPatterns.join('|');

    // 2. 🌟 ԱՎՏՈՄԱՏ ՑԻԿԼ 126 ԲԱՌԻ ՀԱՄԱՐ
    _globalSubstitutesDictionary.forEach((allergenClean, substitute) {
      bool matchFound = false;

      // Ստուգում ենք՝ արդյոք բառը բացառությունների մեջ է
      String? exceptionPattern = dynamicExceptions[allergenClean];
      
      if (exceptionPattern != null) {
        // Եթե բարդ բառ է (օր. ձու), օգտագործում ենք հատուկ RegExp կաղապարը
        if (RegExp(exceptionPattern, caseSensitive: false).hasMatch(textToScan)) {
          matchFound = true;
          debugPrint ('found words are: $matchFound');
        }
      } else {
        // 🌟 ԱՎՏՈՄԱՏ ԱՐՄԱՏԱԿԱՆ ՈՐՈՆՈՒՄ ՄՆԱՑԱԾ 120 ԲԱՌԵՐԻ ՀԱՄԱՐ
        // Հեռացնում ենք վերջին 1 տառը միայն այն դեպքում, եթե բառը երկար է (ելակ ➔ ելա)
        String baseRoot = allergenClean;
        
        if (allergenClean.length > 4) {
          baseRoot = allergenClean.substring(0, allergenClean.length - 1);
        }

        

        // Dart-ի \b և \w նշանները Unicode բառերի համար հուսալի չեն։
        const String wordCharacters = r'A-Za-zА-Яа-яЁёԱ-Ֆա-ֆ0-9_';
        final RegExp autoRegExp = RegExp(
          
          r'(?:^|[^' + wordCharacters + r'])' +
              RegExp.escape(baseRoot) +
              r'[' + wordCharacters + r']*(?:$|[^' + wordCharacters + r'])',
          caseSensitive: false,
        );

    
        
        matchFound = autoRegExp.hasMatch(textToScan);

        debugPrint(//  'Pattern: ${autoRegExp.pattern}, '
  //'Text: $textToScan, '
  'Found: ${autoRegExp.hasMatch(textToScan)}',
);
      }


      if (matchFound) {
        found.add(allergenClean);
        String formattedName = allergenClean.toUpperCase().substring(0, 1) + allergenClean.substring(1);
        notes += "• $formattedName ➔ Рекомендуем заменить на: $substitute\n";
      }
    });

    if (mounted) {
      setState(() {
        _detectedAllergensInText = found;
        _visualAnalysisNotes = found.isNotEmpty 
            ? notes 
            : "✅ Рецепт полностью безопасен. Из вашего активного профиля аллергенов ничего не обнаружено.";
        isLocalAnalyzing = false;
      });
    }
  }


static String geminiAnswer = '';

Future<void> _transformRecipeWithAI() async {
  final String rcpTitle = widget.recipeTitle ;
  final String rcpOriginalRecipe = widget.originalRecipe ;

  // 1. Формируем список аллергенов строго в формате: ALLERGEN: $allergen
  String allergensPrompt = "";
  for (var allergen in _detectedAllergensInText) {
    allergensPrompt += "ALLERGEN: $allergen\n";
  }

  if (allergensPrompt.trim().isEmpty) {
    allergensPrompt = "NONE";
  }

  setState(() {
    _isTransforming = true;
    _transformError = null;
  });

  try {
    // 2. Формируем промпт
    final String prompt = '''
Вы профессиональный шеф-повар и эксперт по пищевым аллергиям.
Адаптируйте рецепт, полностью исключив указанные аллергены и подобрав для них идеальные безопасные кулинарные замены с сохранением текстуры, влажности и вкуса.

НАЗВАНИЕ РЕЦЕПТА:
$rcpTitle

ИСХОДНЫЙ ТЕКСТ РЕЦЕПТА:
$rcpOriginalRecipe

СПИСОК АЛЛЕРГЕНОВ, КОТОРЫЕ НЕОБХОДИМО ИСКЛЮЧИТЬ И ЗАМЕНИТЬ:
$allergensPrompt

ВЕРНИТЕ РЕЗУЛЬТАТ СТРОГО В ВИДЕ JSON:
{
  "adaptedTitle": "Новое название с учетом замен",
  "substitutions": [
    {
      "originalAllergen": "название исходного аллергена",
      "substitute": "на что заменено и точная пропорция",
      "reasoning": "кулинарное обоснование замены"
    }
  ],
  "fullAdaptedRecipeText": "Полный связный текст адаптированного рецепта с ингредиентами и инструкцией",
  "chefTips": "Советы шефа по выпечке с этими заменами"
}
''';

    // 3. Отправляем запрос на сервер через контроллер (ЕДИНСТВЕННЫЙ вызов!)
    final String responseText = await NetworkApiController.sendTransformRequestToCloud(prompt);

    if (responseText.isNotEmpty) {
      final Map<String, dynamic> data = jsonDecode(responseText);
      setState(() {
        _adaptedRecipeResult = data;
        _isTransforming = false;
      });
    } else {
      throw Exception("Сервер вернул пустой ответ. Проверьте консоль сервера.");
    }
  } catch (e) {
    setState(() {
      _transformError = "Ошибка: $e";
      _isTransforming = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ошибка трансформации: $e'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}


Future<void> AllergensMarkerWithAI() async {
  final String rcpTitle = widget.recipeTitle ;
  final String rcpOriginalRecipe = widget.originalRecipe ;

  // 1. Формируем список аллергенов строго в формате: ALLERGEN: $allergen
  String allergensPrompt = "";
  for (var allergen in _detectedAllergensInText) {
    allergensPrompt += "ALLERGEN: $allergen\n";
  }

  if (allergensPrompt.trim().isEmpty) {
    allergensPrompt = "NONE";
  }

  setState(() {
    _isTransforming = true;
    _transformError = null;
  });

  try {
    // 2. Формируем промпт
    final String prompt = '''
Вы профессиональный шеф-повар и эксперт по пищевым аллергиям.
Найдите в тексте все аллергены, которые переданы, и покчеркните их розовым цветом, как маркером. 

НАЗВАНИЕ РЕЦЕПТА:
$rcpTitle

ИСХОДНЫЙ ТЕКСТ РЕЦЕПТА:
$rcpOriginalRecipe

СПИСОК АЛЛЕРГЕНОВ, КОТОРЫЕ НЕОБХОДИМО ИСКЛЮЧИТЬ И ЗАМЕНИТЬ:
$allergensPrompt

ВЕРНИТЕ РЕЗУЛЬТАТ СТРОГО В ВИДЕ JSON:
{
  "titleWithMarkedAllergens": "Название рецепта",
  "substitutions": [
    {
      "originalAllergen": "название исходного аллергена"
    }
  ],
  "fullRecipeTextWithMarked": "Полный текст рецепта с ингредиентами и инструкцией",
  "chefTips": "Советы шефа по выпечке с этими заменами"
}
''';

    // 3. Отправляем запрос на сервер через контроллер (ЕДИНСТВЕННЫЙ вызов!)
    final String responseText = await NetworkApiController.sendToCloudForAllergensMarker(prompt);

    if (responseText.isNotEmpty) {
      final Map<String, dynamic> data = jsonDecode(responseText);
      setState(() {
        _adaptedRecipeResult = data;
        _isTransforming = false;
      });
    } else {
      throw Exception("Сервер вернул пустой ответ. Проверьте консоль сервера.");
    }
  } catch (e) {
    setState(() {
      _transformError = "Ошибка: $e";
      _isTransforming = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ошибка трансформации: $e'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}
/*

void _transformRecipeWithAi() async {
  setState(() => _isAiGenerating = true);

  try {
    String strictRules = "";
    for (var allergen in _detectedAllergensInText) {
      final String? substitute = _globalSubstitutesDictionary[allergen];
      if (substitute != null) {
        strictRules += "ALLERGEN: $allergen -> SUBSTITUTE: $substitute\n";
      }
    }

    if (strictRules.isEmpty) {
      strictRules = "NONE";
    }

    final String currentLang = Localizations.localeOf(context).languageCode;


    // Определяем JSON Schema (OpenAI / Gemini compatible format)
    final Map<String, dynamic> jsonSchema = {
      "type": "object",
      "properties": {
        "title": {
          "type": "STRING",
          "description": "Translated and adapted recipe title"
        },
        "ingredients": {
          "type": "STRING",
          "description": "List of all ingredients with quantities and required substitutions"
        },
        "instructions": {
          "type": "STRING",
          //"items": {"type": "STRING"},
          "description": "Step-by-step cooking instructions"
        },
    /*    "chef_tips": {
          "type": ["STRING"],
          "description": "Optional culinary tips regarding the substitutions"
        }*/
      },
      "required": ["title", "ingredients", "instructions"],
     // "additionalProperties": false
    };

final String? rcpTitle = widget.recipeTitle;
final String? rcpOriginalRecipe = widget.originalRecipe;


final String advancedPrompt = """
You are a professional Culinary AI specialized in recipe adaptation for dietary restrictions.
Your task is to rewrite the recipe under title: $rcpTitle using the ORIGINAL recipe: $rcpOriginalRecipe as the primary source and applying the strict replacement rules:
$strictRules.
Replace every specified allergen strictly with its mandatory substitute.
Do not invent unrelated ingredients.
Translate everything (title, ingredients, instructions) to target language code: $currentLang.
If useful, provide 1-2 chef tips specifically about cooking with these substitutions in the 'chef_tips' field. Otherwise leave it null.
Send one recipe with changes. 
""";
//Put answer or the rewritten copy of recipe in $geminiAnswer .
// ai_chef_page.dart-ի ներսում _transformRecipeWithAi() մեթոդի 3-րդ կետը.

    // 3. 🌟 🏆 ԿՈՒԼՄԻՆԱՑԻԱ: Կանչում ենք ուղիղ տրանսֆորմացիայի նոր մաքուր մեթոդը!
    final String rawJsonResponse = await NetworkApiController.sendTransformRequestToCloud(
      advancedPrompt,
      //responseFormat,        
      
    );


    // 4. Безопасный парсинг ответа
    final Map<String, dynamic> decodedJson = jsonDecode(rawJsonResponse);
    final adaptedRecipe = AdaptedRecipe.fromJson(decodedJson);
    debugPrint ('the answer from gemini is $decodedJson and  $adaptedRecipe');

    if (mounted) {
      setState(() {
        //_isAiGenerating = false;
        // Теперь у вас есть строго типизированный объект adaptedRecipe!
        // Вы можете отрендерить его красивыми виджетами (ListView, Checkbox и т.д.)

        _generatedResultText = _formatRecipeForDisplay(adaptedRecipe);
      });
    } else {
      
      print(geminiAnswer);
      
      };

  } catch (e) {
    if (mounted) {
      setState(() {
        _isAiGenerating = false;
        _generatedResultText = "⚠️ Ошибка трансформации: $e";
      });
    }
  }
}

// Вспомогательный метод форматирования (если нужен просто текст для отображения)
String _formatRecipeForDisplay(AdaptedRecipe recipe) {
  final buffer = StringBuffer();
  buffer.writeln("📖 ${recipe.title}\n");
  buffer.writeln("🛒 Ингредиенты:");
  for (var item in recipe.ingredients) {
    buffer.writeln("• $item");
  }
  buffer.writeln("\n👩‍🍳 Инструкция:");
  for (var i = 0; i < recipe.instructions.length; i++) {
    buffer.writeln("${i + 1}. ${recipe.instructions[i]}");
  }
 /* if (recipe.chefTips != null && recipe.chefTips!.isNotEmpty) {
    buffer.writeln("\n💡 Совет шеф-повара:\n${recipe.chefTips}");
  }*/
  return buffer.toString();
}
*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipeTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            
                        children: [
              // 🌟 ՔԱՅԼ 3: Ցուցադրում ենք բազայի LIVE վերլուծությունը (UI Breakdown)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _detectedAllergensInText.isNotEmpty 
                      ? Colors.red.withValues(alpha: 0.05) 
                      : Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _detectedAllergensInText.isNotEmpty 
                        ? Colors.red.withValues(alpha: 0.2) 
                        : Colors.green.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _visualAnalysisNotes,
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w500, 
                    color: _detectedAllergensInText.isNotEmpty 
                        ? Colors.red.shade900 
                        : Colors.green.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text("📖 Текст рецепта:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              
              // 🌟 ԻՍՊՐԱՎԼԵՆՈ: Սովորական Text-ի փոխարեն կանչում ենք վարդագույն գունավորման մեր խելացի մեթոդը!
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildHighlightedRecipeText(_generatedResultText),
              ),
              const SizedBox(height: 24),

              // Կոճակը, որը գործարկում է ողջ կուլմինացիան
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
  onPressed: _isTransforming ? null : _transformRecipeWithAI,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepOrangeAccent, // Оранжевый цвет как на скриншоте
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (_isTransforming) ...[
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Трансформация через ИИ...',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ] else ...[
        const Icon(Icons.auto_awesome, size: 20),
        const SizedBox(width: 8),
        const Text(
          'Трансформировать рецепт через ИИ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    ],
  ),
)
/*
                  // 🌟 ԿՈՃԱԿԸ ԱՎՏՈՄԱՏ ԿԱԿՏԻՎԱՆԱ, քանի որ ռեգիստրների սխալը լիովին ուղղված է!
                  onPressed: _isAiGenerating || _detectedAllergensInText.isEmpty ? null : _transformRecipeWithAi,
                  icon: _isAiGenerating 
                      ? const SizedBox(
                          width: 18, 
                          height: 18, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, color: Colors.white),
                  label: Text(
                    _isAiGenerating 
                        ? "ИИ обогащает рецепт знаниями..." 
                        : "Трансформировать рецепт через ИИ",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),*/
              ),
                // Если рецепт трансформирован — отображаем карточку с обновленным рецептом
if (_adaptedRecipeResult != null) ...[
  const SizedBox(height: 24),
  Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.green.shade300, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок карточки
        Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _adaptedRecipeResult!['adaptedTitle'] ?? 'Адаптированный рецепт',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14532D),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
              tooltip: 'Скопировать рецепт',
              onPressed: () {
                final fullText = _adaptedRecipeResult!['fullAdaptedRecipeText'] ?? '';
                Clipboard.setData(ClipboardData(text: fullText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Рецепт скопирован в буфер обмена!')),
                );
              },
            ),
          ],
        ),
        const Divider(height: 24),

        // Список сделанных замен
        const Text(
          'Произведенные замены аллергенов:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (_adaptedRecipeResult!['substitutions'] is List)
          ...(_adaptedRecipeResult!['substitutions'] as List).map((sub) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${sub['originalAllergen']}: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${sub['substitute']} (${sub['reasoning'] ?? ''})',
                      style: const TextStyle(color: Color(0xFF7C2D12)),
                    ),
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 16),
        const Text(
          'Обновленный текст рецепта:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        SelectableText(
          _adaptedRecipeResult!['fullAdaptedRecipeText'] ?? '',
          style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF1C1917)),
        ),

        // Советы шефа (если есть)
        if (_adaptedRecipeResult!['chefTips'] != null &&
            _adaptedRecipeResult!['chefTips'].toString().isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Совет шефа: ${_adaptedRecipeResult!['chefTips']}',
                    style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  ),
],
              
            ],
          ),
        ),
      ),
    );
  }

            

}


class AdaptedRecipe {
  final String title;
  final List<String> ingredients;
  final List<String> instructions;
  final String? chefTips;

  AdaptedRecipe({
    required this.title,
    required this.ingredients,
    required this.instructions,
    this.chefTips,
  });

  factory AdaptedRecipe.fromJson(Map<String, dynamic> json) {
    return AdaptedRecipe(
      title: json['title'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      chefTips: json['chef_tips'],
    );
  }
}

