import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/plant_service.dart';
import 'plant_data.dart';

/// Selects the visual composition used for an individual plant.
enum PlantTileLayout { row, grid }

/// Identifies secondary actions exposed by a plant's overflow menu.
enum _PlantMenuAction { undo, edit, delete }

/// Owns shared plant behavior and delegates rendering to the selected layout.
class PlantTile extends StatelessWidget {
  const PlantTile({super.key, required this.plant, required this.layout});

  final PlantData plant;
  final PlantTileLayout layout;

  @override
  Widget build(BuildContext context) {
    final status = _PlantStatus.forPlant(context, plant);
    return switch (layout) {
      PlantTileLayout.row => _PlantRow(
        key: ValueKey('plant-row-${plant.id}'),
        plant: plant,
        status: status,
        onWater: () => _waterPlant(context),
        onEdit: () => _showEditor(context),
        onMenuSelected: (action) => _handleMenuAction(context, action),
      ),
      PlantTileLayout.grid => _PlantGridCard(
        key: ValueKey('plant-grid-${plant.id}'),
        plant: plant,
        status: status,
        onWater: () => _waterPlant(context),
        onEdit: () => _showEditor(context),
        onMenuSelected: (action) => _handleMenuAction(context, action),
      ),
    };
  }

  Future<void> _waterPlant(BuildContext context) async {
    final store = context.read<PlantService>();
    final previousLevel = plant.waterLevel;
    await store.waterPlant(plant);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (previousLevel >= 100) {
      messenger.showSnackBar(
        SnackBar(content: Text('${plant.name} is already fully watered.')),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text('${plant.name} watered.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => store.undoWaterPlant(plant),
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    _PlantMenuAction action,
  ) async {
    switch (action) {
      case _PlantMenuAction.undo:
        await context.read<PlantService>().undoWaterPlant(plant);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Undid watering for ${plant.name}.')),
          );
        }
      case _PlantMenuAction.edit:
        await _showEditor(context);
      case _PlantMenuAction.delete:
        await _confirmDelete(context);
    }
  }

  Future<void> _showEditor(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: PlantEditor(plant: plant),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete plant?'),
        content: Text(
          '${plant.name} and its watering history will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      await context.read<PlantService>().remove(plant);
    }
  }
}

/// Presents a plant as a readable media row with compact trailing actions.
class _PlantRow extends StatelessWidget {
  const _PlantRow({
    super.key,
    required this.plant,
    required this.status,
    required this.onWater,
    required this.onEdit,
    required this.onMenuSelected,
  });

  final PlantData plant;
  final _PlantStatus status;
  final VoidCallback onWater;
  final VoidCallback onEdit;
  final ValueChanged<_PlantMenuAction> onMenuSelected;

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
                      '${plant.waterLevel}% · ${status.label}',
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
                label: 'Water ${plant.name}',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      onPressed: onWater,
                      tooltip: 'Water ${plant.name}',
                      icon: const Icon(Icons.water_drop),
                    ),
                    Text(
                      'Water',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _PlantActionsMenu(plant: plant, onSelected: onMenuSelected),
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
    required this.onWater,
    required this.onEdit,
    required this.onMenuSelected,
  });

  final PlantData plant;
  final _PlantStatus status;
  final VoidCallback onWater;
  final VoidCallback onEdit;
  final ValueChanged<_PlantMenuAction> onMenuSelected;

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
            top: 4,
            right: 4,
            child: _PlantActionsMenu(
              plant: plant,
              onSelected: onMenuSelected,
              foregroundColor: Colors.white,
              backgroundColor: Colors.black54,
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
              '${status.label}\n${plant.waterLevel}%',
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
              onPressed: onWater,
              tooltip: 'Water ${plant.name}',
              icon: const Icon(Icons.water_drop),
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

/// Keeps infrequent plant actions available without a permanent button row.
class _PlantActionsMenu extends StatelessWidget {
  const _PlantActionsMenu({
    required this.plant,
    required this.onSelected,
    this.foregroundColor,
    this.backgroundColor,
  });

  final PlantData plant;
  final ValueChanged<_PlantMenuAction> onSelected;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PlantMenuAction>(
      onSelected: onSelected,
      tooltip: 'More actions for ${plant.name}',
      icon: Icon(Icons.more_vert, color: foregroundColor),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        backgroundColor: backgroundColor,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _PlantMenuAction.undo,
          child: ListTile(
            leading: Icon(Icons.undo),
            title: Text('Undo watering'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: _PlantMenuAction.edit,
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit plant'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _PlantMenuAction.delete,
          child: ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete plant',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
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

/// Edits a plant's name and watering interval in a modal bottom sheet.
class PlantEditor extends StatefulWidget {
  const PlantEditor({super.key, required this.plant});
  final PlantData plant;

  @override
  State<PlantEditor> createState() => _PlantEditorState();
}

/// Holds draft editor values until the user saves them to the plant service.
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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Plant Name'),
            onChanged: (value) => setState(() => _name = value),
            controller: _nameController,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _decrementInterval,
                tooltip: 'Decrease watering interval',
                icon: const Icon(Icons.remove),
              ),
              Flexible(
                child: Text('Days between watering: $_wateringInterval'),
              ),
              IconButton(
                onPressed: _incrementInterval,
                tooltip: 'Increase watering interval',
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              store.updatePlant(
                widget.plant,
                _name.trim().isEmpty ? widget.plant.name : _name.trim(),
                _wateringInterval,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
