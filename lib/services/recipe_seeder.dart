import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/recipe_model.dart';

class RecipeSeeder {
  static const String _configuredApiKey = AppConfig.spoonacularApiKey;
  static const String _baseUrl = 'https://api.spoonacular.com';

  final FirebaseFirestore _db;
  final http.Client _client;
  final String _apiKey;

  RecipeSeeder({
    FirebaseFirestore? firestore,
    http.Client? client,
    String? apiKey,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _client = client ?? http.Client(),
       _apiKey = (apiKey ?? _configuredApiKey).trim();

  /// Call once to seed first 50 recipes.
  Future<int> seedSampleData({String keyword = 'pasta', int limit = 50}) async {
    if (_apiKey.isEmpty) {
      throw StateError(
        'Spoonacular API key is not configured. Start the app with '
        '--dart-define=SPOONACULAR_API_KEY=your_key to seed recipes.',
      );
    }

    final recipeIds = await _fetchRecipeIdsByKeyword(
      keyword: keyword,
      limit: limit,
    );

    if (recipeIds.isEmpty) return 0;

    final recipes = <Recipe>[];
    for (final id in recipeIds) {
      final recipe = await _fetchAndMapRecipe(id);
      if (recipe != null) {
        recipes.add(recipe);
      }
    }

    final batch = _db.batch();
    for (final recipe in recipes) {
      final docRef = _db.collection('recipes').doc(recipe.id);
      batch.set(docRef, recipe.toMap(), SetOptions(merge: true));
    }
    await batch.commit();

    return recipes.length;
  }

  Future<List<int>> _fetchRecipeIdsByKeyword({
    required String keyword,
    required int limit,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/recipes/findByIngredients'
      '?ingredients=${Uri.encodeQueryComponent(keyword)}'
      '&number=$limit'
      '&ranking=2'
      '&ignorePantry=true'
      '&apiKey=${Uri.encodeQueryComponent(_apiKey)}',
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    if (data is! List) return [];

    return data
        .whereType<Map>()
        .map((item) => _toInt(item['id']))
        .where((id) => id > 0)
        .toSet()
        .toList();
  }

  Future<Recipe?> _fetchAndMapRecipe(int id) async {
    final uri = Uri.parse(
      '$_baseUrl/recipes/$id/information'
      '?includeNutrition=true'
      '&apiKey=${Uri.encodeQueryComponent(_apiKey)}',
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final raw = jsonDecode(response.body);
    if (raw is! Map<String, dynamic>) return null;

    final ingredients = _mapIngredients(raw['extendedIngredients']);
    final steps = _mapSteps(
      analyzedInstructions: raw['analyzedInstructions'],
      fallbackInstructions: raw['instructions'],
    );
    final macros = _extractMacros(raw['nutrition']);

    return Recipe(
      id: (raw['id'] ?? id).toString(),
      title: raw['title']?.toString() ?? 'Untitled Recipe',
      ingredients: ingredients,
      steps: steps,
      prepTime: _toInt(raw['readyInMinutes']),
      estimatedCost: _toDouble(raw['pricePerServing']) / 100.0,
      calories: _extractCalories(raw['nutrition']),
      macros: macros,
      imageUrl: raw['image']?.toString() ?? '',
    );
  }

  List<Map<String, dynamic>> _mapIngredients(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) {
      final mapped = item.map((k, v) => MapEntry(k.toString(), v));
      return {
        'id': _toInt(mapped['id']).toString(),
        'name': mapped['nameClean']?.toString().trim().isNotEmpty == true
            ? mapped['nameClean'].toString()
            : (mapped['name']?.toString() ?? ''),
        'amount': _toDouble(mapped['amount']),
        'unit': mapped['unit']?.toString() ?? '',
        'original': mapped['original']?.toString() ?? '',
      };
    }).toList();
  }

  List<String> _mapSteps({
    required dynamic analyzedInstructions,
    required dynamic fallbackInstructions,
  }) {
    if (analyzedInstructions is List && analyzedInstructions.isNotEmpty) {
      final first = analyzedInstructions.first;
      if (first is Map && first['steps'] is List) {
        final steps = (first['steps'] as List)
            .whereType<Map>()
            .map((step) => step['step']?.toString() ?? '')
            .where((step) => step.trim().isNotEmpty)
            .toList();
        if (steps.isNotEmpty) return steps;
      }
    }

    final fallback = fallbackInstructions?.toString() ?? '';
    if (fallback.trim().isEmpty) return const ['No instructions available.'];

    return fallback
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  int _extractCalories(dynamic nutrition) {
    if (nutrition is! Map) return 0;
    final nutrients = nutrition['nutrients'];
    if (nutrients is! List) return 0;

    for (final item in nutrients.whereType<Map>()) {
      final name = item['name']?.toString().toLowerCase() ?? '';
      if (name == 'calories') return _toInt(item['amount']);
    }
    return 0;
  }

  Map<String, String> _extractMacros(dynamic nutrition) {
    if (nutrition is! Map) {
      return {'protein': '0g', 'carbs': '0g', 'fat': '0g'};
    }

    final nutrients = nutrition['nutrients'];
    if (nutrients is! List) {
      return {'protein': '0g', 'carbs': '0g', 'fat': '0g'};
    }

    String protein = '0g';
    String carbs = '0g';
    String fat = '0g';

    for (final item in nutrients.whereType<Map>()) {
      final name = item['name']?.toString().toLowerCase() ?? '';
      final amount = _toDouble(item['amount']);
      final unit = item['unit']?.toString() ?? 'g';
      final value = '${amount.toStringAsFixed(1)}$unit';

      if (name == 'protein') protein = value;
      if (name == 'carbohydrates') carbs = value;
      if (name == 'fat') fat = value;
    }

    return {'protein': protein, 'carbs': carbs, 'fat': fat};
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
