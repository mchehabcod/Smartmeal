import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/ingredient_inventory_controller.dart';
import '../../../models/user_model.dart';
import '../../../services/vertex_ai_service.dart';

class ScanTabScreen extends StatefulWidget {
  final Student student;

  const ScanTabScreen({super.key, required this.student});

  @override
  State<ScanTabScreen> createState() => _ScanTabScreenState();
}

class _ScanTabScreenState extends State<ScanTabScreen> {
  final TextEditingController _ingredientInput = TextEditingController();
  final IngredientInventoryController _inventory = IngredientInventoryController();
  final VertexAiService _aiService = VertexAiService();
  final ImagePicker _picker = ImagePicker();

  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isSaving = false;
  bool _isScanning = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _ingredientInput.dispose();
    _cameraController?.dispose();
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

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isScanning) {
      return;
    }

    try {
      setState(() {
        _isScanning = true;
      });

      final image = await _cameraController!.takePicture();
      final imageFile = File(image.path);

      final detected = await _aiService.scanIngredients(imageFile);

      if (detected.isNotEmpty) {
        final next = IngredientInventoryController.normalizeIngredients([
          ...widget.student.availableIngredients,
          ...detected,
        ]);

        final err = await _inventory.saveAvailableIngredients(
          studentId: widget.student.uid,
          ingredients: next,
        );

        if (!mounted) return;
        if (err != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save detected items: $err')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Detected and added: ${detected.join(", ")}')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No ingredients detected. Try again.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Scanner error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isScanning) return;
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isScanning = true;
      });

      final imageFile = File(image.path);
      final detected = await _aiService.scanIngredients(imageFile);

      if (detected.isNotEmpty) {
        final next = IngredientInventoryController.normalizeIngredients([
          ...widget.student.availableIngredients,
          ...detected,
        ]);

        final err = await _inventory.saveAvailableIngredients(
          studentId: widget.student.uid,
          ingredients: next,
        );

        if (!mounted) return;
        if (err != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save detected items: $err')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Detected and added: ${detected.join(", ")}')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No ingredients detected in gallery photo.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gallery scan error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
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
          'Position your camera to capture food ingredients in your fridge or pantry. '
          'AI recognition will analyze them and update your inventory list.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF1F2C3F),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isCameraInitialized && _cameraController != null)
                  Positioned.fill(
                    child: AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
                  )
                else
                  const Positioned.fill(
                    child: Center(
                      child: Text(
                        'Initializing Camera Feed...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                if (_isScanning)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 12),
                            Text(
                              'AI Scanning Image...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 28,
              icon: const Icon(Icons.image_rounded),
              onPressed: _isScanning ? null : _pickFromGallery,
              tooltip: 'Scan from Gallery',
            ),
            GestureDetector(
              onTap: _isScanning ? null : _captureAndScan,
              child: CircleAvatar(
                radius: 32,
                backgroundColor: _isScanning ? Colors.grey : const Color(0xFF1F2C3F),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
              ),
            ),
            IconButton(
              iconSize: 28,
              icon: Icon(_isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded),
              onPressed: _isScanning ? null : _toggleFlash,
              tooltip: 'Toggle Flash',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Add ingredients manually',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
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
        const SizedBox(height: 16),
        Text(
          'My Inventory Checklist',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        if (pantry.isEmpty)
          Text(
            'No ingredients saved yet. Add manually or scan above.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
      ],
    );
  }
}
