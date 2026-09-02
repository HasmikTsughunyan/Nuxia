
// lib/features/my_recipes/widgets/edit_recipe_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:my_app/core/utils/image_picker_service.dart';
import '../../../core/network/network_api_controller.dart';
import '../../core/utils/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';




class EditRecipeBottomSheet extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback onRecipeUpdated; // Функция обратного вызова для обновления списка на главном экране

  const EditRecipeBottomSheet({
    super.key,
    required this.recipe,
    required this.onRecipeUpdated,
  });

  @override
  State<EditRecipeBottomSheet> createState() => _EditRecipeBottomSheetState();
}

class _EditRecipeBottomSheetState extends State<EditRecipeBottomSheet> {
  // Выносим контроллеры внутрь локального состояния шторки
  late TextEditingController _titleCtrl;
  late TextEditingController _stepsCtrl;
  late TextEditingController _sourceCtrl;
  late TextEditingController _cuisineCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _mainPhotoCtrl;
  
  
  // 🌟 ИСПРАВЛЕНО: Правильное объявление динамического списка контроллеров для доп. фото
  final List<TextEditingController> _additionalPhotosCtrls = [];
  
  // 🌟 ДОБАВЛЕНО: Карта для live-индикаторов загрузки дополнительных фотографий
  final Map<int, bool> _uploadingAdditionalLoading = {};

  bool _isSaving = false;
  bool _isUploadingPhoto = false;

 @override
void initState() {
  super.initState();
  // Ինիցիալիզացնում ենք տեքստային դաշտերը
  _titleCtrl = TextEditingController(text: widget.recipe['dish']?.toString() ?? widget.recipe['title']?.toString() ?? '');
  _cuisineCtrl = TextEditingController(text: widget.recipe['cuisine']?.toString() ?? widget.recipe['cuisine_name']?.toString());
  _authorCtrl = TextEditingController(text: widget.recipe['author']?.toString() ?? widget.recipe['author_name'] ?? '');
  _stepsCtrl = TextEditingController(text: widget.recipe['instructions']?.toString() ?? widget.recipe['recipe_instructions']?.toString() ?? '');
  _sourceCtrl = TextEditingController(text: widget.recipe['source']?.toString() ?? widget.recipe['source_url']?.toString());

  // 🌟 ՈՒՂՂՈՒՄ 1: Գլխավոր լուսանկարի ապահով բեռնում (Կանխում է "null" տեքստի հայտնվելը)
  final dynamic rawMainPhoto = widget.recipe['imageUrl'] ?? widget.recipe['p_mainimg'] ?? widget.recipe['photo_url'];
  String mainPhotoUrl = '';
  if (rawMainPhoto != null && rawMainPhoto.toString() != 'null' && rawMainPhoto.toString().isNotEmpty) {
    mainPhotoUrl = rawMainPhoto.toString();
  }
  _mainPhotoCtrl = TextEditingController(text: mainPhotoUrl);

  // 🌟 ՈՒՂՂՈՒՄ 2: Լրացուցիչ լուսանկարների կատարյալ պարսինգ
  _additionalPhotosCtrls.clear(); // Մաքրում ենք հին մնացորդները
  
  final dynamic rawAdditionalImg = widget.recipe['additionalimg'] ?? widget.recipe['p_additionalimg'] ?? widget.recipe['additionalimg_url'] ?? widget.recipe['additional_photos'];
  
  if (rawAdditionalImg != null && rawAdditionalImg.toString() != 'null') {
    if (rawAdditionalImg is List) {
      // Եթե բազայից եկել է որպես պատրաստի զանգված (Array)
      for (var url in rawAdditionalImg) {
        if (url != null && url.toString().isNotEmpty && url.toString() != 'null') {
          _additionalPhotosCtrls.add(TextEditingController(text: url.toString()));
        }
      }
    } else if (rawAdditionalImg is String && rawAdditionalImg.isNotEmpty) {
      // Եթե բազայից եկել է որպես ստորակետներով բաժանված մեկ ընդհանուր տեքստ (String)
      // 🌟 Հաշվի ենք առնում թե՛ ստորակետները `,`, թե՛ JSON-ի `[` նշանները, եթե տեքստը սխալ է պահվել
      String cleanText = rawAdditionalImg.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
      final List<String> splitUrls = cleanText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty && e != 'null').toList();
      
      for (var url in splitUrls) {
        _additionalPhotosCtrls.add(TextEditingController(text: url));
      }
    }
  }
}


  // 🌟 ДОБАВЛЕНО: Метод добавления нового пустого поля для доп. фото (макс. 3)
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

  @override
  void dispose() {
    _titleCtrl.dispose();
    _cuisineCtrl.dispose();
    _authorCtrl.dispose();
    _mainPhotoCtrl.dispose();
    _stepsCtrl.dispose();
    _sourceCtrl.dispose();
    for (var ctrl in _additionalPhotosCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        // Динамический отступ снизу, чтобы клавиатура не перекрывала поля ввода
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Row(
              children: [
                Icon(Icons.edit, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).translate('rcp_edit_lbl'), 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration:  InputDecoration(
                labelText: AppLocalizations.of(context).translate('dish_title_lbl'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorCtrl,
              decoration:  InputDecoration(
                labelText: AppLocalizations.of(context).translate('recipe_author_label'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cuisineCtrl,
              decoration:  InputDecoration(
                labelText: AppLocalizations.of(context).translate('recipe_cuisine_label'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mainPhotoCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).translate('main_pht_lbl'),
                border: const OutlineInputBorder(),
                suffixIcon: _isUploadingPhoto
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.add_a_photo, color: Colors.orange),
                        tooltip: AppLocalizations.of(context).translate('upld_pht_lbl'),
                        onPressed: () async {
                          // 1. Открываем галерею и сжимаем картинку до 75% качества через наш общий сервис
                          final pickedData = await ImagePickerService.pickAndCompressImage();
                          if (pickedData != null) {
                            setState(() {
                              _isUploadingPhoto = true;
                            });
                            // 2. Генерируем уникальное имя файла по временной метке (timestamp)
                            final String ext = pickedData.name.split('.').last.toLowerCase();
                            final String uniqueName = 'recipe_${DateTime.now().millisecondsSinceEpoch}.$ext';
                            // 3. Отправляем сжатые байты в сеть через наш сетевой контроллер в бакет 'recipe-images'
                            final String? cloudUrl = await NetworkApiController.uploadImageBytes(
                              bucketName: 'recipe-images',
                              fileName: uniqueName,
                              fileBytes: pickedData.bytes,
                            );
                            if (mounted) {
                              setState(() {
                                _isUploadingPhoto = false;
                                if (cloudUrl != null) {
                                  // 4. АВТОПОДСТАНОВКА: Текстовый линк сам вписывается в поле!
                                  _mainPhotoCtrl.text = cloudUrl;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                      content: Text(AppLocalizations.of(context).translate('pht_upld_scs_lbl')),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                 

                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                      content: Text(AppLocalizations.of(context).translate('pht_upld_unscs_lbl')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              });
                            }
                          }
                        },
                      ),
              ),
            ),
            const SizedBox(height: 12),
    // 🌟 ԻՍՊՐԱՎԼԵՆՈ: Ավելացվել է .toList() վերջում և ուղղվել են ImagePicker կանչերը
..._additionalPhotosCtrls.asMap().entries.map((entry) {
  int idx = entry.key;
  var ctrl = entry.value;
  bool isIdxLoading = _uploadingAdditionalLoading[idx] ?? false;

  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: '${AppLocalizations.of(context).translate('adtnl_pht_lbl2')} №${idx + 1} (URL)',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.add_photo_alternate_outlined),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Եթե տվյալ ինդեքսով նկարը բեռնվում է ամպ՝ ցույց ենք տալիս պտտվող Loader-ը
            isIdxLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.add_a_photo, color: Colors.orange),
                    tooltip: AppLocalizations.of(context).translate('upld_adtnl_pht_lbl'),
                    onPressed: () async {
                      final pickedData = await ImagePickerService.pickAndCompressImage();
                      if (pickedData != null) {
                        setState(() => _uploadingAdditionalLoading[idx] = true);
                        
                        final String ext = pickedData.name.split('.').last.toLowerCase();
                        final String uniqueName = 'recipe_edit_add${idx}_${DateTime.now().millisecondsSinceEpoch}.$ext';
                        
                        final String? cloudUrl = await NetworkApiController.uploadImageBytes(
                          bucketName: 'recipe-images',
                          fileName: uniqueName,
                          fileBytes: pickedData.bytes,
                        );
                        
                        if (mounted) {
                          setState(() {
                            _uploadingAdditionalLoading[idx] = false;
                            if (cloudUrl != null) {
                              ctrl.text = cloudUrl; // Ավտոմատ տեղադրում ենք URL-ը դաշտի մեջ!
                            }
                          });
                        }
                      }
                    },
                  ),
            // Կոճակ՝ տվյալ լրացուցիչ նկարի դաշտը ջնջելու համար
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => _additionalPhotosCtrls.removeAt(idx)),
            ),
          ],
        ),
      ),
    ),
  );
}).toList(), // 🌟 ԿԱՐԵՎՈՐԱԳՈՒՅՆ ՈՒՂՂՈՒՄ: Վերածում ենք Iterable-ը List-ի, որպեսզի Flutter-ը ակնթարթորեն բացի դաշտերը!

// Կոճակ՝ նոր դաշտ ավելացնելու համար (մաքսիմում 3 հատ)
if (_additionalPhotosCtrls.length < 3)
  TextButton.icon(
    onPressed: _addAdditionalPhotoField,
    icon: const Icon(Icons.add_a_photo, color: Colors.orange),
    label: Text(
      AppLocalizations.of(context).translate('upld_adtnl_pht_lbl2'), 
      style: const TextStyle(color: Colors.orange),
    ),
  ),
        
            // 🌟 ДОБАВЛЕНО: ДИНАМИЧЕСКИЙ СПИСОК ДОПОЛНИТЕЛЬНЫХ ФОТО С КНОПКОЙ LIVE-ЗАГРУЗКИ ПО ИКОНКЕ
  /*          ..._additionalPhotosCtrls.asMap().entries.map((entry) {
              int idx = entry.key;
              var ctrl = entry.value;
              bool isIdxLoading = _uploadingAdditionalLoading[idx] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextFormField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context).translate('adtnl_pht_lbl2')} №${idx + 1} (URL)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.add_photo_alternate_outlined),
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
final String uniqueName = 'recipe_edit_add${idx}_${DateTime.now().millisecondsSinceEpoch}.$ext';
final String? cloudUrl = await NetworkApiController.uploadImageBytes(
bucketName: 'recipe-images',
fileName: uniqueName,
fileBytes: pickedData.bytes,
);
if (mounted) {
setState(() {
_uploadingAdditionalLoading[idx] = false;
if (cloudUrl != null) {
ctrl.text = cloudUrl; // Автоподстановка URL линка в поле!
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
label: Text(AppLocalizations.of(context).translate('upld_adtnl_pht_lbl2'), 
style: TextStyle(color: Colors.orange)),
),
*/


const SizedBox(height: 12),
TextField(
controller: _stepsCtrl,
maxLines: 5,
decoration:  InputDecoration(
labelText: AppLocalizations.of(context).translate('instr_lbl'),
border: OutlineInputBorder(),
),
),

const SizedBox(height: 12),
TextField(
controller: _sourceCtrl,
decoration: InputDecoration(
labelText: AppLocalizations.of(context).translate('recipe_source_label'),
border: OutlineInputBorder(),
),
),
const SizedBox(height: 16),
_isSaving
? const Center(child: CircularProgressIndicator(color: Colors.orange))
: ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: Colors.orange,
padding: const EdgeInsets.symmetric(vertical: 12),
),
onPressed: () async {
if (_titleCtrl.text.trim().isEmpty || _stepsCtrl.text.trim().isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text(AppLocalizations.of(context).translate('attn_msg_lbl5'))),
);
return;
}
setState(() {
_isSaving = true;
});
// =========================================================================
// 🔥 THE CRITICAL FIX: CAPTURE MESSENGER AND NAVIGATOR STATES SAFELY HERE
// =========================================================================
final NavigatorState navigator = Navigator.of(context);
final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
// 🌟 Сборка массива измененных дополнительных фото для отправки на сервер
List dynamicPhotos = _additionalPhotosCtrls
.map((c) => c.text.trim())
.where((text) => text.isNotEmpty)
.toList();
// Send the data package parameters down to your Supabase RPC network gateway
// 🌟 ИСПРАВЛЕНО: В метод updateRecipeData добавлен обновленный массив dynamicPhotos
final String successMessage = AppLocalizations.of(context).translate('scs_edit_lbl');
final String errorMessage = AppLocalizations.of(context).translate('unscs_edit_lbl');
final bool success = await NetworkApiController.updateRecipeData(
recipeId: widget.recipe['id'] as int,
dish: _titleCtrl.text.trim(),
cuisine: _cuisineCtrl.text.trim(),
authorname: _authorCtrl.text.trim(),
imageUrl: _mainPhotoCtrl.text.trim(),
instructions: _stepsCtrl.text.trim(),
source: _sourceCtrl.text.trim(),
additionalimg: dynamicPhotos, // Добавьте этот параметр в контроллер, если база поддерживает обновление доп. фото
);


// Check widget lifecycle to prevent crashes if screen was closed during download
if (!mounted) return;
// 1. Dismiss the bottom sheet using our safely captured navigator reference
navigator.pop();
// 2. Display success/error popup feedback messages
messenger.showSnackBar(
  SnackBar(
content: Text(success ? successMessage : errorMessage),
backgroundColor: success ? Colors.green : Colors.red,
));
// 3. Trigger parent dashboard view list reload updates
if (success) {
widget.onRecipeUpdated();
}
},
child:  Text(
AppLocalizations.of(context).translate('save_edit_lbl'),
style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
),
),
],
),
),
);
}
}
