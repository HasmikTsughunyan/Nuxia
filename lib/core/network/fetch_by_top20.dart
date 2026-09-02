// core/network/fetch_by_top20.dart
import 'package:flutter/material.dart';
import 'network_api_controller.dart';

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
  List<Map<String, dynamic>> _topRecipesList = [];
  bool _isLoading = false;

  void _checkNetwork() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Загрузка...';
      _topRecipesList = [];
    });
    
    try {
      // Вызываем наш обновленный метод
      final result = await NetworkApiController.fetchTop20Recipes();
      
      setState(() {
        _isLoading = false;
        _topRecipesList = result;
        if (_topRecipesList.isEmpty) {
          _statusMessage = 'Успешно, но база вернула 0 рецептов.';
        } else {
          _statusMessage = 'Найдено рецептов: ${_topRecipesList.length}';
        }
      });
    } catch (e) {
      // Если дебаг в консоли не работает, мы увидим ошибку прямо на экране смартфона/эмулятора!
      setState(() {
        _isLoading = false;
        _statusMessage = 'КРИТИЧЕСКАЯ ОШИБКА:\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тест архитектуры: Рецепты')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _checkNetwork,
              child: const Text('Запустить метод контроллера'),
            ),
            const SizedBox(height: 16),
            
            // Здесь отобразится текст ошибки, если метод упадет
            SelectableText(
              _statusMessage, 
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: _statusMessage.contains('ОШИБКА') ? Colors.red : Colors.green[800]
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _topRecipesList.isEmpty
                      ? const Center(child: Text('Здесь будет список рецептов'))
                      : ListView.builder(
                          itemCount: _topRecipesList.length,
                          itemBuilder: (context, index) {
                            final recipe = _topRecipesList[index];
                            
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
                                  Text(
                                    recipe['dish'] ?? 'Без названия',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 12),
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
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 18, color: Colors.blueGrey),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Кухня: ${recipe['cuisine'] ?? 'Не указан'}',
                                        style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                      ),
                                    ],
                                  ),
                                   Row(
                                    children: [
                                      const Icon(Icons.person, size: 18, color: Colors.blueGrey),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Источник: ${recipe['source'] ?? 'Не указан'}',
                                        style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                      ),
                                    ],
                                  ),
                                   Row(
                                    children: [
                                      const Icon(Icons.person, size: 18, color: Colors.blueGrey),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Список продуктов: ${recipe['ingredientlist'].toString().trim()}',
                                        style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.visibility, size: 18, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Просмотров: ${recipe['viewsCount'] ?? 0}',
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
