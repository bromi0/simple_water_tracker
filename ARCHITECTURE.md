# Architecture

`simple_water_tracker` is a Flutter application for tracking plant watering,
optionally attaching a camera photo, and delivering watering reminders on
supported platforms. This document is a navigation map; implementation details
belong with the domain that owns them.

## Entry points and composition

`lib/main.dart` bootstraps Flutter, loads persisted settings, and initializes
the Android notification/timezone integration before creating the app.
`lib/src/app.dart` owns the shared `PlantService` and `ReminderCoordinator`,
exposes plant state with Provider, and defines the named-route shell.

The main user surfaces are the plant list, watering schedule, camera capture,
and settings. They live in `lib/src/basic_feature/`, `camera/`, and `settings/`;
widgets read or mutate shared state rather than performing persistence or OS
work themselves.

## Plant domain and persistence

`basic_feature/plant_data.dart` defines the persisted plant model, watering
history, water-level calculation, and the derived time at which a plant needs
watering. JSON support is generated from its annotations.

`services/plant_service.dart` is the in-memory source of truth for the plant
collection. It loads and saves the collection through `shared_preferences`,
notifies the UI after mutations, and maintains the derived watering schedule.
Plant edits, watering, undo, removal, and photo attachment all enter through
this service.

For changes to watering math, start in
`services/watering_reminder_calculator.dart`. The schedule view consumes the
same derived schedule; it does not calculate reminder dates independently.

## Reminders and notifications

Reminder calculation and notification delivery are deliberately separate:

1. `PlantService` derives each plant's reminder time from plant state.
2. `ReminderCoordinator` observes plant changes and app lifecycle. On entering
   the background it applies `ReminderDeliveryPolicy` (exit grace and overdue
   retry cooldown) to derive delivery candidates.
3. `NotificationService` owns the OS boundary: permission checks, scheduling,
   cancellation, and persistence of scheduled notification IDs.
4. Returning to the foreground cancels watering notifications. Dismissing a
   notification never changes plant state. The schedule screen's short-delay
   test notification is intentionally outside the watering-reminder set.

`reminder_delivery_policy.dart` is the extension point for quiet hours,
morning delivery, or grouping. Lifecycle and stale-notification safeguards are
in `reminder_coordinator.dart`; platform-specific notification setup is in
`notification_service.dart` and Android manifest/build configuration.

Timezone initialization happens before scheduling. Notification delivery is
currently Android-only in application code; web continues to show the schedule
but deliberately does not request or deliver local notifications.

## Camera and pictures

`camera/take_picture_screen.dart` owns camera permission, controller lifecycle,
preview, and capture UI. It hands captured bytes to
`services/plant_picture_storage.dart`, which atomically stores the final image
in the application documents directory. The resulting path is attached to the
plant through `PlantService`.

## Settings, localization, and platforms

`settings/` separates the UI controller from preference-backed storage; it
currently owns the theme preference and notification-permission actions.
Localization sources are under `localization/`; edit ARB inputs and regenerate
instead of editing generated localization files.

`android/` contains permissions, notification receivers, and Android build
settings. `web/` is the web host shell. Keep platform delivery policy out of
the plant domain so the app remains usable where platform notification support
is unavailable.

## Tests and generated code

Focused domain tests live in `test/` for watering math, delivery policy, plant
data, and picture storage; widget tests cover visible states and interactions.
Files ending in `.g.dart` and generated localization classes are outputs: edit
their source annotations or ARB files, then regenerate with the documented
tooling.
