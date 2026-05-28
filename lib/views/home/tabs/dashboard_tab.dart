import 'package:flutter/material.dart';
import '../../../controllers/meal_plan_controller.dart';
import '../../../models/budget_summary.dart';
import '../../../models/recipe_model.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../utils/recipe_filters.dart';
import '../recipe_detail_screen.dart';
import '../widgets/home_widgets.dart';

class DashboardTab extends StatelessWidget {
  final Student student;
  final ValueChanged<int> onTabChange;

  const DashboardTab({
    super.key,
    required this.student,
    required this.onTabChange,
  });

  static final _firestore = FirestoreService();
  static final _mealPlan = MealPlanController();

  @override
  Widget build(BuildContext context) {
    final pantry = student.availableIngredients;
    final screenH = MediaQuery.sizeOf(context).height;
    final recipeStripH = (screenH * 0.26).clamp(200.0, 280.0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu_rounded),
              const SizedBox(width: 8),
              Text('SmartMeal', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<BudgetSummary>(
            stream: _mealPlan.watchCurrentWeekBudgetSummary(
              uid: student.uid,
              weeklyBudget: student.weeklyBudget,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Unable to load weekly budget.'),
                  ),
                );
              }
              final summary =
                  snapshot.data ??
                  BudgetSummary.fromMealPlanItems(
                    weeklyBudget: student.weeklyBudget,
                    items: const [],
                  );
              return _DashboardBudgetCard(summary: summary);
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ActionTile(
                  icon: Icons.camera_alt_rounded,
                  title: 'Scan Ingredients',
                  onTap: () => onTabChange(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionTile(
                  icon: Icons.search_rounded,
                  title: 'Find Recipes',
                  onTap: () => onTabChange(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ActionTile(
                  icon: Icons.checklist_rounded,
                  title: 'My Meals',
                  onTap: () => onTabChange(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionTile(
                  icon: Icons.attach_money_rounded,
                  title: 'Budget',
                  onTap: () => onTabChange(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Recommended for You',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => onTabChange(2),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            pantry.isEmpty
                ? 'Add ingredients on Scan — recommendations use your saved pantry list.'
                : 'Based on your pantry: ${pantry.take(4).join(', ')}${pantry.length > 4 ? '…' : ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: recipeStripH,
            child: StreamBuilder<List<Recipe>>(
              stream: _firestore.watchRecipes(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Could not load recipes: ${snap.error}'),
                  );
                }
                final all = snap.data ?? const <Recipe>[];
                final ranked = applyRecipeTabFilters(
                  recipes: all,
                  pantry: pantry,
                  filterIndex: 0,
                  weeklyBudget: student.weeklyBudget,
                  maxPrepTimeMinutes: student.maxPrepTimeMinutes,
                );
                final top = ranked.take(12).toList();

                if (top.isEmpty) {
                  return Center(
                    child: Text(
                      all.isEmpty
                          ? 'No recipes yet. Seed the database or open Recipes.'
                          : 'No recipes match your pantry yet — try Scan to add more ingredients.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: top.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final r = top[i];
                    return RecipeMiniCard(
                      title: r.title,
                      time: '${r.prepTime} min',
                      price: 'RM${r.estimatedCost.toStringAsFixed(2)}',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RecipeDetailScreen(
                              recipe: r,
                              studentId: student.uid,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBudgetCard extends StatelessWidget {
  final BudgetSummary summary;

  const _DashboardBudgetCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final planned = summary.plannedCost.toStringAsFixed(2);
    final cap = summary.hasBudget
        ? 'RM${summary.weeklyBudget.toStringAsFixed(2)}'
        : 'No budget set';
    final remaining = summary.hasBudget
        ? 'RM${summary.remaining.clamp(0.0, summary.weeklyBudget).toStringAsFixed(2)} remaining this week'
        : 'Set a weekly budget to track your plan';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Weekly Budget',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text('RM$planned / $cap'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: summary.progress,
              color: summary.isOverBudget
                  ? Theme.of(context).colorScheme.error
                  : null,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            Text(
              summary.isOverBudget
                  ? 'Over budget by RM${summary.overage.toStringAsFixed(2)}'
                  : remaining,
              style: summary.isOverBudget
                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
