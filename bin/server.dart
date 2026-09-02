// bin/server.dart
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';



void myDebugPrint(Object? message) {
  stdout.writeln('[DEBUG] $message');
}

void main() async {

 


// 🌟 ՖՈՒՆԿՑԻԱ, ՈՐԸ ՋՆՋՈՒՄ Է ԲՐԱՈՒԶԵՐԻ ԲՈԼՈՐ CORS ԱՐԳԵԼՔՆԵՐԸ
Map<String, String> _corsHeaders() {
  return {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*', // 👈 Թույլատրում է բոլորին կարդալ պատասխանը
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token, Authorization,  X-Requested-With',
  };
}


 Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Обработка Preflight-запроса OPTIONS от браузера
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders());
      }
      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders());
    };
  };
}



   // 🌟 Ավտոմատ ֆոնում կարդում է .env ֆայլը
  var env = DotEnv(includePlatformEnvironment: true)..load();
  
  // Վերցնում ենք բանալին ֆայլից: Եթե չկա, դնում ենք դատարկություն
  final String geminiKey = env['GEMINI_API_KEY'] ?? '';
  final router = Router();

  // 🌟 ԻԻ ԷՆԴՓՈԻՆԹ
  router.post('/api/ai-chef', (Request request) async {
    try {
      final String payloadString = await request.readAsString();
     final dynamic decoded = jsonDecode(payloadString);
String userPrompt = '';

if (decoded is Map<String, dynamic>) {
  userPrompt = decoded['prompt']?.toString() ?? '';
} else if (decoded is List && decoded.isNotEmpty) {
  final firstItem = decoded.first;
  if (firstItem is Map<String, dynamic>) {
    userPrompt = firstItem['prompt']?.toString() ?? '';
  }
}



      if (userPrompt.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Prompt is required'}),
          headers: _corsHeaders(),
        );
      }

      // Կազմում ենք Google Gemini REST-ի ճիշտ փաթեթը
      final Map<String, dynamic> googlePayload = {
        'contents': [
          {
            'parts': [
              {'text': userPrompt}
            ]
          }
        ]
      };


      // Հարցումը ուղարկում ենք ուղիղ Google-ի պաշտոնական REST API-ին
       final model = 'gemini-3.6-flash';
    final response = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?key=$geminiKey"),

        headers: {
          'Content-Type': 'application/json',
          // 🌟 ՁԵՐ ԻՐԱԿԱՆ ԲԱՆԱԼԻՆ ԱՅՍՏԵՂ
          'X-goog-api-key': geminiKey,
        },
        body: jsonEncode(googlePayload),
      ).timeout(const Duration(seconds: 45));

        stdout.writeln('=== СТАТУС ОТВЕТА: ${response.statusCode} ===');
  stdout.writeln('=== ТЕЛО ОТВЕТА GEMINI: ${response.body} ===');


     if (response.statusCode == 200 || response.statusCode == 201) {
      final decodedBody = jsonDecode(response.body);
      String fullAiText = "";

      // 🌟 ՈՒՂՂՈՒՄ 1: Եթե Gemini-ն պատասխանը տվել է որպես ԿՏՈՐՆԵՐԻ ԶԱՆԳՎԱԾ (List / Stream)
      if (decodedBody is List) {
        for (var chunk in decodedBody) {
          try {
            final candidates = chunk['candidates'] as List? ?? [];
            if (candidates.isNotEmpty) {
              final firstCandidate = candidates[0] as Map<String, dynamic>? ?? {};
              final content = firstCandidate['content'] as Map<String, dynamic>? ?? {};
              final parts = content['parts'] as List? ?? [];
              if (parts.isNotEmpty) {
                // Կպցնում ենք բոլոր տեքստային կտորները իրար
                fullAiText += parts[0]['text'].toString(); 
              }
            }
          } catch (_) {
            continue; // Անտեսում ենք տեխնիկական սխալ կտորները (thoughtsTokenCount և այլն)
          }
        }
      } 
      // 🌟 ՈՒՂՂՈՒՄ 2: Եթե Gemini-ն պատասխանը տվել է որպես սովորական ՄԵԿԱՆԳԱՄՅԱ ՕԲՅԵԿՏ (Map)
      else if (decodedBody is Map<String, dynamic>) {
        final candidates = decodedBody['candidates'] as List? ?? [];
        if (candidates.isNotEmpty) {
          final firstCandidate = candidates[0] as Map<String, dynamic>? ?? {};
          final content = firstCandidate['content'] as Map<String, dynamic>? ?? {};
          final parts = content['parts'] as List? ?? [];
          if (parts.isNotEmpty) {
            fullAiText = parts[0]['text'].toString().trim();
          }
        }
      }

      stderr.writeln('=== 🏆 AI RESPONSE TEXT ASSEMBLED ===\n$fullAiText\n================================');

      // Վերջնական մաքուր տեքստը ապահով ուղարկում ենք Flutter UI-ին
      return Response.ok(
        jsonEncode({'result': fullAiText.trim()}),
        headers: _corsHeaders(),
      );
    }


      return Response.internalServerError(
        body: jsonEncode({'error': 'Google AI Server Error: ${response.statusCode}'}),
        headers: _corsHeaders(),
      );

    } catch (e, stackTrace) {

        stderr.writeln('=== ОШИБКА: $e ===');
  stderr.writeln('=== СТЕК: $stackTrace ===');

      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: _corsHeaders(),
      );
    }
  });


// bin/server.dart ֆայլի ներսում՝ ROUTER-Ի ԲԱԺՆՈՒՄ

router.post('/api/parse-allergens', (Request request) async {
  try {

    final String payloadString = await request.readAsString();

final dynamic requestBody = jsonDecode(payloadString);
String recipeText = '';

if (requestBody is Map<String, dynamic>) {
  recipeText = requestBody['prompt']?.toString() ?? '';
} else if (requestBody is List && requestBody.isNotEmpty) {
  final firstItem = requestBody.first;
  if (firstItem is Map<String, dynamic>) {
    recipeText = firstItem['prompt']?.toString() ?? '';
  }
}

   final List<dynamic> userAllergens = requestBody['userAllergens'] ?? [];

    // 🌟 1. ԿԱԶՄՈՒՄ ԵՆՔ ԽԻՍՏ ՏԵԽՆԻԿԱԿԱՆ ՊՐՈՄԹ
    final String parsingPrompt = 
        "You are a strict recipe parsing engine. Your task is to analyze the provided recipe text and find all ingredient words that match or are related to the user's active allergens list.\n\n"
        "Recipe Text: \"$recipeText\"\n"
        "User Active Allergens List (with IDs and names): ${jsonEncode(userAllergens)}\n\n"
        "CRITICAL RULES:\n"
        "1. Find the exact character coordinates (start index and end index) of the matched allergen word in the ORIGINAL recipe text.\n"
        "2. The 'matched_text' must be the exact word from the recipe text.\n"
        "3. Respond ONLY with a clean JSON array containing objects with keys: 'id', 'start', 'end', 'matched_text'. No markdown, no backticks.";

    // 🌟 2. ԳՈՒԳԼԻ REST PAYLOAD՝ ԽԻՍՏ JSON ՍԽԵՄԱՅՈՎ (responseSchema)
    final Map<String, dynamic> googlePayload = {
      'contents': [
        {
          'parts': [
            {'text': parsingPrompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1, // Ցածր ջերմաստիճան՝ կոորդինատների 100% ճշտության համար
        'responseMimeType': 'application/json', // 🌟 Խստորեն պահանջում ենք ՄԱՔՈՒՐ JSON
        'responseSchema': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'id': {'type': 'STRING'},
              'start': {'type': 'INTEGER'},
              'end': {'type': 'INTEGER'},
              'matched_text': {'type': 'STRING'}
            },
            'required': ['id', 'start', 'end', 'matched_text']
          }
        }
      }
    };

    // 🌟 3. ՈՒՂԻՂ ՍԵՐՎԵՐԱՅԻՆ ՀԱՐՑՈՒՄ ԴԵՊԻ GOOGLE GEMINI
    final model = 'gemini-3.6-flash';
    final response = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?key=$geminiKey"),
      headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': geminiKey, // Ձեր աշխատող տոկենը
      },
      body: jsonEncode(googlePayload),
    ).timeout(const Duration(seconds: 45));

    stdout.writeln('=== СТАТУС ОТВЕТА: ${response.statusCode} ===');
  stdout.writeln('=== ТЕЛО ОТВЕТА GEMINI: ${response.body} ===');


       if (response.statusCode == 200 || response.statusCode == 201) {
      final decodedBody = jsonDecode(response.body);
      String rawAiText = "";

      // 1. Հավաքում ենք Streaming-ի բոլոր տեքստային կտորները
      if (decodedBody is List) {
        for (var chunk in decodedBody) {
          try {
            if (chunk['candidates'] != null && chunk['candidates'].isNotEmpty) {
              final parts = chunk['candidates'][0]['content']['parts'];
              if (parts != null && parts.isNotEmpty) {
                rawAiText += parts[0]['text'].toString();
              }
            }
          } catch (_) {
            continue;
          }
        }
      } else if (decodedBody is Map<String, dynamic>) {
        try {
          final candidates = decodedBody['candidates'] as List? ?? [];
          if (candidates.isNotEmpty) {
            final parts = candidates[0]['content']['parts'] as List? ?? [];
            if (parts.isNotEmpty) {
              rawAiText = parts[0]['text'].toString().trim();
            }
          }
        } catch (_) {}
      }

      // Մաքրում ենք տեքստը հնարավոր markdown նշաններից (```json ... ```)
      String cleanJsonText = rawAiText.trim()
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // 🌟 ՈՒՂՂՈՒՄ: Խելացի վալիդացիա դատարկ զանգվածների համար
      List<dynamic> finalAllergensList = [];
      if (cleanJsonText == '[]' || cleanJsonText.isEmpty) {
        stdout.writeln('ℹ️ AI Filter: No allergens detected in this recipe.');
      } else {
        try {
          finalAllergensList = jsonDecode(cleanJsonText) as List? ?? [];
        } catch (e) {
          stdout.writeln('⚠️ JSON parsing failed, using fallback empty list');
        }
      }

      // Վերադարձնում ենք մաքուր JSON-ը Flutter-ին
      return Response.ok(
        jsonEncode({
          'status': 'success',
          'detected_allergens': finalAllergensList,
          'is_safe': finalAllergensList.isEmpty // 🌟 Եթե դատարկ է, ուրեմն ռեցեպտը 100% անվտանգ է!
        }),
        headers: _corsHeaders(),
      );
    }



    return Response.internalServerError(
      body: jsonEncode({'error': 'Google Gemini parsing failed'}),
      headers: _corsHeaders(),
    );

  } catch (e, stackTrace) {
         stderr.writeln('=== ОШИБКА: $e ===');
  stderr.writeln('=== СТЕК: $stackTrace ===');

    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: _corsHeaders(),
    );
  }
});

  // 🌟 ԿԱՐԵՎՈՐԱԳՈՒՅՆ ՈՒՂՂՈՒՄ: Մշակում ենք OPTIONS հարցումները (CORS Preflight-ի համար բրաուզերում)
  router.options('/<String|.*>', (Request request) {
    return Response.ok('', headers: _corsHeaders());
  });

  final handler 
  = const Pipeline()
  .addMiddleware(logRequests())
  .addMiddleware(corsMiddleware()) 
  .addHandler(router.call);
  
  // 🌟 Միացնում ենք սերվերը 8080 պորտով
  final port = int.tryParse(env['PORT'] ?? '8080') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('🚀 Culinary Dart Backend is running on http://localhost:${server.port}');

router.all ('/<ignored|.*>', (Request request)
{
  
print ('Пришел запрос на неизвестный путь: ${request.url.path}');
return Response.notFound ('Page not found');

});
  
}

