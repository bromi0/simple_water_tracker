import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_water_tracker/src/sample_feature/plant_data.dart';

import '../services/plant_service.dart';

class PlantTile extends StatelessWidget {
  const PlantTile({
    super.key,
    required this.plant,
  });

  final PlantData plant;

  @override
  Widget build(BuildContext context) {
    final PlantService store = Provider.of<PlantService>(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: InkWell(
        splashColor: plant.color.withAlpha(30),
        onTap: () {
          // Navigate to the details page or handle tap event
          // Navigate to the details page. If the user leaves and returns to
          // the app after it has been killed while running in the
          // background, the navigation stack is restored.
          // Navigator.restorablePushNamed(
          //   context,
          //   SampleItemDetailsView.routeName,
          // );
          store.waterPlant(plant);
        },
        child: Column(children: [
          Text(plant.name),
          plant.picturePath == null
              ? Container(
                  width: double.infinity,
                  height: 90,
                  color: plant.color,
                )
              : Image.file(
                  File(plant.picturePath!),
                  width: double.infinity,
                  height: 90,
                  fit: BoxFit.cover,
                ),
          const Spacer(),
          Text('Water Level: ${plant.waterLevel}%'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel watering
                IconButton(
                  onPressed: () {
                    store.undoWaterPlant(plant);                    
                  },
                  icon: const Icon(Icons.undo),
                ),
                // Edit plant
                IconButton(
                  onPressed: () {                    
                  },
                  icon: const Icon(Icons.edit),
                ),
                // Delete plant
                IconButton(
                    onPressed: () {
                      store.remove(plant);
                    },
                    icon: const Icon(Icons.delete_forever)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
