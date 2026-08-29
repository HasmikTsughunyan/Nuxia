// features/home_screen/category_recipes_screen.dart
import 'package:flutter/material.dart';
import '../../../core/network/network_api_controller.dart';
import '../../core/utils/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert';

class CategoryRecipesScreen extends StatefulWidget {
  final String categoryTitle;
  final String categoryType;

  const CategoryRecipesScreen({
    super.key, 
    required this.categoryTitle, 
    required this.categoryType,
  });

  @override
  State<CategoryRecipesScreen> createState() => _CategoryRecipesScreenState();
}

class _CategoryRecipesScreenState extends State<CategoryRecipesScreen> {
  List<Map<String, dynamic>> _recipesList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCategoryRecipes();
  }

  void _loadCategoryRecipes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final result = await NetworkApiController.fetchRecipesFromCloud(widget.categoryType);
      if (mounted) {
        setState(() {
          _recipesList = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
                : _recipesList.isEmpty
                    ?  Center(child: Text(
          AppLocalizations.of(context).translate('ctgr_label1')))
                    : ListView.builder(
                        itemCount: _recipesList.length,
                        itemBuilder: (context, index) {

                          final recipe = _recipesList[index];
                          
                          // Безопасное чтение данных
                          final title = recipe['title']?.toString() ?? recipe['dish']?.toString() ?? 'Без названия';
                          final author = recipe['author_name']?.toString() ?? recipe['p_author']?.toString() ?? 'Не указан';
                          final views = recipe['viewscount'] ?? recipe['viewsCount'] ?? 0;
                          final instructions = recipe['instructions']?.toString() ?? recipe['recipe_instructions']?.toString() ?? 'Инструкция отсутствует';
                          final cuisine = recipe['cuisine']?.toString() ?? recipe['p_cuisine']?.toString();
                          // 1. Safe extraction of the source data at the top of your itemBuilder:
final rawSource = recipe['source'] ?? recipe['source_url'] ?? recipe['p_source'];
// Ensure it is a valid, non-zero string and doesn't equal stringified "null" or "0"
final String? source = (rawSource != null && 
                        rawSource.toString().trim() != '0' && 
                        rawSource.toString().trim().toLowerCase() != 'null' && 
                        rawSource.toString().trim().isNotEmpty)
    ? rawSource.toString().trim()
    : null;
                          final imageUrl = recipe['photo_url']?.toString() ?? recipe['p_mainimg']?.toString();
                          final imageSize = MediaQuery.of(context).size.width / 3;
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
                              // Убираем дефолтные разделительные линии ExpansionTile при раскрытии
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                // Фиксируем событие раскрытия и отправляем RPC-запрос счетчика на бэкенд
                                onExpansionChanged: (bool isExpanded) {
                                  if (isExpanded && recipe['id'] != null) {
                                    NetworkApiController.incrementRecipeViews(recipe['id'] as int);
                                    
                                  }
                                },
                                // ШАПКА КАРТОЧКИ: Картинка слева, текст справа
                                title: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
        // АДАПТИВНОЕ ПРЕВЬЮ (1/3 экрана)
        GestureDetector(
          onTap: () {
            if (imageUrl != null && imageUrl.isNotEmpty) {
              showDialog(
                context: context,
                builder: (context) => Dialog.fullscreen(
                  backgroundColor: Colors.black.withValues(alpha:0.9),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(imageUrl, fit: BoxFit.contain),
                      ),
                      Positioned(
                        top: 40,
                        right: 20,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
                                      // 1. контейнер для фото с сохранением пропорций
            child: Container(
            height: imageSize, // Адаптивная высота (1/3 экрана)
            width: imageSize,  // Адаптивная ширина (1/3 экрана)
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

                  child: Image.network(
                    imageUrl, 
                    fit: BoxFit.contain, // Пропорции фото не искажаются
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                  ),
    ),
    )
              : const Center(child: Icon(Icons.restaurant, size: 30, color: Colors.grey)),
          ),
        ),
        const SizedBox(width: 16),
                                      
                                      // 2. Колонка текстовых данных (название, автор, просмотры)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 18, 
                                                fontWeight: FontWeight.bold, 
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                           
                                            Row(
                                              children: [
                                                const Icon(Icons.visibility, size: 14, color: Colors.grey),
                                                const SizedBox(width: 6),
                                                Text(
                                                   '${AppLocalizations.of(context).translate('recipe_veiws_label')} $views',
                                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                               // Опциональный вывод Кухни
                                        if (cuisine != null && cuisine.isNotEmpty) ...[
Row(
children: [
const Icon(Icons.flag_outlined, size: 14, color: Colors.blueGrey),
const SizedBox(width: 6),
Expanded(
child: Text( '${AppLocalizations.of(context).translate('recipe_cuisine_label')} $cuisine', 
style: const TextStyle(
  fontSize: 13, 
  color: Colors.blueGrey), 
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
),
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
        child: Text(
           '${AppLocalizations.of(context).translate('recipe_source_label')} $source',
          style: const TextStyle(
            fontSize: 13, 
            color: Colors.blueGrey,
            decoration: TextDecoration.none,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  ),
  const SizedBox(height: 8),
],

 Row(
                                              children: [
                                                const Icon(Icons.person, size: 14, color: Colors.blueGrey),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                     '${AppLocalizations.of(context).translate('recipe_author_label')} $author',
                                                    style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),



                                            
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // ВНУТРЕННЕЕ СОДЕРЖИМОЕ (Раскрывающийся блок рецепта)
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const Divider(height: 1, color: Colors.grey),
                                        const SizedBox(height: 12),
                                        
                                       
// Раздел Инструкции
Text(  AppLocalizations.of(context).translate('prep_method_title'),
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
),
);
}
}
