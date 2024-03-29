import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_water_tracker/src/sample_feature/plant_data.dart';

import 'plant_tile.dart';

// To work with lists that may contain a large number of items, it’s best
// to use the ListView.builder constructor.
//
// In contrast to the default ListView constructor, which requires
// building all Widgets up front, the ListView.builder constructor lazily
// builds Widgets as they’re scrolled into view.
class PlantList extends StatelessWidget {
  const PlantList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantStore>(
      builder: (context, store, child) {
        final plants = store.plants;
        return GridView.count(
            padding: const EdgeInsets.all(20),
            crossAxisCount: 2,
            crossAxisSpacing: 30,
            mainAxisSpacing: 10,
            childAspectRatio: (1 / 1.3),
            children: List<PlantTile>.generate(plants.length, (index) {
              final plant = plants[index];
              return PlantTile(plant: plant);
            }));
      },
    );
  }
}
