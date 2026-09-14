import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:simple_water_tracker/src/basic_feature/plant_data.dart';
import 'package:simple_water_tracker/src/helpers/plant_name_generator.dart';

import '../services/plant_service.dart';
import '../services/room_service.dart';
import '../rooms/room_assignment_field.dart';
import '../localization/app_localizations.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, this.initialRoomId});

  static const routeName = '/camera';
  final String? initialRoomId;

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

enum _CameraStatus { initializing, ready, capturing, unavailable, error }

enum _CameraPermissionDecision { granted, needsRequest }

class _TakePictureScreenState extends State<TakePictureScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  final TextEditingController _plantNameController = TextEditingController();
  String? _suggestedPlantName;
  int _currentWateringIntervalSliderValue = 3;
  _CameraStatus _cameraStatus = _CameraStatus.initializing;
  Future<void>? _cameraDisposal;
  bool _isInitializingCamera = false;
  bool _cameraWasDisposedForLifecycle = false;
  bool _cameraPermissionNeeded = false;
  bool _cameraPermissionRequiresSettings = false;
  bool _waitingForPermissionSettings = false;
  String? _roomId;

  @override
  void initState() {
    super.initState();
    _roomId = widget.initialRoomId;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A suggestion becomes draft content once shown; do not rename a draft
    // when the system language changes while the camera screen is open.
    _suggestedPlantName ??= generateRandomPlantName(
      AppLocalizations.of(context)!,
    );
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

      controller = CameraController(cameras.first, ResolutionPreset.veryHigh);
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
      await store.add(plant, pictureBytes: await imageFile.readAsBytes());

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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pictureCaptureFailed),
        ),
      );
    }
  }

  PlantData _createPlant() {
    return PlantData(
      name: _plantNameController.text.trim().isEmpty
          ? _suggestedPlantName!
          : _plantNameController.text,
      waterLevel: 0,
      wateringInterval: _currentWateringIntervalSliderValue,
      roomId: _resolvedRoomId(),
    );
  }

  Future<void> _addPlantWithoutPhoto(PlantService store) async {
    try {
      await store.add(_createPlant());
      if (mounted) Navigator.pop(context);
    } catch (error) {
      debugPrint('Could not add plant: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.plantAddFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final PlantService store = Provider.of<PlantService>(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.photoYourPlant)),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _plantNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.plantName,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: _suggestedPlantName,
                        helperText: l10n.plantNameSuggestionHelp,
                        helperMaxLines: 3,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    RoomAssignmentField(
                      roomId: _roomId,
                      onChanged: (roomId) => setState(() => _roomId = roomId),
                    ),
                    const SizedBox(height: 16),
                    _WateringIntervalControl(
                      interval: _currentWateringIntervalSliderValue,
                      onChanged: (value) => setState(
                        () => _currentWateringIntervalSliderValue = value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            // Keep the preview in the remaining space, while permission help
            // and large-text forms can extend the page and remain reachable.
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildCameraView(store),
            ),
          ],
        ),
      ),
      floatingActionButton: _cameraStatus == _CameraStatus.ready
          ? SizedBox(
              height: 70,
              width: 70,
              child: FittedBox(
                child: FloatingActionButton(
                  tooltip: l10n.takePhoto,
                  onPressed: () => _captureAndAddPlant(store),
                  child: const Icon(Icons.camera_alt),
                ),
              ),
            )
          : null,
    );
  }

  String? _resolvedRoomId() =>
      context.read<RoomService>().roomById(_roomId)?.id;

  Widget _buildCameraView(PlantService store) {
    switch (_cameraStatus) {
      case _CameraStatus.ready:
        return CameraPreview(_cameraController!);
      case _CameraStatus.initializing:
        return const Center(child: CircularProgressIndicator());
      case _CameraStatus.capturing:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.takingPicture),
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
                ? AppLocalizations.of(context)!.cameraPermissionDenied
                : cameraPermissionNeeded
                ? AppLocalizations.of(context)!.cameraPermissionRequired
                : canRetry
                ? AppLocalizations.of(context)!.cameraUnavailable
                : AppLocalizations.of(context)!.noCamera,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.cameraUnavailableHelp,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _addPlantWithoutPhoto(store),
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.addWithoutPhoto),
          ),
          if (canRetry) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  _initializeCamera(requestPermission: cameraPermissionNeeded),
              child: Text(
                cameraPermissionNeeded
                    ? AppLocalizations.of(context)!.useCamera
                    : AppLocalizations.of(context)!.retryCamera,
              ),
            ),
          ],
          if (canOpenSettings) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _openCameraSettings,
              child: Text(AppLocalizations.of(context)!.openAppSettings),
            ),
          ],
        ],
      ),
    );
  }
}

class _WateringIntervalControl extends StatelessWidget {
  const _WateringIntervalControl({
    required this.interval,
    required this.onChanged,
  });

  final int interval;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.waterEveryDays(interval),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Slider(
            value: interval.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: AppLocalizations.of(context)!.dayCount(interval),
            semanticFormatterCallback: (value) =>
                AppLocalizations.of(context)!.dayCount(value.toInt()),
            onChanged: (value) => onChanged(value.toInt()),
          ),
        ],
      ),
    ),
  );
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.displayPicture)),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}
