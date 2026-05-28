import 'dart:math' as math;

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
import '../widgets/home_widgets.dart';

/// US008 / US009 / US0010 / US0011 — Plan hub (meal plan, shopping, favorites, history).
class PlanTabScreen extends StatelessWidget {
  final Student student;

  const PlanTabScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
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
              Tab(text: 'Nutrition'),
              Tab(text: 'Shopping'),
              Tab(text: 'Favorites'),
              Tab(text: 'History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MealPlanSubtab(student: student),
                _NutritionSubtab(student: student),
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
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove from plan'),
                    ),
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

class _NutritionSubtab extends StatelessWidget {
  final Student student;

  const _NutritionSubtab({required this.student});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _mealPlanCtrl.watchMealPlanDocs(student.uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to load nutrition totals. Please check your connection and try again.',
                textAlign: TextAlign.center,
              ),
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
                'Add meals to your plan to analyze calories and nutrients.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return FutureBuilder<_NutritionSummary>(
          future: _buildNutritionSummary(docs),
          builder: (context, nutritionSnap) {
            if (nutritionSnap.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Unable to analyze meal nutrition right now. Please try again.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!nutritionSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final summary = nutritionSnap.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Planned meal nutrition',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 24,
                          runSpacing: 16,
                          children: [
                            StatTile(
                              title: 'Calories',
                              value: '${summary.totalCalories} kcal',
                            ),
                            StatTile(
                              title: 'Protein',
                              value: '${_fmtGrams(summary.proteinGrams)} g',
                            ),
                            StatTile(
                              title: 'Carbs',
                              value: '${_fmtGrams(summary.carbsGrams)} g',
                            ),
                            StatTile(
                              title: 'Fat',
                              value: '${_fmtGrams(summary.fatGrams)} g',
                            ),
                            StatTile(
                              title: 'Meals counted',
                              value: '${summary.mealCount}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _MacroPieChart(
                          proteinGrams: summary.proteinGrams,
                          carbsGrams: summary.carbsGrams,
                          fatGrams: summary.fatGrams,
                        ),
                      ],
                    ),
                  ),
                ),
                if (summary.missingNutritionCount > 0) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text(
                        'Some recipes have incomplete nutrition',
                      ),
                      subtitle: Text(
                        '${summary.missingNutritionCount} planned meal(s) are missing calories or macro data.',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Meal breakdown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...summary.lines.map(
                  (line) => Card(
                    child: ListTile(
                      title: Text(line.title),
                      subtitle: Text(
                        '${line.calories} kcal | '
                        'P ${_fmtGrams(line.proteinGrams)}g  '
                        'C ${_fmtGrams(line.carbsGrams)}g  '
                        'F ${_fmtGrams(line.fatGrams)}g',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openRecipeDetailFromId(
                        context,
                        studentUid: student.uid,
                        recipeId: line.recipeId,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

const _proteinColor = Color(0xFF4E79A7);
const _carbsColor = Color(0xFFF2B84B);
const _fatColor = Color(0xFFE56B6F);

class _MacroPieChart extends StatelessWidget {
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  const _MacroPieChart({
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final slices = [
      _MacroSlice(
        label: 'Protein',
        grams: proteinGrams,
        calories: proteinGrams * 4,
        color: _proteinColor,
      ),
      _MacroSlice(
        label: 'Carbs',
        grams: carbsGrams,
        calories: carbsGrams * 4,
        color: _carbsColor,
      ),
      _MacroSlice(
        label: 'Fat',
        grams: fatGrams,
        calories: fatGrams * 9,
        color: _fatColor,
      ),
    ];
    final totalCalories = slices.fold<double>(
      0,
      (total, slice) => total + slice.calories,
    );

    return Wrap(
      spacing: 18,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox.square(
          dimension: 112,
          child: CustomPaint(
            painter: _MacroPiePainter(
              slices: slices,
              totalCalories: totalCalories,
              emptyColor: colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: slices
                .map(
                  (slice) => _MacroLegendRow(
                    slice: slice,
                    totalCalories: totalCalories,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _MacroLegendRow extends StatelessWidget {
  final _MacroSlice slice;
  final double totalCalories;

  const _MacroLegendRow({required this.slice, required this.totalCalories});

  @override
  Widget build(BuildContext context) {
    final percent = totalCalories <= 0
        ? '0%'
        : '${((slice.calories / totalCalories) * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: slice.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(slice.label)),
          Text('${_fmtGrams(slice.grams)}g | $percent'),
        ],
      ),
    );
  }
}

class _MacroSlice {
  final String label;
  final double grams;
  final double calories;
  final Color color;

  const _MacroSlice({
    required this.label,
    required this.grams,
    required this.calories,
    required this.color,
  });
}

class _MacroPiePainter extends CustomPainter {
  final List<_MacroSlice> slices;
  final double totalCalories;
  final Color emptyColor;

  const _MacroPiePainter({
    required this.slices,
    required this.totalCalories,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    if (totalCalories <= 0) {
      paint.color = emptyColor;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      if (slice.calories <= 0) continue;
      final sweepAngle = (slice.calories / totalCalories) * math.pi * 2;
      paint.color = slice.color;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroPiePainter oldDelegate) {
    if (oldDelegate.emptyColor != emptyColor ||
        oldDelegate.slices.length != slices.length) {
      return true;
    }

    for (var i = 0; i < slices.length; i++) {
      final oldSlice = oldDelegate.slices[i];
      final slice = slices[i];
      if (oldSlice.calories != slice.calories ||
          oldSlice.color != slice.color) {
        return true;
      }
    }
    return false;
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
    final r = await _shoppingSvc.buildShoppingList(
      studentId: widget.student.uid,
    );
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
        const SnackBar(content: Text('Add meals to your meal plan first.')),
      );
      return;
    }
    if (code == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate list. Please try again.'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Shopping list updated.')));
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
              return const Text(
                'Generate a list to see categorized missing items.',
              );
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
                  Text(cat, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  ...state.byCategory[cat]!.map(
                    (ShoppingListLineUi row) => Padding(
                      padding: const EdgeInsets.only(left: 0, bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            value: row.isChecked,
                            onChanged: (v) async {
                              if (v == null) return;
                              final err = await _shoppingSvc
                                  .setShoppingItemChecked(
                                    studentId: widget.student.uid,
                                    category: row.category,
                                    line: row.line,
                                    checked: v,
                                  );
                              if (!context.mounted) return;
                              if (err != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not update your list. Try again.',
                                    ),
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
                                    ? Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
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
  final doc = await FirebaseFirestore.instance
      .collection('recipes')
      .doc(id)
      .get();
  if (!doc.exists || doc.data() == null) return null;
  return Recipe.fromMap(doc.data()!, doc.id);
}

Future<_NutritionSummary> _buildNutritionSummary(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) async {
  final items = docs.map(MealPlanItem.fromDoc).toList();
  final recipesById = await _fetchRecipesByIds(
    items.map((item) => item.recipeId),
  );
  final lines = items.map((item) {
    final recipeId = item.recipeId.trim();
    return _NutritionRecipeLine.fromRecipe(
      recipesById[recipeId],
      fallbackRecipeId: recipeId,
      fallbackTitle: item.title,
    );
  }).toList();

  return _NutritionSummary(
    mealCount: lines.length,
    totalCalories: lines.fold<int>(0, (total, line) => total + line.calories),
    proteinGrams: lines.fold<double>(
      0,
      (total, line) => total + line.proteinGrams,
    ),
    carbsGrams: lines.fold<double>(0, (total, line) => total + line.carbsGrams),
    fatGrams: lines.fold<double>(0, (total, line) => total + line.fatGrams),
    missingNutritionCount: lines.where((line) => line.hasMissingData).length,
    lines: lines,
  );
}

Future<Map<String, Recipe>> _fetchRecipesByIds(Iterable<String> ids) async {
  final recipeIds = ids
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();
  final recipes = <String, Recipe>{};
  const chunkSize = 30;

  for (var start = 0; start < recipeIds.length; start += chunkSize) {
    final end = (start + chunkSize).clamp(0, recipeIds.length);
    final chunk = recipeIds.sublist(start, end);
    if (chunk.isEmpty) continue;

    final snap = await FirebaseFirestore.instance
        .collection('recipes')
        .where(FieldPath.documentId, whereIn: chunk)
        .get();
    for (final doc in snap.docs) {
      recipes[doc.id] = Recipe.fromMap(doc.data(), doc.id);
    }
  }

  return recipes;
}

class _NutritionSummary {
  final int mealCount;
  final int totalCalories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final int missingNutritionCount;
  final List<_NutritionRecipeLine> lines;

  const _NutritionSummary({
    required this.mealCount,
    required this.totalCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.missingNutritionCount,
    required this.lines,
  });
}

class _NutritionRecipeLine {
  final String recipeId;
  final String title;
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final bool hasMissingData;

  const _NutritionRecipeLine({
    required this.recipeId,
    required this.title,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.hasMissingData,
  });

  factory _NutritionRecipeLine.fromRecipe(
    Recipe? recipe, {
    required String fallbackRecipeId,
    required String fallbackTitle,
  }) {
    final macros = recipe?.macros ?? const <String, String>{};
    final protein = _macroAmount(macros['protein']);
    final carbs = _macroAmount(macros['carbs']);
    final fat = _macroAmount(macros['fat']);
    final calories = recipe?.calories ?? 0;
    final recipeTitle = recipe?.title.trim();
    final fallback = fallbackTitle.trim();

    return _NutritionRecipeLine(
      recipeId: recipe?.id ?? fallbackRecipeId,
      title: recipeTitle != null && recipeTitle.isNotEmpty
          ? recipeTitle
          : (fallback.isNotEmpty ? fallback : 'Recipe'),
      calories: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      hasMissingData: calories <= 0 || (protein == 0 && carbs == 0 && fat == 0),
    );
  }
}

double _macroAmount(String? value) {
  if (value == null) return 0;
  final match = RegExp(r'\d+(\.\d+)?').firstMatch(value);
  return double.tryParse(match?.group(0) ?? '') ?? 0;
}

String _fmtGrams(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
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
      builder: (_) => RecipeDetailScreen(recipe: recipe, studentId: studentUid),
    ),
  );
}
