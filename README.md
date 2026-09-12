# Simply Water Plant

A small Flutter app (`simple_water_tracker`) for tracking plant watering,
attaching photos, and viewing a watering schedule. Local notification delivery
is currently Android-only.

## Development

Use the SDK constraints in [pubspec.yaml](pubspec.yaml). Run `flutter pub get`
to install dependencies, then `flutter run` with a connected device or emulator.

- [AGENTS.md](AGENTS.md): working rules, proportional validation, and device
  testing boundaries.
- [ARCHITECTURE.md](ARCHITECTURE.md): entry points, state ownership, reminder
  behavior, and links to focused investigation notes.
