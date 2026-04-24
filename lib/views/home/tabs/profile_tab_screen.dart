import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/recipe_seeder.dart';

class ProfileTabScreen extends StatefulWidget {
  final Student student;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final Future<void> Function() onSignOut;

  const ProfileTabScreen({
    super.key,
    required this.student,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onSignOut,
  });

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  final RecipeSeeder _seeder = RecipeSeeder();
  bool _isSeeding = false;

  Future<bool> _isAdmin() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.student.uid)
        .get();
    final role = doc.data()?['role']?.toString().toLowerCase() ?? '';
    return role == 'admin';
  }

  Future<void> _seedRecipes() async {
    setState(() => _isSeeding = true);
    try {
      final count = await _seeder.seedSampleData(keyword: 'pasta', limit: 50);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seed completed: $count recipes uploaded')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seeding failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
            title: Text(widget.student.name),
            subtitle: Text(widget.student.email),
          ),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          value: widget.isDarkMode,
          onChanged: widget.onThemeChanged,
          title: const Text('Dark Mode Accessibility'),
          subtitle: const Text('Improves low-light readability'),
        ),
        FutureBuilder<bool>(
          future: _isAdmin(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            if (snapshot.data != true) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: FilledButton.icon(
                onPressed: _isSeeding ? null : _seedRecipes,
                icon: _isSeeding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _isSeeding ? 'Seeding recipes...' : 'Seed Recipes (Admin)',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: widget.onSignOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign Out'),
        ),
      ],
    );
  }
}
