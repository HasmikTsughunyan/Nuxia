import 'package:flutter/material.dart';
// Импортируйте правильные пути к вашим файлам
import 'ai_chef_page.dart';
import '../network/network_api_controller.dart'; 

class AiChefMainPage extends StatefulWidget {
const AiChefMainPage({super.key});

@override
State<AiChefMainPage> createState() => _AiChefMainPageState();
}

class _AiChefMainPageState extends State<AiChefMainPage> {
// ИСПРАВЛЕНО: Объявляем переменные, которых не хватало компилятору
List<String> _activeAllergensForAi = [];
bool isLoadingAllergens = false;

@override
void initState() {
super.initState();
_loadCurrentAllergens();
}

void _loadCurrentAllergens() async {
setState(() => isLoadingAllergens = true);

// Загружаем данные из нашей настроенной БД Supabase
final Map<String, bool> dbData = await NetworkApiController.fetchUserAllergensFromDb();

List<String> textAllergens = [];
if (dbData['group_1'] == true) textAllergens.add('сыр, молоко, лактоза');
if (dbData['group_2'] == true) textAllergens.add('орехи, арахис');
if (dbData['group_3'] == true) textAllergens.add('глютен, мука');
if (dbData['group_4'] == true) textAllergens.add('рыбы, морепродукты');
if (dbData['group_5'] == true) textAllergens.add('яйца');

setState(() {
_activeAllergensForAi = textAllergens;
isLoadingAllergens = false;
});
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Чат с ИИ Шефом'), backgroundColor: Colors.orange),
body: Padding(
padding: const EdgeInsets.all(24.0),
child: Column(
children: [
// ПЛИТКА 1: ГЕНЕРАТОР РЕЦЕПТОВ
_buildMenuCard(
title: 'Умный генератор рецептов',
description: 'Создание блюд из вашего холодильника с автоматической заменой аллергенов.',
icon: Icons.auto_awesome,
onTap: isLoadingAllergens ? () {} : () {
Navigator.push(
context,
MaterialPageRoute(
// ИСПРАВЛЕНО: передаем параметры строго по именам конструктора
builder: (context) => AiChefPage(
recipeTitle: 'Салат Цезарь',
originalRecipe: 'Ингредиенты: куриное филе, салат Романо, гренки, соус, сыр Пармезан.',
userAllergens: _activeAllergensForAi,
),
),
);
},
),
],
),
),
);
}
//ПЛИТКА 2: Чат с ИИ шефом
Widget _buildMenuCard({
required String title, 
required String description, 
required IconData icon, 
required VoidCallback onTap}) {
return InkWell(
onTap: onTap, // здесь должен быть AiCHefChatPage
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
child: Row(
children: [
Icon(icon, color: Colors.orange, size: 32),
const SizedBox(width: 16),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(description, style: const TextStyle(fontSize: 12))])),
],
),
),
);
}
}

