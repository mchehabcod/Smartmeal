import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_summary.dart';
import '../models/cooking_history_entry.dart';
import '../models/meal_plan_item.dart';
import '../models/recipe_model.dart';

/// US008: persist selected meals under `users/{uid}/mealPlan/{recipeId}`.
class MealPlanController {
  final FirebaseFirestore _db;

  MealPlanController({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _mealPlan(String uid) =>
      _db.collection('users').doc(uid).collection('mealPlan');
  CollectionReference<Map<String, dynamic>> _history(String uid) =>
      _db.collection('users').doc(uid).collection('cookingHistory');

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchMealPlanDocs(
    String uid,
  ) {
    return _mealPlan(uid).snapshots().map((s) {
      final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
        s.docs,
      );
      int ts(QueryDocumentSnapshot<Map<String, dynamic>> d) {
        final t = d.data()['addedAt'];
        if (t is Timestamp) return t.millisecondsSinceEpoch;
        return 0;
      }

      docs.sort((a, b) => ts(b).compareTo(ts(a)));
      return docs;
    });
  }

  Stream<List<MealPlanItem>> watchCurrentWeekMealPlanItems(String uid) {
    final period = BudgetPeriod.current();
    return watchMealPlanDocs(uid).map((docs) {
      return docs
          .map(MealPlanItem.fromDoc)
          .where((item) => item.belongsToBudgetPeriod(period))
          .toList();
    });
  }

  Stream<BudgetSummary> watchCurrentWeekBudgetSummary({
    required String uid,
    required double weeklyBudget,
  }) {
    late StreamSubscription<List<MealPlanItem>> mealPlanSub;
    late StreamSubscription<List<CookingHistoryEntry>> historySub;
    final controller = StreamController<BudgetSummary>();
    List<MealPlanItem>? latestMeals;
    List<CookingHistoryEntry>? latestHistory;

    void emitIfReady() {
      final meals = latestMeals;
      final history = latestHistory;
      if (meals == null || history == null || controller.isClosed) return;
      controller.add(
        BudgetSummary.fromMealPlanItems(
          weeklyBudget: weeklyBudget,
          items: meals,
          cookedItems: history,
        ),
      );
    }

    controller.onListen = () {
      mealPlanSub = watchCurrentWeekMealPlanItems(uid).listen((items) {
        latestMeals = items;
        emitIfReady();
      }, onError: controller.addError);
      historySub = watchCurrentWeekCookingHistory(uid).listen((items) {
        latestHistory = items;
        emitIfReady();
      }, onError: controller.addError);
    };
    controller.onCancel = () async {
      await mealPlanSub.cancel();
      await historySub.cancel();
    };

    return controller.stream;
  }

  Future<List<MealPlanItem>> getCurrentWeekMealPlanItems(String uid) async {
    final period = BudgetPeriod.current();
    final snap = await _mealPlan(uid).get();
    return snap.docs
        .map(MealPlanItem.fromDoc)
        .where((item) => item.belongsToBudgetPeriod(period))
        .toList();
  }

  Stream<List<CookingHistoryEntry>> watchCurrentWeekCookingHistory(String uid) {
    final period = BudgetPeriod.current();
    return _history(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map(CookingHistoryEntry.fromDoc)
          .where((item) => item.belongsToBudgetPeriod(period))
          .toList();
    });
  }

  Future<List<CookingHistoryEntry>> getCurrentWeekCookingHistory(
    String uid,
  ) async {
    final period = BudgetPeriod.current();
    final snap = await _history(uid).get();
    return snap.docs
        .map(CookingHistoryEntry.fromDoc)
        .where((item) => item.belongsToBudgetPeriod(period))
        .toList();
  }

  Future<MealPlanBudgetPreview> previewAddToMealPlan({
    required String studentId,
    required Recipe recipe,
  }) async {
    try {
      final doc = _mealPlan(studentId).doc(recipe.id);
      final snap = await doc.get();
      if (snap.exists) return MealPlanBudgetPreview.duplicate();

      final userDoc = await _db.collection('users').doc(studentId).get();
      final budget = _toDouble(userDoc.data()?['weeklyBudget']);
      final items = await getCurrentWeekMealPlanItems(studentId);
      final history = await getCurrentWeekCookingHistory(studentId);
      final currentCost =
          items.fold<double>(0, (total, item) => total + item.estimatedCost) +
          history.fold<double>(0, (total, item) => total + item.estimatedCost);

      return MealPlanBudgetPreview.ready(
        weeklyBudget: budget,
        currentCost: currentCost,
        projectedCost: currentCost + recipe.estimatedCost,
      );
    } catch (_) {
      return MealPlanBudgetPreview.error();
    }
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
      final period = BudgetPeriod.current();

      await doc.set({
        'recipeId': recipe.id,
        'title': recipe.title,
        'estimatedCost': recipe.estimatedCost,
        'costSource': 'recipe.estimatedCost',
        'addedAt': FieldValue.serverTimestamp(),
        'plannedWeekStart': Timestamp.fromDate(period.start),
        'plannedWeekEnd': Timestamp.fromDate(period.end),
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

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class MealPlanBudgetPreview {
  final String? code;
  final double weeklyBudget;
  final double currentCost;
  final double projectedCost;

  const MealPlanBudgetPreview._({
    required this.code,
    required this.weeklyBudget,
    required this.currentCost,
    required this.projectedCost,
  });

  factory MealPlanBudgetPreview.ready({
    required double weeklyBudget,
    required double currentCost,
    required double projectedCost,
  }) {
    return MealPlanBudgetPreview._(
      code: null,
      weeklyBudget: weeklyBudget < 0 ? 0 : weeklyBudget,
      currentCost: currentCost,
      projectedCost: projectedCost,
    );
  }

  factory MealPlanBudgetPreview.duplicate() {
    return const MealPlanBudgetPreview._(
      code: 'duplicate',
      weeklyBudget: 0,
      currentCost: 0,
      projectedCost: 0,
    );
  }

  factory MealPlanBudgetPreview.error() {
    return const MealPlanBudgetPreview._(
      code: 'error',
      weeklyBudget: 0,
      currentCost: 0,
      projectedCost: 0,
    );
  }

  bool get hasBudget => weeklyBudget > 0;
  bool get isOverBudget => hasBudget && projectedCost > weeklyBudget;
  double get overage => isOverBudget ? projectedCost - weeklyBudget : 0;
}
