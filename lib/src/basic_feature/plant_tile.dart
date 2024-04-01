import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';

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
                    showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) {
                          return SingleChildScrollView(
                              child: Container(
                                  padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                          .viewInsets
                                          .bottom),
                                  child: PlantEditor(plant: plant)));
                        });
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

class PlantEditor extends StatefulWidget {
  const PlantEditor({super.key, required this.plant});
  final PlantData plant;

  @override
  State<PlantEditor> createState() => _PlantEditorState();
}

class _PlantEditorState extends State<PlantEditor> {
  late String _name;
  late int _wateringInterval;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name = widget.plant.name;
    _wateringInterval = widget.plant.wateringInterval;
    _nameController.text = _name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: _nameController.text.length),
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _decrementInterval() {
    setState(() {
      _wateringInterval = max(_wateringInterval - 1, 1);
    });
  }

  void _incrementInterval() {
    setState(() {
      _wateringInterval++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final PlantService store = Provider.of<PlantService>(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Plant Name'),
            onChanged: (value) => setState(() => _name = value),
            controller: _nameController,
            autofocus: true, // Set autofocus to true
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _decrementInterval,
                icon: const Icon(Icons.remove),
              ),
              Text('Watering Interval: $_wateringInterval days'),
              IconButton(
                onPressed: _incrementInterval,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              store.updatePlant(widget.plant, _name, _wateringInterval);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
