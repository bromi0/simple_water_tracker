import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/plant_service.dart';
import '../settings/settings_service.dart';
import 'plant_tile.dart';

/// Lazily renders the plant collection in the user's selected responsive view.
class PlantList extends StatelessWidget {
  const PlantList({super.key, required this.layout, required this.onAddPlant});

  final PlantListLayout layout;
  final VoidCallback onAddPlant;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantService>(
      builder: (context, store, child) {
        final plants = store.plants;
        if (plants.isEmpty) {
          return _EmptyPlantList(onAddPlant: onAddPlant);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final useRows =
                layout == PlantListLayout.rows || constraints.maxWidth < 360;
            if (useRows) {
              return ListView.separated(
                key: const PageStorageKey('plant-row-list'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: plants.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) => PlantTile(
                  plant: plants[index],
                  layout: PlantTileLayout.row,
                ),
              );
            }

            return GridView.builder(
              key: const PageStorageKey('plant-grid-list'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.74,
              ),
              itemCount: plants.length,
              itemBuilder: (context, index) =>
                  PlantTile(plant: plants[index], layout: PlantTileLayout.grid),
            );
          },
        );
      },
    );
  }
}

/// Guides users to the existing add-plant flow when the collection is empty.
class _EmptyPlantList extends StatelessWidget {
  const _EmptyPlantList({required this.onAddPlant});

  final VoidCallback onAddPlant;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.eco_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text('No plants yet', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Add your first plant to start tracking its watering.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddPlant,
              icon: const Icon(Icons.add),
              label: const Text('Add plant'),
            ),
          ],
        ),
      ),
    );
  }
}
