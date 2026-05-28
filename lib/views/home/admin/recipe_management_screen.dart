import 'package:flutter/material.dart';

import '../../../models/recipe_model.dart';
import '../../../services/firestore_service.dart';
import 'add_recipe_screen.dart';

class RecipeManagementScreen extends StatelessWidget {
  RecipeManagementScreen({super.key});

  final FirestoreService _firestore = FirestoreService();

  Future<void> _openAdd(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddRecipeScreen()));
  }

  Future<void> _openEdit(BuildContext context, Recipe recipe) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AddRecipeScreen(recipe: recipe)),
    );
  }

  Future<void> _deleteRecipe(BuildContext context, Recipe recipe) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete recipe?'),
          content: Text(
            'This will permanently remove "${recipe.title}" from SmartMeal.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true || !context.mounted) return;

    try {
      await _firestore.deleteRecipe(recipe.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recipe deleted.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete recipe: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Recipes'),
        actions: [
          IconButton(
            onPressed: () => _openAdd(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<Recipe>>(
        stream: _firestore.watchRecipes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load recipes.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = [...snapshot.data!]
            ..sort((a, b) => a.title.compareTo(b.title));
          if (recipes.isEmpty) {
            return const Center(child: Text('No recipes available.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Card(
                child: ListTile(
                  title: Text(recipe.title),
                  subtitle: Text(
                    '${recipe.prepTime} min  |  '
                    'RM${recipe.estimatedCost.toStringAsFixed(2)}  |  '
                    '${recipe.calories} kcal',
                  ),
                  onTap: () => _openEdit(context, recipe),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openEdit(context, recipe);
                      }
                      if (value == 'delete') {
                        _deleteRecipe(context, recipe);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
