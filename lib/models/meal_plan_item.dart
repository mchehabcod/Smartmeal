import 'package:cloud_firestore/cloud_firestore.dart';

class MealPlanItem {
  final String recipeId;
  final String title;
  final double estimatedCost;
  final DateTime addedAt;
  final DateTime? plannedWeekStart;
  final DateTime? plannedWeekEnd;

  const MealPlanItem({
    required this.recipeId,
    required this.title,
    required this.estimatedCost,
    required this.addedAt,
    this.plannedWeekStart,
    this.plannedWeekEnd,
  });

  factory MealPlanItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return MealPlanItem(
      recipeId: m['recipeId']?.toString() ?? doc.id,
      title: m['title']?.toString() ?? '',
      estimatedCost: (m['estimatedCost'] is num)
          ? (m['estimatedCost'] as num).toDouble()
          : double.tryParse('${m['estimatedCost']}') ?? 0.0,
      addedAt: _toDateTime(m['addedAt']) ?? DateTime.now(),
      plannedWeekStart: _toDateTime(m['plannedWeekStart']),
      plannedWeekEnd: _toDateTime(m['plannedWeekEnd']),
    );
  }

  bool belongsToBudgetPeriod(dynamic period) {
    final weekStart = plannedWeekStart;
    final weekEnd = plannedWeekEnd;
    if (weekStart != null && weekEnd != null) {
      return period.contains(weekStart) || period.contains(weekEnd);
    }
    return period.contains(addedAt);
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
