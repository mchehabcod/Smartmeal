import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/budget_controller.dart';
import '../../models/user_model.dart';
import 'tabs/budget_tab_screen.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/plan_tab_screen.dart';
import 'tabs/profile_tab_screen.dart';
import 'tabs/recipes_tab_screen.dart';
import 'tabs/scan_tab_screen.dart';

class HomeScreen extends StatefulWidget {
  final Student student;
  final AuthController authController;
  final ThemeMode themeMode;
  final ValueChanged<bool> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.student,
    required this.authController,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BudgetController _budgetController = BudgetController();
  final TextEditingController _budgetTextController = TextEditingController();
  int _currentTabIndex = 0;
  bool _isSavingBudget = false;

  @override
  void initState() {
    super.initState();
    _budgetTextController.text =
        widget.student.weeklyBudget.toStringAsFixed(2);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.student.weeklyBudget != widget.student.weeklyBudget) {
      _budgetTextController.text =
          widget.student.weeklyBudget.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _budgetTextController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final value = double.tryParse(_budgetTextController.text.trim());
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget value')),
      );
      return;
    }

    setState(() => _isSavingBudget = true);
    final error = await _budgetController.setWeeklyBudget(
      studentId: widget.student.uid,
      weeklyBudget: value,
    );
    if (!mounted) return;
    setState(() => _isSavingBudget = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Weekly budget updated to RM ${value.toStringAsFixed(2)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(
        student: widget.student,
        onTabChange: (index) => setState(() => _currentTabIndex = index),
      ),
      PlanTabScreen(student: widget.student),
      RecipesTabScreen(student: widget.student),
      ScanTabScreen(student: widget.student),
      BudgetTabScreen(
        student: widget.student,
        controller: _budgetTextController,
        isSavingBudget: _isSavingBudget,
        onSaveBudget: _saveBudget,
      ),
      ProfileTabScreen(
        student: widget.student,
        isDarkMode: widget.themeMode == ThemeMode.dark,
        onThemeChanged: widget.onThemeChanged,
        onSignOut: widget.authController.signOut,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_currentTabIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (value) =>
            setState(() => _currentTabIndex = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_rounded),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_rounded),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
