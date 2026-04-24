import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';

/// US0011: log prepared meals under `users/{uid}/cookingHistory/{autoId}`.
class CookingHistoryController {
  final FirebaseFirestore _db;

  CookingHistoryController({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _history(String uid) =>
      _db.collection('users').doc(uid).collection('cookingHistory');

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchHistoryDocs(
    String uid,
  ) {
    return _history(uid).snapshots().map((s) {
      final docs =
          List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(s.docs);
      int ts(QueryDocumentSnapshot<Map<String, dynamic>> d) {
        final t = d.data()['cookedAt'];
        if (t is Timestamp) return t.millisecondsSinceEpoch;
        return 0;
      }

      docs.sort((a, b) => ts(b).compareTo(ts(a)));
      return docs;
    });
  }

  Future<String?> logCooked({
    required String studentId,
    required Recipe recipe,
  }) async {
    try {
      await _history(studentId).add({
        'recipeId': recipe.id,
        'recipeTitle': recipe.title,
        'cookedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (_) {
      return 'error';
    }
  }
}
