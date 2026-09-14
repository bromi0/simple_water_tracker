import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../services/plant_service.dart';
import '../services/room_service.dart';
import 'room_data.dart';
import 'room_suggestion_labels.dart';

/// Keeps room editing separate from the main watering collection.
class RoomManagementView extends StatelessWidget {
  const RoomManagementView({super.key});

  static const routeName = '/rooms';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageRooms),
        actions: [
          IconButton(
            onPressed: () => _showRoomNameDialog(context),
            tooltip: l10n.createRoom,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<RoomService>(
        builder: (context, rooms, child) {
          final labels = roomSuggestionLabels(
            Localizations.of(context, AppLocalizations),
            Localizations.localeOf(context),
          );
          final usedNames = rooms.rooms
              .map((room) => room.name.toLowerCase())
              .toSet();
          final suggestions = labels.values
              .where((name) => !usedNames.contains(name.toLowerCase()))
              .toList();
          // Suggestions scroll with rooms so translated chips cannot crowd
          // the room list off a small screen at large text sizes.
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            header: suggestions.isEmpty
                ? null
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _SuggestedRooms(suggestions: suggestions),
                  ),
            footer: rooms.rooms.isEmpty ? const _EmptyRoomList() : null,
            itemCount: rooms.rooms.length,
            onReorderItem: (oldIndex, newIndex) =>
                _reorder(context, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final room = rooms.rooms[index];
              return _RoomTile(key: ValueKey(room.id), room: room);
            },
          );
        },
      ),
    );
  }

  Future<void> _reorder(
    BuildContext context,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      await context.read<RoomService>().reorder(oldIndex, newIndex);
    } catch (_) {
      if (context.mounted) {
        _showError(context, AppLocalizations.of(context)!.roomReorderFailed);
      }
    }
  }
}

class _SuggestedRooms extends StatelessWidget {
  const _SuggestedRooms({required this.suggestions});

  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.suggestedPlaces,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in suggestions)
              ActionChip(
                label: Text(name),
                onPressed: () async {
                  try {
                    await context.read<RoomService>().add(name);
                  } catch (_) {
                    if (context.mounted) {
                      _showError(context, l10n.roomAddFailed(name));
                    }
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _EmptyRoomList extends StatelessWidget {
  const _EmptyRoomList();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        AppLocalizations.of(context)!.roomsHelp,
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({super.key, required this.room});

  final RoomData room;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plantCount = context.select<PlantService, int>(
      (plants) =>
          plants.plants.where((plant) => plant.roomId == room.id).length,
    );
    return Card(
      child: ListTile(
        leading: const Icon(Icons.drag_handle),
        title: Text(room.name),
        subtitle: Text(l10n.plantCount(plantCount)),
        onTap: () => _showRoomNameDialog(context, room: room),
        trailing: IconButton(
          onPressed: () => _confirmDelete(context, room, plantCount),
          tooltip: l10n.deleteNamedRoom(room.name),
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

Future<void> _showRoomNameDialog(BuildContext context, {RoomData? room}) async {
  final roomService = context.read<RoomService>();
  final existingNames = roomService.rooms
      .where((candidate) => candidate != room)
      .map((candidate) => candidate.name)
      .toSet();
  final result = await showDialog<String>(
    context: context,
    builder: (context) =>
        _RoomNameDialog(room: room, existingNames: existingNames),
  );
  if (result == null || !context.mounted) return;
  try {
    if (room == null) {
      await roomService.add(result);
    } else {
      await roomService.rename(room, result);
    }
  } on RoomNameException catch (error) {
    if (context.mounted) {
      _showError(context, _roomNameError(context, error.reason));
    }
  } catch (_) {
    if (context.mounted) {
      _showError(context, AppLocalizations.of(context)!.roomSaveFailed);
    }
  }
}

class _RoomNameDialog extends StatefulWidget {
  const _RoomNameDialog({this.room, required this.existingNames});

  final RoomData? room;
  final Set<String> existingNames;

  @override
  State<_RoomNameDialog> createState() => _RoomNameDialogState();
}

class _RoomNameDialogState extends State<_RoomNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.room?.name ?? '',
  );
  RoomNameFailure? _nameFailure;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    alignment: Alignment.topCenter,
    insetPadding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
    insetAnimationDuration: Duration.zero,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.room == null
                ? AppLocalizations.of(context)!.createRoom
                : AppLocalizations.of(context)!.renameRoom,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.roomName,
              errorText: _nameFailure == null
                  ? null
                  : _roomNameError(context, _nameFailure!),
              errorMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_nameFailure != null) setState(() => _nameFailure = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            spacing: 8,
            overflowSpacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: _submit,
                child: Text(
                  widget.room == null
                      ? AppLocalizations.of(context)!.create
                      : AppLocalizations.of(context)!.save,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  void _submit() {
    final name = _controller.text.trim();
    final duplicate = widget.existingNames.any(
      (existing) => existing.toLowerCase() == name.toLowerCase(),
    );
    if (name.isEmpty || duplicate) {
      setState(() {
        _nameFailure = name.isEmpty
            ? RoomNameFailure.empty
            : RoomNameFailure.duplicate;
      });
      return;
    }
    Navigator.pop(context, name);
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  RoomData room,
  int plantCount,
) async {
  final delete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.roomDeleteTitle(room.name)),
      content: Text(
        plantCount == 0
            ? AppLocalizations.of(context)!.roomWillBeRemoved
            : AppLocalizations.of(context)!.roomPlantsKept(plantCount),
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
  if (delete != true || !context.mounted) return;
  final roomService = context.read<RoomService>();
  final plantService = context.read<PlantService>();
  try {
    await roomService.remove(room);
    await plantService.clearRoomReferences(room.id);
  } catch (_) {
    if (context.mounted) {
      _showError(context, AppLocalizations.of(context)!.roomDeleteFailed);
    }
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _roomNameError(BuildContext context, RoomNameFailure reason) {
  final l10n = AppLocalizations.of(context)!;
  return switch (reason) {
    RoomNameFailure.empty => l10n.roomNameRequired,
    RoomNameFailure.duplicate => l10n.roomNameDuplicate,
  };
}
