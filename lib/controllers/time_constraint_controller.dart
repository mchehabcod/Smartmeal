import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class TimeConstraintController {
  final FirebaseFirestore _db;

  TimeConstraintController({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  Future<String?> setMaxPrepTime({
    required String studentId,
    required int minutes,
  }) async {
    if (minutes <= 0) {
      return 'Prep time must be greater than 0 minutes';
    }
    if (minutes > 240) {
      return 'Prep time must be 240 minutes or less';
    }

    try {
      await _db
          .collection('users')
          .doc(studentId)
          .set({'maxPrepTimeMinutes': minutes}, SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
      return null;
    } on TimeoutException {
      return 'Could not reach Firestore. Check your internet connection and try again.';
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        return 'Could not reach Firestore. Check your internet connection and try again.';
      }
      return e.message ?? 'Failed to update time constraint';
    } catch (_) {
      return 'Failed to update time constraint';
    }
  }
}
