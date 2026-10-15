#!/usr/bin/env bash
# Snapshot of the runner around the emulator step: what the workspace, the SDK,
# the AVD and the device look like. Called twice by the workflow - once before
# the emulator step and once after it - because the interesting failures happen
# when the emulator action never reaches our script (run 38794903944: the step
# died after 73 s with no journey output at all), and the emulator action's own
# log is only in the job log.
#
# Usage: runner_state.sh <output-file> <label>
set -u

out=${1:-runner-state.txt}
label=${2:-"runner state"}

{
  echo "label: $label"
  echo "utc: $(date -u '+%F %T')"
  echo "runner: ${RUNNER_OS:-?} ${RUNNER_ARCH:-?}   cpus: $(nproc)   kernel: $(uname -r)"
  if [ -w /dev/kvm ]; then echo "kvm: writable"; else echo "kvm: not writable / missing"; fi
  if command -v adb > /dev/null 2>&1; then
    echo "adb: $(command -v adb)"
  else
    echo "adb: not on PATH yet (the emulator action installs the platform tools)"
  fi
  echo
  echo "\$ df -h /"; df -h /
  echo; echo "\$ free -m"; free -m
  echo; echo "\$ adb devices -l"
  if command -v adb > /dev/null 2>&1; then
    timeout -k 2 20 adb devices -l 2>&1
  else
    echo "(adb not available)"
  fi
  echo; echo "\$ ps (emulator, qemu, adb, flutter, gradle)"
  # Full ps columns are the point here, so not pgrep.
  # shellcheck disable=SC2009
  ps -eo pid,ppid,stat,etime,pcpu,rss,args --sort=-rss 2>/dev/null \
    | grep -E "^ *PID|emulator|qemu|adb|flutter|dart|java" | grep -v grep | cut -c1-200 | head -n 20
  echo; echo "\$ android sdk: system images and AVDs"
  for dir in "${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}/system-images" \
             "$HOME/.android/avd"; do
    echo "-- $dir"
    # shellcheck disable=SC2012  # human-readable listing for the report
    ls -la "$dir" 2>&1 | head -n 12
  done
  for ini in "$HOME"/.android/avd/*.avd/config.ini; do
    [ -f "$ini" ] || continue
    echo; echo "\$ $ini (memory/abi/partition lines)"; grep -E "ram|heap|abi|hw.cpu|dataPartition|sdcard" "$ini"
  done
  echo; echo "\$ ls -laR /tmp/android-$(id -un) (emulator crash reports / temp files)"
  # shellcheck disable=SC2012  # human-readable listing for the report
  ls -laR "/tmp/android-$(id -un)" 2>&1 | head -n 60
} > "$out" 2>&1 || true

echo "$(basename "$out"): $(wc -c < "$out") bytes"
