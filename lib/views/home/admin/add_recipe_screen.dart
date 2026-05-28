import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/recipe_model.dart';
import '../../../services/firestore_service.dart';

class AddRecipeScreen extends StatefulWidget {
  final Recipe? recipe;

  const AddRecipeScreen({super.key, this.recipe});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();
  final _titleController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _costController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _ingredientControllers = <_IngredientControllers>[];
  final _stepControllers = <TextEditingController>[];
  bool _isSaving = false;

  bool get _isEditing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    if (recipe == null) {
      _ingredientControllers.add(_IngredientControllers());
      _stepControllers.add(TextEditingController());
      return;
    }

    _titleController.text = recipe.title;
    _prepTimeController.text = recipe.prepTime.toString();
    _costController.text = _formatInputNumber(recipe.estimatedCost);
    _caloriesController.text = recipe.calories.toString();
    _proteinController.text = _macroInput(recipe.macros['protein']);
    _carbsController.text = _macroInput(recipe.macros['carbs']);
    _fatController.text = _macroInput(recipe.macros['fat']);

    if (recipe.ingredients.isEmpty) {
      _ingredientControllers.add(_IngredientControllers());
    } else {
      _ingredientControllers.addAll(
        recipe.ingredients.map(_IngredientControllers.fromIngredient),
      );
    }

    if (recipe.steps.isEmpty) {
      _stepControllers.add(TextEditingController());
    } else {
      _stepControllers.addAll(
        recipe.steps.map((step) => TextEditingController(text: step)),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _prepTimeController.dispose();
    _costController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    for (final controllers in _ingredientControllers) {
      controllers.dispose();
    }
    for (final controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() => _ingredientControllers.add(_IngredientControllers()));
  }

  void _removeIngredient(int index) {
    if (_ingredientControllers.length == 1) return;
    final removed = _ingredientControllers.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  void _addStep() {
    setState(() => _stepControllers.add(TextEditingController()));
  }

  void _removeStep(int index) {
    if (_stepControllers.length == 1) return;
    final removed = _stepControllers.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _saveRecipe() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final recipeId =
        widget.recipe?.id ??
        FirebaseFirestore.instance.collection('recipes').doc().id;
    final recipe = Recipe(
      id: recipeId,
      title: _titleController.text.trim(),
      ingredients: _ingredientControllers
          .map((controllers) => controllers.toIngredient())
          .where((ingredient) => ingredient['name'].toString().isNotEmpty)
          .toList(),
      steps: _stepControllers
          .map((controller) => controller.text.trim())
          .where((step) => step.isNotEmpty)
          .toList(),
      prepTime: int.parse(_prepTimeController.text.trim()),
      estimatedCost: double.parse(_costController.text.trim()),
      calories: int.parse(_caloriesController.text.trim()),
      macros: {
        'protein': '${_formatMacro(_proteinController.text)}g',
        'carbs': '${_formatMacro(_carbsController.text)}g',
        'fat': '${_formatMacro(_fatController.text)}g',
      },
    );

    setState(() => _isSaving = true);
    try {
      await _firestore.addRecipe(recipe);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Recipe updated.' : 'Recipe added.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add recipe: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Recipe' : 'Add Recipe')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Recipe title'),
              validator: _requiredText,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    decoration: const InputDecoration(labelText: 'Prep min'),
                    keyboardType: TextInputType.number,
                    validator: _positiveInt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(labelText: 'Cost RM'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _nonNegativeDouble,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(labelText: 'Calories'),
              keyboardType: TextInputType.number,
              validator: _nonNegativeInt,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    decoration: const InputDecoration(labelText: 'Protein g'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _nonNegativeDouble,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    decoration: const InputDecoration(labelText: 'Carbs g'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _nonNegativeDouble,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    decoration: const InputDecoration(labelText: 'Fat g'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _nonNegativeDouble,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionHeader(title: 'Ingredients', onAdd: _addIngredient),
            const SizedBox(height: 8),
            for (var i = 0; i < _ingredientControllers.length; i++) ...[
              _IngredientFields(
                controllers: _ingredientControllers[i],
                onRemove: () => _removeIngredient(i),
                canRemove: _ingredientControllers.length > 1,
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
            _SectionHeader(title: 'Steps', onAdd: _addStep),
            const SizedBox(height: 8),
            for (var i = 0; i < _stepControllers.length; i++) ...[
              TextFormField(
                controller: _stepControllers[i],
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Step ${i + 1}',
                  suffixIcon: _stepControllers.length > 1
                      ? IconButton(
                          onPressed: () => _removeStep(i),
                          icon: const Icon(Icons.remove_circle_outline),
                        )
                      : null,
                ),
                validator: _requiredText,
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveRecipe,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : (_isEditing ? 'Update Recipe' : 'Save Recipe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;

  const _SectionHeader({required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton.filledTonal(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _IngredientFields extends StatelessWidget {
  final _IngredientControllers controllers;
  final VoidCallback onRemove;
  final bool canRemove;

  const _IngredientFields({
    required this.controllers,
    required this.onRemove,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: controllers.name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: _requiredText,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: controllers.amount,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _optionalNonNegativeDouble,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: controllers.unit,
            decoration: const InputDecoration(labelText: 'Unit'),
          ),
        ),
        IconButton(
          onPressed: canRemove ? onRemove : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
      ],
    );
  }
}

class _IngredientControllers {
  final name = TextEditingController();
  final amount = TextEditingController();
  final unit = TextEditingController();

  _IngredientControllers();

  factory _IngredientControllers.fromIngredient(Map<String, dynamic> item) {
    final controllers = _IngredientControllers();
    controllers.name.text = (item['name'] ?? item['original'] ?? '').toString();
    controllers.amount.text = _formatInputValue(item['amount']);
    controllers.unit.text = (item['unit'] ?? '').toString();
    return controllers;
  }

  Map<String, dynamic> toIngredient() {
    final trimmedAmount = amount.text.trim();
    return {
      'name': name.text.trim(),
      'amount': double.tryParse(trimmedAmount),
      'unit': unit.text.trim(),
    };
  }

  void dispose() {
    name.dispose();
    amount.dispose();
    unit.dispose();
  }
}

String _formatMacro(String value) {
  final parsed = double.tryParse(value.trim()) ?? 0;
  return parsed == parsed.roundToDouble()
      ? parsed.toStringAsFixed(0)
      : parsed.toStringAsFixed(1);
}

String _macroInput(String? value) {
  if (value == null) return '';
  final match = RegExp(r'\d+(\.\d+)?').firstMatch(value);
  return _formatInputValue(match?.group(0));
}

String _formatInputValue(dynamic value) {
  if (value == null) return '';
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  if (parsed == null) return '';
  return _formatInputNumber(parsed);
}

String _formatInputNumber(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

String? _requiredText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return null;
}

String? _positiveInt(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  if (parsed == null || parsed <= 0) {
    return 'Enter a number above 0';
  }
  return null;
}

String? _nonNegativeInt(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  if (parsed == null || parsed < 0) {
    return 'Enter 0 or above';
  }
  return null;
}

String? _nonNegativeDouble(String? value) {
  final parsed = double.tryParse(value?.trim() ?? '');
  if (parsed == null || parsed < 0) {
    return 'Enter 0 or above';
  }
  return null;
}

String? _optionalNonNegativeDouble(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final parsed = double.tryParse(trimmed);
  if (parsed == null || parsed < 0) {
    return 'Enter 0 or above';
  }
  return null;
}
