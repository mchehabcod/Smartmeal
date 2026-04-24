import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';

/// US008: persist selected meals under `users/{uid}/mealPlan/{recipeId}`.
class MealPlanController {
  final FirebaseFirestore _db;

  MealPlanController({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _mealPlan(String uid) =>
      _db.collection('users').doc(uid).collection('mealPlan');

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchMealPlanDocs(
    String uid,
  ) {
    return _mealPlan(uid).snapshots().map((s) {
      final docs =
          List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(s.docs);
      int ts(QueryDocumentSnapshot<Map<String, dynamic>> d) {
        final t = d.data()['addedAt'];
        if (t is Timestamp) return t.millisecondsSinceEpoch;
        return 0;
      }

      docs.sort((a, b) => ts(b).compareTo(ts(a)));
      return docs;
    });
  }

  /// Returns `null` on success, `'duplicate'`, or `'error'`.
  Future<String?> addToMealPlan({
    required String studentId,
    required Recipe recipe,
  }) async {
    try {
      final doc = _mealPlan(studentId).doc(recipe.id);
      final snap = await doc.get();
      if (snap.exists) return 'duplicate';

      await doc.set({
        'recipeId': recipe.id,
        'title': recipe.title,
        'estimatedCost': recipe.estimatedCost,
        'addedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (_) {
      return 'error';
    }
  }

  Future<String?> removeFromMealPlan({
    required String studentId,
    required String recipeId,
  }) async {
    try {
      await _mealPlan(studentId).doc(recipeId).delete();
      return null;
    } catch (_) {
      return 'error';
    }
  }
}
