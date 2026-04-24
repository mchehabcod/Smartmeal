import 'package:flutter/material.dart';
import '../../../models/recipe_model.dart';
import '../../../utils/recipe_filters.dart';

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
    final meta =
        '${recipe.prepTime} min    RM${recipe.estimatedCost.toStringAsFixed(2)}    ${recipe.calories} cal';
    final caption = rankCaption?.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            color: Colors.blueGrey.shade400,
            alignment: Alignment.center,
            child: Text(
              recipe.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
                Text(meta),
                if (caption != null && caption.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    caption,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
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
                  child: FilledButton(
                    onPressed: onView,
                    child: const Text('View Recipe'),
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
