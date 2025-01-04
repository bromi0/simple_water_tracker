import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'package:simple_water_tracker/src/helpers/plant_name_generator.dart';

import '../services/plant_service.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
  });

  static const routeName = '/camera';

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  CameraController? _cameraController;
  final TextEditingController _plantNameController =
      TextEditingController(text: generateRandomPlantName());
  late Future<void>? _initializeControllerFuture;
  int _currentWateringIntervalSliderValue = 3;
  bool _isCameraAvailable = false;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController, if camera is available.
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isCameraAvailable = false;
        });
        return;
      }

      final firstCamera = cameras.first;
      final controller = CameraController(
        firstCamera,
        ResolutionPreset.veryHigh,
      );

      _cameraController = controller;
      _initializeControllerFuture = controller.initialize();

      setState(() {
        _isCameraAvailable = true;
      });
    } catch (e) {
      setState(() {
        _isCameraAvailable = false;
      });
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _cameraController?.dispose();
    _plantNameController.dispose();
    super.dispose();
  }

  Future<XFile?> _takePicture() async {
    if (!_isCameraAvailable || _cameraController == null) {
      return null;
    }

    try {
      await _initializeControllerFuture;
      final XFile file = await _cameraController!.takePicture();
      return file;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    }
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
          Text('Days between watering: $_currentWateringIntervalSliderValue',
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
              child: _isCameraAvailable
                  ? _buildCameraView()
                  : _buildNoCameraView()),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () async {
              // Take the Picture in a try / catch block. If anything goes wrong,
              // catch the error.
              try {
                final XFile? imageFile = await _takePicture();

                if (!context.mounted) return;

                // Create and Store new plant
                final plant = PlantData(
                    name: _plantNameController.text,
                    waterLevel: 0,
                    picture: imageFile,
                    wateringInterval: _currentWateringIntervalSliderValue);
                store.add(plant);

                Navigator.pop(context);
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

  Widget _buildCameraView() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the Future is complete, display the preview.
          return CameraPreview(_cameraController!);
        } else {
          // Otherwise, display a loading indicator.
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildNoCameraView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          const Text(
            'No camera available',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can still add a plant without a photo',
            style: TextStyle(color: Colors.grey),
          ),
        ],
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
