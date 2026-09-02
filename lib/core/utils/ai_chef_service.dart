// core/utils/ai_chef_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // Օգտագործում ենք ստանդարտ http փաթեթը



void myDebugPrint(Object? message) {
  stdout.writeln('[DEBUG] $message');
}


class AiChefService {
  // 🌟 ՃՇԳՐԻՏ ՀԱՍՑԵՆ: Նույն հասցեն, ինչ օգտագործում ենք չատի և թարգմանչի համար
  static String get _backendUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/parse-allergens';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/parse-allergens'; // Специальный адрес для Android-эмулятора
    } else {
      return 'http://127.0.0.1:8080/api/parse-allergens'; // iOS эмулятор и Desktop
    }
  }


  static Future<Map<String, dynamic>?> generateRecipeFromFridge({
    required List<String> availableIngredients,
    required List<String> activeAllergens,
  }) async {
    try {
      stdout.writeln('=== AI SECURE PIPELINE: Dispatched Fridge Request to Dart Server ===');

      final String ingredientsText = availableIngredients.isNotEmpty ? availableIngredients.join(', ') : 'Any';
      final String allergensText = activeAllergens.isNotEmpty ? activeAllergens.join(', ') : 'None';

      // 🌟 ԿԱԶՄՈՒՄ ԵՆՔ ԽԻՍՏ JSON ՀՐԱՀԱՆԳ ԳՈՒԳԼԻ ԻԻ-Ի ՀԱՄԱՐ
      final String compoundPrompt = 
          "You are an elite Michelin-star Chef Assistant specializing in food safety. "
          "Create a unique, delicious recipe using ONLY these available ingredients: [$ingredientsText]. "
          "🔥 CRITICAL SAFETY TASK: Your absolute CRITICAL task is to ensure the recipe is 100% safe by completely replacing or excluding these allergens: [$allergensText] with safe alternatives. "
          "You MUST respond ONLY with a raw, valid JSON object matching this exact structure, without markdown tags, backticks or conversational text: "
          '{"title": "Safe Version of [Dish Name]", "cuisine": "Type of cuisine", "instructions": "Step-by-step cooking process using safe alternatives instead of the allergens.", "source": "AI Chef Safety Engine via Dart Server"}';

      // Հարցումը ուղարկում ենք մեր սեփական Dart սերվերին (Առանց Content-Type-ի՝ Chrome-ի բլոկը շրջանցելու համար)
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {
            'Content-Type': 'application/json',

        }, 
        body: jsonEncode({'prompt': compoundPrompt}),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String generatedText = responseData['result'].toString().trim();

        stdout.writeln('=== AI ENGINE FRIDGE RAW RESPONSE ===\n$generatedText\n============================');

        // 🌟 ՁԵՐ ՕՐԻԳԻՆԱԼ ԷՔՍՏՐԱԿՏՈՐԸ (Վերածում է տեքստը մաքուր JSON Map-ի)
        final int jsonStartIndex = generatedText.indexOf('{');
        final int jsonEndIndex = generatedText.lastIndexOf('}');

        if (jsonStartIndex != -1 && jsonEndIndex != -1 && jsonEndIndex > jsonStartIndex) {
          final String cleanJsonString = generatedText.substring(jsonStartIndex, jsonEndIndex + 1);
          return jsonDecode(cleanJsonString) as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка вызова Сառնարանի ԻԻ через Dart Server: $e');
    }
    
    // 🌟 ԱՆՎՏԱՆԳՈՒԹՅԱՆ ՖԵՅԼԲԵՔ (Fallback), որպեսզի սխալի դեպքում էկրանը 0% կրեշ լինի
    return {
      "title": "Безопасное блюдо из холодильника",
      "cuisine": "Домашняя кухня",
      "instructions": "ИИ-Сервер Google сейчас перегружен. Рекомендуем обжарить выбранные продукты: ${availableIngredients.join(', ')} на сковороде с добавлением оливкового масла и специй по вкусу. Обязательно исключите: ${activeAllergens.join(', ')}.",
      "source": "Резервный Модуль Dart"
    };
  }
}
