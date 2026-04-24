import 'package:flutter_test/flutter_test.dart';
import 'package:smartmeal/models/user_model.dart';

void main() {
  test('Student model maps required registration fields', () {
    final student = Student(
      uid: 'uid-001',
      studentID: 'st-001',
      email: 'student@uni.edu',
      name: 'Test Student',
      weeklyBudget: 120.5,
    );

    final map = student.toMap();

    expect(map['studentID'], 'st-001');
    expect(map['name'], 'Test Student');
    expect(map['email'], 'student@uni.edu');
    expect(map['weeklyBudget'], 120.5);
  });
}
