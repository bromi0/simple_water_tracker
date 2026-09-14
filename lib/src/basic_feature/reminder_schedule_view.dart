import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/reminder_coordinator.dart';
import '../services/plant_service.dart';
import '../settings/settings_controller.dart';
import 'watering_status_presentation.dart';
import '../localization/app_localizations.dart';

class ReminderScheduleView extends StatelessWidget {
  const ReminderScheduleView({super.key});

  static const routeName = '/watering-schedule';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wateringWeek),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: l10n.testNotificationTooltip,
            onPressed: () => _scheduleTest(context),
          ),
        ],
      ),
      body: Consumer<PlantService>(
        builder: (context, store, child) {
          if (store.wateringSchedule.isEmpty) {
            return Center(child: Text(l10n.noReminders));
          }
          return _ReminderCalendar(
            reminders: store.wateringSchedule,
            presentation: context
                .watch<SettingsController>()
                .wateringStatusPresentation,
          );
        },
      ),
    );
  }

  Future<void> _scheduleTest(BuildContext context) async {
    bool? scheduled;
    try {
      scheduled = await context
          .read<ReminderCoordinator>()
          .scheduleTestNotification();
    } catch (_) {
      // Resolve the message after the await so it uses the current locale.
    }
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final message = switch (scheduled) {
      true => l10n.testReminderScheduled,
      false => l10n.notificationsOff,
      null => l10n.testReminderFailed,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReminderCalendar extends StatelessWidget {
  const _ReminderCalendar({
    required this.reminders,
    required this.presentation,
  });

  final List<ExpectedWateringTime> reminders;
  final WateringStatusPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final days = List.generate(7, (index) => today.add(Duration(days: index)));
    final grouped = <DateTime, List<ExpectedWateringTime>>{};
    for (final reminder in reminders) {
      var day = _dateOnly(reminder.scheduledDateTime.toLocal());
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
            _ReminderCard(
              reminder: reminder,
              now: now,
              presentation: presentation,
            ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                      DateFormat.E(l10n.localeName).format(day),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(DateFormat.d(l10n.localeName).format(day)),
                    const SizedBox(height: 4),
                    CircleAvatar(
                      radius: 9,
                      child: Text(
                        l10n.visibleCount(grouped[day]?.length ?? 0),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = date == today
        ? l10n.today
        : DateFormat.MMMMd(l10n.localeName).format(date);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.now,
    required this.presentation,
  });

  final ExpectedWateringTime reminder;
  final DateTime now;
  final WateringStatusPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = PlantWateringStatus.forPlant(
      reminder.plant,
      estimatedWateringTime: reminder.scheduledDateTime,
      now: now,
    );
    final time = reminder.scheduledDateTime.toLocal();
    final timeLabel = status.state == PlantWateringState.needsWater
        ? l10n.waterNow
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(time),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          );
    final theme = Theme.of(context);
    final statusColor = status.colorFor(theme);
    return Card(
      elevation: 0,
      color: statusColor.withAlpha(28),
      child: Semantics(
        label: l10n.namedWateringStatus(
          reminder.plant.name,
          status.semanticsLabel(l10n, presentation, now: now),
        ),
        child: ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Long translations and large text need the full line width.
              final stackDetail =
                  constraints.maxWidth < 400 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              final detail =
                  presentation == WateringStatusPresentation.informative
                  ? status.informativeLabel(l10n, now: now)
                  : timeLabel;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: statusColor,
                  foregroundColor:
                      ThemeData.estimateBrightnessForColor(statusColor) ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  child: const Icon(Icons.water_drop_outlined),
                ),
                title: Text(reminder.plant.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.simpleLabel(l10n),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (stackDetail) Text(detail),
                  ],
                ),
                trailing: stackDetail ? null : Text(detail),
              );
            },
          ),
        ),
      ),
    );
  }
}
