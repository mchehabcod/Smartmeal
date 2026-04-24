import 'package:cloud_firestore/cloud_firestore.dart';

class CookingHistoryEntry {
  final String id;
  final String recipeId;
  final String recipeTitle;
  final DateTime cookedAt;

  const CookingHistoryEntry({
    required this.id,
    required this.recipeId,
    required this.recipeTitle,
    required this.cookedAt,
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
    );
  }
}
