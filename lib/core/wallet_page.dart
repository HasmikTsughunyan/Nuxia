// lib/features/auth_and_profile/wallet_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/utils/app_localizations.dart';

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

  // 🌟 ՈՒղիղ Supabase-ից ստուգում ենք՝ արդյո՞ք օգտատերը ունի ակտիվ VIP
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
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  // 🌟 Ֆունկցիա, որը բացում է Stripe-ի անվտանգ քարտային վճարման էջը բրաուզերում
  Future<void> _redirectToStripeCheckout(String planType) async {
    setState(() => _isRedirecting = true);

    // 🔗 ԳՐԱՆՑՎԵԼՈՒՑ ՀԵՏՈ ԱՅՍՏԵՂ ԿՏԵՂԱԴՐԵՔ STRIPE-Ի ՁԵՐ ՊԱՇՏՈՆԱԿԱՆ ԼԻՆԿԵՐԸ
    String stripeUrl = 'https://stripe.com';
    
    if (planType == 'yearly') {
      stripeUrl = 'https://stripe.com';
    }

    final Uri uri = Uri.parse(stripeUrl);

    if (await canLaunchUrl(uri)) {
      // Անվտանգ բացում ենք Stripe-ի պաշտոնական պատուհանը սովորական բանկային քարտով վճարելու համար
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
        backgroundColor: Colors.orange
      ),
      body: _isLoadingStatus
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 📊 ՔԱՐՏ 1: ԸՆԹԱՑԻԿ ԿԱՐԳԱՎԻՃԱԿԻ ՑՈՒՑԱԴՐՈՒՄ
                  Card(
                    color: _isVipActive ? Colors.green.shade50 : Colors.orange.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            _isVipActive ? Icons.verified_user : Icons.star_border, 
                            size: 54, 
                            color: _isVipActive ? Colors.green : Colors.orange
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isVipActive 
                                ? localizations.translate('vip_status_active')
                                : localizations.translate('vip_status_inactive'),
                            style: TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.bold, 
                              color: _isVipActive ? Colors.green : Colors.orange
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            localizations.translate('vip_status_desc'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    localizations.translate('vip_choose_plan'), 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14)
                  ),
                  const SizedBox(height: 12),

                  // 💳 ՏԱՐԲԵՐԱԿ Ա: ԱՄՍԱԿԱՆ ԲԱԺԱՆՈՐԴԱԳՐՈՒԹՅՈՒՆ
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.calendar_month, color: Colors.orange, size: 30),
                      title: Text(localizations.translate('plan_monthly_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(localizations.translate('plan_monthly_desc')),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        onPressed: _isRedirecting ? null : () => _redirectToStripeCheckout('monthly'),
                        child: const Text('\$4.99', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 💳 ՏԱՐԲԵՐԱԿ Բ: ՏԱՐԵԿԱՆ ԲԱԺԱՆՈՐԴԱԳՐՈՒԹՅՈՒՆ (Խնայողությամբ)
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.workspace_premium, color: Colors.orange, size: 30),
                      title: Text(localizations.translate('plan_yearly_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(localizations.translate('plan_yearly_desc'), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        onPressed: _isRedirecting ? null : () => _redirectToStripeCheckout('yearly'),
                        child: const Text('\$39.99', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  Text(
                    localizations.translate('stripe_disclaimer'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}
