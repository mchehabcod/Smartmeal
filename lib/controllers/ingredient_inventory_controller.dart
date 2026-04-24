import 'package:cloud_firestore/cloud_firestore.dart';

/// Persists manually entered pantry ingredients on `users/{studentId}` (UC004).
class IngredientInventoryController {
  final FirebaseFirestore _db;

  IngredientInventoryController({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Normalizes list: trim, drop empties, case-insensitive dedupe (keeps first casing).
  static List<String> normalizeIngredients(List<String> raw) {
    final seen = <String>{};
    final out = <String>[];
    for (final item in raw) {
      final t = item.trim();
      if (t.isEmpty) continue;
      final key = t.toLowerCase();
      if (seen.add(key)) out.add(t);
    }
    return out;
  }

  Future<String?> saveAvailableIngredients({
    required String studentId,
    required List<String> ingredients,
  }) async {
    try {
      final cleaned = normalizeIngredients(ingredients);
      await _db.collection('users').doc(studentId).set(
        {'availableIngredients': cleaned},
        SetOptions(merge: true),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
