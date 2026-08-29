import 'package:flutter/material.dart';
import 'ai_chef_service.dart';
import '../../../core/utils/app_localizations.dart';
//import 'package:flutter_localizations/flutter_localizations.dart';
import '../network/network_api_controller.dart';



class AiChefPage extends StatefulWidget {
  // ИСПРАВЛЕНО: Конструктор теперь строго соответствует camelCase синтаксису Dart
  final String recipeTitle;       
  final String originalRecipe;    
  final List<String> userAllergens; 

  const AiChefPage({
    super.key,
    required this.recipeTitle,
    required this.originalRecipe,
    required this.userAllergens,
  });

  @override
  State<AiChefPage> createState() => _AiChefPageState();
}

class _AiChefPageState extends State<AiChefPage> {
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
