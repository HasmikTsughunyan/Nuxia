import 'package:flutter/material.dart';
import 'ai_chef_service.dart';
import '../../../core/utils/app_localizations.dart';
//import 'package:flutter_localizations/flutter_localizations.dart';
import '../network/network_api_controller.dart';




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
  List<String> _detectedAllergensInText = [];
  String _visualAnalysisNotes = '';

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
    
    // Разделяем текст на слова, сохраняя знаки препинания и пробелы
    final RegExp splitRegExp = RegExp(r'(\s+|,|\.|\!|\?|-|\n)');
    final List<String> parts = fullText.split(splitRegExp);
    
    final Iterable<Match> matches = splitRegExp.allMatches(fullText);
    List<String> separators = matches.map((m) => m.group(0)!).toList();

    // 🌟 СПИСОК РУССКИХ ОКОНЧАНИЙ (Для точечного мэтчинга падежей: мука, муку, мукой)
    const List<String> russianEndings = ['', 'а', 'и', 'у', 'ой', 'е', 'ю', 'я', 'ом', 'ам', 'ами', 'ах', 'ы'];

    for (int i = 0; i < parts.length; i++) {
      final String word = parts[i];
      final String cleanWord = word.trim().toLowerCase();

      bool isAllergen = false;

      if (cleanWord.isNotEmpty && cleanWord.length > 2) {
        for (var detectedAllergen in _detectedAllergensInText) {
          List<String> subWords = detectedAllergen.toLowerCase().split(' ');
          
          for (var subWord in subWords) {
            if (subWord.length <= 2) continue;

            // 1. Выделяем чистую основу слова (отбрасываем последнюю гласную букву у аллергена из базы)
            String baseRoot = subWord;
            if (subWord.endsWith('а') || subWord.endsWith('я') || subWord.endsWith('о') || subWord.endsWith('е') || subWord.endsWith('ы') || subWord.endsWith('и')) {
              baseRoot = subWord.substring(0, subWord.length - 1);
            }

            // 2. 🌟 ПРОВЕРЯЕМ СЛОВО ИЗ РЕЦЕПТА ПО СПИСКУ ОКОНЧАНИЙ
            for (var ending in russianEndings) {
              if (cleanWord == '$baseRoot$ending') {
                isAllergen = true;
                break;
              }
            }
            if (isAllergen) break;
          }
          if (isAllergen) break;
        }
      }

      if (isAllergen) {
        // Подсвечиваем красивым розовым маркером
        spans.add(
          TextSpan(
            text: word,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade100,
              backgroundColor: Colors.pink.withValues(alpha: 0.9),
            ),
          ),
        );
      } else {
        // Обычное слово без изменений
        spans.add(TextSpan(text: word, style: const TextStyle(color: Colors.black87, fontSize: 14)));
      }

      if (i < separators.length) {
        spans.add(TextSpan(text: separators[i], style: const TextStyle(color: Colors.black87, fontSize: 14)));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }





  // 🌟 ИСПРАВЛЕНО: Полная синхронизация регистров букв при локальном сканировании
  void _runLocalTextAnalysis() async {
    setState(() => isLocalAnalyzing = true);

    // 1. Получаем карту из пайплайна
    final Map<String, String> rawDictionary = await NetworkApiController.fetchUserActiveSubstitutesPipeline();

  debugPrint('📊 CLIENT ENGINE: Fetched raw dictionary = $rawDictionary');
    
    // Создаем полностью очищенный нижнерегистровый словарь для работы внутри экрана
    _globalSubstitutesDictionary = rawDictionary.map(
      (key, value) => MapEntry(key.trim().toLowerCase(), value.trim())
    );

  List<String> found = [];
    String notes = "⚠️ Внимание! В тексте рецепта обнаружены ваши аллергены:\n";
    final String textToScan = widget.originalRecipe.toLowerCase();

    // 2. 🌟 УМНОЕ ПОСЛОВЕСНОЕ СКАНИРОВАНИЕ
    _globalSubstitutesDictionary.forEach((allergenClean, substitute) {
      // Разбиваем длинное название аллергена (например, "мука пшеничная") на отдельные слова
      List<String> allergenWords = allergenClean.split(' ');
      
      bool matchFound = false;

      for (var word in allergenWords) {
        // Убираем окончания (берём корень слова, если оно длиннее 3 символов)
        String rootWord = word.length > 3 ? word.substring(0, word.length - 2) : word;

        if (rootWord.isNotEmpty && textToScan.contains(rootWord)) {
          matchFound = true;
          break; // Если хоть одно базовое слово совпало (например, "яйц" или "мук"), фиксируем совпадение
        }
      }

      if (matchFound) {
        found.add(allergenClean);
        // Красиво форматируем вывод для плашки интерфейса
        String formattedName = allergenClean.toUpperCase().substring(0, 1) + allergenClean.substring(1);
        notes += "• $formattedName ➔ Рекомендуем заменить на: $substitute\n";
      }
    });


    if (mounted) {
      setState(() {
        _detectedAllergensInText = found;
        // 🌟 ИСПРАВЛЕНО: Проверяем реальное наличие элементов в массиве found
        _visualAnalysisNotes = found.isNotEmpty 
            ? notes 
            : "✅ Рецепт полностью безопасен. Из вашего активного профиля аллергенов ничего не обнаружено.";
        isLocalAnalyzing = false;
      });
    }
  }

  // 🌟 ИСПРАВЛЕНО: Безопасное извлечение заменителей из очищенного словаря
  void _transformRecipeWithAi() async {
    setState(() => _isAiGenerating = true);

    try {
      String strictRules = "";
      for (var allergen in _detectedAllergensInText) {
        // Теперь поиск по ключу гарантированно вернет значение, так как регистры совпадают!
        final substitute = _globalSubstitutesDictionary[allergen];
        if (substitute != null) {
          strictRules += "- Replace '$allergen' strictly with '$substitute'\n";
        }
      }

      final String currentLang = Localizations.localeOf(context).languageCode;

      final String advancedPrompt = 
          "You are an advanced medical-dietary Culinary AI. Review and rewrite this recipe based on strict local database rules and your domain knowledge.\n\n"
          "Recipe Title: ${widget.recipeTitle}\n"
          "Original Text: ${widget.originalRecipe}\n\n"
          "🔒 STRICT DATABASE REPLACEMENT RULES:\n"
          "$strictRules\n"
          "Target Language: '$currentLang'\n\n"
          "🌟 BONUS INSIGHT REQUIREMENT:\n"
          "1. Rewrite the recipe cleanly using the database substitutes.\n"
          "2. If you possess additional, advanced culinary knowledge regarding these specific substitutes, add a dedicated section at the very end titled '💡 Professional Chef Insights & Tips'.";

      final String aiFinalResponse = await NetworkApiController.generateRecipeHybrid(
        prompt: advancedPrompt,
      );

      if (mounted) {
        setState(() {
          _generatedResultText = aiFinalResponse;
          _isAiGenerating = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isAiGenerating = false;
          _generatedResultText = "⚠️ Ошибка трансформации: $e";
        });
      }
    }
  }

 /*void _runLocalTextAnalysis() async {
    // 🌟 Կանչում ենք մեր նոր 2-await-անի հզոր պայփլայնը
    
    _globalSubstitutesDictionary = await NetworkApiController.fetchUserActiveSubstitutesPipeline();

    List<String> found = [];
    String notes = "⚠️ Внимание! В тексте рецепта обнаружены ваши аллергены:\n";

    final String textToScan = widget.originalRecipe.toLowerCase();
    
    _globalSubstitutesDictionary.forEach((allergenName, substituteName) {
      if (textToScan.contains(allergenName.toLowerCase())) {
        found.add(allergenName);
        notes += "• $allergenName ➔ Рекомендуем заменить на: $substituteName\n";
      }
    });

    setState(() {
      _detectedAllergensInText = found;
      _visualAnalysisNotes = found.isNotEmpty ? notes : "✅ Рецепт полностью безопасен. Ваш профиль аллергенов чист.";
    });
  }

  // 🌟 ՔԱՅԼ 4: ԿՈՒԼՄԻՆԱՑԻԱ. Հարցումը ԻԻ-ին՝ լրացուցիչ գիտելիքի հավելումով
  void _transformRecipeWithAi() async {
    setState(() => _isAiGenerating = true);

    try {
      // Ձևավորում ենք փոխարինման կանոնները խիստ տեքստով
      String strictRules = "";
      for (var allergenName in _detectedAllergensInText) {
        final substituteName = _globalSubstitutesDictionary[allergenName];
        strictRules += "- Replace '$allergenName' strictly with '$substituteName'\n";
      }

      final String currentLang = Localizations.localeOf(context).languageCode;

      // 🏆 ԱՄԵՆԱԽԵԼԱՑԻ ՊՐՈՄԹԸ (PROMPT ENHANCEMENT)
      final String advancedPrompt = 
          "You are an advanced medical-dietary Culinary AI. Review and rewrite this recipe based on strict local database rules and your domain knowledge.\n\n"
          "Recipe Title: ${widget.recipeTitle}\n"
          "Original Text: ${widget.originalRecipe}\n\n"
          "🔒 STRICT DATABASE REPLACEMENT RULES:\n"
          "$strictRules\n"
          "Target Language: '$currentLang'\n\n"
          "🌟 BONUS INSIGHT REQUIREMENT:\n"
          "1. Rewrite the recipe cleanly using the database substitutes.\n"
          "2. If you possess additional, advanced culinary or chemistry knowledge regarding these specific substitutes (e.g., how baking times change, binding properties, or secret allergy-safe enhancements we didn't specify), add a dedicated section at the very end titled '💡 Professional Chef Insights & Tips'.";

      final String aiFinalResponse = await NetworkApiController.generateRecipeHybrid(
        prompt: advancedPrompt,
      );

      setState(() {
        _generatedResultText = aiFinalResponse;
        _isAiGenerating = false;
      });

    } catch (e) {
      setState(() {
        _isAiGenerating = false;
        _generatedResultText = "⚠️ Ошибка трансформации: $e";
      });
    }
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
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, 
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

            
            /*children: [
              // 🌟 ՔԱՅԼ 3: Ցուցադրում ենք բազայից եկած նախնական հուշումը (UI Breakdown)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _detectedAllergensInText.isNotEmpty ? Colors.red.withValues(alpha: 0.05) : Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _detectedAllergensInText.isNotEmpty ? Colors.red.withValues(alpha: 0.05) : Colors.green.withValues(alpha: 0.05)),
                ),
                child: Text(
                  _visualAnalysisNotes,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _detectedAllergensInText.isNotEmpty ? Colors.red.shade900 : Colors.green.shade900),
                ),
              ),
              const SizedBox(height: 20),

              const Text("📖 Текст рецепта:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(_generatedResultText, style: const TextStyle(fontSize: 14, height: 1.5)),
              const SizedBox(height: 24),

              // Կոճակը, որը գործարկում է ողջ կուլմինացիան
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: _isAiGenerating || _detectedAllergensInText.isEmpty ? null : _transformRecipeWithAi,
                  icon: _isAiGenerating 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, color: Colors.white),
                  label: Text(_isAiGenerating ? "ИИ обогащает рецепт знаниями..." : "Трансформировать рецепт через ИИ"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
/*class _AiChefPageState extends State<AiChefPage> {
  // 🌟 1. Ավելացնում ենք ԻԻ-ի սպասման և արդյունքի փոփոխականները
  bool _isAiGenerating = false;
  String _generatedResultText = '';

  @override
  void initState() {
    super.initState();
    // Սկզբնական շրջանում էկրանին ցույց ենք տալիս օրիգինալ ռեցեպտի տեքստը
    _generatedResultText = widget.originalRecipe;
  }

  // 🌟 2. ՄԵԹՈԴ, ՈՐԸ ԿԱՆՉՎՈՒՄ Է ԿՈՃԱԿԸ ՍԵՂՄԵԼԻՍ

    void _generateSafeRecipe() async {

       debugPrint('📊 CLIENT ENGINE: Checking widget.userAllergens data = ${widget.userAllergens}');
      
    setState(() {
      _isAiGenerating = true; // Միացնում ենք պտտվող Loader-ը
    });

    try {
      // 🌟 1. ԿԱԶՄՈՒՄ ԵՆՔ ԽԻՍՏ ՊՐՈՄԹԸ ԻԻ-Ի ՀԱՄԱՐ
      final String currentLang = Localizations.localeOf(context).languageCode;
      
      final String hybridPrompt = 
          "You are a master chef. Translate this recipe to language '$currentLang' and clean it from user allergens.\n"
          "Recipe Title: ${widget.recipeTitle}\n"
          "Original Instructions: ${widget.originalRecipe}\n"
          "User Active Allergens to Remove: ${widget.userAllergens.join(', ')}\n"
          "Respond with the safe, formatted recipe only.";

      // 🌟 2. ԿԱՆՉՈՒՄ ԵՆՔ ՆՈՐ ՀԻԲՐԻԴԱՅԻՆ ՄՈԴՈՒԼԸ (0\$ On-Device AI + Cloud Server Fallback)
      // Այս մեթոդը ավտոմատ կստուգի հեռախոսի NPU չիպը, իսկ եթե չկա՝ կգնա server.dart
      final String result = await NetworkApiController.generateRecipeHybrid(
        prompt: hybridPrompt,
      );

      setState(() {
        _generatedResultText = result;
        _isAiGenerating = false; // Անջատում ենք Loader-ը
      });

    } catch (e) {
      setState(() {
        _isAiGenerating = false;
        _generatedResultText = "⚠️ Не удалось связаться с ИИ-сервером: $e";
      });
    }
  }

 /* void _generateSafeRecipe() async {
    setState(() {
      _isAiGenerating = true;
    });

    try {
      // Կանչում ենք մեր սեփական Dart սերվերի անվտանգ ԻԻ մեթոդը
      final String result = await NetworkApiController.translateAndCleanRecipeViaBackend(
        activeRecipe: {
          'title': widget.recipeTitle,
          'instructions': widget.originalRecipe,
        },
        targetLanguageCode: Localizations.localeOf(context).languageCode,
        // 🌟 ԻՍՊՐԱՎԼԵՆՈ: widget.userAllergens-ը արդեն իսկ List<String> է, ուղղակի փոխանցում ենք!
        activeAllergens: widget.userAllergens, 
      );

      setState(() {
        _generatedResultText = result;
        _isAiGenerating = false;
      });

    } catch (e) {
      setState(() {
        _isAiGenerating = false;
        _generatedResultText = "⚠️ Не удалось связаться с ИИ-сервером: $e";
      });
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipeTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Оригинальный рецепт шефа:",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              
              // 🌟 3. ՑՈՒՑԱԴՐՈՒՄ ԵՆՔ ԱՐԴՅՈՒՆՔԸ ԷԿՐԱՆԻՆ
              Text(
                _generatedResultText,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),

              // 🌟 4. ԿՈՃԱԿԸ, ՈՐԸ ԳՈՐԾԱՐԿՈՒՄ Է ԱՆՎՏԱՆԳ ԻԻ ՄԱՔՐՈՒՄԸ
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _isAiGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.security, color: Colors.white),
                  label: Text(
                    _isAiGenerating ? "ИИ Шеф очищает рецепт..." : "Очистить рецепт от аллергенов через ИИ",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  // Եթե արդեն ընթանում է գեներացիա, կոճակը անջատում ենք
                  onPressed: _isAiGenerating ? null : _generateSafeRecipe,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
}