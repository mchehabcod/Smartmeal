import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/auth_controller.dart';
import 'models/user_model.dart';
import 'theme/app_theme.dart';
import 'views/auth/auth_screen.dart';
import 'views/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('is_dark_mode') ?? false;
  runApp(SmartMealApp(initialDarkMode: isDarkMode));
}

class SmartMealApp extends StatefulWidget {
  final bool initialDarkMode;
  const SmartMealApp({super.key, required this.initialDarkMode});

  @override
  State<SmartMealApp> createState() => _SmartMealAppState();
}

class _SmartMealAppState extends State<SmartMealApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  void _updateTheme(bool isDarkMode) async {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartMeal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: AppBootstrap(themeMode: _themeMode, onThemeChanged: _updateTheme),
    );
  }
}

class AppBootstrap extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<bool> onThemeChanged;

  const AppBootstrap({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Firebase initialization failed. Check your Firebase setup and try again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          );
        }

        return AuthGate(themeMode: themeMode, onThemeChanged: onThemeChanged);
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<bool> onThemeChanged;

  const AuthGate({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();
    return StreamBuilder<User?>(
      stream: authController.userStream,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const AuthScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = userSnapshot.data?.data();
            if (data == null) {
              return _MissingProfileBootstrap(
                user: user,
                themeMode: themeMode,
                onThemeChanged: onThemeChanged,
                authController: authController,
              );
            }

            final student = Student.fromMap(data, user.uid);
            return HomeScreen(
              student: student,
              authController: authController,
              themeMode: themeMode,
              onThemeChanged: onThemeChanged,
            );
          },
        );
      },
    );
  }
}

class _MissingProfileBootstrap extends StatelessWidget {
  final User user;
  final ThemeMode themeMode;
  final ValueChanged<bool> onThemeChanged;
  final AuthController authController;

  const _MissingProfileBootstrap({
    required this.user,
    required this.themeMode,
    required this.onThemeChanged,
    required this.authController,
  });

  Future<void> _ensureStudentProfile() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'studentID': user.uid,
        'name': (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!.trim()
            : 'Student',
        'email': user.email ?? '',
        'weeklyBudget': 0.0,
        'availableIngredients': <String>[],
        'maxPrepTimeMinutes': 30,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('Firebase ${e.code}: ${e.message ?? "Unknown error"}');
    } catch (e) {
      throw Exception('Unexpected profile creation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ensureStudentProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          final details = snapshot.error.toString();
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Could not create your profile. Please try signing out and logging in again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      details,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: authController.signOut,
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return HomeScreen(
          student: Student(
            uid: user.uid,
            studentID: user.uid,
            email: user.email ?? '',
            name: (user.displayName?.trim().isNotEmpty ?? false)
                ? user.displayName!.trim()
                : 'Student',
            weeklyBudget: 0.0,
            availableIngredients: const [],
            maxPrepTimeMinutes: 30,
          ),
          authController: authController,
          themeMode: themeMode,
          onThemeChanged: onThemeChanged,
        );
      },
    );
  }
}
