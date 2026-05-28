import 'package:flutter/material.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/meal_plan_controller.dart';
import '../../controllers/cooking_history_controller.dart';
import '../../models/recipe_model.dart';
import 'widgets/home_widgets.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final String studentId;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.studentId,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final MealPlanController _mealPlan = MealPlanController();
  final FavoritesController _favorites = FavoritesController();
  final CookingHistoryController _history = CookingHistoryController();

  Recipe get recipe => widget.recipe;

  Future<void> _addToMealPlan(BuildContext context) async {
    final preview = await _mealPlan.previewAddToMealPlan(
      studentId: widget.studentId,
      recipe: recipe,
    );
    if (!context.mounted) return;
    if (preview.code == 'duplicate') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This meal is already in your plan.')),
      );
      return;
    }
    if (preview.code == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to check your weekly budget. Please try again.',
          ),
        ),
      );
      return;
    }
    if (preview.isOverBudget) {
      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Weekly budget exceeded'),
            content: Text(
              'Adding this meal will bring your weekly plan to '
              'RM${preview.projectedCost.toStringAsFixed(2)}, which is '
              'RM${preview.overage.toStringAsFixed(2)} over your budget.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Add anyway'),
              ),
            ],
          );
        },
      );
      if (shouldAdd != true) return;
    }

    final code = await _mealPlan.addToMealPlan(
      studentId: widget.studentId,
      recipe: recipe,
    );
    if (!context.mounted) return;
    if (code == 'duplicate') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This meal is already in your plan.')),
      );
      return;
    }
    if (code == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save your plan. Please try again.'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          preview.isOverBudget
              ? 'Meal added. Your weekly plan is over budget by RM${preview.overage.toStringAsFixed(2)}.'
              : 'Meal added to your plan.',
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, bool isFav) async {
    if (isFav) {
      final err = await _favorites.removeFavorite(
        studentId: widget.studentId,
        recipeId: recipe.id,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            err == null
                ? 'Removed from favorites'
                : 'Failed to save recipe. Please try again later.',
          ),
        ),
      );
      return;
    }

    final code = await _favorites.addFavorite(
      studentId: widget.studentId,
      recipe: recipe,
    );
    if (!context.mounted) return;
    if (code == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save recipe. Please try again later.'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recipe added to favorites.')));
  }

  Future<void> _logCooked(BuildContext context) async {
    final err = await _history.logCooked(
      studentId: widget.studentId,
      recipe: recipe,
    );
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save. Please try again later.'),
        ),
      );
      return;
    }
    final rmErr = await _mealPlan.removeFromMealPlan(
      studentId: widget.studentId,
      recipeId: recipe.id,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          rmErr == null
              ? 'Marked as cooked, removed from meal plan, and saved to History.'
              : 'Saved to History, but meal plan was not updated. Check your connection.',
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final macros = recipe.macros;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = (screenHeight * 0.55).clamp(420.0, 470.0).toDouble();
    final heroHeight = (headerHeight - 188).clamp(210.0, 260.0).toDouble();

    return Scaffold(
      body: SafeArea(
        top: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                expandedHeight: headerHeight,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.white70,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: StreamBuilder<bool>(
                      stream: _favorites.watchIsFavorite(
                        widget.studentId,
                        recipe.id,
                      ),
                      builder: (context, snap) {
                        final isFav = snap.data ?? false;
                        return CircleAvatar(
                          backgroundColor: Colors.white70,
                          child: IconButton(
                            icon: Icon(
                              isFav
                                  ? Icons.favorite
                                  : Icons.favorite_border_rounded,
                              color: isFav ? Colors.redAccent : null,
                            ),
                            onPressed: () => _toggleFavorite(context, isFav),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RecipeHeroVisual(
                        title: recipe.title,
                        imageUrl: recipe.imageUrl,
                        height: heroHeight,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                InfoPill(
                                  icon: Icons.schedule_rounded,
                                  label: '${recipe.prepTime} min',
                                ),
                                InfoPill(
                                  icon: Icons.payments_rounded,
                                  label:
                                      'RM${recipe.estimatedCost.toStringAsFixed(2)}',
                                ),
                                InfoPill(
                                  icon: Icons.local_fire_department_rounded,
                                  label: '${recipe.calories} cal',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: kTextTabBarHeight),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(kTextTabBarHeight),
                  child: Material(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Ingredients'),
                        Tab(text: 'Instructions'),
                        Tab(text: 'Nutrition'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              ListView(
                primary: false,
                padding: const EdgeInsets.all(16),
                children: recipe.ingredients.isEmpty
                    ? [const Text('No ingredient list for this recipe.')]
                    : recipe.ingredients.map((m) {
                        final name = (m['name'] ?? m['original'] ?? '')
                            .toString();
                        final amount = m['amount'];
                        final unit = (m['unit'] ?? '').toString();
                        final qty =
                            [if (amount != null) amount.toString(), unit]
                                .where((s) => s.toString().trim().isNotEmpty)
                                .join(' ');
                        return IngredientRow(
                          name: name.isEmpty ? 'Item' : name,
                          quantity: qty.isEmpty ? '—' : qty,
                        );
                      }).toList(),
              ),
              ListView(
                primary: false,
                padding: const EdgeInsets.all(16),
                children: recipe.steps.isEmpty
                    ? const [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No instructions available.'),
                          ),
                        ),
                      ]
                    : List.generate(recipe.steps.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(radius: 14, child: Text('${i + 1}')),
                              const SizedBox(width: 12),
                              Expanded(child: Text(recipe.steps[i])),
                            ],
                          ),
                        );
                      }),
              ),
              ListView(
                primary: false,
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    title: const Text('Calories'),
                    trailing: Text('${recipe.calories} kcal'),
                  ),
                  ListTile(
                    title: const Text('Protein'),
                    trailing: Text(macros['protein'] ?? '—'),
                  ),
                  ListTile(
                    title: const Text('Carbohydrates'),
                    trailing: Text(macros['carbs'] ?? '—'),
                  ),
                  ListTile(
                    title: const Text('Fat'),
                    trailing: Text(macros['fat'] ?? '—'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _addToMealPlan(context),
                icon: const Icon(Icons.event_note_rounded),
                label: const Text('Add to Meal Plan'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logCooked(context),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Mark as cooked'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
