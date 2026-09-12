import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/plant_service.dart';
import 'plant_data.dart';
import 'plant_editor_screen.dart';

/// Selects the visual composition used for an individual plant.
enum PlantTileLayout { row, grid }

/// Owns shared plant behavior and delegates rendering to the selected layout.
class PlantTile extends StatefulWidget {
  const PlantTile({super.key, required this.plant, required this.layout});

  final PlantData plant;
  final PlantTileLayout layout;

  @override
  State<PlantTile> createState() => _PlantTileState();
}

class _PlantTileState extends State<PlantTile> {
  Timer? _undoTimer;
  bool _showUndo = false;
  DateTime? _undoForWatering;

  PlantData get plant => widget.plant;

  @override
  void initState() {
    super.initState();
    _scheduleUndoExpiry();
  }

  @override
  void didUpdateWidget(PlantTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plant.id != plant.id ||
        _undoForWatering != plant.lastWateringTimestamp) {
      _scheduleUndoExpiry();
    }
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _PlantStatus.forPlant(context, plant);
    return switch (widget.layout) {
      PlantTileLayout.row => _PlantRow(
        key: ValueKey('plant-row-${plant.id}'),
        plant: plant,
        status: status,
        isUndo: _showUndo,
        onWaterOrUndo: () => _waterOrUndo(context),
        onEdit: () => _openEditor(context),
      ),
      PlantTileLayout.grid => _PlantGridCard(
        key: ValueKey('plant-grid-${plant.id}'),
        plant: plant,
        status: status,
        isUndo: _showUndo,
        onWaterOrUndo: () => _waterOrUndo(context),
        onEdit: () => _openEditor(context),
      ),
    };
  }

  Future<void> _waterOrUndo(BuildContext context) async {
    final store = context.read<PlantService>();
    if (_showUndo) {
      await store.undoWaterPlant(plant);
      _undoTimer?.cancel();
      if (mounted) setState(() => _showUndo = false);
      return;
    }

    if (plant.waterLevel >= 100) return;
    await store.waterPlant(plant);
    if (!context.mounted) return;
    _scheduleUndoExpiry();
    setState(() {});
  }

  void _scheduleUndoExpiry() {
    _undoTimer?.cancel();
    _undoForWatering = plant.lastWateringTimestamp;
    final remaining = plant.undoWateringTimeRemaining();
    _showUndo = remaining != null;
    if (remaining == null) return;
    _undoTimer = Timer(remaining, () {
      if (mounted) setState(() => _showUndo = false);
    });
  }

  Future<void> _openEditor(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => PlantEditorScreen(plant: plant)),
    );
  }
}

/// Presents a plant as a readable media row with compact trailing actions.
class _PlantRow extends StatelessWidget {
  const _PlantRow({
    super.key,
    required this.plant,
    required this.status,
    required this.isUndo,
    required this.onWaterOrUndo,
    required this.onEdit,
  });

  final PlantData plant;
  final _PlantStatus status;
  final bool isUndo;
  final VoidCallback onWaterOrUndo;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PlantPhoto(plant: plant, size: 96, borderRadius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plant.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: status.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Every ${plant.wateringInterval} ${plant.wateringInterval == 1 ? 'day' : 'days'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label:
                    '${isUndo ? 'Undo watering for' : 'Water'} ${plant.name}',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      onPressed: onWaterOrUndo,
                      tooltip: isUndo
                          ? 'Undo watering for ${plant.name}'
                          : 'Water ${plant.name}',
                      icon: Icon(isUndo ? Icons.undo : Icons.water_drop),
                    ),
                    Text(
                      isUndo ? 'Undo' : 'Water',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Presents a plant as a photo-first card for the two-column gallery.
class _PlantGridCard extends StatelessWidget {
  const _PlantGridCard({
    super.key,
    required this.plant,
    required this.status,
    required this.isUndo,
    required this.onWaterOrUndo,
    required this.onEdit,
  });

  final PlantData plant;
  final _PlantStatus status;
  final bool isUndo;
  final VoidCallback onWaterOrUndo;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PlantPhoto(plant: plant, borderRadius: 0),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.35, 1],
                colors: [Colors.transparent, Color(0xE6000000)],
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Edit ${plant.name}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onEdit),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 58,
            child: Text(
              plant.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 62,
            bottom: 14,
            child: Text(
              status.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: status.onImageColor,
                fontWeight: FontWeight.w700,
                height: 1.15,
                shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: IconButton.filled(
              onPressed: onWaterOrUndo,
              tooltip: isUndo
                  ? 'Undo watering for ${plant.name}'
                  : 'Water ${plant.name}',
              icon: Icon(isUndo ? Icons.undo : Icons.water_drop),
              style: IconButton.styleFrom(
                minimumSize: const Size.square(48),
                backgroundColor: status.actionColor,
                foregroundColor: status.onActionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a plant photo consistently across layouts, including load states.
class PlantPhoto extends StatelessWidget {
  const PlantPhoto({
    super.key,
    required this.plant,
    this.size,
    required this.borderRadius,
  });

  final PlantData plant;
  final double? size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final photo = plant.picturePath == null
        ? _PhotoFallback(plant: plant)
        : Image.file(
            File(plant.picturePath!),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _PhotoFallback(plant: plant, didFail: true),
          );

    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            photo,
            if (plant.isPictureSaving)
              ColoredBox(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

/// Supplies an accessible visual when a plant photo is absent or unavailable.
class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.plant, this.didFail = false});

  final PlantData plant;
  final bool didFail;

  @override
  Widget build(BuildContext context) {
    final foreground =
        ThemeData.estimateBrightnessForColor(plant.color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return ColoredBox(
      color: plant.color,
      child: Center(
        child: Icon(
          plant.didPictureSaveFail || didFail
              ? Icons.broken_image_outlined
              : Icons.eco,
          size: 42,
          color: foreground,
          semanticLabel: plant.didPictureSaveFail || didFail
              ? 'Photo unavailable'
              : 'No photo for ${plant.name}',
        ),
      ),
    );
  }
}

/// Maps the current water level to concise text and accessible action colors.
class _PlantStatus {
  const _PlantStatus({
    required this.label,
    required this.color,
    required this.onImageColor,
    required this.actionColor,
    required this.onActionColor,
  });

  final String label;
  final Color color;
  final Color onImageColor;
  final Color actionColor;
  final Color onActionColor;

  factory _PlantStatus.forPlant(BuildContext context, PlantData plant) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    late final String label;
    late final Color color;
    if (plant.waterLevel <= plant.wateringThreshold) {
      label = 'Needs water';
      color = colors.error;
    } else if (plant.waterLevel <= plant.wateringThreshold + 20) {
      label = 'Water soon';
      color = isDark ? Colors.amber.shade300 : Colors.amber.shade800;
    } else {
      label = 'Doing well';
      color = isDark ? Colors.green.shade300 : Colors.green.shade700;
    }

    final actionColor = color;
    final onActionColor =
        ThemeData.estimateBrightnessForColor(actionColor) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final onImageColor = color == colors.error
        ? Colors.red.shade200
        : label == 'Doing well'
        ? Colors.green.shade200
        : Colors.amber.shade200;

    return _PlantStatus(
      label: label,
      color: color,
      onImageColor: onImageColor,
      actionColor: actionColor,
      onActionColor: onActionColor,
    );
  }
}
