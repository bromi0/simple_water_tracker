# Android keyboard transition investigation

Measured on 2026-09-12 using the connected Xiaomi 2112123AG, Android 13/API 33,
Gboard, and the device's existing 60 Hz display mode (16.67 ms frame budget).
Flutter 3.47.1, revision `6655482ec0`; AOT profile builds, existing plant data,
including photos. No device settings, plant data, dependencies, or toolchain
versions were changed. The original grid preference was restored.

## Finding and change

There is a confirmed application-side contributor, not evidence of a general
Flutter keyboard bug. The main `Scaffold` resized its body for every animated
keyboard inset. That changed `PlantList`'s `LayoutBuilder` constraints even
though its row/grid decision only depends on width. The builder recreated the
list/grid and visible plant widgets behind the modal editor.

Set `resizeToAvoidBottomInset: false` only on `PlantListView`. All main-screen
text editing lives in a separate modal route, whose existing
`MediaQuery.viewInsetsOf(context)` padding still moves the editor above the
keyboard. No new animation, delay, focus policy, or screen redesign was added.
The add-plant screen still resizes normally.

This removes substantial unnecessary UI work. It does not eliminate every
slow frame, and should not be described as a complete keyboard-animation fix.

## Reproduction and measurement

1. Run `flutter run --profile -d 192.168.13.107:38725` on the connected device.
2. In grid view, tap the first plant's body to open its editor. The name field
   autofocuses and opens Gboard while the modal route is entering.
3. Hide the keyboard, leaving the editor open. Tap its name field to reopen
   the keyboard. Hide it again, then dismiss the sheet without saving.
4. Repeat three times, then repeat in row view. Each measured batch has three
   editor openings, three keyboard-only reopenings, and six keyboard hidings.
5. Compare with six show/hide cycles on the add-plant name field after the
   camera has initialized. Also check the overflow menu's **Edit plant** path
   and taps on the interval label and plus/minus buttons.

The device rejects `adb shell input tap` with `INJECT_EVENTS` permission errors.
A temporary alternate Dart entry point therefore delivered pointer down/up
through Flutter's gesture binding, used `TextInput.hide` to hide Gboard without
popping the route, and `handlePopRoute` to dismiss the sheet. Actual Android IME
and inset animation remained active. This does not measure Android touch
injection latency or the physical Back-button input path. No security settings
were changed. The harness was removed and the normal profile entry point was
reinstalled after testing.

Measurements used `WidgetsBinding.addTimingsCallback` for UI/build, raster,
vsync overhead and total span; `WidgetsBindingObserver.didChangeMetrics` for
physical keyboard insets; Dart VM timelines; and Android Perfetto traces with
SurfaceFlinger FrameTimeline plus gfx/view/wm/input and scheduler events.
Actions were separated by approximately 1.2 seconds. The editor was warmed
before the main grid/profile comparisons. Startup was excluded. Screen capture
was not running during timing batches.

Separate diagnostic runs enabled `ext.flutter.profileWidgetBuilds` and
`ext.flutter.profileRenderObjectLayouts`; these heavier runs were excluded
from the timing table. The baseline VM timeline ring retained only the end of
the batch: its surviving last-reopen segment contained five `GridView` builds
and 32 `PlantTile`/`PlantPhoto` builds. The after-fix last reopening contained
zero of those builds across the full transition. The editor itself still
rebuilds for its necessary inset padding.

## Results

These are small device samples, not guaranteed upper bounds. Counts include
rendered frames during the action windows, including route and cursor frames.
UI and raster phases are separately budgeted; a total span over 16.67 ms alone
is not proof of a missed presentation deadline.

| Scenario | Frames | UI p95 / max, ms | Raster p95 / max, ms | UI / raster phases >16.67 ms |
| --- | ---: | ---: | ---: | ---: |
| Grid, before | 324 | 8.08 / 17.02 | 7.55 / 22.90 | 1 / 1 |
| Grid, after | 347 | 4.19 / 18.15 | 8.07 / 22.87 | 1 / 2 |
| Rows, before | 345 | 7.77 / 21.54 | 5.72 / 19.76 | 2 / 1 |
| Rows, after | 319 | 4.32 / 19.84 | 5.67 / 9.58 | 2 / 0 |
| Add-plant name, control | 590 | 4.54 / 5.71 | 4.16 / 6.08 | 0 / 0 |

UI p95 fell approximately 48% in grid and 44% in rows. There is no consistent
improvement in grid raster maxima; do not infer that all jank disappeared.
The camera control also emits texture frames between actions, so its frame
count is not directly comparable with the editor batches.

For keyboard-only transitions (already-open editor), considering frames in
the first 700 ms after each action:

| Grid transition | UI p95 before → after, ms | Raster max before → after, ms |
| --- | ---: | ---: |
| Reopen keyboard | 7.71 → 3.84 | 7.25 → 7.44 |
| Hide keyboard | 9.92 → 4.02 | 11.96 → 6.26 |

Neither phase exceeded 16.67 ms in these keyboard-only grid or row samples,
before or after. The budget overruns were concentrated in the combined
editor-opening/keyboard transition. After the change, remaining slow UI frames
started roughly 56–61 ms after the injected tap, before IME inset motion
started. Grid raster outliers occurred about 97 ms and 459 ms after one opening;
the latter was near the keyboard animation's end. Their exact GPU/driver cause
was not isolated, so they cannot all be assigned to Android or declared outside
application control.

Android FrameTimeline also flagged actual presentation irregularities. In the
row trace, app-window `Buffer Stuffing` flags went from 17 to zero, and IME
`SurfaceFlinger Scheduling` flags from 17 to zero; the after-grid trace had one
IME scheduling flag. IME `App Deadline Missed` flags remained (8 in after-rows,
12 in after-grid, and 12 in the add-plant control). These layer events are not
Flutter frame counts, and the app-window layer is not a complete accounting
of Flutter's rendered surface. Early baseline traces used a smaller ring
buffer; some traces report one or two dropped negative-timestamp events.
Treat the native counts as supporting diagnostic evidence rather than a
precise before/after jank-rate estimate.

## Attribution and remaining behavior

- **Our layout/rebuild work:** confirmed, unnecessary, and substantially
  reduced by the one-property fix. Both main-screen layouts were affected.
- **Flutter reacting to insets:** expected and necessary in the editor.
  Insets generally arrived every 16–17 ms, occasionally with a longer gap.
  No additional `AnimatedPadding`, `AnimatedSize`, repeated focus requests,
  or explicit scrolling animation exists in this editor. Its scroll view is
  needed to keep the form usable in constrained space.
- **Focus and overlapping motion:** autofocus starts as the sheet opens.
  There is one initialization-time selection callback, not a per-inset focus
  loop. Sheet entrance and keyboard growth can overlap, changing the moving
  sheet's height. Reopening the keyboard in an already-open sheet separates
  this from route construction. The remaining initial UI spikes and combined
  motion were not addressed by changing autofocus or redesigning the editor.
- **Android/IME:** Gboard's own content still misses deadlines in the control
  case where Flutter is comfortably below budget. The inset curve is also
  asymmetric: opening grows from 0 to 701 physical pixels over roughly 260 ms
  of nonzero motion; hiding usually reaches zero in about 115–130 ms of motion,
  while callbacks continue until approximately 330 ms after the hide request.
  Thus rapid-looking disappearance need not indicate expensive Flutter layout.
  OS keyboard content rendering and its animation curve are outside this
  widget's direct control; this experiment does not prove a Flutter engine bug.
- **Other work:** no plant-service mutation, persistence, reminder scheduling,
  image reattachment, or application-level per-frame focus handler runs merely
  because the keyboard changes. The editor listens to its provider and calls
  `setState` on text changes, but those do not explain keyboard-only transitions.

The overflow **Edit plant** path uses the same editor and showed the same inset
sequence. In this checkout there is only one text field in that editor:
watering interval is a label with plus/minus controls, not a numeric text input.
Tapping those controls after hiding the keyboard produced no new inset events.
Unsaved test edits were discarded. If another screen/version exposes numeric
text fields, that path still needs a separate reproduction.

## Validation and artifacts

- `dart format lib/src/basic_feature/plant_list_view.dart test/plant_list_view_test.dart`
- `flutter test test/plant_list_view_test.dart`: 2 passed.
- `flutter test`: 23 passed.
- `flutter analyze`: no issues found.
- Profile APK builds and device installs before and after the change.

`test/plant_list_view_test.dart` checks both layouts across increasing and
shrinking keyboard insets: collection viewport stays fixed, Save stays above
the keyboard, draft text survives, and no layout exception occurs.

Raw local evidence and capture/analysis scripts are under `/tmp/water-jank/`
(`baseline-*`, `after-*`, `detailed-*`, `*-samples.json`, and `.perfetto-trace`).
The temporary `keyboard_probe.dart` is retained there for reproducing the
instrumentation, but is not part of the application. These temporary artifacts
are not tracked and may be removed by system cleanup.
