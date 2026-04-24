import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream to listen to login state
  Stream<User?> get userStream => _auth.authStateChanges();

  // REGISTER
  Future<String?> register(String email, String password, String name) async {
    final trimmedEmail = email.trim();
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return 'Name is required';
    }
    if (trimmedEmail.isEmpty) {
      return 'Email is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }

    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      // Create Student Record in Firestore
      Student newStudent = Student(
        uid: cred.user!.uid,
        studentID: cred.user!.uid,
        email: trimmedEmail,
        name: trimmedName,
        weeklyBudget: 0.0,
      );

      await _db
          .collection('users')
          .doc(cred.user!.uid)
          .set(newStudent.toMap(), SetOptions(merge: true));
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Unknown error occurred";
    }
  }

  // LOGIN
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (_) {
      return "Unknown error occurred";
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }
}