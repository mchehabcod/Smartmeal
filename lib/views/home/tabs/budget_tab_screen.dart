import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../widgets/home_widgets.dart';

class BudgetTabScreen extends StatelessWidget {
  final Student student;
  final TextEditingController controller;
  final bool isSavingBudget;
  final Future<void> Function() onSaveBudget;

  const BudgetTabScreen({
    super.key,
    required this.student,
    required this.controller,
    required this.isSavingBudget,
    required this.onSaveBudget,
  });

  @override
  Widget build(BuildContext context) {
    final cap = student.weeklyBudget <= 0 ? 60.0 : student.weeklyBudget;
    const spent = 45.0;
    final remaining = (cap - spent).clamp(0, cap);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              'Budget Tracker',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings_rounded),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Weekly Food Budget',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    const Text('May 24-30, 2025'),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'RM${spent.toStringAsFixed(2)} spent of RM${cap.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (spent / cap).clamp(0.0, 1.0),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(99),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        title: 'Remaining',
                        value: 'RM${remaining.toStringAsFixed(2)}',
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        title: 'Daily Average',
                        value: 'RM6.43',
                      ),
                    ),
                    const Expanded(
                      child: StatTile(title: 'Days Left', value: '3'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Update Weekly Budget (RM)',
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: isSavingBudget ? null : onSaveBudget,
          child: isSavingBudget
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Text('Save Budget'),
        ),
      ],
    );
  }
}
