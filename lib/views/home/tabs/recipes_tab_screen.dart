import 'package:flutter/material.dart';
import '../../../controllers/time_constraint_controller.dart';
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
  int? _localMaxPrepTimeMinutes;
  final FirestoreService _firestore = FirestoreService();
  final TimeConstraintController _timeConstraint = TimeConstraintController();

  int get _maxPrepTimeMinutes =>
      _localMaxPrepTimeMinutes ?? widget.student.maxPrepTimeMinutes;

  Future<void> _editTimeConstraint() async {
    final current = _maxPrepTimeMinutes;

    final minutes = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _PrepTimeDialog(current: current),
    );

    if (!mounted || minutes == null) return;

    final previous = _maxPrepTimeMinutes;
    setState(() {
      _localMaxPrepTimeMinutes = minutes;
      _selectedFilter = 1;
    });

    final error = await _timeConstraint.setMaxPrepTime(
      studentId: widget.student.uid,
      minutes: minutes,
    );
    if (!mounted) return;
    if (error != null) {
      if (error.startsWith('Could not reach Firestore')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved locally. It will sync when you are online.'),
          ),
        );
        return;
      }

      setState(() => _localMaxPrepTimeMinutes = previous);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Time constraint updated')));
  }

  @override
  Widget build(BuildContext context) {
    final pantry = widget.student.availableIngredients;
    final filters = [
      'All Recipes',
      'Under $_maxPrepTimeMinutes min',
      'Budget-friendly',
    ];

    return StreamBuilder<List<Recipe>>(
      stream: _firestore.watchRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load recipes: ${snapshot.error}'),
          );
        }

        final all = snapshot.data ?? const <Recipe>[];
        final filtered = applyRecipeTabFilters(
          recipes: all,
          pantry: pantry,
          filterIndex: _selectedFilter,
          weeklyBudget: widget.student.weeklyBudget,
          maxPrepTimeMinutes: _maxPrepTimeMinutes,
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
                  onSelected: (_) {
                    setState(() => _selectedFilter = i);
                    if (i == 1) {
                      _editTimeConstraint();
                    }
                  },
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

class _PrepTimeDialog extends StatefulWidget {
  final int current;

  const _PrepTimeDialog({required this.current});

  @override
  State<_PrepTimeDialog> createState() => _PrepTimeDialogState();
}

class _PrepTimeDialogState extends State<_PrepTimeDialog> {
  late final TextEditingController _controller;
  late int _selected;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    _controller = TextEditingController(text: widget.current.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPreset(int minutes) {
    setState(() {
      _selected = minutes;
      _controller.text = minutes.toString();
      _errorText = null;
    });
  }

  void _save() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      setState(() {
        _errorText = 'Enter a prep time greater than 0 minutes.';
      });
      return;
    }
    if (value > 240) {
      setState(() {
        _errorText = 'Prep time must be 240 minutes or less.';
      });
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set prep time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [15, 30, 45, 60].map((minutes) {
              return ChoiceChip(
                selected: _selected == minutes,
                label: Text('$minutes min'),
                onSelected: (_) => _selectPreset(minutes),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Custom minutes',
              errorText: _errorText,
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value.trim());
              setState(() {
                _selected = parsed ?? -1;
                _errorText = null;
              });
            },
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
