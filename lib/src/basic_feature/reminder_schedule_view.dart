import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';
import '../services/plant_service.dart';

class ReminderScheduleView extends StatelessWidget {
  const ReminderScheduleView({super.key});

  static const routeName = '/watering-schedule';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watering week'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Test notification in one minute',
            onPressed: () => _scheduleTest(context),
          ),
        ],
      ),
      body: Consumer<PlantService>(
        builder: (context, store, child) {
          if (store.wateringSchedule.isEmpty) {
            return const Center(child: Text('No plants to remind you about.'));
          }
          return _ReminderCalendar(reminders: store.wateringSchedule);
        },
      ),
    );
  }

  Future<void> _scheduleTest(BuildContext context) async {
    final scheduled = await NotificationService.scheduleTestNotification();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          scheduled
              ? 'Test reminder scheduled for one minute from now.'
              : 'Enable notifications to schedule a test reminder.',
        ),
      ),
    );
  }
}

class _ReminderCalendar extends StatelessWidget {
  const _ReminderCalendar({required this.reminders});

  final List<ExpectedWateringTime> reminders;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final days = List.generate(7, (index) => today.add(Duration(days: index)));
    final grouped = <DateTime, List<ExpectedWateringTime>>{};
    for (final reminder in reminders) {
      var day = _dateOnly(reminder.scheduledDateTime);
      // Past reminders are still actionable, so present them in today's group
      // rather than creating sections for dates the user can no longer act on.
      if (day.isBefore(today)) day = today;
      grouped.putIfAbsent(day, () => []).add(reminder);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _WeekStrip(days: days, grouped: grouped),
        const SizedBox(height: 20),
        for (final entry in grouped.entries) ...[
          _DateHeading(date: entry.key, today: today),
          for (final reminder in entry.value)
            _ReminderCard(reminder: reminder, now: now),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days, required this.grouped});

  final List<DateTime> days;
  final Map<DateTime, List<ExpectedWateringTime>> grouped;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final day in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: grouped.containsKey(day)
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      _weekdays[day.weekday - 1],
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text('${day.day}'),
                    const SizedBox(height: 4),
                    CircleAvatar(
                      radius: 9,
                      child: Text(
                        '${grouped[day]?.length ?? 0}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DateHeading extends StatelessWidget {
  const _DateHeading({required this.date, required this.today});

  final DateTime date;
  final DateTime today;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final label = date == today
        ? 'Today'
        : '${_months[date.month - 1]} ${date.day}';
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder, required this.now});

  final ExpectedWateringTime reminder;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final isDue = !reminder.scheduledDateTime.isAfter(now);
    final time = reminder.scheduledDateTime;
    final timeLabel = isDue
        ? 'Needs attention'
        : '${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')}';
    return Card(
      elevation: 0,
      color: reminder.plant.color.withAlpha(35),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: reminder.plant.color,
          child: const Icon(Icons.water_drop_outlined),
        ),
        title: Text(reminder.plant.name),
        subtitle: Text('${reminder.plant.waterLevel}% water remaining'),
        trailing: Text(timeLabel),
      ),
    );
  }
}
