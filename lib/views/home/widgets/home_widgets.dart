import 'package:flutter/material.dart';

class RecipeHeroVisual extends StatelessWidget {
  final String title;
  final String imageUrl;
  final double? height;
  final BorderRadius borderRadius;
  final bool showTitle;

  const RecipeHeroVisual({
    super.key,
    required this.title,
    this.imageUrl = '',
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    final visual = url.isEmpty
        ? _RecipeFallbackArt(title: title)
        : Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _RecipeFallbackArt(title: title);
            },
            errorBuilder: (context, error, stackTrace) {
              return _RecipeFallbackArt(title: title);
            },
          );

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            visual,
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x11000000), Color(0xAA000000)],
                ),
              ),
            ),
            if (showTitle)
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecipeFallbackArt extends StatelessWidget {
  final String title;

  const _RecipeFallbackArt({required this.title});

  @override
  Widget build(BuildContext context) {
    final accent = _recipeAccent(title);
    final deep = Color.lerp(accent, const Color(0xFF1F2C3F), 0.45)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, deep],
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 72,
          color: Colors.white.withAlpha(54),
        ),
      ),
    );
  }
}

Color _recipeAccent(String title) {
  const colors = [
    Color(0xFF2E9D6F),
    Color(0xFFF2B84B),
    Color(0xFFE56B6F),
    Color(0xFF4E79A7),
    Color(0xFF7A6FF0),
  ];
  final hash = title.codeUnits.fold<int>(0, (sum, code) => sum + code);
  return colors[hash % colors.length];
}

class InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoPill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(190),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: SizedBox(
          height: 110,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.onSecondaryContainer),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecipeMiniCard extends StatelessWidget {
  final String title;
  final String time;
  final String price;
  final String imageUrl;
  final VoidCallback? onTap;

  const RecipeMiniCard({
    super.key,
    required this.title,
    required this.time,
    required this.price,
    this.imageUrl = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final cardW = (screen.width * 0.42).clamp(148.0, 200.0);

    Widget core = LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.hasBoundedHeight && constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (screen.height * 0.24).clamp(196.0, 260.0);
        return SizedBox(
          height: h,
          width: cardW,
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: RecipeHeroVisual(
                    title: title,
                    imageUrl: imageUrl,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MiniMeta(
                          icon: Icons.schedule_rounded,
                          label: time,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _MiniMeta(icon: Icons.payments_rounded, label: price),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (onTap == null) return core;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: core,
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class RecipeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onView;

  const RecipeCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipeHeroVisual(title: title, height: 150),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text('15 min    RM2.50    320 cal'),
                const SizedBox(height: 8),
                Text(subtitle),
                if (onView != null) ...[
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String title;
  final String value;

  const StatTile({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class IngredientRow extends StatelessWidget {
  final String name;
  final String quantity;

  const IngredientRow({super.key, required this.name, required this.quantity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(fontSize: 18)),
          Expanded(
            child: Text(name, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(quantity),
        ],
      ),
    );
  }
}
