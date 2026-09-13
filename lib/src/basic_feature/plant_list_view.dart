import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../camera/take_picture_screen.dart';
import '../settings/settings_view.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_service.dart';
import 'plant_list.dart';
import 'reminder_schedule_view.dart';
import '../rooms/room_management_view.dart';
import '../rooms/room_selection.dart';
import '../services/plant_service.dart';
import '../services/room_service.dart';

/// Hosts the plant collection, view toggle, and main-screen navigation.
class PlantListView extends StatefulWidget {
  const PlantListView({super.key, required this.settingsController});

  final SettingsController settingsController;

  static const routeName = '/';

  @override
  State<PlantListView> createState() => _PlantListViewState();
}

class _PlantListViewState extends State<PlantListView> {
  RoomSelection _selection = const RoomSelection.all();

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<RoomService>();
    final selection = _normalizedSelection(rooms);
    final title = _selectionTitle(rooms, selection);
    return Scaffold(
      // Keep the collection's viewport stable during route transitions.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Semantics(
          button: true,
          label: 'Room filter, $title, change room',
          child: TextButton.icon(
            onPressed: _showRoomSelector,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.expand_more),
            label: Text(title, overflow: TextOverflow.ellipsis),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.settingsController.plantListLayout == PlantListLayout.rows
                  ? Icons.grid_view_rounded
                  : Icons.view_agenda_outlined,
            ),
            tooltip:
                widget.settingsController.plantListLayout ==
                    PlantListLayout.rows
                ? 'Use two-column view'
                : 'Use one-column view',
            onPressed: () {
              final nextLayout =
                  widget.settingsController.plantListLayout ==
                      PlantListLayout.rows
                  ? PlantListLayout.grid
                  : PlantListLayout.rows;
              widget.settingsController.updatePlantListLayout(nextLayout);
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Watering schedule',
            onPressed: () {
              Navigator.pushNamed(context, ReminderScheduleView.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              // Use a restorable route so Android can restore this navigation
              // stack after reclaiming the app in the background.
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: PlantList(
        layout: widget.settingsController.plantListLayout,
        selection: selection,
        roomName: rooms.roomById(selection.roomId)?.name,
        onAddPlant: () {
          _openAddPlant(selection);
        },
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.room),
            icon: Icon(Icons.room_outlined),
            label: 'Rooms',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.camera_roll),
            icon: Icon(Icons.camera_roll_outlined),
            label: 'Add Plant',
          ),
        ],
        onDestinationSelected: (int index) {
          if (index == 0) {
            _showRoomSelector();
          } else {
            _openAddPlant(selection);
          }
        },
      ),
    );
  }

  RoomSelection _normalizedSelection(RoomService rooms) {
    if (_selection.roomId != null &&
        rooms.roomById(_selection.roomId) == null) {
      return const RoomSelection.all();
    }
    return _selection;
  }

  String _selectionTitle(RoomService rooms, RoomSelection selection) {
    if (selection.isAll) return 'Plants';
    if (selection.isUnassigned) return 'No room';
    return rooms.roomById(selection.roomId)?.name ?? 'Plants';
  }

  Future<void> _showRoomSelector() async {
    final selected = await showModalBottomSheet<RoomSelection>(
      context: context,
      showDragHandle: true,
      builder: (context) => _RoomSelector(
        selection: _normalizedSelection(context.read<RoomService>()),
      ),
    );
    if (selected != null && mounted) setState(() => _selection = selected);
  }

  void _openAddPlant(RoomSelection selection) {
    Navigator.pushNamed(
      context,
      TakePictureScreen.routeName,
      arguments: selection.roomId,
    );
  }
}

class _RoomSelector extends StatelessWidget {
  const _RoomSelector({required this.selection});

  final RoomSelection selection;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<RoomService, PlantService>(
        builder: (context, rooms, plants, child) {
          int countFor(String? roomId, {required bool unassigned}) => plants
              .plants
              .where(
                (plant) =>
                    unassigned ? plant.roomId == null : plant.roomId == roomId,
              )
              .length;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Show plants', style: TextStyle(fontSize: 20)),
                  ),
                ),
                _ScopeTile(
                  label: 'All plants',
                  count: plants.plants.length,
                  selected: selection.isAll,
                  onTap: () =>
                      Navigator.pop(context, const RoomSelection.all()),
                ),
                _ScopeTile(
                  label: 'No room',
                  count: countFor(null, unassigned: true),
                  selected: selection.isUnassigned,
                  onTap: () =>
                      Navigator.pop(context, const RoomSelection.unassigned()),
                ),
                if (rooms.rooms.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: rooms.rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms.rooms[index];
                        return _ScopeTile(
                          label: room.name,
                          count: countFor(room.id, unassigned: false),
                          selected: selection.roomId == room.id,
                          onTap: () => Navigator.pop(
                            context,
                            RoomSelection.room(room.id),
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Manage rooms'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const RoomManagementView(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScopeTile extends StatelessWidget {
  const _ScopeTile({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count'),
        if (selected) ...[const SizedBox(width: 12), const Icon(Icons.check)],
      ],
    ),
    selected: selected,
    onTap: onTap,
  );
}
