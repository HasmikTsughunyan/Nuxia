// features/auth_and_profile/my_recipes_hub_screen.dart
import 'package:flutter/material.dart';
import '../../../core/network/network_api_controller.dart';
import 'package:my_app/core/utils/image_picker_service.dart';
import 'package:my_app/features/auth_and_profile/edit_recipe_bottom_sheet.dart';
import 'dart:convert';
import '../../core/utils/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';




class MyRecipesHubScreen extends StatelessWidget {
  final String userLogin;
  const MyRecipesHubScreen({super.key, required this.userLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('my_ktchn_lbl'), 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.menu_book, color: Colors.white),
              label: Text(AppLocalizations.of(context).translate('my_ckbk_lbl'), 
              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyAuthoredRecipesListScreen(userLogin: NetworkApiController.currentUserLogin)),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.orange, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
              label: Text(AppLocalizations.of(context).translate('add_rcp_lbl'), 
              style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddNewRecipeFormScreen(userLogin: NetworkApiController.currentUserLogin)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// ПОД-ЭКРАН 1: СПИСОК АВТОРСКИХ РЕЦЕПТОВ ПО ЛОГИНУ
// =======================================================
class MyAuthoredRecipesListScreen extends StatefulWidget {
  final String userLogin;
  const MyAuthoredRecipesListScreen({super.key, required this.userLogin});

  @override
  State<MyAuthoredRecipesListScreen> createState() => _MyAuthoredRecipesListScreenState();
}

class _MyAuthoredRecipesListScreenState extends State<MyAuthoredRecipesListScreen> {
  List<Map<String, dynamic>> _myRecipes = [];
  bool _isLoading = true;

  void _showEditSheet(Map<String, dynamic> recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return EditRecipeBottomSheet(
          recipe: recipe,
          onRecipeUpdated: () {
            _refreshRecipesList();
          },
        );
      },
    );
  }

  Future<void> _refreshRecipesList() async {
    try {
      final String currentLogin = NetworkApiController.currentUserLogin;
      final List<Map<String, dynamic>> freshData = await NetworkApiController.fetchMyAuthoredRecipes(currentLogin);
      if (mounted) {
        setState(() {
          _myRecipes.clear();
          _myRecipes.addAll(freshData);
        });
      }
    } catch (e) {
      debugPrint('Ошибка при перезагрузке списка рецептов: $e');
    }
  }

  void _confirmDeleteRecipe(int recipeId, String imageUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:  Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text(AppLocalizations.of(context).translate('delete_rcp_lbl')),
            ],
          ),
          content: Text(AppLocalizations.of(context).translate('attn_msg_lbl')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(context).translate('discard_chng_lbl'), 
              style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (imageUrl.isNotEmpty) {
                  await NetworkApiController.deleteRecipeImageFile(imageUrl);
                }
                final bool ok = await NetworkApiController.deleteRecipeFromCloud(recipeId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? AppLocalizations.of(context).translate('dlt_scs_lbl') : AppLocalizations.of(context).translate('dlt_unscs_lbl')),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ));
                  if (ok) {
                    _refreshRecipesList();
                  }
                }
              },
              child: Text(AppLocalizations.of(context).translate('slct_lbl'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMyRecipes();
  }

  Future<void> _loadMyRecipes() async {
    final res = await NetworkApiController.fetchMyAuthoredRecipes(NetworkApiController.currentUserLogin);
    if (mounted) {
      setState(() {
        _myRecipes = res;
        _isLoading = false;
      });
    }
    
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<dynamic> allRecipes = _myRecipes; // или widget.userRecipesList

    // 🌟 ИСПРАВЛЕНО: Теперь фильтр находится внутри метода build, и Dart его скомпилирует без ошибок!
    final List<dynamic> validRecipes = allRecipes.where((recipe) {
      if (recipe == null) return false;
      final String? recipeId = recipe['id']?.toString() ?? recipe['recipe_id']?.toString();
      return recipeId != null && recipeId != 'null' && recipeId.isNotEmpty;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title:  Text(AppLocalizations.of(context).translate('my_ckbk_lbl2')),
         backgroundColor: Colors.orange),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : validRecipes.isEmpty
              ? Center(
                child: Text(AppLocalizations.of(context).translate('attn_msg_lbl2')))
              : ListView.builder(
                  itemCount: validRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = validRecipes[index];
                    final title = recipe['title']?.toString() ?? recipe['dish']?.toString() ?? 'Без названия';
                    final author = recipe['author_name']?.toString() ?? recipe['p_author']?.toString() ?? 'Не указан';
                    final views = recipe['viewscount'] ?? recipe['viewsCount'] ?? 0;
                    final instructions = recipe['instructions']?.toString() ?? recipe['recipe_instructions']?.toString() ?? 'Инструкция отсутствует';
                    final cuisine = recipe['cuisine']?.toString() ?? recipe['p_cuisine']?.toString();

                    final rawSource = recipe['source'] ?? recipe['source_url'] ?? recipe['p_source'];
                    final String? source = (rawSource != null && rawSource.toString().trim() != '0' && rawSource.toString().trim().toLowerCase() != 'null' && rawSource.toString().trim().isNotEmpty)
                        ? rawSource.toString().trim()
                        : null;
                    final imageUrl = recipe['photo_url']?.toString() ?? recipe['p_mainimg']?.toString();
                    final imageSize = MediaQuery.of(context).size.shortestSide / 3;
                    
                    // 🌟 ԼՐԱՑՈՒՑԻՉ ԼՈՒՍԱՆԿԱՐՆԵՐԻ ՆԵՐԲԵՌՆՈՒՄԸ ԲԱԶԱՅԻՑ
                    
final dynamic rawAdditionalImg = recipe['p_additionalimg'] ?? recipe['additionalimg'] ?? recipe['additionalImg'];
List<String> additionalImages = [];

if (rawAdditionalImg != null) {
  if (rawAdditionalImg is List) {
    additionalImages = rawAdditionalImg.map((e) => e.toString().trim()).where((e) => e.isNotEmpty && e != 'null').toList();
  } else if (rawAdditionalImg is String && rawAdditionalImg.isNotEmpty && rawAdditionalImg != 'null') {
    final String cleanStr = rawAdditionalImg.trim();
    // Проверяем, если строка пришла в формате JSON-массива ["url", "url"]
    if (cleanStr.startsWith('[') && cleanStr.endsWith(']')) {
      try {
        final List<dynamic> decoded = jsonDecode(cleanStr);
        additionalImages = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      } catch (e) {
        // Если jsonDecode не сработал, чистим скобки вручную
        additionalImages = cleanStr
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .replaceAll("'", "")
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } else {
      // Обычная строка со ссылками через запятую
      additionalImages = cleanStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
  }
}
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: isDark ? Colors.grey[850] : Colors.white,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          onExpansionChanged: (bool isExpanded) {
                            if (isExpanded && recipe['id'] != null) {
                              NetworkApiController.incrementRecipeViews(recipe['id'] as int);
                            }
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
                                onPressed: () => _showEditSheet(recipe),),
IconButton(
icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 22),
tooltip: (AppLocalizations.of(context).translate('dlt_rcp_lbl')),
onPressed: () {
final int id = recipe['id'] as int;
final String photoPath = recipe['image_url']?.toString() ?? '';
_confirmDeleteRecipe(id, photoPath);
},
),
],
),
title: Padding(
padding: const EdgeInsets.symmetric(vertical: 8.0),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
GestureDetector(
onTap: () {
if (imageUrl != null && imageUrl.isNotEmpty) {
showDialog(
context: context,
builder: (context) => Dialog.fullscreen(
backgroundColor: Colors.black.withValues(alpha: 0.9),
child: Stack(
children: [
Positioned.fill(child: Image.network(imageUrl, fit: BoxFit.scaleDown)),
Positioned(
top: 40,
right: 20,
child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
),
],
),
),
);
}
},
child: Container(
height: imageSize,
width: imageSize,
decoration: BoxDecoration(
color: isDark ? Colors.grey[800] : Colors.grey[200],
borderRadius: BorderRadius.circular(8),
),
child: imageUrl != null && imageUrl.isNotEmpty
? ClipRRect(
borderRadius: BorderRadius.circular(12.0),
    child: FittedBox(
      // 🌟 ШАГ 1: FittedBox берет любой дочерний виджет и насильно масштабирует его
      fit: BoxFit.cover,
      // 🌟 ШАГ 2: Принудительно обрезаем всё, что вылазит за рамки квадрата imageSize
      clipBehavior: Clip.hardEdge, 
      alignment: Alignment.center,

child: Image.network(imageUrl,
 fit: BoxFit.cover, 
errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 30, color: Colors.grey)),
),
)
: const Center(child: Icon(Icons.restaurant, size: 30, color: Colors.grey)),
),
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(title, 
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
 maxLines: 2, 
 overflow: TextOverflow.ellipsis),
const SizedBox(height: 8),
Row(
children: [
const Icon(Icons.visibility, size: 14, color: Colors.grey),
const SizedBox(width: 6),
Text('${AppLocalizations.of(context).translate('recipe_veiws_label')} $views',
 style: const TextStyle(fontSize: 13, color: Colors.grey)),
],
),
if (cuisine != null && cuisine.isNotEmpty) ...[
Row(
children: [
const Icon(Icons.flag_outlined, size: 14, color: Colors.blueGrey),
const SizedBox(width: 6),
Text('${AppLocalizations.of(context).translate('recipe_cuisine_label')} $cuisine', 
style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
],
),
const SizedBox(height: 8),
],
if (source != null) ...[
Row(
children: [
const Icon(Icons.link, size: 16, color: Colors.blueGrey),
const SizedBox(width: 6),
Expanded(
  child: Text('${AppLocalizations.of(context).translate('recipe_source_label')} $source', 
  style: const TextStyle(fontSize: 13, color: Colors.blueGrey, decoration: TextDecoration.none), 
  maxLines: 1, 
  overflow: TextOverflow.ellipsis)),
],
),
const SizedBox(height: 8),
],
Row(
children: [
const Icon(Icons.person, size: 14, color: Colors.blueGrey),
const SizedBox(width: 6),
Expanded(child: Text('${AppLocalizations.of(context).translate('recipe_author_label')} $author', 
style: const TextStyle(fontSize: 13, color: Colors.blueGrey), overflow: TextOverflow.ellipsis)),
],
),
const SizedBox(height: 6),
],
),
),
],
),
),
children: [
Padding(
padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [

const Divider(height: 1, color: Colors.grey),
const SizedBox(height: 12),

Text(AppLocalizations.of(context).translate('prep_method_title'),
 style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
const SizedBox(height: 6),
Text(instructions, style: const TextStyle(height: 1.4, fontSize: 14)),
// 🌟 ԻՍՊՐԱՎԼԵՆՈ: ԼՐԱՑՈՒՑԻՉ ԼՈՒՍԱՆԿԱՐՆԵՐԻ ՀՈՐԻԶՈՆԱԿԱՆ ՑՈՒՑԱԴՐՈՒՄԸ ՔԱՐՏԻ ՄԵՋ
if (additionalImages.isNotEmpty) ...[

const SizedBox(height: 16),

Text(AppLocalizations.of(context).translate('recipe_adtnl_img_label'), 
style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),

const SizedBox(height: 8),
SizedBox(
height: 80,
child: ListView.builder(
scrollDirection: Axis.horizontal,
itemCount: additionalImages.length,
itemBuilder: (context, imgIdx) {
final url = additionalImages[imgIdx];
return Padding(
padding: const EdgeInsets.only(right: 8.0),
child: ClipRRect(
borderRadius: BorderRadius.circular(8),
child: Image.network(
url,
width: 80,
height: 80,
fit: BoxFit.cover,
errorBuilder: (c, e, s) =>  Container(width: 80, color: Colors.grey, child: Icon(Icons.broken_image, color: Colors.white)),
),
), 
);
},
),
),
],
],
),
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

// =======================================================
// ПОД-ЭКРАН 2: ФОРМА ДОБАВЛЕНИЯ НОВОГО РЕЦЕПТА
// =======================================================
class AddNewRecipeFormScreen extends StatefulWidget {
final String userLogin;
const AddNewRecipeFormScreen({super.key, required this.userLogin});
@override
State createState() => _AddNewRecipeFormScreenState();
}
class _AddNewRecipeFormScreenState extends State<AddNewRecipeFormScreen> {
final _formKey = GlobalKey();
final _titleCtrl = TextEditingController();
final _mainPhotoCtrl = TextEditingController();
final _instructionsCtrl = TextEditingController();
final _cuisineCtrl = TextEditingController();
final _authorCtrl = TextEditingController();
final _sourceCtrl = TextEditingController();
final _categoryCtrl = TextEditingController();
final List _additionalPhotosCtrls = [];
List<Map<String, dynamic>> _allIngredients = [];
final List _selectedIngredientIds = [];
final List _selectedIngredientNames = [];
String? _tempSelectedId;
String? _tempSelectedName;
bool _isSubmitting = false;
bool _isUploadingPhoto = false;
// 🌟 ԱՎԵԼԱՑՎԱԾ Է. Լրացուցիչ նկարների LIVE բեռնման սպիների ինդեքսային քարտեզ
final Map<int, bool> _uploadingAdditionalLoading = {};
@override
void initState() {
super.initState();
_loadIngredientsDropdown();
}
@override
void dispose() {
_titleCtrl.dispose();
_mainPhotoCtrl.dispose();
_instructionsCtrl.dispose();
_authorCtrl.dispose();
_cuisineCtrl.dispose();
_sourceCtrl.dispose();
_categoryCtrl.dispose();
for (var ctrl in _additionalPhotosCtrls) {
ctrl.dispose();
}
super.dispose();
}
Future _loadIngredientsDropdown() async {
final list = await NetworkApiController.fetchInitialIngredients();
if (mounted) {
setState(() => _allIngredients = list);
}
}
void _addAdditionalPhotoField() {
if (_additionalPhotosCtrls.length < 3) {
setState(() {
_additionalPhotosCtrls.add(TextEditingController());
});
} else {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(AppLocalizations.of(context).translate('attn_msg_lbl3')))
);
}
}
void _addIngredientToRecipe() {
if (_tempSelectedId == null || _tempSelectedName == null) return;
setState(() {
if (!_selectedIngredientIds.contains(_tempSelectedId!)) {
_selectedIngredientIds.add(_tempSelectedId!);
_selectedIngredientNames.add(_tempSelectedName!);
}
_tempSelectedId = null;
_tempSelectedName = null;
});
}
Future<void> _submitForm() async {
  
final dynamicState = _formKey.currentState;
    
    if (dynamicState == null) return;
    
    // Вызываем метод validate через динамическое или явное приведение, игнорируя сбитый контекст скобок
    if (!(dynamicState as dynamic).validate()) return;
    
if (_selectedIngredientIds.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(AppLocalizations.of(context).translate('slct_ingr_lbl'))));
return;
}
setState(() => _isSubmitting = true);
List dynamicPhotos = _additionalPhotosCtrls
.map((c) => c.text.trim())
.where((text) => text.isNotEmpty)
.toList();
final List ingredientIdsInt = _selectedIngredientIds.map((id) => int.parse(id.trim())).toList();
final Map<String, dynamic> recipePayload = {
'p_action': 'add_new_recipe',
'p_additionalimg': dynamicPhotos.isNotEmpty ? dynamicPhotos : null,
'p_author': _authorCtrl.text.trim().isNotEmpty ? _authorCtrl.text.trim() : null,
'p_category': _categoryCtrl.text.trim().isNotEmpty ? _categoryCtrl.text.trim() : null,
'p_cuisine': _cuisineCtrl.text.trim().isNotEmpty ? _cuisineCtrl.text.trim() : null,
'p_ingrid': ingredientIdsInt.isNotEmpty ? ingredientIdsInt.first : null,
'p_login': NetworkApiController.currentUserLogin,
'p_mainimg': _mainPhotoCtrl.text.trim(),
'p_message_text': null,
'p_password': null,
'p_recipe_id': null,
'p_recipe_instructions': _instructionsCtrl.text.trim(),
'p_recipe_title': _titleCtrl.text.trim(),
'p_selected_ids': ingredientIdsInt,
'p_source': _sourceCtrl.text.trim().isNotEmpty ? _sourceCtrl.text.trim() : null,
'p_ticket_id': null,
'p_viewscount': 0
};
final bool success = await NetworkApiController.uploadNewRecipeToDatabase(recipePayload);
if (mounted) {
setState(() => _isSubmitting = false);
if (success) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('🎉 Рецепт успешно опубликован на сервере!'), backgroundColor: Colors.green)
);
Navigator.pop(context);
} else {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('❌ Ошибка отправки рецепта в Supabase RPC. Проверьте типы данных.'))
);
}
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
  title: Text(AppLocalizations.of(context).translate('new_rcp_lbl2')), backgroundColor: Colors.orange),
body: _isSubmitting
? const Center(child: CircularProgressIndicator(color: Colors.orange))
: Form(
key: _formKey,
child: ListView(
padding: const EdgeInsets.all(16),
children: [
 Text(AppLocalizations.of(context).translate('fill_rcp_data_lbl') ,
  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),

const SizedBox(height: 16),
TextFormField(
controller: _titleCtrl,
decoration: InputDecoration(
  labelText: AppLocalizations.of(context).translate('dish_title_lbl'), 
  border: OutlineInputBorder()),
validator: (v) => v == null || v.isEmpty ? AppLocalizations.of(context).translate('input_title_lbl') : null,
),

const SizedBox(height: 12),
TextFormField(
controller: _authorCtrl,
decoration:  InputDecoration(
  labelText: AppLocalizations.of(context).translate('rcp_author_lbl'),
   border: OutlineInputBorder()),
),

const SizedBox(height: 12),
TextFormField(
controller: _cuisineCtrl,
decoration:  InputDecoration(
  labelText: AppLocalizations.of(context).translate('rcp_cuisine_lbl'), 
  border: OutlineInputBorder()),
),

const SizedBox(height: 12),
TextFormField(
controller: _sourceCtrl,
decoration:  InputDecoration(
  labelText: AppLocalizations.of(context).translate('rcp_source_lbl'), 
  hintText: AppLocalizations.of(context).translate('rcp_nscr_lbl'),
),
),

const SizedBox(height: 12),
// 🌟 ԻՍՊՐԱՎЛЕНՈ: Սովորական տեքստային TextField-ի փոխարեն դրվել է անվտանգ Dropdown ցուցակ
DropdownButtonFormField<String>(
  // Որպեսզի եթե վերահսկիչը (controller) ունի արժեք, այն ավտոմատ ընտրվի ցուցակում
  initialValue: _categoryCtrl.text.trim().isNotEmpty ? _categoryCtrl.text.trim() : 'горячее',
  decoration: InputDecoration(
    labelText: AppLocalizations.of(context).translate('rcp_ctgr_lbl'),  
    border: const OutlineInputBorder(),
    prefixIcon: const Icon(Icons.restaurant_menu, color: Colors.orange),
  ),
  dropdownColor: Theme.of(context).cardColor,
  items: [
    DropdownMenuItem(
      value: 'горячее', 
      child: Text(AppLocalizations.of(context).translate('cat_hot_dishes')),
    ),
    DropdownMenuItem(
      value: 'салаты', 
      child: Text(AppLocalizations.of(context).translate('cat_salads')),
    ),
    DropdownMenuItem(
      value: 'десерты', 
      child: Text(AppLocalizations.of(context).translate('cat_desserts')),
    ),
    DropdownMenuItem(
      value: 'овощи', 
      child: Text(AppLocalizations.of(context).translate('cat_vegetables')),
    ),
  ],
  onChanged: (String? newValue) {
    if (newValue != null) {
      // Ավտոմատ թարմացնում ենք ձեր բնօրինակ կոնտրոլերը, որպեսզի բազայի ուղարկվող կոդը չխախտվի! [4.2]
      _categoryCtrl.text = newValue; 
    }
  },
),

const SizedBox(height: 12),
// ССЫЛКА НА ОСНОВНОЕ ФОТО
TextFormField(
controller: _mainPhotoCtrl,
decoration: InputDecoration(
labelText: AppLocalizations.of(context).translate('main_pht_lbl'),
border: const OutlineInputBorder(),
suffixIcon: _isUploadingPhoto
? const Padding(
padding: EdgeInsets.all(12.0),
child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2)),
)
: IconButton(
icon: const Icon(Icons.add_a_photo, color: Colors.orange),
tooltip: AppLocalizations.of(context).translate('upld_pht_lbl') ,

onPressed: () async {
final pickedData = await ImagePickerService.pickAndCompressImage();
if (pickedData != null) {
setState(() => _isUploadingPhoto = true);
final String ext = pickedData.name.split('.').last.toLowerCase();
final String uniqueName = 'recipe${DateTime.now().millisecondsSinceEpoch}.$ext';
final String? cloudUrl = await NetworkApiController.uploadImageBytes(bucketName: 'recipe-images', fileName: uniqueName, fileBytes: pickedData.bytes);
if (mounted) {
setState(() {
_isUploadingPhoto = false;
if (cloudUrl != null) {
_mainPhotoCtrl.text = cloudUrl;
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Фото блюда успешно загружено в облако!'), backgroundColor: Colors.green));
}
});
}
}
},
),
),
),

const SizedBox(height: 12),
// 🌟 ԻՍՊՐԱՎԼԵՆՈ: ԼՐԱՑՈՒՑԻՉ ԼՈՒՍԱՆԿԱՐՆԵՐԻ ՑՈՒՑԱԿՈՒՄ ԱՎԵԼԱՑՎԵԼ Է ICONS.ADD_A_PHOTO ԿՈՃԱԿԸ
..._additionalPhotosCtrls.asMap().entries.map((entry) {
int idx = entry.key;
var ctrl = entry.value;
bool isIdxLoading = _uploadingAdditionalLoading[idx] ?? false;
return Padding(
padding: const EdgeInsets.only(bottom: 12.0),
child: TextFormField(
controller: ctrl,
decoration: InputDecoration(
labelText: '${AppLocalizations.of(context).translate('adtnl_pht_lbl2')}  №${idx + 1} (URL)',
border: const OutlineInputBorder(),
prefixIcon: const Icon(Icons.add_photo_alternate_outlined),
// 🌟 ՆՈՐ ԿՈՃԱԿ. Թույլ է տալիս բեռնել նկարը պատկերասրահից ուղիղ տեքստային դաշտի մեջ
suffixIcon: Row(
mainAxisSize: MainAxisSize.min,
children: [
isIdxLoading
? const Padding(
padding: EdgeInsets.all(12.0),
child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2)),
)
: IconButton(
icon: const Icon(Icons.add_a_photo, color: Colors.orange),
tooltip: AppLocalizations.of(context).translate('upld_adtnl_pht_lbl'),
onPressed: () async {
final pickedData = await ImagePickerService.pickAndCompressImage();
if (pickedData != null) {
setState(() => _uploadingAdditionalLoading[idx] = true);
final String ext = pickedData.name.split('.').last.toLowerCase();
final String uniqueName = 'recipe_add${idx}_${DateTime.now().millisecondsSinceEpoch}.$ext';
final String? cloudUrl = await NetworkApiController.uploadImageBytes(
  bucketName: 'recipe-images', 
  fileName: uniqueName, 
  fileBytes: pickedData.bytes);
if (mounted) {
setState(() {
_uploadingAdditionalLoading[idx] = false;
if (cloudUrl != null) {
ctrl.text = cloudUrl; // Ավտոմատ լրացնում է URL դաշտը
}
});
}
}
},
),
IconButton(
icon: const Icon(Icons.delete, color: Colors.red),
onPressed: () => setState(() => _additionalPhotosCtrls.removeAt(idx)),
),
],
),
),
),
);
}),
if (_additionalPhotosCtrls.length < 3)
TextButton.icon(
onPressed: _addAdditionalPhotoField,
icon: const Icon(Icons.add_a_photo, color: Colors.orange),
label:  Text(AppLocalizations.of(context).translate('upld_adtnl_pht_lbl2'), 
style: TextStyle(color: Colors.orange)),
),
const SizedBox(height: 12),
// ВЫБОР ИНГРЕДИЕНТОВ
Row(
children: [
Expanded(
child: Autocomplete<String>(
optionsBuilder: (TextEditingValue value) {
if (value.text.isEmpty) return const Iterable.empty();
final q = value.text.trim().toLowerCase();
return _allIngredients
.map((e) => e['ingrname']?.toString() ?? e['name']?.toString() ?? '')
.where((name) => name.toLowerCase().startsWith(q))
.cast();
},
onSelected: (String name) {
final match = _allIngredients.firstWhere(
(e) => (e['ingrname']?.toString() ?? e['name']?.toString()) == name,
orElse: () => <String, dynamic>{},
);
if (match.isNotEmpty) {
_tempSelectedId = match['id']?.toString();
_tempSelectedName = name;
}
},
fieldViewBuilder: (ctx, txtCtrl, focusNode, onSubmitted) {
return TextField(
  controller: txtCtrl, 
  focusNode: focusNode, 
  decoration:  InputDecoration(
    labelText: AppLocalizations.of(context).translate('ingr_srch_lbl'), 
    border: OutlineInputBorder()));
},
),
),
const SizedBox(width: 8),
IconButton.filled(
  style: IconButton.styleFrom(backgroundColor: Colors.orange), 
  onPressed: _addIngredientToRecipe, icon: 
  const Icon(Icons.add, color: Colors.white))
],
),
const SizedBox(height: 8),
Wrap(
spacing: 6,
children: _selectedIngredientNames.map((name) => Chip(
label: Text(name, style: const TextStyle(fontSize: 12)),
onDeleted: () => setState(() {
int idx = _selectedIngredientNames.indexOf(name);
_selectedIngredientNames.removeAt(idx);
_selectedIngredientIds.removeAt(idx);
}),
)).toList(),
),
const SizedBox(height: 12),
TextFormField(
controller: _instructionsCtrl,
maxLines: 5,
decoration: InputDecoration(
  labelText: AppLocalizations.of(context).translate('instr_lbl'), 
  border: OutlineInputBorder()),
validator: (v) => v == null || v.isEmpty ? AppLocalizations.of(context).translate('describe_lbl') : null,
),
const SizedBox(height: 20),
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(AppLocalizations.of(context).translate('adtnl_prpt_lbl'), 
style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
const SizedBox(height: 4),
Text(AppLocalizations.of(context).translate('id_lbl'), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
Text(AppLocalizations.of(context).translate('date_lbl'), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
Text(AppLocalizations.of(context).translate('views_lbl2'), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
],


),
),
const SizedBox(height: 24),
ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 14)),
onPressed: _submitForm,
child: Text(AppLocalizations.of(context).translate('upld_rcp_lbl'), 
style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
),
],
),
),
);
}
}
