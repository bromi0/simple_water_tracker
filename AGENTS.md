# Repository Guidelines

Read [ARCHITECTURE.md](ARCHITECTURE.md) for ownership and control flows before
cross-cutting changes. Read its linked investigation notes only when relevant.

## Working rules

- Inspect `git status` and relevant diffs before editing. Preserve unrelated
  user work and avoid broad reformatting.
- Prefer the smallest coherent change and existing project patterns.
- Treat dependency and toolchain changes as migrations. Inspect configuration
  and explain the compatibility reason before changing Flutter, Dart, Gradle,
  AGP, Kotlin, Android SDK/NDK, or Java versions. Do not run `flutter upgrade`
  or switch channels.
- Do not run broad `flutter pub upgrade` or `flutter pub upgrade
  --major-versions` unless dependency maintenance is explicitly requested.
- After a successful `flutter pub get`, use `flutter analyze --no-pub` and
  `flutter test --no-pub` for repeated validation. Use a normal `flutter build`
  after version changes so Android's generated version values are refreshed.
- Keep builds resource-conscious: prefer lower peak memory and limited
  parallelism over speed.
- Diagnose failed commands before changing configuration or adding workarounds.
  Prefer standard Flutter, Dart, Gradle, and Android tooling.
- Do not hand-edit generated JSON or localization files. Change annotations or
  ARB sources, regenerate with
  `dart run build_runner build --delete-conflicting-outputs` or
  `flutter gen-l10n`, and review generated diffs.
- Format changed Dart files with `dart format <paths>`. Add concise comments for
  non-obvious decisions and invariants, not restatements of code.
- Do not commit, push, merge, publish, deploy, or modify credentials unless
  explicitly requested.

## Validation

Choose checks by the changed area; do not repeat broad checks after every edit.
Keep command output and agent context proportionate too: run focused tests while
iterating, and reserve a full suite for a completed milestone, before a commit,
or when a cross-cutting change makes focused coverage insufficient. Summarize
successful test counts rather than replaying full output. A full run is useful
as a release gate, but repeating it for each small follow-up consumes time and
context without adding meaningful confidence.

- Documentation-only: check references and review the diff.
- Small/local edit: run directly affected checks or tests, for example
  `flutter test test/plant_data_test.dart` for a plant-model change.
- Coherent feature change: run `flutter analyze` and affected tests. Add focused
  behavioral regression tests where needed.
- Milestone/pre-commit: run `flutter analyze` and the full `flutter test` suite.
- Build/device/profile checks: only when relevant. Android/toolchain changes
  need an appropriate Android build; camera, permission, and notification
  changes may need device checks. Performance changes may need profile
  measurements; release resource changes need a release build check.

At handoff, summarize files changed and why, checks run and results, and any
unresolved failures or follow-up work. Note generated files and permission or
platform configuration changes explicitly.

## Android device testing

Check `adb devices` / `flutter devices` before device-dependent testing; a
physical device may be available through the Linux ADB installation.

For relevant testing, agents may install debug/profile builds, inspect logcat,
launch/force-stop the app, and perform device-side diagnostics. Do not change
device-wide settings, remove unrelated applications, erase data, or modify ADB
pairing/debug authorization unless explicitly requested.
