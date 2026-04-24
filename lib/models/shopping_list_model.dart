import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingList {
  final String id;
  final String studentId;
  final List<Map<String, dynamic>> items;
  final DateTime createdAt;

  const ShoppingList({
    required this.id,
    required this.studentId,
    required this.items,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'items': items,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map, String documentId) {
    final rawItems = (map['items'] as List?) ?? const [];

    return ShoppingList(
      id: map['id']?.toString() ?? documentId,
      studentId: map['studentId']?.toString() ?? '',
      items: rawItems
          .whereType<Map>()
          .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
          .toList(),
      createdAt: _toDateTime(map['createdAt']),
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
