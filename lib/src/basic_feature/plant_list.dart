import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/plant_service.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_service.dart';
import 'plant_tile.dart';
import '../rooms/room_selection.dart';

/// Lazily renders the plant collection in the user's selected responsive view.
class PlantList extends StatelessWidget {
  const PlantList({
    super.key,
    required this.layout,
    required this.onAddPlant,
    required this.selection,
    required this.roomName,
  });

  final PlantListLayout layout;
  final VoidCallback onAddPlant;
  final RoomSelection selection;
  final String? roomName;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantService>(
      builder: (context, store, child) {
        final plants = store.plants.where((plant) {
          if (selection.isAll) return true;
          if (selection.isUnassigned) return plant.roomId == null;
          return plant.roomId == selection.roomId;
        }).toList();
        final scheduledTimes = {
          for (final reminder in store.wateringSchedule)
            reminder.plant.id: reminder.scheduledDateTime,
        };
        final presentation = context
            .watch<SettingsController>()
            .wateringStatusPresentation;
        if (plants.isEmpty) {
          return _EmptyPlantList(
            onAddPlant: onAddPlant,
            roomName: selection.roomId == null ? null : roomName,
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final useRows =
                layout == PlantListLayout.rows ||
                constraints.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            if (useRows) {
              return ListView.separated(
                key: const PageStorageKey('plant-row-list'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: plants.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) => PlantTile(
                  key: ValueKey(plants[index].id),
                  plant: plants[index],
                  layout: PlantTileLayout.row,
                  estimatedWateringTime: scheduledTimes[plants[index].id],
                  presentation: presentation,
                ),
              );
            }

            return GridView.builder(
              key: const PageStorageKey('plant-grid-list'),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: 0.74,
              ),
              itemCount: plants.length,
              itemBuilder: (context, index) => PlantTile(
                key: ValueKey(plants[index].id),
                plant: plants[index],
                layout: PlantTileLayout.grid,
                estimatedWateringTime: scheduledTimes[plants[index].id],
                presentation: presentation,
              ),
            );
          },
        );
      },
    );
  }
}

/// Guides users to the existing add-plant flow when the collection is empty.
class _EmptyPlantList extends StatelessWidget {
  const _EmptyPlantList({required this.onAddPlant, this.roomName});

  final VoidCallback onAddPlant;
  final String? roomName;

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
            Text(
              roomName == null ? 'No plants yet' : 'No plants in $roomName',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              roomName == null
                  ? 'Add your first plant to start tracking its watering.'
                  : 'Add a plant or move one here from its editor.',
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
