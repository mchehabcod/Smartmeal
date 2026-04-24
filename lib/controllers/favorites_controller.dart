import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/recipe_model.dart';

/// US0010: favorites under `users/{uid}/favorites/{recipeId}`.
class FavoritesController {
  final FirebaseFirestore _db;

  FavoritesController({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _favDoc(String uid, String recipeId) =>
      _db.collection('users').doc(uid).collection('favorites').doc(recipeId);

  static String _normalizeRecipeId(Recipe recipe) => recipe.id.trim();

  Stream<bool> watchIsFavorite(String uid, String recipeId) {
    final id = recipeId.trim();
    if (id.isEmpty) {
      return Stream<bool>.value(false);
    }
    return _favDoc(uid, id).snapshots().map((s) => s.exists);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchFavoriteDocs(
    String uid,
  ) {
    return _db.collection('users').doc(uid).collection('favorites').snapshots().map(
      (s) {
        final docs =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(s.docs);
        int ts(QueryDocumentSnapshot<Map<String, dynamic>> d) {
          final t = d.data()['savedAt'];
          if (t is Timestamp) return t.millisecondsSinceEpoch;
          return 0;
        }

        docs.sort((a, b) => ts(b).compareTo(ts(a)));
        return docs;
      },
    );
  }

  /// Returns `null` on success, `'error'` on failure.
  ///
  /// Uses [SetOptions.merge] so repeat taps stay consistent and the favorites
  /// tab stream always reflects the hearted recipe.
  Future<String?> addFavorite({
    required String studentId,
    required Recipe recipe,
  }) async {
    final recipeId = _normalizeRecipeId(recipe);
    if (recipeId.isEmpty) return 'error';
    try {
      await _favDoc(studentId, recipeId).set(
        {
          'recipeId': recipeId,
          'title': recipe.title,
          'savedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return null;
    } on FirebaseException catch (e, st) {
      debugPrint('addFavorite FirebaseException: ${e.code} ${e.message} $st');
      return 'error';
    } catch (e, st) {
      debugPrint('addFavorite: $e $st');
      return 'error';
    }
  }

  Future<String?> removeFavorite({
    required String studentId,
    required String recipeId,
  }) async {
    final id = recipeId.trim();
    if (id.isEmpty) return 'error';
    try {
      await _favDoc(studentId, id).delete();
      return null;
    } on FirebaseException catch (e, st) {
      debugPrint('removeFavorite FirebaseException: ${e.code} ${e.message} $st');
      return 'error';
    } catch (e, st) {
      debugPrint('removeFavorite: $e $st');
      return 'error';
    }
  }
}
