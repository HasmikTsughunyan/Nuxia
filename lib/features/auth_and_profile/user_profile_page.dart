// features/auth_and_profile/user_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/network_api_controller.dart';
import '../home_screen/detail_screen/local_controller.dart';
//import 'package:image_picker/image_picker.dart';
//import 'dart:typed_data';
import 'my_recipes_hub_screen.dart';
import 'package:my_app/core/utils/image_picker_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/main.dart';
import '../../core/utils/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../core/wallet_page.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final Map<String, bool> activeAllergens;
  final VoidCallback onLogout;
  final Widget? child;

  const UserProfilePage({
    super.key,
    required this.userProfile,
    required this.activeAllergens,
    required this.onLogout,
    this.child,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isUpdatingPassword = false;
  String _passwordFeedbackMessage = '';
  final _passwordFormKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  bool _obscurePassword = true;

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isUploadingAvatar = false;
  String? _networkAvatarUrl; // Holds the live online avatar image URL

  Map<String, bool> _localAllergens = {};

  @override
  void initState() {
    super.initState();
    // 1. Ավտոմատ բեռնում ենք ալերգենները բազայից
    _loadAllergensFromDb();
    _loadAvatarFromDB();

    // 2. (ԱՎՏՈԲԵՌՆՈՒՄ): Վերցնում ենք NetworkApiController-ի պահած թարմ լինկը
    final String freshAvatar = NetworkApiController.currentUserAvatarUrl;
    if (freshAvatar.isNotEmpty && freshAvatar != 'null') {
      _networkAvatarUrl = freshAvatar; 
    } else {
      // Եթե ստատիկը դեռ դատարկ է, վերցնում ենք widget-ի սկզբնական պրոֆիլից
      final dbAvatar = widget.userProfile['avatar_url'] ?? widget.userProfile['p_mainimg'];
      if (dbAvatar != null && dbAvatar.toString().isNotEmpty && dbAvatar.toString() != 'null') {
        _networkAvatarUrl = dbAvatar.toString();
      }
    }
  }

  Future<void> _pickProfileImage() async {
    // 1. Вызываем наш общий изолированный сервис
    final PickedImageData? pickedData = await ImagePickerService.pickAndCompressImage();
    if (pickedData != null && mounted) {
      setState(() {
        _selectedFileName = pickedData.name;
        _selectedFileBytes = pickedData.bytes;
      });
      // 2. Сразу отправляем сжатые bytes в сеть через NetworkApiController
      _uploadAvatarToCloud();
    }
  }

  Future<void> _uploadAvatarToCloud() async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;
    setState(() {
      _isUploadingAvatar = true;
    });

    final String currentLogin = widget.userProfile['login']?.toString().trim() ?? 'unknown_chef';
    final String extension = _selectedFileName!.split('.').last.toLowerCase();
    final String uniqueRemoteName = 'avatar_${currentLogin.toLowerCase()}.$extension';

    // Отправляем байты в сеть через наш сетевой контроллер
    final String? uploadedUrl = await NetworkApiController.uploadImageBytes(
      bucketName: 'recipe-images',
      fileName: uniqueRemoteName,
      fileBytes: _selectedFileBytes!,
    );

    if (mounted) {
      setState(() {
        _isUploadingAvatar = false;
        if (uploadedUrl != null) {
          _networkAvatarUrl = uploadedUrl;
          
          // 🌟 ԻՍՊՐԱՎԼԵՆՈ: Գրանցում ենք նաև մեր նոր ստատիկ փոփոխականում հաջորդ էջերի համար
          NetworkApiController.currentUserAvatarUrl = uploadedUrl;

          final String currentLogin = widget.userProfile['login']?.toString().trim() ?? '';
          // 1. Отправляем ссылку на сервер Supabase (Запрос Б)
          NetworkApiController.saveAvatarLinkToProfile(currentLogin, uploadedUrl);
          // 2. ОБЯЗАТЕЛЬНО: Параллельно обновляем локальный кэш в Local Storage Хрома!
          LocalCacheController.saveLocalUserSession({
            'login': currentLogin,
            'avatar_url': uploadedUrl, // Сохраняем свежую ссылку на диск
          });

          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
              content: Text (AppLocalizations.of(context).translate('photo_upload_success_lbl')), 
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text(AppLocalizations.of(context).translate('photo_upload_unsuccess')),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  void _loadAllergensFromDb() async {
    // 1. Կանչում ենք մեր թարմացրած ստատիկ մեթոդը
    final Map<String, bool> dbData = await NetworkApiController.fetchUserAllergensFromDb();
    // 2. Թարմացնում ենք էկրանի վիճակը բազայի տվյալներով
    if (mounted) {
      setState(() {
        _localAllergens = dbData;
        
        
      });
    }
  }

 // Թարմացրեք այս մեթոդը ձեր պրոֆիլի էջի ներսում
void _loadAvatarFromDB() async {
  // 1. Կանչում ենք մեր նոր առանձին ցանցային մեթոդը
  final String? dbAvatarUrl = await NetworkApiController.fetchAvatarFromDb();

  // 2. Թարմացնում ենք էկրանի ակտիվ _networkAvatarUrl փոփոխականը [4.2]
  if (dbAvatarUrl != null && mounted) {
    setState(() {
      _networkAvatarUrl = dbAvatarUrl; // 🌟 Գրվում է ճիշտ փոփոխականի մեջ, և CircleAvatar-ը միանում է!
    });
    debugPrint('📸 Էկրանը հաջողությամբ ստացավ և պատկերեց ավատարը: $_networkAvatarUrl');
  }
}


  Future<void> _processPasswordUpdate() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() {
      _isUpdatingPassword = true;
      _passwordFeedbackMessage = '';
    });

    final String currentLogin = widget.userProfile['login']?.toString().trim() ?? '';
    final String newPassword = _newPasswordController.text.trim();

    if (currentLogin.isEmpty) {
      setState(() {
        _isUpdatingPassword = false;
        _passwordFeedbackMessage = AppLocalizations.of(context).translate('current_user_err');
      });
      return;
    }
    try {
      final bool success = await NetworkApiController.changeUserPassword(currentLogin, newPassword);
      if (success) {
        await LocalCacheController.updateLocalPasswordInSession(newPassword);
        if (mounted) {
          setState(() {
            _isUpdatingPassword = false;
            _passwordFeedbackMessage = AppLocalizations.of(context).translate('psw_chng_success'); 
            _newPasswordController.clear();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isUpdatingPassword = false;
            _passwordFeedbackMessage = AppLocalizations.of(context).translate('server_err_lbl');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
          _passwordFeedbackMessage = AppLocalizations.of(context).translate('ntw_err'); 
        });
      }
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //final String currentLogin = widget.userProfile['login']?.toString().trim() ?? 'HasmikAdmin';

    return Scaffold(
      appBar: AppBar(title: 
      Text(AppLocalizations.of(context).translate('prsn_cab')), 
      backgroundColor: Colors.orange),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
                   Center(
            child: Column(
              children: [
                // 🌟 СТЕК ДЛЯ НАЛОЖЕНИЯ ИКОНКИ КАРАНДАША НА АВАТАР
                Stack(
                  children: [
                    // АВАТАРКА: Показывает текущее фото из базы и блокирует клики во время загрузки
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.orange.shade900,
                      backgroundImage:
                      (_networkAvatarUrl != null && _networkAvatarUrl!.startsWith('http'))
      ? NetworkImage(_networkAvatarUrl!) // Եթե բազայից եկած լինկը վավեր է, ցուցադրում ենք այն
      : null, 
                      child: _isUploadingAvatar
                          ? const CircularProgressIndicator(color: Colors.orange) // Спиннер загрузки
                          : (_selectedFileBytes == null && (_networkAvatarUrl == null || _networkAvatarUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 50, color: Colors.orange) // Дефолтный силуэт, если фото нет
                              : null),
                    ),

                    // КНОПКА-КАРАНДАШИК: Срабатывает строго по клику на иконку
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingAvatar ? null : _pickProfileImage, // Вызывает вашу функцию загрузки нового фото [4.2]
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.orange, // Оранжевый фон кнопки
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit, // Иконка карандаша
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
       const SizedBox(height: 10),
                Text(
                  widget.userProfile['login'] ?? 'Шеф-Повар', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),

// Տեղադրեք սա ձեր user_profile_page.dart-ի ListView-ի մեջ՝ Ալերգենների Divider-ից առաջ
const Divider(height: 30),
Padding(
  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
  child: Text(
    AppLocalizations.of(context).translate('lng_slct_lbl'),
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
  ),
),
// 🌟 ԻՍՊՐԱՎЛЕНՈ: Հին 3 կոճակները փոխարինվել են մաքուր բացվող Dropdown ցուցակով
DropdownButtonFormField<String>(
  initialValue: Localizations.localeOf(context).languageCode, // Ավտոմատ վերցնում է ընթացիկ ակտիվ լեզուն [4.2]
  decoration: InputDecoration(
    //border: const OutlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    filled: true,
    fillColor: Colors.orange.shade50, // Նարնջագույն թեթև ֆոն
  ),
  dropdownColor: Colors.orange.shade50,
  icon: const Icon(Icons.language, color: Colors.orange),
  items: const [
    DropdownMenuItem(value: 'ru', child: Text('🇷🇺 Русский', style: TextStyle(fontWeight: FontWeight.bold))),
    DropdownMenuItem(value: 'hy', child: Text('🇦🇲 Հայերեն', style: TextStyle(fontWeight: FontWeight.bold))),
    DropdownMenuItem(value: 'en', child: Text('🇺🇸 English', style: TextStyle(fontWeight: FontWeight.bold))),
  ],
  onChanged: (String? newLangCode) {
    if (newLangCode != null) {
      // Ակնթարթորեն միացնում է ընտրված լեզուն main.dart-ում [4.2]
      MyApp.setLocale(context, Locale(newLangCode)); 
    }
  },
),

// 🌟 ԱՎԵԼԱՑՎԱԾ Է. ԻՐԱԿԱՆ ԿՐԻՊՏՈ-ԴՐԱՄԱՊԱՆԱԿԻ ՄՈՒՏՔԻ ԿՈՃԱԿԸ
Padding(
  padding: const EdgeInsets.symmetric(vertical: 8.0),
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange, // Պահպանում ենք հավելվածի նարնջագույն ոճը
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
    label: Text(
      AppLocalizations.of(context).translate('btn_my_wallet'), // 🌟 Դինամիկ թարգմանություն
      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
    ),
    onPressed: () {
      // Սահուն կերպով բացում ենք մեր ստեղծած իրական WalletPage էկրանը
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WalletPage(userProfile: widget.userProfile),
        ),
      );
    },
  ),
),

          // allergens tiles
          const Divider(height: 30),
           Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Text(AppLocalizations.of(context).translate('slct_algns'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          ),
          Card(
            elevation: 2,
            child: Column(
              children: [
                _buildAllergenSwitch('group_1', AppLocalizations.of(context).translate('lactose_lbl'),  1),
                _buildAllergenSwitch('group_2', AppLocalizations.of(context).translate('prtn_lbl'), 2),
                _buildAllergenSwitch('group_3', AppLocalizations.of(context).translate('gluten_lbl'), 3),
                _buildAllergenSwitch('group_4', AppLocalizations.of(context).translate('nut_lbl'), 4),
                _buildAllergenSwitch('group_5', AppLocalizations.of(context).translate('fish_lbl'), 5),
              ],
            ),
          ),
          
          // change password card
          const Divider(height: 30),
          _buildTile(
            Icons.published_with_changes,
            AppLocalizations.of(context).translate('psw_chng_lbl'),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text( AppLocalizations.of(context).translate('prf_scrt_lbl')),
                      backgroundColor: Colors.orange,
                    ),

body: SingleChildScrollView(
padding: const EdgeInsets.all(16.0),
child: Card(
elevation: 4,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
child: Padding(
padding: const EdgeInsets.all(16.0),
child: Form(
key: _passwordFormKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
 Text(
AppLocalizations.of(context).translate('prf_scrt_lbl2'),
style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
const SizedBox(height: 12),
// 🌟 ԻՍՊՐԱՎԼԵՆՈ: Փաթաթում ենք StatefulBuilder-ով, որպեսզի շտորկայի/դիալոգի ներսում setState-ը աշխատի LIVE!
StatefulBuilder(
  builder: (BuildContext context, StateSetter setModalState) {
    return TextFormField(
      controller: _newPasswordController,
      obscureText: _obscurePassword,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9!@#$%^&*()_+=\-`~[\]{}|;:",./<>?]')),
      ],
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).translate('new_psw_lbl'),
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.orange),
          onPressed: () {
            // 🌟 ԿԱՐԵՎՈՐ ՈՒՂՂՈՒՄ: Կանչում ենք setModalState՝ սովորական setState-ի փոխարեն!
            setModalState(() {
              _obscurePassword = !_obscurePassword;
            });
            // Նաև թարմացնում ենք գլխավոր էջի վիճակը
            setState(() {
              _obscurePassword = _obscurePassword;
            });
            debugPrint('🔐 Գաղտնաբառի տեսանելիությունը փոխվեց: Թաքցված է = $_obscurePassword');
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return AppLocalizations.of(context).translate('input_psw_lbl');
        if (value.trim().length < 6) return AppLocalizations.of(context).translate('smb_qty_lbl');
        return null;
      },
    );
  },
),

const SizedBox(height: 12),
_isUpdatingPassword
? const Center(child: CircularProgressIndicator(color: Colors.orange))
: ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
onPressed: _processPasswordUpdate,
child:  Text(AppLocalizations.of(context).translate('upd_psw_lbl'), style: TextStyle(color: Colors.white)),
),
if (_passwordFeedbackMessage.isNotEmpty) ...[
const SizedBox(height: 12),
Text(
_passwordFeedbackMessage,
style: TextStyle(
color: _passwordFeedbackMessage.contains('✅') ? Colors.green : Colors.red,
fontWeight: FontWeight.w600,
),
textAlign: TextAlign.center,
),
],
],
),
),
),
),
),
),
),
);
},
          ),
const Divider(height: 30),
_buildTile(
Icons.menu_book,
AppLocalizations.of(context).translate('myrcp_lbl'),
() => Navigator.push(
context,
MaterialPageRoute(
builder: (_) => MyRecipesHubScreen(userLogin: widget.userProfile['login'] ?? 'Повар')
),
),
),
//if (currentLogin == NetworkApiController.currentUserLogin) 
if (NetworkApiController.isCurrentUserAdmin())
...[
Card(
margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
elevation: 3,
shadowColor: Colors.red.withValues(alpha: 0.2),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
side: const BorderSide(color: Colors.redAccent, width: 1),
),
child: ListTile(
leading: const CircleAvatar(
backgroundColor: Colors.redAccent,
child: Icon(Icons.admin_panel_settings, color: Colors.white),
),
title:  Text(
AppLocalizations.of(context).translate('admin_lbl'),
style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
),
subtitle:  Text(AppLocalizations.of(context).translate('inbox_lbl')),
trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
onTap: () {
Navigator.pushNamed(context, '/admin_tickets');
},
),
),
const SizedBox(height: 8),
]
else
  const SizedBox.shrink(),

_buildTile(
Icons.support_agent,
AppLocalizations.of(context).translate('ask_sprt_lbl'),
() => Navigator.push(
context,
MaterialPageRoute(builder: (_) => AdminTicketScreen(userLogin: widget.userProfile['login'] ?? 'Повар'))
),
),
const Divider(),
ListTile(
leading: const Icon(Icons.logout, color: Colors.red),
title: Text(AppLocalizations.of(context).translate('logout_lbl')),
onTap: () async {
await LocalCacheController.clearLocalSession();
NetworkApiController.currentUserLogin = '';
if (context.mounted) {
Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
}
}
),
],
),
);
}
Widget _buildAllergenSwitch(String key, String title, int groupNum) {
return SwitchListTile(
  
title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
activeThumbColor: Colors.orange,
tileColor: Colors.orange.shade200,
value: _localAllergens[key] ?? false,
onChanged: (bool newValue) async {
setState(() {
_localAllergens[key] = newValue;
});
final bool isSuccess = await NetworkApiController.updateUserAllergenGroupInDb(groupNum, newValue);
if (!isSuccess) {
setState(() {
_localAllergens[key] = !newValue;
});
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
  content: Text(AppLocalizations.of(context).translate('ntw_err2') )),
);
}
}
},
);
}
Widget _buildTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
return Card(
child: ListTile(
leading: Icon(icon, color: color ?? Colors.blueGrey),
title: Text(title, style: const TextStyle(fontSize: 13)),
trailing: const Icon(Icons.arrow_forward_ios, size: 12),
onTap: onTap,
),
);
}
}
// =========================================================================
// 🌟 ԱԴՄԻՆԻ ՏԻԿԵՏՆԵՐԻ ԷԿՐԱՆ (Պահպանված է 100%-ով ուղիղ PDF-ից)
// =========================================================================
class AdminTicketScreen extends StatefulWidget {
final String userLogin;
const AdminTicketScreen({super.key, required this.userLogin});
@override
State createState() => _AdminTicketScreenState();
}
class _AdminTicketScreenState extends State {
final _ticketController = TextEditingController();
List<Map<String, dynamic>> _ticketHistory = [];
bool _isLoadingHistory = true;

@override
void initState() {
super.initState();
_loadTicketHistory();
}

@override
void dispose() {
_ticketController.dispose();
super.dispose();
}

Future _loadTicketHistory() async {
final localData = await LocalCacheController.getLocalTickets();
if (mounted) {
setState(() {
_ticketHistory = localData;
_isLoadingHistory = false;
});
}

final cloudData = await NetworkApiController.fetchUserTickets(NetworkApiController.currentUserLogin);
if (cloudData.isNotEmpty && mounted) {
int newRepliesCount = 0;
for (var cloudTicket in cloudData) {
final localMatch = localData.firstWhere(
(l) => l['id'] == cloudTicket['id'],
orElse: () => {},
);
if (cloudTicket['admin_reply'] != null && localMatch['admin_reply'] == null) {
newRepliesCount++;
}
}
if (newRepliesCount > 0) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
content: Text('🔔 Техподдержка ответила на ваши обращения (Новых ответов: $newRepliesCount)'),
backgroundColor: Colors.orange,
duration: const Duration(seconds: 4),
));
}
setState(() {
_ticketHistory = cloudData;
});
}
}
@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
  title:  Text(AppLocalizations.of(context).translate('ask_sprt_lbl')),
   backgroundColor: Colors.orange),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(AppLocalizations.of(context).translate('descrpt_lbl'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
const SizedBox(height: 8),
TextField(
  controller: _ticketController, 
  maxLines: 3, 
  decoration: InputDecoration(
    hintText: (AppLocalizations.of(context).translate('msg_lbl')), 
    border: OutlineInputBorder())),

const SizedBox(height: 12),
ElevatedButton(
style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(42), backgroundColor: Colors.orange),
onPressed: () async {
if (_ticketController.text.isEmpty) return;
final Map<String, dynamic> newTicket = {
'user_login': NetworkApiController.currentUserLogin,
'message_text': _ticketController.text,
'created_at': DateTime.now().toIso8601String().substring(0, 10),
'admin_reply': null,
};
await LocalCacheController.saveLocalTicket(newTicket);
bool ok = await NetworkApiController.sendAdminTicket(NetworkApiController.currentUserLogin, _ticketController.text);
if (context.mounted) {
_ticketController.clear();
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
content: Text(ok ? AppLocalizations.of(context).translate('msg_rcv_lbl') : AppLocalizations.of(context).translate('ntw_err')),
backgroundColor: ok ? Colors.green : Colors.blue,
));
_loadTicketHistory();
}
},
child: Text(AppLocalizations.of(context).translate('send_msg_lbl'), style: TextStyle(color: Colors.white)),
),
const SizedBox(height: 24),
Expanded(
child: _isLoadingHistory
? const Center(child: CircularProgressIndicator(color: Colors.orange))
: ListView.builder(
itemCount: _ticketHistory.length,
itemBuilder: (context, index) {
final ticket = _ticketHistory[index];
final bool hasReply = ticket['admin_reply'] != null;

return Card(
color: hasReply ? Colors.green.shade50 : Colors.orange.shade50,
child: ListTile(
title: Text('${AppLocalizations.of(context).translate('your_rqst_lbl')}  ${ticket['message_text']}'),
subtitle: Text(hasReply ? '${AppLocalizations.of(context).translate('sprt_answ_lbl')} ${ticket['admin_reply']}' : AppLocalizations.of(context).translate('wait_answ_lbl') ),
),
);
},
),
)
],
),
),
);
}
}
// =========================================================================
// 🌟 ԽՕՀԱՐԱՐԻ ՌԵՑԵՊՏՆԵՐԻ ԷԿՐԱՆ (Պահպանված է 100%-ով ուղիղ PDF-ից)
// =========================================================================
class UserRecipesScreen extends StatefulWidget {
final String userLogin;
const UserRecipesScreen({super.key, required this.userLogin});
@override
State createState() => _UserRecipesScreenState();
}
class _UserRecipesScreenState extends State {
List<Map<String, dynamic>> _myRecipes = [];
bool _isLoading = true;
@override
void initState() {
super.initState();
_loadData();
}
Future _loadData() async {
final res = await NetworkApiController.fetchMyAuthoredRecipes(NetworkApiController.currentUserLogin);
setState(() {
_myRecipes = res;
_isLoading = false;
});
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: 

Text(AppLocalizations.of(context).translate('myrcp_lbl')), 
backgroundColor: Colors.orange),

body: _isLoading
? const Center(child: CircularProgressIndicator())
: ListView.builder(
itemCount: _myRecipes.length,
itemBuilder: (context, index) {
final recipe = _myRecipes[index];
return Card(child: ListTile(title: Text(recipe['title'] ?? 'Без названия')));
},
),
);
}
}
