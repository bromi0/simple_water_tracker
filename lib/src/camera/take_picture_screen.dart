import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'package:simple_water_tracker/src/helpers/plant_name_generator.dart';

import '../services/plant_picture_storage.dart';
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

enum _CameraStatus { initializing, ready, capturing, unavailable, error }

enum _CameraPermissionDecision { granted, needsRequest }

class _TakePictureScreenState extends State<TakePictureScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  final TextEditingController _plantNameController =
      TextEditingController(text: generateRandomPlantName());
  int _currentWateringIntervalSliderValue = 3;
  _CameraStatus _cameraStatus = _CameraStatus.initializing;
  Future<void>? _cameraDisposal;
  bool _isInitializingCamera = false;
  bool _cameraWasDisposedForLifecycle = false;
  bool _cameraPermissionNeeded = false;
  bool _cameraPermissionRequiresSettings = false;
  bool _waitingForPermissionSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  Future<void> _initializeCamera({bool requestPermission = false}) async {
    if (_isInitializingCamera ||
        _cameraStatus == _CameraStatus.ready ||
        _cameraStatus == _CameraStatus.capturing) {
      return;
    }
    _isInitializingCamera = true;

    if (mounted) {
      setState(() {
        _cameraStatus = _CameraStatus.initializing;
      });
    }

    CameraController? controller;
    try {
      await _cameraDisposal;
      var permissionDecision = await _resolveCameraPermission();
      if (permissionDecision == _CameraPermissionDecision.needsRequest &&
          requestPermission) {
        final status = await Permission.camera.request();
        permissionDecision = status.isGranted
            ? _CameraPermissionDecision.granted
            : _CameraPermissionDecision.needsRequest;
        _cameraPermissionRequiresSettings = !status.isGranted;
      }
      if (permissionDecision != _CameraPermissionDecision.granted) {
        if (!mounted) return;
        setState(() {
          _cameraPermissionNeeded = true;
          _cameraStatus = _CameraStatus.error;
        });
        return;
      }

      _cameraPermissionNeeded = false;
      _cameraPermissionRequiresSettings = false;
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cameraStatus = _CameraStatus.unavailable;
        });
        return;
      }

      controller = CameraController(
        cameras.first,
        ResolutionPreset.veryHigh,
      );
      _cameraController = controller;
      await controller.initialize().timeout(const Duration(seconds: 15));

      if (!mounted || _cameraController != controller) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraStatus = _CameraStatus.ready;
      });
    } catch (error) {
      debugPrint('Error initializing camera: $error');
      _cameraPermissionNeeded = false;
      if (_cameraController == controller) {
        _cameraController = null;
      }
      await controller?.dispose();
      if (!mounted) return;
      setState(() {
        _cameraStatus = _CameraStatus.error;
      });
    } finally {
      _isInitializingCamera = false;
    }
  }

  Future<_CameraPermissionDecision> _resolveCameraPermission() async {
    if (kIsWeb || !Platform.isAndroid) {
      return _CameraPermissionDecision.granted;
    }

    var status = await Permission.camera.status;
    if (status.isGranted) {
      return _CameraPermissionDecision.granted;
    }
    return _CameraPermissionDecision.needsRequest;
  }

  Future<void> _openCameraSettings() async {
    _waitingForPermissionSettings = await openAppSettings();
  }

  Future<void> _disposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    try {
      await controller?.dispose();
    } catch (error) {
      debugPrint('Error disposing camera: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForPermissionSettings) {
      _waitingForPermissionSettings = false;
      unawaited(_initializeCamera());
      return;
    }

    if (state == AppLifecycleState.resumed && _cameraWasDisposedForLifecycle) {
      _cameraWasDisposedForLifecycle = false;
      unawaited(_initializeCamera());
      return;
    }

    final controller = _cameraController;
    if (state == AppLifecycleState.inactive &&
        controller != null &&
        controller.value.isInitialized) {
      _cameraWasDisposedForLifecycle = true;
      if (mounted) {
        setState(() {
          _cameraStatus = _CameraStatus.initializing;
        });
      }
      _cameraDisposal = _disposeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeCamera());
    _plantNameController.dispose();
    super.dispose();
  }

  Future<void> _captureAndAddPlant(PlantService store) async {
    final controller = _cameraController;
    if (_cameraStatus != _CameraStatus.ready || controller == null) return;

    setState(() {
      _cameraStatus = _CameraStatus.capturing;
    });
    try {
      final imageFile = await controller.takePicture();
      if (!mounted) return;

      final plant = _createPlant();
      final pictureSave = PlantPictureStorage.save(
        plantId: plant.id,
        pictureBytes: imageFile.readAsBytes(),
      );
      unawaited(store.add(plant, pictureSave: pictureSave));

      await _disposeCamera();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      debugPrint('Error taking picture: $error');
      if (!mounted) return;
      setState(() {
        _cameraStatus = _cameraController == null
            ? _CameraStatus.error
            : _CameraStatus.ready;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not take the picture. Try again.')),
      );
    }
  }

  PlantData _createPlant() {
    return PlantData(
      name: _plantNameController.text,
      waterLevel: 0,
      wateringInterval: _currentWateringIntervalSliderValue,
    );
  }

  void _addPlantWithoutPhoto(PlantService store) {
    unawaited(store.add(_createPlant()));
    Navigator.pop(context);
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
          Expanded(child: _buildCameraView(store)),
        ],
      ),
      floatingActionButton: _cameraStatus == _CameraStatus.ready
          ? SizedBox(
              height: 70,
              width: 70,
              child: FittedBox(
                child: FloatingActionButton(
                  onPressed: () => _captureAndAddPlant(store),
                  child: const Icon(Icons.camera_alt),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCameraView(PlantService store) {
    switch (_cameraStatus) {
      case _CameraStatus.ready:
        return CameraPreview(_cameraController!);
      case _CameraStatus.initializing:
        return const Center(child: CircularProgressIndicator());
      case _CameraStatus.capturing:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Taking picture...'),
            ],
          ),
        );
      case _CameraStatus.unavailable:
        return _buildNoCameraView(store, canRetry: false);
      case _CameraStatus.error:
        return _buildNoCameraView(
          store,
          canRetry: !_cameraPermissionRequiresSettings,
          canOpenSettings: _cameraPermissionRequiresSettings,
          cameraPermissionNeeded: _cameraPermissionNeeded,
        );
    }
  }

  Widget _buildNoCameraView(
    PlantService store, {
    required bool canRetry,
    bool canOpenSettings = false,
    bool cameraPermissionNeeded = false,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            canOpenSettings
                ? 'Camera permission denied'
                : cameraPermissionNeeded
                    ? 'Camera permission required'
                    : canRetry
                        ? 'Camera access unavailable'
                        : 'No camera available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'The camera may be unavailable or permission may have been denied.\n'
            'You can still add this plant without a photo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _addPlantWithoutPhoto(store),
            icon: const Icon(Icons.add),
            label: const Text('Add without photo'),
          ),
          if (canRetry) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _initializeCamera(
                requestPermission: cameraPermissionNeeded,
              ),
              child: Text(
                cameraPermissionNeeded ? 'Use camera' : 'Retry camera',
              ),
            ),
          ],
          if (canOpenSettings) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _openCameraSettings,
              child: const Text('Open app settings'),
            ),
          ],
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
