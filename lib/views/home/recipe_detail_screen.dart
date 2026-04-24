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
      const SnackBar(content: Text('Meal added to your plan.')),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recipe added to favorites.')),
    );
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
    final meta =
        '${recipe.prepTime} min    RM${recipe.estimatedCost.toStringAsFixed(2)}    '
        '${recipe.calories} cal    ${macros['protein'] ?? '0g'} protein';

    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 270,
                width: double.infinity,
                color: const Color(0xFF34445B),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  recipe.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              Positioned(
                top: 42,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white70,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
              Positioned(
                top: 42,
                right: 16,
                child: StreamBuilder<bool>(
                  stream: _favorites.watchIsFavorite(widget.studentId, recipe.id),
                  builder: (context, snap) {
                    final isFav = snap.data ?? false;
                    return CircleAvatar(
                      backgroundColor: Colors.white70,
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border_rounded,
                          color: isFav ? Colors.redAccent : null,
                        ),
                        onPressed: () => _toggleFavorite(context, isFav),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(meta),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Ingredients'),
              Tab(text: 'Instructions'),
              Tab(text: 'Nutrition'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: recipe.ingredients.isEmpty
                      ? [
                          const Text('No ingredient list for this recipe.'),
                        ]
                      : recipe.ingredients.map((m) {
                          final name =
                              (m['name'] ?? m['original'] ?? '').toString();
                          final amount = m['amount'];
                          final unit = (m['unit'] ?? '').toString();
                          final qty = [
                            if (amount != null) amount.toString(),
                            unit,
                          ].where((s) => s.toString().trim().isNotEmpty).join(' ');
                          return IngredientRow(
                            name: name.isEmpty ? 'Item' : name,
                            quantity: qty.isEmpty ? '—' : qty,
                          );
                        }).toList(),
                ),
                ListView(
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
                                CircleAvatar(
                                  radius: 14,
                                  child: Text('${i + 1}'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(recipe.steps[i])),
                              ],
                            ),
                          );
                        }),
                ),
                ListView(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _addToMealPlan(context),
                    child: const Text('Add to Meal Plan'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _logCooked(context),
                    child: const Text('Mark as cooked'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
