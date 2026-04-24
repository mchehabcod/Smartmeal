import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import '../utils/ingredient_category.dart';
import '../utils/recipe_filters.dart';

/// How long a checked row stays visible (strikethrough) before it is removed.
const Duration shoppingCheckedGrace = Duration(hours: 24);

/// One line in the shopping list UI (Plan → Shopping).
class ShoppingListLineUi {
  final String category;
  final String line;
  final bool isChecked;

  const ShoppingListLineUi({
    required this.category,
    required this.line,
    required this.isChecked,
  });
}

/// Parsed shopping list for display, including check state.
class ShoppingListDisplayState {
  final Map<String, List<ShoppingListLineUi>> byCategory;
  /// True when some rows are checked past [shoppingCheckedGrace] and a prune write was needed.
  final bool hasExpiredChecked;

  const ShoppingListDisplayState({
    required this.byCategory,
    this.hasExpiredChecked = false,
  });

  bool get isEmpty =>
      byCategory.values.every((list) => list.isEmpty) || byCategory.isEmpty;
}

/// US009: compare planned recipes to pantry; categorize missing items.
class ShoppingListService {
  final FirebaseFirestore _db;

  ShoppingListService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _shoppingListRef(String studentId) =>
      _db.collection('users').doc(studentId).collection('meta').doc('shoppingList');

  /// Stable id for a row within the shopping list document.
  static String itemCheckKey(String category, String line) =>
      '${category.trim()}\x1E${line.trim()}';

  static Map<String, List<String>> _parseItemsByCategory(dynamic raw) {
    if (raw is! Map) return {};
    return Map<String, List<String>>.from(
      raw.map((k, v) {
        if (v is List) {
          return MapEntry(
            k.toString(),
            v.map((e) => e.toString()).toList(),
          );
        }
        return MapEntry(k.toString(), <String>[]);
      }),
    );
  }

  static Map<String, DateTime> _parseCheckedAt(Map<String, dynamic>? data) {
    final raw = data?['checkedItems'];
    if (raw is! Map) return {};
    final out = <String, DateTime>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v is Timestamp) {
        out[e.key.toString()] = v.toDate();
      } else if (v is Map && v['at'] is Timestamp) {
        out[e.key.toString()] = (v['at'] as Timestamp).toDate();
      }
    }
    return out;
  }

  ShoppingListDisplayState _displayStateFromDocument(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final m = snap.data();
    if (m == null) {
      return const ShoppingListDisplayState(byCategory: {});
    }
    final items = _parseItemsByCategory(m['itemsByCategory']);
    final checkedAt = _parseCheckedAt(m);
    final now = DateTime.now();
    final cutoff = now.subtract(shoppingCheckedGrace);
    var hasExpired = false;

    final byCategory = <String, List<ShoppingListLineUi>>{};
    for (final catEntry in items.entries) {
      final cat = catEntry.key;
      final rows = <ShoppingListLineUi>[];
      for (final line in catEntry.value) {
        final key = itemCheckKey(cat, line);
        final at = checkedAt[key];
        if (at != null) {
          if (!at.isAfter(cutoff)) {
            hasExpired = true;
            continue;
          }
          rows.add(ShoppingListLineUi(category: cat, line: line, isChecked: true));
        } else {
          rows.add(ShoppingListLineUi(category: cat, line: line, isChecked: false));
        }
      }
      if (rows.isNotEmpty) {
        byCategory[cat] = rows;
      }
    }
    return ShoppingListDisplayState(
      byCategory: byCategory,
      hasExpiredChecked: hasExpired,
    );
  }

  /// Removes checked rows older than [shoppingCheckedGrace] from Firestore.
  Future<void> maybePruneExpiredFromRemote(String studentId) async {
    final ref = _shoppingListRef(studentId);
    try {
      await _db.runTransaction((txn) async {
        final snap = await txn.get(ref);
        if (!snap.exists || snap.data() == null) return;
        final m = snap.data()!;
        final items = <String, List<String>>{};
        for (final e in _parseItemsByCategory(m['itemsByCategory']).entries) {
          items[e.key] = List<String>.from(e.value);
        }
        final checkedRaw = m['checkedItems'];
        if (checkedRaw is! Map || checkedRaw.isEmpty) return;

        final checkedAt = _parseCheckedAt(m);
        if (checkedAt.isEmpty) return;

        final cutoff = DateTime.now().subtract(shoppingCheckedGrace);
        final keysToRemove = checkedAt.entries
            .where((e) => !e.value.isAfter(cutoff))
            .map((e) => e.key)
            .toList();
        if (keysToRemove.isEmpty) return;

        for (final key in keysToRemove) {
          checkedAt.remove(key);
          final sep = key.indexOf('\x1E');
          if (sep <= 0 || sep >= key.length - 1) continue;
          final cat = key.substring(0, sep);
          final line = key.substring(sep + 1);
          final list = items[cat];
          if (list == null) continue;
          list.remove(line);
          if (list.isEmpty) {
            items.remove(cat);
          }
        }

        final checkedForWrite = <String, Timestamp>{
          for (final e in checkedAt.entries) e.key: Timestamp.fromDate(e.value),
        };

        txn.set(
          ref,
          {
            'itemsByCategory': items,
            'checkedItems': checkedForWrite,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (_) {
      // Non-fatal; UI already hides expired rows until next successful prune.
    }
  }

  /// Toggle strikethrough / checked state for one ingredient line.
  Future<String?> setShoppingItemChecked({
    required String studentId,
    required String category,
    required String line,
    required bool checked,
  }) async {
    final ref = _shoppingListRef(studentId);
    final key = itemCheckKey(category, line);
    try {
      if (checked) {
        await ref.update({
          FieldPath(['checkedItems', key]): FieldValue.serverTimestamp(),
        });
      } else {
        await ref.update({
          FieldPath(['checkedItems', key]): FieldValue.delete(),
        });
      }
      return null;
    } catch (_) {
      return 'error';
    }
  }

  /// Same data as [watchShoppingListDisplay] but without check metadata (legacy callers).
  Stream<Map<String, List<String>>> watchSavedShoppingList(String studentId) {
    return watchShoppingListDisplay(studentId).map((state) {
      return state.byCategory.map(
        (cat, rows) => MapEntry(
          cat,
          rows.map((r) => r.line).toList(),
        ),
      );
    });
  }

  /// Shopping list with per-line checked state; prunes expired checked rows on the server when needed.
  Stream<ShoppingListDisplayState> watchShoppingListDisplay(String studentId) {
    return _shoppingListRef(studentId).snapshots().asyncMap((snap) async {
      final state = _displayStateFromDocument(snap);
      if (state.hasExpiredChecked) {
        await maybePruneExpiredFromRemote(studentId);
      }
      return state;
    });
  }

  /// Codes: `null` + data, `'no_meals'`, `'no_pantry'`, `'error'`
  Future<({String? code, Map<String, List<String>>? byCategory})>
      buildShoppingList({
    required String studentId,
  }) async {
    try {
      final userRef = _db.collection('users').doc(studentId);
      final userSnap = await userRef.get();
      final pantry = StudentPantry.parse(userSnap.data()?['availableIngredients']);

      if (pantry.isEmpty) {
        return (code: 'no_pantry', byCategory: null);
      }

      final planSnap = await userRef.collection('mealPlan').get();
      if (planSnap.docs.isEmpty) {
        return (code: 'no_meals', byCategory: null);
      }

      final missing = <String>{};

      for (final planDoc in planSnap.docs) {
        final recipeId = planDoc.data()['recipeId']?.toString() ?? planDoc.id;
        final recipeSnap =
            await _db.collection('recipes').doc(recipeId).get();
        if (!recipeSnap.exists || recipeSnap.data() == null) continue;
        final recipe = Recipe.fromMap(recipeSnap.data()!, recipeSnap.id);

        for (final ing in recipe.ingredients) {
          final line =
              (ing['name'] ?? ing['original'] ?? '').toString().trim();
          if (line.isEmpty) continue;
          if (!ingredientLineCoveredByPantry(line, pantry)) {
            missing.add(line);
          }
        }
      }

      final byCategory = <String, List<String>>{};
      for (final name in missing) {
        final cat = categorizeIngredient(name);
        byCategory.putIfAbsent(cat, () => []).add(name);
      }
      for (final e in byCategory.entries) {
        e.value.sort();
      }

      final listRef = userRef.collection('meta').doc('shoppingList');
      final existing = await listRef.get();
      final preservedChecked = <String, dynamic>{};
      final existingData = existing.data();
      final rawChecked = existingData?['checkedItems'];
      if (rawChecked is Map) {
        final validKeys = <String>{};
        for (final e in byCategory.entries) {
          for (final line in e.value) {
            validKeys.add(itemCheckKey(e.key, line));
          }
        }
        for (final e in rawChecked.entries) {
          if (validKeys.contains(e.key)) {
            preservedChecked[e.key.toString()] = e.value;
          }
        }
      }

      await listRef.set({
        'itemsByCategory': byCategory,
        'checkedItems': preservedChecked,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return (code: null, byCategory: byCategory);
    } catch (_) {
      return (code: 'error', byCategory: null);
    }
  }
}

class StudentPantry {
  static List<String> parse(dynamic value) {
    if (value is! List) return [];
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
