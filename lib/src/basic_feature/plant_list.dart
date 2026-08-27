import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/plant_service.dart';
import 'plant_tile.dart';

// Build plant tiles lazily so a large collection does not create every widget
// before it becomes visible.
class PlantList extends StatelessWidget {
  const PlantList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantService>(
      builder: (context, store, child) {
        final plants = store.plants;
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisSpacing: 10,
            crossAxisSpacing: 5,
            childAspectRatio: 1 / 1.3,
          ),
          itemCount: plants.length,
          itemBuilder: (context, index) {
            return PlantTile(plant: plants[index]);
          },
        );
      },
    );
  }
}
