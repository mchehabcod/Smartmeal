import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../controllers/meal_plan_controller.dart';
import '../../../models/budget_summary.dart';
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

  static final _mealPlan = MealPlanController();

  @override
  Widget build(BuildContext context) {
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
        StreamBuilder<BudgetSummary>(
          stream: _mealPlan.watchCurrentWeekBudgetSummary(
            uid: student.uid,
            weeklyBudget: student.weeklyBudget,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Unable to load planned meal costs. Check your connection.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }

            final summary =
                snapshot.data ??
                BudgetSummary.fromMealPlanItems(
                  weeklyBudget: student.weeklyBudget,
                  items: const [],
                );
            return _BudgetSummaryCard(summary: summary);
          },
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

class _BudgetSummaryCard extends StatelessWidget {
  final BudgetSummary summary;

  const _BudgetSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.MMMd();
    final periodLabel =
        '${dateFormat.format(summary.period.start)}-${dateFormat.format(summary.period.end)}';
    final budgetLabel = summary.hasBudget
        ? 'RM${summary.weeklyBudget.toStringAsFixed(2)}'
        : 'No budget set';
    final remainingLabel = summary.hasBudget
        ? 'RM${summary.remaining.clamp(0.0, summary.weeklyBudget).toStringAsFixed(2)}'
        : 'Set a budget';
    final plannedLabel =
        'RM${summary.plannedCost.toStringAsFixed(2)} planned of $budgetLabel';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Weekly Food Budget',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(periodLabel),
              ],
            ),
            const SizedBox(height: 8),
            Text(plannedLabel, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: summary.progress,
              color: summary.isOverBudget
                  ? Theme.of(context).colorScheme.error
                  : null,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            if (summary.isOverBudget) ...[
              const SizedBox(height: 8),
              Text(
                'Over budget by RM${summary.overage.toStringAsFixed(2)}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatTile(title: 'Remaining', value: remainingLabel),
                ),
                Expanded(
                  child: StatTile(
                    title: 'Daily Remaining',
                    value: summary.hasBudget
                        ? 'RM${summary.dailyRemaining.toStringAsFixed(2)}'
                        : '-',
                  ),
                ),
                Expanded(
                  child: StatTile(
                    title: 'Days Left',
                    value: summary.daysLeft.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${summary.plannedMeals} meal${summary.plannedMeals == 1 ? '' : 's'} counted this week',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
