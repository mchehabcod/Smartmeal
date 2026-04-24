import 'package:cloud_firestore/cloud_firestore.dart';

class MealPlanItem {
  final String recipeId;
  final String title;
  final double estimatedCost;
  final DateTime addedAt;

  const MealPlanItem({
    required this.recipeId,
    required this.title,
    required this.estimatedCost,
    required this.addedAt,
  });

  factory MealPlanItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final ts = m['addedAt'];
    DateTime added;
    if (ts is Timestamp) {
      added = ts.toDate();
    } else {
      added = DateTime.now();
    }
    return MealPlanItem(
      recipeId: m['recipeId']?.toString() ?? doc.id,
      title: m['title']?.toString() ?? '',
      estimatedCost: (m['estimatedCost'] is num)
          ? (m['estimatedCost'] as num).toDouble()
          : double.tryParse('${m['estimatedCost']}') ?? 0.0,
      addedAt: added,
    );
  }
}
