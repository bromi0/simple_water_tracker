import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/room_service.dart';
import '../localization/app_localizations.dart';

/// A room field for plant drafts. It avoids a platform dropdown so room names
/// stay aligned and the choice has enough space on narrow screens.
class RoomAssignmentField extends StatelessWidget {
  const RoomAssignmentField({
    super.key,
    required this.roomId,
    required this.onChanged,
    this.enabled = true,
  });

  final String? roomId;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rooms = context.watch<RoomService>();
    final label = rooms.roomById(roomId)?.name ?? l10n.noRoom;
    return Semantics(
      button: enabled,
      label: l10n.roomAssignmentSemantics(label),
      child: InkWell(
        onTap: !enabled
            ? null
            : () async {
                final selected =
                    await showModalBottomSheet<_RoomAssignmentResult>(
                      context: context,
                      showDragHandle: true,
                      builder: (context) =>
                          _RoomAssignmentSheet(roomId: roomId),
                    );
                if (selected != null && context.mounted) {
                  onChanged(selected.roomId);
                }
              },
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.room,
            border: OutlineInputBorder(),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomAssignmentResult {
  const _RoomAssignmentResult(this.roomId);

  final String? roomId;
}

class _RoomAssignmentSheet extends StatelessWidget {
  const _RoomAssignmentSheet({required this.roomId});

  final String? roomId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rooms = context.watch<RoomService>();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.chooseRoom, style: TextStyle(fontSize: 20)),
              ),
            ),
            _RoomChoiceTile(
              name: l10n.noRoom,
              selected: roomId == null,
              onTap: () =>
                  Navigator.pop(context, const _RoomAssignmentResult(null)),
            ),
            if (rooms.rooms.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: rooms.rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms.rooms[index];
                    return _RoomChoiceTile(
                      name: room.name,
                      selected: room.id == roomId,
                      onTap: () => Navigator.pop(
                        context,
                        _RoomAssignmentResult(room.id),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoomChoiceTile extends StatelessWidget {
  const _RoomChoiceTile({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(name),
    trailing: selected ? const Icon(Icons.check) : null,
    selected: selected,
    onTap: onTap,
  );
}
