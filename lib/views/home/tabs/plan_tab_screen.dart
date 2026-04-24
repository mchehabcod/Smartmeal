import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../controllers/cooking_history_controller.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../controllers/meal_plan_controller.dart';
import '../../../models/cooking_history_entry.dart';
import '../../../models/meal_plan_item.dart';
import '../../../models/recipe_model.dart';
import '../../../models/user_model.dart';
import '../../../services/shopping_list_service.dart';
import '../recipe_detail_screen.dart';

/// US008 / US009 / US0010 / US0011 — Plan hub (meal plan, shopping, favorites, history).
class PlanTabScreen extends StatelessWidget {
  final Student student;

  const PlanTabScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Plan & shop',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Meal plan'),
              Tab(text: 'Shopping'),
              Tab(text: 'Favorites'),
              Tab(text: 'History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MealPlanSubtab(student: student),
                _ShoppingSubtab(student: student),
                _FavoritesSubtab(student: student),
                _HistorySubtab(student: student),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _mealPlanCtrl = MealPlanController();
final _favoritesCtrl = FavoritesController();
final _historyCtrl = CookingHistoryController();
final _shoppingSvc = ShoppingListService();

class _MealPlanSubtab extends StatelessWidget {
  final Student student;

  const _MealPlanSubtab({required this.student});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _mealPlanCtrl.watchMealPlanDocs(student.uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Unable to load meal plan. Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!;
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No meals in your plan yet. Browse recipes and tap “Add to Meal Plan”.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final item = MealPlanItem.fromDoc(docs[i]);
            return Card(
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(
                  'RM ${item.estimatedCost.toStringAsFixed(2)} · added ${_fmt(item.addedAt)}',
                ),
                leading: const Icon(Icons.restaurant_menu_outlined),
                onTap: () => _openRecipeDetailFromId(
                  context,
                  studentUid: student.uid,
                  recipeId: item.recipeId,
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'remove') {
                      final err = await _mealPlanCtrl.removeFromMealPlan(
                        studentId: student.uid,
                        recipeId: item.recipeId,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            err == null
                                ? 'Removed from meal plan'
                                : 'Failed to save your plan. Please try again.',
                          ),
                        ),
                      );
                    } else if (v == 'cook') {
                      final recipe = await _fetchRecipe(item.recipeId);
                      if (!context.mounted) return;
                      if (recipe == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recipe not found in database.'),
                          ),
                        );
                        return;
                      }
                      final err = await _historyCtrl.logCooked(
                        studentId: student.uid,
                        recipe: recipe,
                      );
                      if (!context.mounted) return;
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to save. Please try again later.',
                            ),
                          ),
                        );
                        return;
                      }
                      final rmErr = await _mealPlanCtrl.removeFromMealPlan(
                        studentId: student.uid,
                        recipeId: item.recipeId,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            rmErr == null
                                ? 'Marked as cooked and removed from your meal plan.'
                                : 'Logged as cooked, but could not remove from plan. Try removing it manually.',
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'cook', child: Text('Mark as cooked')),
                    PopupMenuItem(value: 'remove', child: Text('Remove from plan')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ShoppingSubtab extends StatefulWidget {
  final Student student;

  const _ShoppingSubtab({required this.student});

  @override
  State<_ShoppingSubtab> createState() => _ShoppingSubtabState();
}

class _ShoppingSubtabState extends State<_ShoppingSubtab> {
  bool _busy = false;

  Future<void> _generate() async {
    setState(() => _busy = true);
    final r = await _shoppingSvc.buildShoppingList(studentId: widget.student.uid);
    if (!mounted) return;
    setState(() => _busy = false);

    final code = r.code;
    if (code == 'no_pantry') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload a pantry photo or enter ingredients manually before generating a shopping list.',
          ),
        ),
      );
      return;
    }
    if (code == 'no_meals') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add meals to your meal plan first.'),
        ),
      );
      return;
    }
    if (code == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate list. Please try again.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shopping list updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: _busy ? null : _generate,
          icon: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.playlist_add_check_rounded),
          label: const Text('Generate shopping list'),
        ),
        const SizedBox(height: 8),
        Text(
          'Uses your meal plan recipes and subtracts ingredients you already listed on the Scan tab.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        StreamBuilder<ShoppingListDisplayState>(
          stream: _shoppingSvc.watchShoppingListDisplay(widget.student.uid),
          builder: (context, snap) {
            if (snap.hasError) {
              return Text('Unable to load list: ${snap.error}');
            }
            final state = snap.data;
            if (state == null || state.isEmpty) {
              return const Text('Generate a list to see categorized missing items.');
            }
            final keys = state.byCategory.keys.toList()..sort();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Check off items as you buy them. Checked rows stay crossed out, '
                  'then drop off your list after a day.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                for (final cat in keys) ...[
                  Text(
                    cat,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  ...state.byCategory[cat]!.map(
                    (ShoppingListLineUi row) => Padding(
                      padding: const EdgeInsets.only(left: 0, bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            value: row.isChecked,
                            onChanged: (v) async {
                              if (v == null) return;
                              final err = await _shoppingSvc.setShoppingItemChecked(
                                studentId: widget.student.uid,
                                category: row.category,
                                line: row.line,
                                checked: v,
                              );
                              if (!context.mounted) return;
                              if (err != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not update your list. Try again.'),
                                  ),
                                );
                              }
                            },
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 11),
                              child: Text(
                                row.line,
                                style: row.isChecked
                                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          decoration: TextDecoration.lineThrough,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        )
                                    : Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FavoritesSubtab extends StatelessWidget {
  final Student student;

  const _FavoritesSubtab({required this.student});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _favoritesCtrl.watchFavoriteDocs(student.uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Unable to load favorites.'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!;
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No favorites yet. Open a recipe and tap the heart.'),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final m = docs[i].data();
            final recipeId = m['recipeId']?.toString() ?? docs[i].id;
            final title = m['title']?.toString() ?? 'Recipe';
            return Card(
              child: ListTile(
                title: Text(title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openRecipeDetailFromId(
                  context,
                  studentUid: student.uid,
                  recipeId: recipeId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HistorySubtab extends StatelessWidget {
  final Student student;

  const _HistorySubtab({required this.student});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _historyCtrl.watchHistoryDocs(student.uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Text(
              'Unable to load history. Please check your connection and try again.',
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!;
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No cooking history available. Start by selecting a meal to cook.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final e = CookingHistoryEntry.fromDoc(docs[i]);
            return Card(
              child: ListTile(
                title: Text(e.recipeTitle),
                subtitle: Text(_fmt(e.cookedAt)),
              ),
            );
          },
        );
      },
    );
  }
}

String _fmt(DateTime d) {
  return DateFormat.yMMMd().add_jm().format(d);
}

Future<Recipe?> _fetchRecipe(String id) async {
  final doc =
      await FirebaseFirestore.instance.collection('recipes').doc(id).get();
  if (!doc.exists || doc.data() == null) return null;
  return Recipe.fromMap(doc.data()!, doc.id);
}

Future<void> _openRecipeDetailFromId(
  BuildContext context, {
  required String studentUid,
  required String recipeId,
}) async {
  final recipe = await _fetchRecipe(recipeId.trim());
  if (!context.mounted) return;
  if (recipe == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recipe not found in database.')),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RecipeDetailScreen(
        recipe: recipe,
        studentId: studentUid,
      ),
    ),
  );
}
