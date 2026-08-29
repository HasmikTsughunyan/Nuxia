// core/network/fetch_by_categories.dart
import 'package:flutter/material.dart';
import 'network_api_controller.dart'; // Проверьте, что путь именно такой


void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TestScreen(),
  ));
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String _statusMessage = 'Нажмите кнопку для загрузки рецептов';
  List<Map<String, dynamic>> _recipesList = [];
  bool _isLoading = false;

  void _checkNetwork() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Загрузка...';
      _recipesList = [];
      
    });
    
    // Вызываем ваш рабочий метод
    final result = await NetworkApiController.fetchRecipesFromCloud('салаты'); // Передаем тип категории, если он есть, иначе пустую строку
    
    setState(() {
      _isLoading = false;
      _recipesList = result;
      if (_recipesList.isEmpty) {
        _statusMessage = 'Связь есть, но база вернула пустой список';
      } else {
        _statusMessage = 'Найдено рецептов: ${_recipesList.length}';
      }
    });
    debugPrint('Fetched recipes: ${result.length}');
    debugPrint('Error: ${result.isEmpty ? 'No recipes found' : 'Recipes fetched successfully'}');
    debugPrint( 'result: $result.toListString()');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Рецепты')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Кнопка запуска
            ElevatedButton(
              onPressed: _checkNetwork,
              child: const Text('Запустить метод контроллера'),
            ),
            const SizedBox(height: 16),
            
            // Статус загрузки
            Text(_statusMessage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Индикатор загрузки или сам список
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _recipesList.isEmpty
                      ? const Center(child: Text('Здесь будет список рецептов'))
                      : ListView.builder(
                          itemCount: _recipesList.length,
                          itemBuilder: (context, index) {
                            final recipe = _recipesList[index];
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. НАЗВАНИЕ БЛЮДА (из поля 'dish')
                                  Text(
                                    recipe['dish'] ?? 'Без названия',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // 2. ФОТО (Пока в базе нет поля с картинкой, выводим красивую заглушку)
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: recipe['image_url'] != null
                                        ? Image.network(recipe['image_url'], fit: BoxFit.cover)
                                        : const Center(child: Icon(Icons.restaurant, size: 50, color: Colors.grey)),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // 3. АВТОР РЕЦЕПТА (из поля 'author_name')
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 18, color: Colors.blueGrey),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Автор: ${recipe['author_name'] ?? 'Не указан'}',
                                        style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  
                                  // 4. КОЛ-ВО ПРОСМОТРОВ (из поля 'views_count')
                                  Row(
                                    children: [
                                      const Icon(Icons.visibility, size: 18, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Просмотров: ${recipe['views_count'] ?? 0}',
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
