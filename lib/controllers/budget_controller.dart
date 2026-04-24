import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';

class BudgetController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> setWeeklyBudget({
    required String studentId,
    required double weeklyBudget,
  }) async {
    if (weeklyBudget < 0) {
      return 'Weekly budget cannot be negative';
    }

    try {
      final budget = Budget(
        studentID: studentId,
        weeklyBudget: weeklyBudget,
        updatedAt: DateTime.now(),
      );

      await _db.collection('users').doc(studentId).set({
        'weeklyBudget': budget.weeklyBudget,
        'studentID': budget.studentID,
      }, SetOptions(merge: true));

      await _db.collection('budgets').doc(studentId).set(budget.toMap());
      return null;
    } catch (_) {
      return 'Failed to update weekly budget';
    }
  }
}
