#!/usr/bin/env bash

set -euo pipefail

runs="${RUNS:-10}"
package_name="${PACKAGE_NAME:-com.bromiapps.simplywaterplant}"
activity_name="${ACTIVITY_NAME:-com.example.simple_water_tracker.MainActivity}"
component_name="${package_name}/${activity_name}"
adb_args=()
if [[ -n "${ADB_SERIAL:-}" ]]; then
  adb_args=(-s "$ADB_SERIAL")
fi

if ! [[ "$runs" =~ ^[1-9][0-9]*$ ]]; then
  echo "RUNS must be a positive integer" >&2
  exit 2
fi

results_file="$(mktemp)"
trap 'rm -f "$results_file"' EXIT

adb "${adb_args[@]}" get-state >/dev/null

# Prime Android and filesystem caches once. Each recorded launch still starts
# from a force-stopped process, which is the repeatable state this script names.
adb "${adb_args[@]}" shell am force-stop "$package_name"
adb "${adb_args[@]}" shell am start -W -n "$component_name" >/dev/null
sleep 1

printf "run\tlaunch_state\ttotal_ms\twait_ms\n"
for run_number in $(seq 1 "$runs"); do
  adb "${adb_args[@]}" shell am force-stop "$package_name"
  sleep 0.5
  launch_output="$(
    adb "${adb_args[@]}" shell am start -W -n "$component_name"
  )"
  launch_state="$(awk '/LaunchState:/ {print $2}' <<<"$launch_output")"
  total_time="$(awk '/TotalTime:/ {print $2}' <<<"$launch_output")"
  wait_time="$(awk '/WaitTime:/ {print $2}' <<<"$launch_output")"
  printf "%s\t%s\t%s\t%s\n" \
    "$run_number" "$launch_state" "$total_time" "$wait_time"
  printf "%s\t%s\n" "$total_time" "$wait_time" >>"$results_file"
done

summarize_column() {
  local column="$1"
  cut -f"$column" "$results_file" | sort -n | awk '
    { values[NR] = $1 }
    END {
      if (NR % 2 == 0) {
        median = (values[NR / 2] + values[NR / 2 + 1]) / 2
      } else {
        median = values[(NR + 1) / 2]
      }
      p90_index = int((NR * 9 + 9) / 10)
      printf "median=%.1f min=%d p90=%d max=%d", \
        median, values[1], values[p90_index], values[NR]
    }
  '
}

printf "\nTotalTime: %s ms\n" "$(summarize_column 1)"
printf "WaitTime:  %s ms\n" "$(summarize_column 2)"
