class Recipe {
  final String id;
  final String title;
  final List<Map<String, dynamic>> ingredients;
  final List<String> steps;
  final int prepTime;
  final double estimatedCost;
  final int calories;
  final Map<String, String> macros;

  const Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.prepTime,
    required this.estimatedCost,
    required this.calories,
    this.macros = const {'protein': '0g', 'carbs': '0g', 'fat': '0g'},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'ingredients': ingredients,
      'steps': steps,
      'prepTime': prepTime,
      'estimatedCost': estimatedCost,
      'calories': calories,
      'macros': macros,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map, String documentId) {
    final rawIngredients = (map['ingredients'] as List?) ?? const [];
    final rawSteps = (map['steps'] as List?) ?? const [];

    return Recipe(
      id: map['id']?.toString() ?? documentId,
      title: map['title']?.toString() ?? '',
      ingredients: rawIngredients
          .whereType<Map>()
          .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
          .toList(),
      steps: rawSteps.map((step) => step.toString()).toList(),
      prepTime: _toInt(map['prepTime']),
      estimatedCost: _toDouble(map['estimatedCost']),
      calories: _toInt(map['calories']),
      macros: _toStringMap(map['macros']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static Map<String, String> _toStringMap(dynamic value) {
    if (value is Map) {
      final mapped = value.map(
        (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
      );
      return {
        'protein': mapped['protein'] ?? '0g',
        'carbs': mapped['carbs'] ?? '0g',
        'fat': mapped['fat'] ?? '0g',
      };
    }
    return {'protein': '0g', 'carbs': '0g', 'fat': '0g'};
  }
}
