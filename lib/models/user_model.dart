class Student {
  final String uid;
  final String studentID;
  final String email;
  final String name;
  final double weeklyBudget;

  /// Pantry / manual ingredients (UC004); also used to filter recipe suggestions (UC006).
  final List<String> availableIngredients;
  final int maxPrepTimeMinutes;

  Student({
    required this.uid,
    String? studentID,
    required this.email,
    required this.name,
    this.weeklyBudget = 0.0,
    this.availableIngredients = const [],
    this.maxPrepTimeMinutes = 30,
  }) : studentID = studentID ?? uid;

  Map<String, dynamic> toMap() {
    return {
      'studentID': studentID,
      'uid': uid,
      'email': email,
      'name': name,
      'weeklyBudget': weeklyBudget,
      'availableIngredients': availableIngredients,
      'maxPrepTimeMinutes': maxPrepTimeMinutes,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map, String documentId) {
    return Student(
      uid: documentId,
      studentID: map['studentID'] ?? documentId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      weeklyBudget: (map['weeklyBudget'] ?? 0.0).toDouble(),
      availableIngredients: _parseStringList(map['availableIngredients']),
      maxPrepTimeMinutes: _parsePositiveInt(map['maxPrepTimeMinutes'], 30),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static int _parsePositiveInt(dynamic value, int fallback) {
    final parsed = value is num
        ? value.toInt()
        : value is String
        ? int.tryParse(value)
        : null;
    if (parsed == null || parsed <= 0) return fallback;
    return parsed;
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final double weeklyBudget;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'student',
    this.weeklyBudget = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'weeklyBudget': weeklyBudget,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: map['uid']?.toString() ?? documentId,
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'student',
      weeklyBudget: _toDouble(map['weeklyBudget']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
