# Startup performance and observability

## 2026-08-27 baseline

Measurements used a Xiaomi 2112123AG running Android 13 (API 33), connected
over wireless ADB, with Flutter 3.47.1 and an app version 1.0.1+4 profile APK.
The recorded state is a force-stopped process with warmed device/filesystem
caches; it is not a reboot-level cold start.

Before application changes, 10 launches produced:

- ActivityManager `TotalTime`: 1,466 ms median, 1,440–1,514 ms range.
- ActivityManager `WaitTime`: 1,475 ms median, 1,451–1,524 ms range.
- A Flutter startup trace reported 943 ms to first frame: 164 ms to framework
  initialization and another 780 ms before the first frame.

Temporary phase instrumentation was then made permanent through
`AppPerformance`. Across 10 stabilized launches, the device-timezone platform
call took 135 ms median and Dart `main` to first frame took 165 ms median. The
first launch immediately after APK installation was a meaningful cold outlier:
the first platform-plugin call took about 0.8–0.9 seconds. That cost appeared as
timezone lookup when notifications ran first and as preference loading when
settings ran first, so it is plugin/platform-channel readiness rather than the
timezone calculation itself. In stabilized runs, settings preference load was
5 ms or less and theme application was below 1 ms. Reminder reconciliation
completed after the first frame (483 ms median) and therefore did not delay
initial display.

A controlled A/B installed both the original and instrumented APKs after forced
ART `speed` compilation. Original startup measured 1,373 ms median
`TotalTime`; moving notification setup behind `runApp` measured 1,397 ms. The
reordering was therefore not retained: it did not improve end-to-end startup,
and keeping notification initialization before the UI preserves the simpler
existing failure and scheduling semantics.

The final instrumented build, with the original ordering restored, measured
1,307 ms median `TotalTime` in a later 10-run series. Treat this as a healthy
device result rather than a claimed optimization: the lower number after more
launches demonstrates why APK order and evolving device caches must be reported.

## Follow-up attribution

Repeated replacement-install tests wait five seconds for package-replacement
recovery, force-stop the package, and then launch the foreground activity. A
subsequent cold launch always force-stops the process without reinstalling.
Five first-after-install samples and 10 steady samples produced these medians:

| Build mode | First after install | Steady cold process |
| --- | ---: | ---: |
| Profile | 1,443 ms | 890 ms |
| Release | 967 ms | 408 ms |

The release APK used local debug signing solely because this checkout has no
release keystore. It otherwise used release AOT and shrinking. Release resource
shrinking initially removed the dynamically referenced notification icon,
causing notification setup to throw before `runApp`; `res/raw/keep.xml` now
keeps that resource.

An expensive profile launch traced with Android's `dalvik`, scheduling, Binder,
disk, activity, window, and graphics categories showed that the profile APK was
running directly from 16 dex files totaling 21.88 MB. Startup included 16 dex
extractions (about 122 ms inclusive), 15 dex verifications (about 56 ms), and
roughly 1,044 baseline JIT compilations (about 225 ms). The equivalent release
APK contains two dex files totaling 2.46 MB; its trace showed no dex extraction
or verification and only eight JIT compilations.

The timezone plugin itself performs a small `ZoneId.systemDefault` lookup and
returns a localized name. Earlier ordering experiments made the long wait move
to `shared_preferences` when that was the first plugin called. Together with
the system traces, this shows that the first awaited platform call is a
synchronization point behind common Android runtime, class-loading, and plugin
registration work; the work is not specific to timezone or MethodChannel
serialization.

The release build already merges AndroidX baseline profile rules (745 source
rules, 115 after R8) and packages the compiled profile. More importantly, the
release trace has negligible ART compilation work and steady cold startup is
about 408 ms. A project-specific Baseline or Startup Profile would add build and
benchmark maintenance while targeting little of the remaining native Flutter,
graphics, and filesystem-cache cost, so it is not warranted for this app.

## Repeatable Android measurement

Build and install a profile APK, keep the test device awake and unlocked, and
avoid changing its power or thermal state during a comparison:

```sh
flutter build apk --profile
adb install -r build/app/outputs/flutter-apk/app-profile.apk
tool/measure_android_startup.sh
```

Set `ADB_SERIAL` when more than one device is attached and `RUNS` to change the
sample count. Compare medians from at least 10 runs, keep the same device and
build mode, and report the range or p90 so a single fast run cannot hide
variance. Installing a new APK can expose one-off plugin/service costs, so
record that first launch separately from the script's stabilized launches. The
app's `MY_PACKAGE_REPLACED` receiver starts a headless Flutter engine after an
update; allow it to complete or use the same fixed settling interval before
every first-after-install measurement.

For a Flutter timeline trace:

```sh
flutter run --profile --trace-startup -d <device-id> \
  --use-application-binary=build/app/outputs/flutter-apk/app-profile.apk
```

This writes `build/start_up_info.json` and `build/start_up_timeline.json`.

## Reading application diagnostics

Structured logs are enabled in debug/profile builds and mirrored to logcat:

```sh
adb logcat -v brief | rg '\[simple_water_tracker\]'
```

Each performance record has an `operation`, `elapsed_ms`, and completion or
failure event. The same operations are timeline spans in DevTools. Keep names
stable and hierarchical (startup operations begin with `startup.`), instrument
coarse asynchronous boundaries rather than individual functions, and never log
plant names, picture paths, preference values, or other user data.
