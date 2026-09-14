# Localization implementation plan

English is the fallback locale; Russian is the first additional locale. Settings
offers System default, English, and Russian with a persisted override.
Keep Flutter's generated AppLocalizations API and
the existing ARB directory. Saved plant and room names remain user-owned text.
Random name suggestions must be complete grammatical phrases in each locale,
not independently translated adjective and noun fragments.

## Milestone 1: English foundation

- Extract application UI copy, accessibility labels, and dynamic watering copy
  into the English ARB; use generated delegates and supported locales.
- Replace English date arrays and plural concatenation with locale-aware output.
- Keep errors as stable reasons where they survive widget rebuilds.
- Move random suggestions to complete localized names.
- Validate with analysis, tests, and a debug APK; pause for device review.

## Milestone 2: Russian UI

- Add reviewed Russian messages and grammatically complete name suggestions.
- Verify English fallback, Russian plural rules, system locale switching,
  retained drafts/names, semantics, and narrow/large-text layouts.
- Fix only layout constraints exposed by translations.
- Build a debug APK and pause for Russian device review.

## Milestone 3: Notification localization

- Load generated messages for normal startup and headless package recovery,
  using the saved language override when present.
- Translate reminder/test copy and channel metadata without changing stable IDs.
- Refresh future pending text on locale changes without moving delivery times,
  clearing visible alerts, or changing permission/retry behavior.
- Retain cached notification language while the app cannot execute Dart.
- Validate lifecycle and scheduling invariants, build, and pause for device review.

No toolchain migrations, broad UI redesign,
automatic renaming of persisted names, or changes to watering mathematics.
No commits or publication without an explicit request.

## Progress

- Plan recorded; implementation branch: `feat/flutter-localization`.
- Milestone 1 passed analysis and all 72 tests; debug APK built successfully.
  User requested continuing directly into the Russian milestone.
- Milestone 2 completed: Russian ARB and generated code, plural/draft/semantics
  tests, and focused wrapping/scrolling fixes for schedule, rooms, settings,
  and camera. Analysis and all 84 tests pass. The debug APK was installed on
  the connected physical device without clearing app data.
- Device review pending. Use Settings → Language to select Russian directly
  in the app. Check camera capture/preview,
  room creation with keyboard visible, both plant layouts, and the schedule.
- Milestone 3 completed: reminder and test notification titles/bodies plus
  Android channel metadata use generated messages. Foreground scheduling reads
  the active Settings language; headless package-replacement recovery reads the
  persisted override. Existing OS-scheduled alerts retain their rendered copy
  until normal reminder reconciliation replaces them. Existing demo plant names
  and legacy `Unknown` names remain unchanged; they are not automatically
  rewritten as translations.
- Added a simple Settings language selector at the user's request. The choice
  switches the UI immediately and persists as a nullable language tag in the
  existing settings JSON. Focused persistence/switching tests passed; settings
  JSON and localization Dart files were regenerated.
- Build warnings: the existing `flutter_timezone` plugin uses legacy KGP, and
  installed Android tools report an SDK XML version mismatch. Both debug builds
  succeeded; no toolchain or permission configuration was changed.
