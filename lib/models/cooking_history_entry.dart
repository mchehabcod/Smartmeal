import 'package:cloud_firestore/cloud_firestore.dart';

class CookingHistoryEntry {
  final String id;
  final String recipeId;
  final String recipeTitle;
  final DateTime cookedAt;
  final double estimatedCost;
  final DateTime? plannedWeekStart;
  final DateTime? plannedWeekEnd;

  const CookingHistoryEntry({
    required this.id,
    required this.recipeId,
    required this.recipeTitle,
    required this.cookedAt,
    this.estimatedCost = 0.0,
    this.plannedWeekStart,
    this.plannedWeekEnd,
  });

  factory CookingHistoryEntry.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data() ?? {};
    final ts = m['cookedAt'];
    DateTime cooked;
    if (ts is Timestamp) {
      cooked = ts.toDate();
    } else {
      cooked = DateTime.now();
    }
    return CookingHistoryEntry(
      id: doc.id,
      recipeId: m['recipeId']?.toString() ?? '',
      recipeTitle: m['recipeTitle']?.toString() ?? '',
      cookedAt: cooked,
      estimatedCost: _toDouble(m['estimatedCost']),
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
    return period.contains(cookedAt);
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
