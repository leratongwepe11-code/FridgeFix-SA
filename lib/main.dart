import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(FridgeFixApp());

class FridgeFixApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FridgeFix SA',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: HomePage(),
    );
  }
}

class Recipe {
  final String name;
  final List<String> ingredients;
  final String instructions;
  final String imageUrl;
  final String affiliateUrl;

  Recipe({
    required this.name, 
    required this.ingredients, 
    required this.instructions, 
    required this.imageUrl, 
    this.affiliateUrl = "https://www.checkers.co.za/sixty60"
  });
}

List<Recipe> recipeDatabase = [
  Recipe(
    name: "Cheesy Egg Toast",
    ingredients: ["egg", "bread", "cheese"],
    instructions: "1. Toast bread. 2. Fry egg. 3. Top with cheese.",
    imageUrl: "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400",
  ),
  Recipe(
    name: "Tomato Egg Scramble",
    ingredients: ["egg", "tomato", "onion"],
    instructions: "1. Sauté onion and tomato. 2. Add eggs and scramble.",
    imageUrl: "https://images.unsplash.com/photo-1594759842811-97b533307e4e?w=400",
  ),
];

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController controller = TextEditingController();
  List<String> fridge = [];
  List<Recipe> results = [];

  void findRecipes() {
    setState(() {
      results = recipeDatabase.where((r) => 
        r.ingredients.any((i) => fridge.contains(i.toLowerCase()))).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🇿🇦 FridgeFix SA"), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Add ingredient (e.g. egg)",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add), 
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      setState(() { 
                        fridge.add(controller.text.trim().toLowerCase()); 
                        controller.clear(); 
                      });
                      findRecipes();
                    }
                  }
                ),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            children: fridge.map((i) => Chip(
              label: Text(i),
              onDeleted: () => setState(() { fridge.remove(i); findRecipes(); }),
            )).toList(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (c, i) {
                final r = results[i];
                final missing = r.ingredients.where((ing) => !fridge.contains(ing)).toList();
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(r.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(missing.isEmpty ? "✅ Ready to cook!" : "🛒 Need: ${missing.join(', ')}"),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(c, MaterialPageRoute(
                      builder: (context) => DetailPage(recipe: r, missing: missing))),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final Recipe recipe;
  final List<String> missing;
  DetailPage({required this.recipe, required this.missing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipe.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(recipe.imageUrl, width: double.infinity, height: 250, fit: BoxFit.cover),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Instructions:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text(recipe.instructions, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 30),
                  if (missing.isNotEmpty) Center(
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(recipe.affiliateUrl)),
                      icon: Icon(Icons.shopping_cart),
                      label: Text("Order Missing on Sixty60"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, 
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
