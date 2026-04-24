import 'package:flutter/material.dart';
import '../../../controllers/ingredient_inventory_controller.dart';
import '../../../models/user_model.dart';

class ScanTabScreen extends StatefulWidget {
  final Student student;

  const ScanTabScreen({super.key, required this.student});

  @override
  State<ScanTabScreen> createState() => _ScanTabScreenState();
}

class _ScanTabScreenState extends State<ScanTabScreen> {
  final TextEditingController _ingredientInput = TextEditingController();
  final IngredientInventoryController _inventory =
      IngredientInventoryController();
  bool _isSaving = false;

  @override
  void dispose() {
    _ingredientInput.dispose();
    super.dispose();
  }

  Future<void> _addIngredient() async {
    final text = _ingredientInput.text.trim();
    if (text.isEmpty) return;

    final next = IngredientInventoryController.normalizeIngredients([
      ...widget.student.availableIngredients,
      text,
    ]);

    setState(() => _isSaving = true);
    final err = await _inventory.saveAvailableIngredients(
      studentId: widget.student.uid,
      ingredients: next,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    _ingredientInput.clear();

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $err')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingredient added')),
      );
    }
  }

  Future<void> _removeIngredient(String name) async {
    final next = widget.student.availableIngredients
        .where((e) => e.toLowerCase() != name.toLowerCase())
        .toList();

    setState(() => _isSaving = true);
    final err = await _inventory.saveAvailableIngredients(
      studentId: widget.student.uid,
      ingredients: next,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $err')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantry = widget.student.availableIngredients;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Scan Ingredients',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Manual entry: add what you have if you skip the camera or if '
          'recognition fails. Your list is saved and used to rank recipes.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF1F2C3F),
          child: Container(
            height: 220,
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white54, width: 1.2),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Camera Viewfinder',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            CircleAvatar(radius: 24, child: Icon(Icons.image_rounded)),
            CircleAvatar(
              radius: 32,
              backgroundColor: Color(0xFF1F2C3F),
              child: Icon(Icons.camera_alt_rounded, color: Colors.white),
            ),
            CircleAvatar(radius: 24, child: Icon(Icons.flash_on_rounded)),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Add ingredients manually',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'If the camera is not available yet, type what you have. '
          'Recipes will prioritize items that match your pantry.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _ingredientInput,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Ingredient name',
                  hintText: 'e.g. chicken breast',
                ),
                onSubmitted: (_) => _addIngredient(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isSaving ? null : _addIngredient,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (pantry.isEmpty)
          Text(
            'No ingredients saved yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pantry
                .map(
                  (name) => InputChip(
                    label: Text(name),
                    onDeleted: _isSaving ? null : () => _removeIngredient(name),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 18),
        Text(
          'Position your camera to capture all ingredients in your fridge or pantry. '
          'SmartMeal will identify them and suggest recipes.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
