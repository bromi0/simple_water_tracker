import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'package:simple_water_tracker/src/helpers/plant_name_generator.dart';

import '../services/plant_service.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;
  static const routeName = '/camera';

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _cameraController;
  final TextEditingController _plantNameController =
      TextEditingController(text: generateRandomPlantName());
  late Future<void> _initializeControllerFuture;
  int _currentWateringIntervalSliderValue = 3;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _cameraController = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _cameraController.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlantService store = Provider.of<PlantService>(context);
    final sliderTextStyle = Theme.of(context).textTheme.bodyLarge;
    return Scaffold(
      appBar: AppBar(title: const Text('Photo your plant')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: Column(
        children: [
          Padding(
              padding: const EdgeInsets.all(32.0),
              child: TextField(
                controller: _plantNameController,
                decoration: const InputDecoration(
                  hintText: 'How should we call the plant?',
                  border: OutlineInputBorder(),
                ),
              )),
          Text('Days between watering: ${_currentWateringIntervalSliderValue}',
              style: sliderTextStyle),
          const SizedBox(height: 12.0),
          Slider(
              value: _currentWateringIntervalSliderValue.toDouble(),
              min: 1,
              max: 20,
              divisions: 20,
              onChanged: (double value) {
                setState(() {
                  _currentWateringIntervalSliderValue = value.toInt();
                });
              }),
          const SizedBox(height: 24.0),
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // If the Future is complete, display the preview.
                  return CameraPreview(_cameraController);
                } else {
                  // Otherwise, display a loading indicator.
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        height: 70,
        width: 70,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () async {
              // Take the Picture in a try / catch block. If anything goes wrong,
              // catch the error.
              try {
                // Ensure that the camera is initialized.
                await _initializeControllerFuture;

                // Attempt to take a picture and get the file `image`
                // where it was saved.
                final image = await _cameraController.takePicture();

                if (!context.mounted) return;

                // Create and Store new plant
                final plant = PlantData(
                    name: _plantNameController.text,
                    waterLevel: 0,
                    picture: image,
                    wateringInterval: _currentWateringIntervalSliderValue);
                store.add(plant);

                Navigator.pop(context);
                // If the picture was taken, display it on a new screen.
                // await Navigator.of(context).push(
                //   MaterialPageRoute(
                //     builder: (context) => DisplayPictureScreen(
                //       // Pass the automatically generated path to
                //       // the DisplayPictureScreen widget.
                //       imagePath: image.path,
                //     ),
                //   ),
                // );
              } catch (e) {
                // If an error occurs, log the error to the console.
                // print(e);
              }
            },
            child: const Icon(Icons.camera_alt),
          ),
        ),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}
