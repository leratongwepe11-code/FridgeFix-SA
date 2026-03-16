import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Make sure to add this to your pubspec.yaml

void main() => runApp(FridgeFixApp());

class FridgeFixApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FridgeFix SA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

// --- DATA MODEL ---
class Recipe {
  final String name;
  final List<String> ingredients;
  final String instructions;
  final String imageUrl;
  final String affiliateUrl; // The "Profit" link

  Recipe({
    required this.name, 
    required this.ingredients, 
    required this.instructions, 
    required this.imageUrl,
    this.affiliateUrl = "https://www.checkers.co.za/sixty60", // Default placeholder
  });
}

// --- DATABASE (Mock) ---
List<Recipe> recipeDatabase = [
  Recipe(
    name: "Cheesy Egg Toast",
    ingredients: ["egg", "bread", "cheese"],
    instructions: "1. Toast your bread.\n2. Fry your egg.\n3. Melt cheese on top.",
    imageUrl: "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400",
    affiliateUrl: "https://www.checkers.co.za/search?text=eggs+bread+cheese",
  ),
  Recipe(
    name: "Tomato Egg Scramble",
    ingredients: ["egg", "tomato", "onion"],
    instructions: "1. Chop tomatoes and onions.\n2. Sauté until soft.\n3. Add whisked eggs.",
    imageUrl: "https://images.unsplash.com/photo-1594759842811-97b533307e4e?w=400",
    affiliateUrl: "https://www.woolworths.co.za/cat/Food/_/N-1z13sk5",
  ),
];

// --- MAIN UI ---
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _userFridge = [];
  List<Recipe> _results = [];

  void _addIngredient() {
    String input = _controller.text.trim().toLowerCase();
    if (input.isNotEmpty && !_userFridge.contains(input)) {
      setState(() {
        _userFridge.add(input);
        _controller.clear();
      });
      _findRecipes(); // Live search update
    }
  }

  void _findRecipes() {
    setState(() {
      _results = recipeDatabase.where((recipe) {
        // Show if user has at least 1 ingredient (Choosable)
        return recipe.ingredients.any((item) => _userFridge.contains(item));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🇿🇦 FridgeFix SA"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "What's in your fridge?",
                hintText: "e.g., egg, milk, tomato",
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(icon: Icon(Icons.add_circle), onPressed: _addIngredient),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _addIngredient(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _userFridge.map((i) => Chip(
                label: Text(i),
                onDeleted: () => setState(() { _userFridge.remove(i); _findRecipes(); }),
                backgroundColor: Colors.green.shade50,
              )).toList(),
            ),
            const Divider(height: 30),
            Expanded(
              child: _results.isEmpty 
                ? Center(child: Text("Add ingredients to see recipes!"))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final recipe = _results[index];
                      final missing = recipe.ingredients.where((i) => !_userFridge.contains(i)).toList();
                      
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(10),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(recipe.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                          ),
                          title: Text(recipe.name, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(missing.isEmpty 
                            ? "✅ Ready to cook!" 
                            : "🛒 Need: ${missing.join(', ')}"),
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (c) => RecipeDetails(recipe: recipe, missing: missing))),
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

// --- DETAIL SCREEN (The Monetized Part) ---
class RecipeDetails extends StatelessWidget {
  final Recipe recipe;
  final List<String> missing;

  RecipeDetails({required this.recipe, required this.missing});

  Future<void> _launchStore(String url) async {
    final Uri _url = Uri.parse(url);
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipe.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(recipe.imageUrl, width: double.infinity, height: 250, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ingredients Needed:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ...recipe.ingredients.map((i) => Text("• $i", 
                    style: TextStyle(color: missing.contains(i) ? Colors.red : Colors.green))),
                  const SizedBox(height: 20),
                  Text("Instructions:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(recipe.instructions, style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 30),
                  
                  // THE PROFITABLE HOOK
                  if (missing.isNotEmpty) 
                    Center(
                      child: Column(
                        children: [
                          Text("Missing items? Don't stress.", style: TextStyle(fontStyle: FontStyle.italic)),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => _launchStore(recipe.affiliateUrl),
                            icon: Icon(Icons.shopping_cart),
                            label: Text("Order Missing via Sixty60"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            ),
                          ),
                        ],
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
