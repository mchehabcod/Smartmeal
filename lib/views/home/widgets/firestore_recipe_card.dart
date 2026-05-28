import 'package:flutter/material.dart';
import '../../../models/recipe_model.dart';
import '../../../utils/recipe_filters.dart';
import 'home_widgets.dart';

class FirestoreRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onView;

  /// UC004 ranked list hint (e.g. missing ingredient count).
  final String? rankCaption;

  const FirestoreRecipeCard({
    super.key,
    required this.recipe,
    required this.onView,
    this.rankCaption,
  });

  @override
  Widget build(BuildContext context) {
    final caption = rankCaption?.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipeHeroVisual(
            title: recipe.title,
            imageUrl: recipe.imageUrl,
            height: 168,
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
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
                      label: 'RM${recipe.estimatedCost.toStringAsFixed(2)}',
                    ),
                    InfoPill(
                      icon: Icons.local_fire_department_rounded,
                      label: '${recipe.calories} cal',
                    ),
                  ],
                ),
                if (caption != null && caption.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(caption, style: Theme.of(context).textTheme.labelMedium),
                ],
                const SizedBox(height: 8),
                Text(
                  recipeCardSubtitle(recipe),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.restaurant_menu_rounded),
                    label: const Text('View Recipe'),
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
