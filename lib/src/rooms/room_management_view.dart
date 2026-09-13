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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage rooms'),
        actions: [
          IconButton(
            onPressed: () => _showRoomNameDialog(context),
            tooltip: 'Create room',
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (suggestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _SuggestedRooms(suggestions: suggestions),
                ),
              Expanded(
                child: rooms.rooms.isEmpty
                    ? const _EmptyRoomList()
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: rooms.rooms.length,
                        onReorderItem: (oldIndex, newIndex) =>
                            _reorder(context, oldIndex, newIndex),
                        itemBuilder: (context, index) {
                          final room = rooms.rooms[index];
                          return _RoomTile(key: ValueKey(room.id), room: room);
                        },
                      ),
              ),
            ],
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
      if (context.mounted) _showError(context, 'Could not reorder rooms.');
    }
  }
}

class _SuggestedRooms extends StatelessWidget {
  const _SuggestedRooms({required this.suggestions});

  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested places',
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
                      _showError(context, 'Could not add $name.');
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
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'Rooms are optional. Add a suggested place or create your own.',
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
    final plantCount = context.select<PlantService, int>(
      (plants) =>
          plants.plants.where((plant) => plant.roomId == room.id).length,
    );
    return Card(
      child: ListTile(
        leading: const Icon(Icons.drag_handle),
        title: Text(room.name),
        subtitle: Text('$plantCount ${plantCount == 1 ? 'plant' : 'plants'}'),
        onTap: () => _showRoomNameDialog(context, room: room),
        trailing: IconButton(
          onPressed: () => _confirmDelete(context, room, plantCount),
          tooltip: 'Delete ${room.name}',
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
  } on ArgumentError catch (error) {
    if (context.mounted) _showError(context, error.message.toString());
  } catch (_) {
    if (context.mounted) _showError(context, 'Could not save this room.');
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
  String? _errorText;

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
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.room == null ? 'Create room' : 'Rename room',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Room name',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submit,
                child: Text(widget.room == null ? 'Create' : 'Save'),
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
        _errorText = name.isEmpty
            ? 'Enter a room name.'
            : 'A room with that name already exists.';
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
      title: Text('Delete ${room.name}?'),
      content: Text(
        plantCount == 0
            ? 'This room will be removed.'
            : '$plantCount ${plantCount == 1 ? 'plant will' : 'plants will'} be kept without a room.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Delete'),
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
    if (context.mounted) _showError(context, 'Could not delete this room.');
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
