# Architecture

`simple_water_tracker` is a Flutter application for tracking plant watering,
optionally attaching a photo, and delivering watering reminders on
supported platforms. This document is a navigation map; implementation details
belong with the domain that owns them.

## Entry points and composition

`lib/main.dart` bootstraps Flutter, loads persisted settings, and initializes
the Android notification/timezone integration before creating the app.
`lib/src/app.dart` owns the shared `PlantService` and `ReminderCoordinator`,
exposes plant state with Provider, and defines the named-route shell.

The main user surfaces are the plant list, full-screen editor, watering schedule,
camera capture, and settings. They live in `lib/src/basic_feature/`, `camera/`,
and `settings/`. Paths below are relative to `lib/src/` unless noted.

## Plant domain and persistence

`basic_feature/plant_data.dart` defines the persisted plant model, watering
history, water-level calculation, and the derived time at which a plant needs
watering. JSON support is generated from its annotations.

`services/plant_service.dart` is the in-memory source of truth for the plant
collection. It loads and saves the collection through `shared_preferences`,
notifies the UI after mutations, and maintains the derived watering schedule.
Creation, edits, watering, undo, and removal enter through this service.
Photo persistence differs between creation and editing; see below.

For changes to watering math, start in
`services/watering_reminder_calculator.dart`. The schedule view consumes the
same derived schedule; it does not calculate reminder dates independently.
The coordinator also asks `PlantService` to refresh derived state before
reconciliation; calculation is not currently a read-only operation.

## Reminders and notifications

The app calculates reminders at startup and after plant saves, then lets the
OS deliver them. There is no periodic Dart background worker, and returning
from the background does not generally trigger recalculation. The notification
settings section rechecks OS permission on return; newly enabled delivery
reconciles reminders. Unchanged permission checks do not move delivery times.

The flow is `PlantService` → `ReminderCoordinator` → `NotificationService`
(all under `services/`). Plant state determines when watering is due;
`reminder_delivery_policy.dart` adds an overdue grace period and one retry.
The notification service handles timezone setup and OS delivery.
`services/android_notification_permissions.dart` handles Android app permission
and watering-channel status. Requests use the existing permission-handler plugin;
UI-only navigation to Android notification settings uses a small channel in
`MainActivity`. Headless package recovery only reads delivery status through the
notification plugin and does not depend on an Activity. Unsupported platforms
report notifications unavailable; future iOS authorization needs its own policy.

Each plant has stable notification IDs for its initial reminder and retry.
Startup updates pending slots while preserving already-visible alerts. Saving
changes replaces that plant's slots and clears outdated alerts; removal cancels
them. Dismissing an alert never marks a plant watered. Stable IDs avoid creating
new slots on each calculation. The coordinator serializes startup, plant changes,
and permission-triggered reconciliation, reading current plant state when queued
work runs. Both permission entry points await pending-slot reconciliation without
clearing visible alerts. Recalculating overdue reminders can still move delivery
times.

Android package updates can remove an alert before the user sees it. This is
the exception requiring brief background Dart work: `NotificationRecoveryReceiver`
starts a temporary headless engine and calls
`services/package_replacement_recovery.dart` through `notificationRecoveryMain`
in `lib/main.dart`. It rebuilds reminders from saved plant state using the same
coordinator, then shuts down. This receiver exclusively owns package-replacement
recovery; the notification plugin's receiver restores cached alarms only after
device boot. This prevents two update receivers from racing while keeping plant
state authoritative. The short-lived test notification is not restored across
an app update. Keep recovery independent of an Activity and within the broadcast
execution window.

Delivery is currently Android-only; web can still show the watering schedule.
Domain times stay in UTC, with local-time conversion for display and OS
scheduling. The schedule screen's test notification stays separate from plant
reminder slots.

## Camera and pictures

`camera/take_picture_screen.dart` owns camera permission, controller lifecycle,
preview, and capture UI for new plants. `basic_feature/plant_editor_screen.dart`
owns an unsaved draft and selects camera/gallery photos through
`services/plant_photo_picker.dart`. `app.dart` recovers interrupted Android
photo picks and opens the editor with the recovered draft.

The camera screen and editor pass photo bytes to `PlantService`, which owns
storage, plant persistence, and releasing replaced or removed files. Storage
writes images atomically in the application documents directory.
`basic_feature/plant_tile.dart` shares photo rendering and water/undo actions
between rows and grid cards; the editor has its own preview.

## Settings, localization, and platforms

`settings/` separates the UI controller from preference-backed storage; it
owns theme and row/grid preferences. `settings/notification_settings.dart` shows
OS-owned notification status, offers permission requests or Android settings,
and sends permission transitions through the reminder coordinator. It keeps
permission errors separate from reminder scheduling errors. Localization ARB sources and generated classes are under
`localization/`.

`android/` contains permissions, notification receivers, and Android build
settings. `web/` is the web host shell. Keep platform delivery policy out of
the plant domain so the app remains usable where platform notification support
is unavailable.

## Tests and investigations

Focused domain tests live in `test/` for watering math, delivery policy, plant
data, and picture storage; widget tests cover visible states and interactions.
See [AGENTS.md](AGENTS.md) for validation scope and generation commands.

`observability/app_observability.dart` provides debug/profile logs and timeline
spans; startup names use `startup.`. Logs must contain technical metadata only,
never plant names, picture paths, or other user data. Release logging is disabled.

- [Startup measurements and diagnostics](docs/startup_observability.md):
  measured tradeoffs and `tool/measure_android_startup.sh` usage.
