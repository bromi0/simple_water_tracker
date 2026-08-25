# Repository Guidelines

## Project Structure & Module Organization

Application entry points are `lib/main.dart` and `lib/src/app.dart`. Feature code lives under `lib/src/`: `basic_feature/` contains plant list models and widgets, `camera/` handles photo capture, `services/` contains persistence and notification logic, `settings/` manages user preferences, and `localization/` contains ARB sources and generated localization classes. Tests live in `test/` and follow Flutter's unit and widget test patterns. Static images belong in `assets/images/`; declare new asset directories in `pubspec.yaml`. Platform-specific Android and web files are in `android/` and `web/`.

## Build, Test, and Development Commands

- `flutter pub get` installs dependencies from `pubspec.yaml`.
- `flutter run` launches the app on a selected connected device or emulator; use `flutter run -d chrome` for web.
- `flutter analyze` runs the analyzer and the rules inherited from `flutter_lints`.
- `flutter test` runs all unit and widget tests; pass a path such as `flutter test test/widget_test.dart` for one file.
- `dart format lib test` formats Dart sources and tests.
- `dart run build_runner build --delete-conflicting-outputs` regenerates JSON serialization files such as `*.g.dart` after annotated models change.
- `flutter build apk` or `flutter build web` creates release artifacts for supported targets.

## Coding Style & Naming Conventions

Use Dart's standard two-space indentation and accept `dart format` output. Name files and libraries in `snake_case`, types in `UpperCamelCase`, and variables or methods in `lowerCamelCase`. Prefer small widgets, `const` constructors where possible, and feature-local code over adding unrelated logic to `main.dart`. Do not hand-edit generated `*.g.dart` or localization output; update the source annotations or `app_en.arb` and regenerate instead.

## Testing Guidelines

Use `flutter_test`. Keep test files named `*_test.dart`, group related behavior with `group`, and write expectations in behavior-focused terms such as `should display a string of text`. Add unit tests for services and helpers, and widget tests for visible states and user interactions. Run `flutter analyze` and `flutter test` before submitting changes. No coverage threshold is currently enforced; new behavior should still include focused regression tests.

## Commit & Pull Request Guidelines

Recent history favors brief, imperative summaries such as `clean up` and `regenerate platforms`. Keep commits focused and use a concise subject that states the change; add context in the body when platform or migration details matter. Pull requests should explain the user-visible impact, list verification commands, link relevant issues, and include screenshots or recordings for UI changes. Note any generated files, permission changes, or notification/platform configuration updates explicitly.

## Agent Working Guidelines

Preserve pre-existing work. Before making changes, inspect `git status` and relevant diffs so unrelated user changes are not overwritten, reverted, or reformatted.

Prefer the smallest coherent change that solves the task. Follow existing project patterns unless the task specifically requires an architectural change.

Treat dependency and toolchain changes as migrations rather than routine cleanup. Before changing Flutter, Dart, Gradle, AGP, Kotlin, Android SDK/NDK versions, or Java compatibility, inspect the current configuration and explain the compatibility reason for each required change. Do not run `flutter upgrade` or switch Flutter channels.

Keep project build configuration resource-conscious so development remains reliable in constrained environments. Prefer lower peak memory usage and limited parallelism over faster builds when the two conflict.

Do not hand-edit generated files. Change their source inputs and regenerate them with the project's normal tooling. Review generated diffs before keeping them.

When a command fails, diagnose the failure before changing configuration or adding workarounds. Prefer standard Flutter, Dart, Gradle, and Android tooling over project-specific wrappers or environment hacks unless a concrete issue requires one.

Validate changes at the narrowest useful scope first, then run broader checks appropriate to the change. For Dart or Flutter source changes, this normally includes formatting, `flutter analyze`, and relevant tests. For Android or toolchain changes, also perform an appropriate Android build.

Do not commit, push, merge, publish, deploy, or modify credentials unless the task explicitly requests it.

At the end of a task, summarize:
- files changed and why;
- validation commands run and their results;
- any unresolved failures, risks, or follow-up work.
