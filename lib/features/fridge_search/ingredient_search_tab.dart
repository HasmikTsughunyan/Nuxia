// features/fridge_search/ingredient_search_tab.dart
import 'package:flutter/material.dart';
import '../../../core/network/network_api_controller.dart';
import '../../core/utils/ai_chef_page.dart'; // 🌟 ԱՎԵԼԱՑՎԱԾ Է. ԻԻ էջի ներմուծումը
import '../../core/utils/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


class IngredientOption {
  const IngredientOption({required this.id, required this.name});
  final String id;
  final String name;
  @override
  String toString() => name;
}

class IngredientSearchTab extends StatefulWidget {
  const IngredientSearchTab({super.key});

  @override
  State<IngredientSearchTab> createState() => _IngredientSearchTabState();
}

class _IngredientSearchTabState extends State<IngredientSearchTab> {
  bool _loadingIngredients = false;
  bool _searchingRecipes = false;
  bool _generatingAiRecipe = false; // 🌟 ԱՎԵԼԱՑՎԱԾ Է. ԻԻ-ի բեռնման կարգավիճակը
  List<Map<String, dynamic>> _allIngredients = [];
  List<Map<String, dynamic>> _foundRecipes = [];

  // Переменные для отслеживания текущего ввода
  String? _currentSelectedId;
  String? _currentSelectedName;

  // Списки для хранения выбранного
  final List<String> _selectedIds = [];
  final List<String> _selectedNames = [];
  TextEditingController? _autocompleteController;

  @override
  void initState() {
    super.initState();
    _loadInitialIngredients();
  }

  Future<void> _loadInitialIngredients() async {
    if (!mounted) return;
    setState(() => _loadingIngredients = true);
    try {
      final result = await NetworkApiController.fetchInitialIngredients();
      debugPrint('=== ЛОГ: Справочник ингредиентов загружен. Всего элементов: ${result.length} ===');
      if (result.isNotEmpty) {
        debugPrint('=== ЛОГ: Пример первого элемента из базы: ${result.first} ===');
      }
      if (mounted) {
        setState(() {
          _allIngredients = List<Map<String, dynamic>>.from(result);
        });
      }
    } catch (error) {
      debugPrint('Ошибка на вкладке при загрузке ингредиентов: $error');
    } finally {
      if (mounted) setState(() => _loadingIngredients = false);
    }
  }

  void _onIngredientSelected(IngredientOption option) {
    debugPrint('=== ЛОГ: Выбран элемент в Autocomplete: id=${option.id}, name=${option.name} ===');
    setState(() {
      _currentSelectedId = option.id;
      _currentSelectedName = option.name;
      // СРАЗУ добавляем в список, чтобы избежать проблемы с кнопкой плюс!
      _addCurrentIngredientToBox();
    });
  }

  void _addCurrentIngredientToBox() {
    if (_currentSelectedId == null || _currentSelectedName == null) {
      debugPrint('=== ЛОГ ПРЕДУПРЕЖДЕНИЕ: Попытка добавить пустой элемент! ===');
      return;
    }
    setState(() {
      if (!_selectedIds.contains(_currentSelectedId!)) {
        _selectedIds.add(_currentSelectedId!);
      }
      if (!_selectedNames.contains(_currentSelectedName!)) {
        _selectedNames.add(_currentSelectedName!);
      }
      debugPrint('=== ЛОГ ТЕКУЩИЙ ХОЛОДИЛЬНИК: IDs=$_selectedIds, Names=$_selectedNames ===');
      _currentSelectedId = null;
      _currentSelectedName = null;
      _autocompleteController?.clear(); // Очищаем поле ввода
    });
  }

  Future<void> _searchRecipesBySelectedIngredients() async {
    if (_selectedIds.isEmpty) {
      debugPrint('=== ЛОГ: Поиск не запущен, список выбранного пуст ===');
      return;
    }
    setState(() {
      _searchingRecipes = true;
      _foundRecipes = []; // Очищаем старые результаты перед новым поиском
    });
    try {
      // 1. Преобразуем строковые ID в массив чисел
      final List<int> idsAsInt = _selectedIds.map((id) => int.parse(id.trim())).toList();
      debugPrint('=== ЛОГ: Отправка ID на сервер: $idsAsInt ===');
      // 2. Ждем строгого ответа от контроллера
      final dynamic responseData = await NetworkApiController.searchRecipesByIngredients(idsAsInt);
      debugPrint('=== ЛОГ С СЕРВЕРА: Получены данные: $responseData ===');
      if (!mounted) return;
      setState(() {
        // 3. Точный разбор структуры, которую мы видим на скриншоте Network
        if (responseData is Map && responseData.containsKey('recipes')) {
          final List<dynamic> recipesList = responseData['recipes'] as List<dynamic>;
          _foundRecipes = recipesList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        } else if (responseData is List) {
          _foundRecipes = responseData.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        } else if (responseData is Map) {
          // На случай, если рецепт пришел один в виде Map
          _foundRecipes = [Map<String, dynamic>.from(responseData)];
        } else {
          _foundRecipes = [];
        }
        debugPrint('=== ЛОГ УСПЕХ: В _foundRecipes сохранено ${_foundRecipes.length} рецептов ===');
      });
    } catch (error) {
      debugPrint('Ошибка при получении или парсинге рецептов: $error');
      if (mounted) {
        setState(() {
          _foundRecipes = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _searchingRecipes = false;
        });
      }
    }
  }

  Future<void> _generateAiRecipeWithAllergens() async {
  if (_selectedNames.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(AppLocalizations.of(context).translate('ingr_label1'))),
    );
    return;
  }
  
  setState(() => _generatingAiRecipe = true);

  try {
    // 1. 🌟 🏆 ԲԵՐՆՈՒՄ ԵՆՔ ՕԳՏԱՏԻՐՈՋ ԱԿՏԻՎ ԱԼԵՐԳԵՆՆԵՐՆ ՈՒ ՓՈԽԱՐԻՆՈՂՆԵՐԸ ԲԱԶԱՅԻՑ
    // Այս հարցումը վերադարձնում է, օրինակ՝ {'молоко': 'миндальное молоко', 'арахис': 'кешью'}
    final Map<String, String> userActiveSubs = await NetworkApiController.fetchUserActiveSubstitutesPipeline();
    
    // 2. 🌟 ՏԵՔՍՏԱՅԻՆ ԱԼԵՐԳԵՆՆԵՐԻ ՑՈՒՑԱԿ: Վերցնում ենք Map-ի բոլոր բանալիները (Keys)
    final List<String> textAllergensList = List<String>.from(userActiveSubs.keys);

    debugPrint('📝 PIPELINE INFO: Personalized allergen-substitute mapping completed: $userActiveSubs');

    final String currentLang = Localizations.localeOf(context).languageCode;
    final String chosenIngredients = _selectedNames.join(", ");
    
    // 3. Ձևավորում ենք ալերգենների մաքուր տեքստը ԻԻ-ի պրոմթի համար
    final String allergensText = textAllergensList.isNotEmpty 
        ? textAllergensList.join(', ') 
        : 'No allergens';
    
    final String hybridPrompt = 
        "You are an expert AI Chef. Create a delicious recipe in language '$currentLang' using ONLY or mostly these ingredients: $chosenIngredients.\n"
        "CRITICAL SECURITY REQUIREMENT: Completely exclude these user allergens from the recipe: $allergensText.\n"
        "Provide a beautiful recipe title and step-by-step cooking instructions.";

    // 4. ԳՈՐԾԱՐԿՈՒՄ ԵՆՔ ԱՆՎՏԱՆԳ ԻԻ-Ն
    final String aiResponseRecipe = await NetworkApiController.generateRecipeHybrid(prompt: hybridPrompt);

    if (mounted) {
      // 5. 🌟 🏆 ԱՆՎՏԱՆԳ ԱՆՑՈՒՄ ԷԿՐԱՆԻՆ (0% ՏԻՊԱՅԻՆ ԿՈՆՖԼԻԿՏ)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AiChefPage(
            recipeTitle: AppLocalizations.of(context).translate('fridge_ingr_label'),
            originalRecipe: aiResponseRecipe, // Փոխանցում ենք ԻԻ-ի գեներացրած մաքուր տեքստը
            userAllergensGroups: textAllergensList, // 🌟 Փոխանցում ենք ակտիվ ալերգեն բաղադրիչների մաքուր ցուցակը հաջորդ էջին!
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ Ошибка подготовки данных для ИИ Шефа: $e');
  } finally {
    if (mounted) setState(() => _generatingAiRecipe = false);
  }
}


/*
  // 🌟 ԱՎԵԼԱՑՎԱԾ Է. ԻԻ ԼՈԳԻԿԱՆ՝ ԱՌԱՆՑ ՕՐԻԳԻՆԱԼ ԿՈԴԸ ԽԱԽՏԵԼՈՒ
  Future<void> _generateAiRecipeWithAllergens() async {
    if (_selectedNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(  AppLocalizations.of(context).translate('ingr_label1'), )),
      );
      return;
    }
    setState(() => _generatingAiRecipe = true);
    try {
      // Բեռնում ենք օգտատիրոջ ակտիվ ալերգենները բազայից
      final Map<String, bool> dbData = await NetworkApiController.fetchUserActiveSubstitutesPipeline();
      List<String> textAllergens = [];
      if (dbData['group_1'] == true) textAllergens.add('сыр, молоко, лактоза');
      if (dbData['group_2'] == true) textAllergens.add('орехи, арахис');
      if (dbData['group_3'] == true) textAllergens.add('глютен, мука');
      if (dbData['group_4'] == true) textAllergens.add('рыбы, морепродукты');
      if (dbData['group_5'] == true) textAllergens.add('яйца');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AiChefPage(
              recipeTitle: AppLocalizations.of(context).translate('fridge_ingr_label'),
              originalRecipe:  '${AppLocalizations.of(context).translate('choosed_ingr_label')} ${_selectedNames.join(", ")}.',
              userAllergens: textAllergens,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Ошибка подготовки данных для ИИ Шефа: $e');
    } finally {
      if (mounted) setState(() => _generatingAiRecipe = false);
    }
  }*/

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loadingIngredients) const LinearProgressIndicator(color: Colors.orange),
          const SizedBox(height: 8),
          Autocomplete<IngredientOption>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<IngredientOption>.empty();
              }
              final query = textEditingValue.text.trim().toLowerCase();
              return _allIngredients.map((item) {
                // Извлекаем ключи максимально безопасно
                final id = item['id']?.toString() ?? item['id_ingredient']?.toString() ?? '';
                final name = item['ingrname']?.toString() ?? item['title']?.toString() ?? item['name']?.toString() ?? 'Без названия';
                return IngredientOption(id: id, name: name);
              }).where((option) => option.name.toLowerCase().contains(query)).toList();
            },
            displayStringForOption: (option) => option.name,
            onSelected: _onIngredientSelected,
            fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
              _autocompleteController = textController;
              return TextField(
                controller: textController,
                focusNode: focusNode,
                decoration:  InputDecoration(
                  labelText: AppLocalizations.of(context).translate('input_ingr_label'), 
                  prefixIcon: Icon(Icons.search, color: Colors.orange),
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Холодильник
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
              color: isDark ? Colors.grey.shade800 : Colors.orange.shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).translate('choosed_ingr_lbl'), style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (_selectedNames.isEmpty)
                  Text(AppLocalizations.of(context).translate('fridge_empty_lbl'), style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _selectedNames.map((name) {
                      return Chip(
                        label: Text(name),
                        onDeleted: () {
                          setState(() {
                            int idx = _selectedNames.indexOf(name);
                            if (idx != -1) {
                              _selectedNames.removeAt(idx);
                              _selectedIds.removeAt(idx);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
),
const SizedBox(height: 16),
// ՁԵՐ ՕՐԻԳԻՆԱԼ ԿՈՃԱԿԸ (Անփոփոխ)
ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
onPressed: _searchRecipesBySelectedIngredients,

child: _searchingRecipes
? const CircularProgressIndicator(color: Colors.white)
: Text(AppLocalizations.of(context).translate('srchby_ingr_lbl'),  style: TextStyle(color: Colors.white)),
),

const SizedBox(height:12), // Տարածություն կոճակների միջև
// 🌟 ԱՎԵԼԱՑՎԱԾ Է. ՆՈՐ ԿՈՃԱԿ ՈՒՂԻՂ ԻԻ ՇԵՖԻՆ ԴԻՄԵԼՈՒ ՀԱՄԱՐ (ԱՌԱՆՑ ՀԻՄՔԸ ԽԱԽՏԵԼՈՒ)
ElevatedButton.icon(
style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),

icon: _generatingAiRecipe
? const SizedBox.shrink()
: const Icon(Icons.auto_awesome, color: Colors.white),
label: _generatingAiRecipe
? const CircularProgressIndicator(color: Colors.white)
:  Text(AppLocalizations.of(context).translate('rewrite_recipe_lbl'), 
style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),

onPressed: _generatingAiRecipe ? null : _generateAiRecipeWithAllergens,
),
const SizedBox(height: 12),

// Результаты (ՁԵՐ ՕՐԻԳԻՆԱԼ ԼԻՍՏԸ՝ ԱՆՓՈՓՈԽ)
Expanded(
child: _foundRecipes.isEmpty
?  Center(child: Text(AppLocalizations.of(context).translate('notfound_lbl'), 
style: TextStyle(color: Colors.grey)))
: ListView.builder(
itemCount: _foundRecipes.toList().length,
itemBuilder: (context, index) {
final recipe = _foundRecipes[index];
// Парсим ключи с защитой от null
final title = recipe['title']?.toString() ?? recipe['dish']?.toString() ?? 'Без названия';
final ingredientList = recipe['ingredientList']?.toString().replaceAll('[', '').replaceAll(']', '') ?? 'Список ингредиентов';
final instructions = recipe['instructions']?.toString() ?? recipe['recipe_instructions']?.toString() ?? 'Инструкции отсутствуют';

final List<String> userAllergens = NetworkApiController.activeAllergenGroups; // 🌟 ԱՎԵԼԱՑՎԱԾ Է. Օգտատիրոջ ալերգենները

return Card(
child: ExpansionTile(

 title: Padding(
      padding: const EdgeInsets.only(bottom: 12.0), // 👈 Այս 8 թվով կարող եք մեծացնել հեռավորությունը (օր.՝ 12.0)
      child: Text(
        title, 
        style: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold, 
          color: Colors.black,
        ),
      ),
    ),


subtitle: Text(ingredientList,
style: TextStyle(fontSize: 14)),
 children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Отображаем оригинальный текст шагов приготовления
            Text(
              instructions,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),

 
const SizedBox(height: 12),
// 2. 🌟 КНОПКА ИИ ШЕФА ТЕПЕРЬ ПРИВЯЗАНА К ЭТОМУ РЕЦЕПТУ!

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text(
                  "Переписать этот рецепт через ИИ Шефа",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                
             

                // 🌟 КУЛЬМИНАЦИЯ: Переходим на AiChefPage и передаем данные ЭТОГО рецепта!
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AiChefPage(
                        recipeTitle: title,       // Передаем название конкретного блюда
                        originalRecipe: instructions, // Передаем оригинальные
                        userAllergensGroups: userAllergens, // Передаем активные аллергены пользователя
                        )
                    ));
                },
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
  }
  )
)
],
),
);
  
}
}
