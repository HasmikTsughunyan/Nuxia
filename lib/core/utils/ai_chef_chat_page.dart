import 'package:flutter/material.dart';
// Импортируйте ваш файл с NetworkApiController (укажите правильный путь к вашему проекту)
import '../network/network_api_controller.dart'; 
import '../../../core/utils/app_localizations.dart';
//import 'package:flutter_localizations/flutter_localizations.dart';




class AiChefChatPage extends StatefulWidget {
  const AiChefChatPage({
    super.key
    });

  @override
  State<AiChefChatPage> createState() => _AiChefChatPageState();
}

class _AiChefChatPageState extends State<AiChefChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = []; // История сообщений чата
  bool _isLoading = false;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
    });

    // Обращаемся к вашему исправленному методу контроллера
    final aiResponse = await NetworkApiController.askLiveAiAgent(text);

    if (mounted) {
      setState(() {
        _messages.add({"role": "chef", "text": aiResponse});
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(AppLocalizations.of(context).translate('ai_chat_title_lbl') ),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:  [
                        Icon(Icons.restaurant, size: 64, color: Colors.orange),
                        SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).translate('ask_ai_lbl'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg["role"] == "user";
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.orange.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg["text"] ?? '',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Индикатор загрузки ответа ИИ
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.orange),
            ),

          // Поле ввода сообщения
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration:  InputDecoration(
                        hintText: AppLocalizations.of(context).translate('ask_ai_lbl2'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.orange),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

