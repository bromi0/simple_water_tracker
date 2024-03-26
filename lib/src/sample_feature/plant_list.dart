import 'package:flutter/material.dart';
import 'package:simple_water_tracker/src/sample_feature/plant_data.dart';
import 'package:simple_water_tracker/src/sample_feature/sample_item_details_view.dart';

// To work with lists that may contain a large number of items, it’s best
// to use the ListView.builder constructor.
//
// In contrast to the default ListView constructor, which requires
// building all Widgets up front, the ListView.builder constructor lazily
// builds Widgets as they’re scrolled into view.
class PlantList extends StatelessWidget {
  const PlantList({
    super.key,
    required this.items,
  });

  final List<PlantData> items;
  @override
  Widget build(BuildContext context) {
    return GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 30,
        mainAxisSpacing: 10,
        childAspectRatio: (1 / 1.3),
        children: List<PlantTile>.generate(items.length, (index) {
          return PlantTile(plant: items[index]);
        })

        // return ListView.builder(
        //   // Providing a restorationId allows the ListView to restore the
        //   // scroll position when a user leaves and returns to the app after it
        //   // has been killed while running in the background.
        //   // restorationId: 'plantListView',
        //   itemCount: items.length,
        //   itemBuilder: (BuildContext context, int index) {
        //     final plant = items[index];

        //     return PlantTile(plant: plant);
        //   },
        );
  }
}

class PlantTile extends StatelessWidget {
  const PlantTile({
    super.key,
    required this.plant,
  });

  final PlantData plant;

  @override
  Widget build(BuildContext context) {
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
        },
        child: Column(children: [
          Text(plant.name),
          Container(
            width: double.infinity,
            height: 100,
            color: plant.color,
          ),
          Text('Water Level: ${plant.waterLevel}%'),
        ]),
      ),
    );
  }
}
