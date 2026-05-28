import '../models/recipe_model.dart';

bool _recipeUsesPantryItem(Recipe recipe, String pantryItem) {
  final q = pantryItem.toLowerCase().trim();
  if (q.isEmpty) return false;
  for (final ing in recipe.ingredients) {
    final name = (ing['name'] ?? ing['original'] ?? '')
        .toString()
        .toLowerCase();
    if (name.contains(q) || (name.isNotEmpty && q.contains(name))) {
      return true;
    }
  }
  return false;
}

/// One recipe ingredient line (name or original) is covered by the pantry list.
bool ingredientLineCoveredByPantry(String recipeLine, List<String> pantry) {
  final n = recipeLine.toLowerCase().trim();
  if (n.isEmpty) return true;
  for (final p in pantry) {
    final q = p.toLowerCase().trim();
    if (q.isEmpty) continue;
    if (n.contains(q) || (n.isNotEmpty && q.contains(n))) return true;
  }
  return false;
}

/// Count of recipe ingredient lines that do **not** match any pantry item
/// (UC004 / UC008: prioritize recipes with the **fewest missing** items).
int missingIngredientCount(Recipe recipe, List<String> pantry) {
  if (pantry.isEmpty) return 0;
  if (recipe.ingredients.isEmpty) return 9999;

  var missing = 0;
  for (final ing in recipe.ingredients) {
    final line = (ing['name'] ?? ing['original'] ?? '').toString();
    if (line.trim().isEmpty) continue;
    if (!ingredientLineCoveredByPantry(line, pantry)) missing++;
  }
  return missing;
}

int countableRecipeIngredients(Recipe recipe) {
  return recipe.ingredients
      .where(
        (ing) =>
            (ing['name'] ?? ing['original'] ?? '').toString().trim().isNotEmpty,
      )
      .length;
}

/// If [pantry] is empty, all recipes match. Otherwise at least one pantry item
/// must match a recipe ingredient (so the recipe “aligns” with the pantry).
bool recipeMatchesPantry(Recipe recipe, List<String> pantry) {
  if (pantry.isEmpty) return true;
  for (final p in pantry) {
    if (_recipeUsesPantryItem(recipe, p)) return true;
  }
  return false;
}

/// UC004: after filtering, rank — fewest missing ingredients first, then lower
/// [Recipe.estimatedCost] (proxy for total ingredient cost).
void sortRecipesForPantryAndCost(List<Recipe> list, List<String> pantry) {
  if (pantry.isEmpty) {
    list.sort((a, b) {
      final c = a.estimatedCost.compareTo(b.estimatedCost);
      if (c != 0) return c;
      return a.prepTime.compareTo(b.prepTime);
    });
    return;
  }

  list.sort((a, b) {
    final ma = missingIngredientCount(a, pantry);
    final mb = missingIngredientCount(b, pantry);
    final c = ma.compareTo(mb);
    if (c != 0) return c;
    final cost = a.estimatedCost.compareTo(b.estimatedCost);
    if (cost != 0) return cost;
    return a.prepTime.compareTo(b.prepTime);
  });
}

List<Recipe> applyRecipeTabFilters({
  required List<Recipe> recipes,
  required List<String> pantry,
  required int filterIndex,
  required double weeklyBudget,
  int maxPrepTimeMinutes = 30,
}) {
  var list = recipes.where((r) => recipeMatchesPantry(r, pantry)).toList();

  switch (filterIndex) {
    case 1:
      final cap = maxPrepTimeMinutes > 0 ? maxPrepTimeMinutes : 30;
      list = list.where((r) => r.prepTime > 0 && r.prepTime <= cap).toList();
      break;
    case 2:
      final cap = weeklyBudget > 0 ? weeklyBudget : 12.0;
      list = list.where((r) => r.estimatedCost <= cap).toList();
      break;
    default:
      break;
  }

  sortRecipesForPantryAndCost(list, pantry);
  return list;
}

/// Short caption for list cards (e.g. “Missing 2 of 8 in recipe”).
String pantryRankCaption(Recipe recipe, List<String> pantry) {
  if (pantry.isEmpty) return '';
  final total = countableRecipeIngredients(recipe);
  if (total == 0) return '';
  final missing = missingIngredientCount(recipe, pantry);
  final have = total - missing;
  return '$have / $total pantry matches · $missing missing in recipe';
}

String recipeCardSubtitle(Recipe recipe) {
  if (recipe.steps.isNotEmpty) {
    final t = recipe.steps.first.trim();
    if (t.length > 120) return '${t.substring(0, 117)}...';
    return t;
  }
  if (recipe.ingredients.isNotEmpty) {
    final names = recipe.ingredients
        .map((m) => (m['name'] ?? m['original'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .take(4)
        .join(', ');
    return names.isEmpty ? 'Tap to view ingredients and steps.' : names;
  }
  return 'Tap to view details.';
}
