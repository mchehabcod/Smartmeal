class Budget {
  final String studentID;
  final double weeklyBudget;
  final DateTime updatedAt;

  Budget({
    required this.studentID,
    required this.weeklyBudget,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentID': studentID,
      'weeklyBudget': weeklyBudget,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      studentID: map['studentID'] ?? '',
      weeklyBudget: (map['weeklyBudget'] ?? 0.0).toDouble(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
