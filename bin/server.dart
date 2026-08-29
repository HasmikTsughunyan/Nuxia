// bin/server.dart
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';



void main() async {

   // 🌟 Ավտոմատ ֆոնում կարդում է .env ֆայլը
  var env = DotEnv(includePlatformEnvironment: true)..load();
  
  // Վերցնում ենք բանալին ֆայլից: Եթե չկա, դնում ենք դատարկություն
  final String geminiKey = env['GEMINI_API_KEY'] ?? '';
  final router = Router();

  // 🌟 ԻԻ ԷՆԴՓՈԻՆԹ
  router.post('/api/ai-chef', (Request request) async {
    try {
      final String payloadString = await request.readAsString();
      final Map<String, dynamic> requestBody = jsonDecode(payloadString);
      final String userPrompt = requestBody['prompt'] ?? '';

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
      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"),
        headers: {
          'Content-Type': 'application/json',
          // 🌟 ՁԵՐ ԻՐԱԿԱՆ ԲԱՆԱԼԻՆ ԱՅՍՏԵՂ
          'X-goog-api-key': geminiKey,
        },
        body: jsonEncode(googlePayload),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> googleData = jsonDecode(response.body);
        final String aiText = googleData['candidates'][0]['content']['parts'][0]['text'].toString().trim();

        return Response.ok(
          jsonEncode({'result': aiText}),
          headers: _corsHeaders(), // 🌟 Կպցնում ենք CORS թույլտվությունը
        );
      }

      return Response.internalServerError(
        body: jsonEncode({'error': 'Google AI Server Error: ${response.statusCode}'}),
        headers: _corsHeaders(),
      );

    } catch (e) {
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
    final Map<String, dynamic> requestBody = jsonDecode(payloadString);
    final String recipeText = requestBody['recipeText'] ?? '';
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
    final response = await http.post(
      Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"),
      headers: {
        'Content-Type': 'application/json',
        'X-goog-api-key': geminiKey, // Ձեր աշխատող տոկենը
      },
      body: jsonEncode(googlePayload),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> googleData = jsonDecode(response.body);
      final String aiJsonText = googleData['candidates'][0]['content']['parts'][0]['text'].toString().trim();

      // Պատասխանը հետ ենք տալիս Flutter UI-ին՝ CORS թույլտվությամբ
      return Response.ok(
        jsonEncode({'result': aiJsonText}),
        headers: _corsHeaders(),
      );
    }

    return Response.internalServerError(
      body: jsonEncode({'error': 'Google Gemini parsing failed'}),
      headers: _corsHeaders(),
    );

  } catch (e) {
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

  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(router.call);
  
  // 🌟 Միացնում ենք սերվերը 8080 պորտով
  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('🚀 Culinary Dart Backend is running on http://localhost:${server.port}');
}

// 🌟 ՖՈՒՆԿՑԻԱ, ՈՐԸ ՋՆՋՈՒՄ Է ԲՐԱՈՒԶԵՐԻ ԲՈԼՈՐ CORS ԱՐԳԵԼՔՆԵՐԸ
Map<String, String> _corsHeaders() {
  return {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*', // 👈 Թույլատրում է բոլորին կարդալ պատասխանը
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token, Authorization',
  };
}