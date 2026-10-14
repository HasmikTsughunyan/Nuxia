import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/utils/app_localizations.dart';
import '../core/network/network_api_controller.dart';
import '../core/direct_payment.dart'; // Ваша страница загрузки чека

class WalletPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const WalletPage({super.key, required this.userProfile});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool _isVipActive = false;
  bool _isLoadingStatus = true;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _fetchRealUserVipStatus();
  }

  // 🌟 ПЕРЕДЕЛАНО: Чистое перенаправление в отдельный экран WebView Screen
  void _initiateLocalPayment(String gatewayName) async {
    final String paymentUrl = await NetworkApiController.createPaymentInvoice(
      gateway: gatewayName,
      amount: 4500, // 4500 AMD за Premium
    );

    if (mounted && paymentUrl.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocalPaymentWebViewScreen(
            gatewayName: gatewayName,
            paymentUrl: paymentUrl,
          ),
        ),
      );
    }
  }

  // Запрос VIP статуса из Supabase
  Future<void> _fetchRealUserVipStatus() async {
    try {
      final String login = widget.userProfile['login']?.toString() ?? '';
      final res = await Supabase.instance.client
          .from('profile')
          .select('is_vip')
          .eq('login', login)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _isVipActive = res['is_vip'] as bool? ?? false;
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки VIP статуса: $e');
      } finally {
      
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    }
  }

  // Редирект в Stripe
  Future<void> _redirectToStripeCheckout(String planType) async {
    setState(() => _isRedirecting = true);
    String stripeUrl = 'https://stripe.com';
    if (planType == 'yearly') stripeUrl = 'https://stripe.com';

    final Uri uri = Uri.parse(stripeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Не удалось открыть страницу оплаты Stripe'))
        );
      }
    }
    if (mounted) setState(() => _isRedirecting = false);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('vip_screen_title')),
        backgroundColor: Colors.orange,
      ),
      // 🌟 РЕШЕНИЕ OVERFLOW: SingleChildScrollView включает плавную прокрутку и убирает желтые полосы
      body: _isLoadingStatus
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Информационная плашка статуса подписки
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isVipActive ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isVipActive ? Colors.green : Colors.orange),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isVipActive ? "Ваш VIP статус: АКТИВЕН" : "Ваш VIP статус: НЕ АКТИВЕН",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _isVipActive ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Активируйте доступ, чтобы разблокировать безлимитный ИИ Помощник и Умный Чат без ограничений.",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Выберите способ оплаты:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),

                  // Кнопка локального терминала: Idram
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet, color: Colors.orange),
                    title: const Text("Idram / Rocket Line"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    tileColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () => _initiateLocalPayment("Idram"),
                  ),
                  const SizedBox(height: 8),

                  // Кнопка локального терминала: Telcell
                  ListTile(
                    leading: const Icon(Icons.phone_android, color: Colors.orange),
                    title: const Text("Telcell Wallet"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    tileColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () => _initiateLocalPayment("Telcell"),
                  ),
                  const SizedBox(height: 8),

                  // Направляем пользователя на ваш новый DirectPayment (Экран ручной загрузки чека)
                  ListTile(
                    leading: const Icon(Icons.credit_card, color: Colors.green),
                    title: const Text("Прямой перевод на карту (Загрузка чека)"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    tileColor: Colors.green.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DirectPayment(userProfile: widget.userProfile),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Глобальный шлюз: Stripe
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: _isRedirecting 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.language, color: Colors.white),
                      label: const Text("Оплатить через Stripe (Visa/Mastercard)", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      onPressed: _isRedirecting ? null : () => _redirectToStripeCheckout("monthly"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// 🌟 ОТДЕЛЬНЫЙ ЭКРАН ДЛЯ НАДЁЖНОЙ РАБОТЫ WEBVIEW (Clean Architecture)
class LocalPaymentWebViewScreen extends StatefulWidget {
  final String gatewayName;
  final String paymentUrl;
  
  const LocalPaymentWebViewScreen({
    super.key, 
    required this.gatewayName, 
    required this.paymentUrl
  });

  @override
  State<LocalPaymentWebViewScreen> createState() => _LocalPaymentWebViewScreenState();
}

class _LocalPaymentWebViewScreenState extends State<LocalPaymentWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллер изолированно
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Оплата через ${widget.gatewayName}"),
        backgroundColor: Colors.orange,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
