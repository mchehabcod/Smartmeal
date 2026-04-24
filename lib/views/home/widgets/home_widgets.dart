import 'package:flutter/material.dart';

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: SizedBox(
          height: 110,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(icon),
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
  final VoidCallback? onTap;

  const RecipeMiniCard({
    super.key,
    required this.title,
    required this.time,
    required this.price,
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
                  child: Container(
                    color: Colors.blueGrey.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    alignment: Alignment.center,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          time,
                          style: Theme.of(context).textTheme.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        price,
                        style: Theme.of(context).textTheme.labelMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
          Container(
            height: 150,
            color: Colors.blueGrey.shade300,
            alignment: Alignment.center,
            child: const Text(
              'Recipe Image',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
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
                    child: FilledButton(
                      onPressed: onView,
                      child: const Text('View Recipe'),
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
              child: Text(name,
                  style: Theme.of(context).textTheme.titleMedium)),
          Text(quantity),
        ],
      ),
    );
  }
}
