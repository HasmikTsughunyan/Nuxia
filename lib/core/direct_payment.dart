
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 🌟 Ձեր ուզած պաշտոնական պիկերը
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
//import 'package:http_parser/http_parser.dart'; // 🌟 ՈՒՂՂՎԱԾ Է (Ճիշտ իմպորտ առանց տառասխալների)

class Environment {
  static const supabaseUrl = 'https://ldpxhegdrycianlebbtp.supabase.co';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxkcHhoZWdkcnljaWFubGViYnRwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1NDkxMTgsImV4cCI6MjA5ODEyNTExOH0.q3qFanjw7NrJJMMPYF_rYV4xnqi4wH41J84IQfSnodk';
  static const baseApiUrl = '$supabaseUrl/rest/v1';
  static const storageBaseUrl = '$supabaseUrl/storage/v1/object';
  static final supabase = Supabase.instance.client;
  
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'apikey': supabaseAnonKey,
        'Prefer': 'return=representation',
      };
}

class DirectPayment extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const DirectPayment({super.key, required this.userProfile});

  @override
  State<DirectPayment> createState() => _DirectPaymentState();
}

class _DirectPaymentState extends State<DirectPayment> {
  Uint8List? _webImageBytes;    // 🌟 Պահում ենք նկարի բայերը
  bool _isUploading = false;
   String _selectedFileName = 'receipt.jpg'; // 🌟 Переменная для хранения имени
  final ImagePicker _picker = ImagePicker(); // 🌟 ImagePicker-ը աշխատում է Live!

  // 1. ՉԵԿԻ ՆԿԱՐԻ ԸՆՏՐՈՒՄ (Աշխատում է և՛ Web-ում, և՛ Mobile-ում)
   Future<void> _pickReceiptImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          _webImageBytes = bytes; 
          // 🌟 Запоминаем оригинальное имя в нижнем регистре (чтобы избежать .JPG)
          _selectedFileName = image.name.toLowerCase(); 
          
        });
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
    }
  }


   Future<void> _uploadReceiptToCloud() async {
    if (_webImageBytes == null) return;

    setState(() => _isUploading = true);

    try {
 
   final client = Supabase.instance.client;
      final session = client.auth.currentSession;

      if (session == null) throw Exception('User not authenticated');
      final authId = session.user.id;

      // 1. Регистрируем транзакцию в базе данных
      final transactionResult = await client
          .from('payment_transactions')
          .insert({
            'auth_id': authId,
            'amount': 44900,
            'gateway': 'manual_payment',
            'status': 'pending',
          })
          .select('id')
          .single();

      if (transactionResult.isEmpty) throw Exception('Failed to register transaction');
      final transactionId = transactionResult['id'].toString();

      // 2. Создаем стандартный Multipart POST запрос
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Environment.supabaseUrl}/functions/v1/upload-receipt'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': Environment.supabaseAnonKey,
        'Accept': 'application/json',
      });

      request.fields['transaction_id'] = transactionId;

      
     request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _webImageBytes!,
          filename: _selectedFileName, 
        ),
      );

final response = await request.send();
final responseBody = await response.stream.bytesToString();

if (response.statusCode < 200 || response.statusCode >= 300) {
  throw Exception(
    'Upload failed: ${response.statusCode} $responseBody',
  );
}  

      if (mounted) {
        setState(() => _webImageBytes = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Чек успешно отправлен на проверку ИИ!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оплата'), backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
"Перевод на карту приложения ",
style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
),
const SizedBox(height: 12),
const Text(
"за 30дней: 4500 АМД ",
style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange),
),
const SizedBox(height: 12),

const Text(
"за год: 36180 АМД ",
style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
),
const SizedBox(height: 12),
// 💳 ՔԱՐՏԻ UI ՎԻԴՋԵԹԸ
Container(
width: double.infinity,
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
borderRadius: BorderRadius.circular(16),
boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
),
child: const Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text("BANK CARD", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
SizedBox(height: 16),
Text("4318 2900 8031 6546", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 3)),
SizedBox(height: 16),
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text("HASMIK TSUGHUNYAN", style: TextStyle(color: Colors.white, fontSize: 14)),
Text("VISA DIGITAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
],
)
],
),
),

            // 📸 ՆԿԱՐԻ ՑՈՒՑԱԴՐՄԱՆ ԴԱՇՏԸ (Image.memory-ով)
            GestureDetector(
              onTap: _isUploading ? null : _pickReceiptImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5), style: BorderStyle.solid),
                ),
                child: _webImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_webImageBytes!, fit: BoxFit.cover), 
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.orange, size: 40),
                          SizedBox(height: 8),
                          Text("Выбрать фото чека", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_webImageBytes == null || _isUploading) ? null : _uploadReceiptToCloud,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: _isUploading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Отправить чек", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}