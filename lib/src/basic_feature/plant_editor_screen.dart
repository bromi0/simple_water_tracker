import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/plant_photo_picker.dart';
import '../services/plant_service.dart';
import '../rooms/room_assignment_field.dart';
import '../settings/settings_controller.dart';
import '../services/room_service.dart';
import 'plant_data.dart';
import 'watering_status_presentation.dart';
import '../localization/app_localizations.dart';

/// A full-screen editor so a plant's photo and care details have one home.
class PlantEditorScreen extends StatefulWidget {
  const PlantEditorScreen({
    super.key,
    required this.plant,
    this.initialName,
    this.initialInterval,
    this.initialRoomId,
    this.initialPhotoBytes,
    this.photoPicker,
  });

  final PlantData plant;
  final String? initialName;
  final String? initialInterval;
  final String? initialRoomId;
  final Uint8List? initialPhotoBytes;
  final PlantPhotoPicker? photoPicker;

  @override
  State<PlantEditorScreen> createState() => _PlantEditorScreenState();
}

class _PlantEditorScreenState extends State<PlantEditorScreen> {
  late final TextEditingController _nameController;
  late int _wateringInterval;
  late Uint8List? _photoBytes;
  String? _roomId;
  late final PlantPhotoPicker _photoPicker;
  Timer? _undoTimer;
  bool _showUndo = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialName ?? widget.plant.name,
    );
    _wateringInterval =
        int.tryParse(widget.initialInterval ?? '') ??
        widget.plant.wateringInterval;
    _photoBytes = widget.initialPhotoBytes;
    _roomId = widget.initialRoomId ?? widget.plant.roomId;
    _photoPicker = widget.photoPicker ?? PlantPhotoPicker();
    _scheduleUndoExpiry();
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppLocalizations.of(context)!.chooseGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(AppLocalizations.of(context)!.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final bytes = await _photoPicker.pick(
        source: source,
        plantId: widget.plant.id,
        name: _nameController.text,
        interval: '$_wateringInterval',
        roomId: _resolvedRoomId(),
      );
      if (bytes != null && mounted) setState(() => _photoBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.photoSelectionFailed),
        ),
      );
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.plantNameRequired),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await context.read<PlantService>().updatePlant(
        widget.plant,
        name,
        _wateringInterval,
        pictureBytes: _photoBytes,
        roomId: _resolvedRoomId(),
        updateRoom: true,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      debugPrint('Could not save plant: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.plantSaveFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deletePlant() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deletePlantTitle),
        content: Text(
          AppLocalizations.of(
            context,
          )!.plantDeleteConfirmation(widget.plant.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    if (shouldDelete == true && mounted) {
      await context.read<PlantService>().remove(widget.plant);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _waterOrUndo() async {
    if (_isSaving) return;
    final store = context.read<PlantService>();
    if (_showUndo) {
      await store.undoWaterPlant(widget.plant);
      _undoTimer?.cancel();
      if (mounted) setState(() => _showUndo = false);
      return;
    }

    if (widget.plant.waterLevel >= 100) return;
    await store.waterPlant(widget.plant);
    if (!mounted) return;
    _scheduleUndoExpiry();
    setState(() {});
  }

  void _scheduleUndoExpiry() {
    _undoTimer?.cancel();
    final remaining = widget.plant.undoWateringTimeRemaining();
    _showUndo = remaining != null;
    if (remaining == null) return;
    _undoTimer = Timer(remaining, () {
      if (mounted) setState(() => _showUndo = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final store = context.watch<PlantService>();
    final presentation = context
        .watch<SettingsController>()
        .wateringStatusPresentation;
    final estimatedWateringTime = store.wateringSchedule
        .where((reminder) => reminder.plant.id == widget.plant.id)
        .map((reminder) => reminder.scheduledDateTime)
        .firstOrNull;
    final wateringStatus = PlantWateringStatus.forPlant(
      widget.plant,
      estimatedWateringTime: estimatedWateringTime,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editPlant),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _deletePlant,
            tooltip: l10n.deletePlant,
            color: theme.colorScheme.error,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PhotoPreview(
                plant: widget.plant,
                photoBytes: _photoBytes,
                onChangePhoto: _isSaving ? null : _changePhoto,
              ),
              const SizedBox(height: 20),
              _CurrentWateringStatus(
                status: wateringStatus,
                presentation: presentation,
                plantName: widget.plant.name,
                isUndo: _showUndo,
                onWaterOrUndo:
                    _isSaving || (!_showUndo && widget.plant.waterLevel >= 100)
                    ? null
                    : _waterOrUndo,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.plantName,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              RoomAssignmentField(
                roomId: _roomId,
                enabled: !_isSaving,
                onChanged: (roomId) => setState(() => _roomId = roomId),
              ),
              const SizedBox(height: 28),
              Text(l10n.watering, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _isSaving || _wateringInterval == 1
                        ? null
                        : () => setState(() => _wateringInterval--),
                    tooltip: l10n.decreaseWateringInterval,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      l10n.wateringInterval(_wateringInterval),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() => _wateringInterval++),
                    tooltip: l10n.increaseWateringInterval,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveChanges),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _resolvedRoomId() =>
      context.read<RoomService>().roomById(_roomId)?.id;
}

class _CurrentWateringStatus extends StatelessWidget {
  const _CurrentWateringStatus({
    required this.status,
    required this.presentation,
    required this.plantName,
    required this.isUndo,
    required this.onWaterOrUndo,
  });

  final PlantWateringStatus status;
  final WateringStatusPresentation presentation;
  final String plantName;
  final bool isUndo;
  final VoidCallback? onWaterOrUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statusColor = status.colorFor(theme);
    return Semantics(
      label: l10n.wateringStatusSemantics(
        status.semanticsLabel(l10n, presentation),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: statusColor.withAlpha(24),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        status.simpleLabel(l10n),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (presentation ==
                          WateringStatusPresentation.informative)
                        Text(
                          status.informativeLabel(l10n),
                          style: theme.textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: isUndo
                    ? l10n.undoWaterPlant(plantName)
                    : l10n.waterPlant(plantName),
                child: IconButton.filled(
                  onPressed: onWaterOrUndo,
                  tooltip: isUndo
                      ? l10n.undoWaterPlant(plantName)
                      : l10n.waterPlant(plantName),
                  style: IconButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor:
                        ThemeData.estimateBrightnessForColor(statusColor) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  icon: Icon(isUndo ? Icons.undo : Icons.water_drop),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.plant,
    required this.photoBytes,
    required this.onChangePhoto,
  });

  final PlantData plant;
  final Uint8List? photoBytes;
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final image = photoBytes != null
        ? Image.memory(photoBytes!, fit: BoxFit.cover)
        : plant.picturePath != null
        ? Image.file(
            File(plant.picturePath!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _FallbackPhoto(color: plant.color),
          )
        : ColoredBox(
            color: plant.color,
            child: const Center(child: Icon(Icons.eco, size: 72)),
          );
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            Positioned(
              right: 12,
              bottom: 12,
              child: IconButton.filled(
                onPressed: onChangePhoto,
                tooltip: l10n.changePhoto,
                icon: const Icon(Icons.photo_camera_back_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackPhoto extends StatelessWidget {
  const _FallbackPhoto({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: const Center(child: Icon(Icons.broken_image_outlined, size: 72)),
    );
  }
}
