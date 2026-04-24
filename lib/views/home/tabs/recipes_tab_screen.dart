import 'package:flutter/material.dart';
import '../../../models/recipe_model.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../utils/recipe_filters.dart';
import '../recipe_detail_screen.dart';
import '../widgets/firestore_recipe_card.dart';

class RecipesTabScreen extends StatefulWidget {
  final Student student;

  const RecipesTabScreen({super.key, required this.student});

  @override
  State<RecipesTabScreen> createState() => _RecipesTabScreenState();
}

class _RecipesTabScreenState extends State<RecipesTabScreen> {
  int _selectedFilter = 0;
  final filters = const ['All Recipes', 'Under 30 min', 'Budget-friendly'];
  final FirestoreService _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final pantry = widget.student.availableIngredients;

    return StreamBuilder<List<Recipe>>(
      stream: _firestore.watchRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Could not load recipes: ${snapshot.error}'));
        }

        final all = snapshot.data ?? const <Recipe>[];
        final filtered = applyRecipeTabFilters(
          recipes: all,
          pantry: pantry,
          filterIndex: _selectedFilter,
          weeklyBudget: widget.student.weeklyBudget,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Recipe Suggestions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              pantry.isEmpty
                  ? 'Your pantry (add items on Scan tab to filter here):'
                  : 'Your pantry:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            if (pantry.isEmpty)
              Text(
                'No ingredients yet — open the Scan tab and add a few.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: pantry
                    .map((item) => Chip(label: Text(item)))
                    .toList(),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: List.generate(filters.length, (i) {
                return ChoiceChip(
                  selected: _selectedFilter == i,
                  onSelected: (_) => setState(() => _selectedFilter = i),
                  label: Text(filters[i]),
                );
              }),
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  all.isEmpty
                      ? 'No recipes in Firestore yet. Use Seed Recipes (admin) or add recipes in the console.'
                      : 'No recipes match your filters or pantry. Try "All Recipes", clear filters, or add different ingredients.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            else
              ...filtered.map(
                (recipe) => FirestoreRecipeCard(
                  recipe: recipe,
                  rankCaption: pantryRankCaption(recipe, pantry),
                  onView: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RecipeDetailScreen(
                          recipe: recipe,
                          studentId: widget.student.uid,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
