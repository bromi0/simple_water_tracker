import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/plant_service.dart';
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
    return Consumer<PlantService>(
      builder: (context, store, child) {
        final plants = store.plants;
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200, // Adjust this value according to your needs
            mainAxisSpacing: 10,
            crossAxisSpacing: 5,
            childAspectRatio: 1 / 1.3,
          ),
          itemCount: plants.length,
          itemBuilder: (context, index) {
            final plant = plants[index];
            return PlantTile(plant: plant);
          },
        );
      },
    );
  }
}
