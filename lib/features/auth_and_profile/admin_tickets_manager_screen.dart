// features/auth_and_profile/admin_tickets_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:my_app/core/utils/app_localizations.dart';
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

  Future<void> _loadAllTickets() async {
    final res = await NetworkApiController.fetchAllTicketsForAdmin('HasmikAdmin'); 
    setState(() {
      _allTickets = res;
      _isLoading = false;
    });
  }

  // 🌟 УЛУЧШЕННЫЙ МОДfolder ДИАЛОГ РАССМОТРЕНИЯ ЧЕКА (Event-Driven Flow)
  void _showReceiptReviewDialog(String messageText, int ticketId) {
    // 1. Автоматически извлекаем 36-значный UUID транзакции из текста сообщения
    final RegExp regExp = RegExp(
      r'[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}', 
      caseSensitive: false
    );
    final Match? match = regExp.firstMatch(messageText);
    final String extractedUuid = match != null ? match.group(0)! : "UUID не найден";

    // 2. Инициализируем локальные переменные для формы
    String selectedDecision = "approve"; // Опция по умолчанию
    final noteCtrl = TextEditingController(text: "Чек подтвержден");
    final userMessageCtrl = TextEditingController(text: "Ваш платеж успешно утвержден, доступ к VIP-функциям открыт!");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // StatefulBuilder нужен, чтобы Dropdown менял состояние внутри диалога
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Рассмотрение чека (Тикет №$ticketId)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Исходное сообщение:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(messageText, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 11)),
                const Divider(),
                
                // Поле 1: Вытащенный UUID (Только для чтения)
                const Text('Идентификатор транзакции (UUID):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: TextEditingController(text: extractedUuid),
                  readOnly: true,
                  decoration: const InputDecoration(
                    fillColor: Colors.black12,
                    filled: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                  ),
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 12),

                // Поле 2: Выпадающий список (Dropdown) с опциями решения
                const Text('Решение модератора:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: selectedDecision,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: "approve", child: Text("📌 Approve (Утвердить)")),
                    DropdownMenuItem(value: "reject", child: Text("❌ Reject (Отклонить)")),
                   // DropdownMenuItem(value: "send_message", child: Text("✉️ Send message to user")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedDecision = val;
                        // Автоматически подстраиваем шаблоны ответов под выбранную опцию
                        if (selectedDecision == "approve") {
                          noteCtrl.text = "Чек подтвержден";
                          userMessageCtrl.text = "Ваш платеж успешно утвержден, доступ к VIP-функциям открыт!";
                        } else if (selectedDecision == "reject") {
                          noteCtrl.text = "Чек отклонен банком";
                          userMessageCtrl.text = "К сожалению, этот чек не прошел проверку системы. Пожалуйста, отправьте корректный снимок андоррагира.";
                        } /*else {
                          noteCtrl.text = "Запрос дополнительной информации";
                          userMessageCtrl.text = "Пожалуйста, свяжитесь со службой поддержки и отправьте повторный скриншот квитанции.";
                        }*/
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Поле 3: Поле ввода системной заметки (Note)
                const Text('Системная заметка (Note):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),

                // Поле 4: Обобщающий ответ для пользователя
                const Text('Сообщение пользователю:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: userMessageCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
   actions: [
    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
    ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      onPressed: () async {
  if (extractedUuid == "UUID не найден") return;
  
  // 🌟 Նախօրոք պահում ենք մեսենջերն ու նավիգատորը, քանի դեռ context-ը 100% կենդանի է
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  
  setState(() => _isLoading = true);

  try {
    // 1. Ուղարկում ենք որոշումը բազա
    final bool success = await NetworkApiController.sendAdminDecision(
      transactionId: extractedUuid,
      decision: selectedDecision,
      note: noteCtrl.text.trim(),
    );

    // 2. Ուղարկում ենք տեքստային պատասխանը օգտատիրոջը
    await NetworkApiController.sendAdminReply(ticketId, userMessageCtrl.text.trim());

    // 3. Ցուցադրում ենք հաղթական SnackBar-ը
    messenger.showSnackBar(SnackBar(
      content: Text(success ? '✅ Решение принято и отправлено в базу данных!' : '❌ Ошибка сети при отправке решения'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
    
    _loadAllTickets(); // Թարմացնում ենք ադմինի էկրանի ցուցակը
  } catch (e) {
    debugPrint('❌ Error: $e');
  } finally {
    // 🌟 ԳԱՐԱՆՏԻԱ: Այս բլոկը կատարվում է ՑԱՆԿԱՑԱԾ պարագայում (նույնիսկ եթե ցանցը կախի)
    if (mounted) {
      setState(() => _isLoading = false); // Անջատում ենք օղակը
    }
    
    // 🚀 ՓԱԿՈՒՄ Է ՊԱՏՈՒՀԱՆԸ 200% ԵՐԱՇԽԻՔՈՎ!
    // Օգտագործում ենք նախօրոք պահված անվտանգ նավիգատորը
    navigator.pop(); 
  }
},

      child: const Text('Применить', style: TextStyle(color: Colors.white)),
    )
  ],
     ),
      ),
    );
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
                _loadAllTickets();
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('moderator_lbl')),
         backgroundColor: Colors.orange),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _allTickets.isEmpty
              ?  Center(
                child: Text(AppLocalizations.of(context).translate('no_new_message')))
              : ListView.builder(
                  itemCount: _allTickets.length,
                  itemBuilder: (context, index) {

final ticket = _allTickets[index];
final int ticketId = ticket['id'] ?? 0;
final String msgText = ticket['message_text'] ?? '';
final bool isAnswered = ticket['admin_reply'] != null;
final bool isReceiptCheck = msgText.contains('Транзакция:') || msgText.contains('проверка чека');
return Card(
margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
color: isAnswered ? Colors.green.shade50 : Colors.orange.shade50,
child: Padding(
padding: const EdgeInsets.all(12.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('От: ${ticket['user_login']}', style: const TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 6),
Text('Сообщение: $msgText'),
if (isAnswered) ...[
const SizedBox(height: 6),
Text('Ваш ответ: ${ticket['admin_reply']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
],
const SizedBox(height: 12),
// 🌟 ИСПРАВЛЕНО: Кнопки теперь выстроены ВЕРТИКАЛЬНО через Column (для узких экранов)
if (!isAnswered)
Column(
//width: double.infinity,
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
if (isReceiptCheck) ...[
ElevatedButton.icon(
icon: const Icon(Icons.rate_review, color: Colors.white, size: 18),
label: const Text('Рассмотреть чек', style: TextStyle(color: Colors.white)),
style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
onPressed: () => _showReceiptReviewDialog(msgText, ticketId),
),
const SizedBox(height: 8),
],
ElevatedButton.icon(
icon: const Icon(Icons.reply, color: Colors.white, size: 18),
label: const Text('Ответить текстом', style: TextStyle(color: Colors.white)),
style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
onPressed: () => _showReplyDialog(ticketId, msgText),
),
],
)
else
 Row(
mainAxisAlignment: MainAxisAlignment.end,
children: [
Icon(Icons.check_circle, color: Colors.green),
SizedBox(width: 4),
Text(AppLocalizations.of(context).translate('obrabotano_lbl'), style: TextStyle(color: Colors.green, fontSize: 12))
],
),
],
),
),
);
},
),
);
}
}
