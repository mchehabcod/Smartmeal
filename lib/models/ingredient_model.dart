class Ingredient {
  final String id;
  final String name;
  final String category;
  final String unit;
  final double pricePerUnit;

  const Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.pricePerUnit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map, String documentId) {
    return Ingredient(
      id: map['id']?.toString() ?? documentId,
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      pricePerUnit: _toDouble(map['pricePerUnit']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
