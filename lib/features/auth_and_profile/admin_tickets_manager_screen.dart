// features/auth_and_profile/admin_tickets_manager_screen.dart
import 'package:flutter/material.dart';
import '../../../core/network/network_api_controller.dart';

class AdminTicketsManagerScreen extends StatefulWidget {
  const AdminTicketsManagerScreen({super.key});

  @override
  State<AdminTicketsManagerScreen> createState() => _AdminTicketsManagerScreenState();
}

class _AdminTicketsManagerScreenState extends State<AdminTicketsManagerScreen> {
  List<Map<String, dynamic>> _allTickets = [];
  bool _isLoading = true;

  

  @override
  void initState() {
    super.initState();
    _loadAllTickets();
  }

  // Для админа мы можем сделать RPC-запрос без логина (получить вообще ВСЕ тикеты из базы)
  Future<void> _loadAllTickets() async {
    // В будущем мы добавим ветку 'get_all_tickets' для админа, 
    // а пока для теста можно загрузить тикеты любого тестового пользователя
    final res = await NetworkApiController.fetchAllTicketsForAdmin('HasmikAdmin'); 
    setState(() {
      _allTickets = res;
      _isLoading = false;
    });
  }

  void _showReplyDialog(int ticketId, String userQuestion) {
    final replyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ответ на обращение №$ticketId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вопрос пользователя:\n"$userQuestion"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: replyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Введите ваш ответ...', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (replyCtrl.text.trim().isEmpty) return;
              final ok = await NetworkApiController.sendAdminReply(ticketId, replyCtrl.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? '✅ Ответ успешно отправлен!' : '❌ Ошибка сервера'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ));
                _loadAllTickets(); // Перезагружаем список
              }
            },
            child: const Text('Отправить', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Панель Модератора: Тикеты'), backgroundColor: Colors.orange),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _allTickets.isEmpty
              ? const Center(child: Text('Нет входящих обращений'))
              : ListView.builder(
                  itemCount: _allTickets.length,
                  itemBuilder: (context, index) {
                    final ticket = _allTickets[index];
                    final int ticketId = ticket['id'] ?? 0;
                    final bool isAnswered = ticket['admin_reply'] != null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: isAnswered ? Colors.green.shade50 : Colors.orange.shade50,
                      child: ListTile(
                        title: Text('От: ${ticket['user_login']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Сообщение: ${ticket['message_text']}'),
                            if (isAnswered) Text('Ваш ответ: ${ticket['admin_reply']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: isAnswered 
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                onPressed: () => _showReplyDialog(ticketId, ticket['message_text'] ?? ''),
                                child: const Text('Ответить', style: TextStyle(color: Colors.white)),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
