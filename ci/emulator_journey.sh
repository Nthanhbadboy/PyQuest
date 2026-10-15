#!/usr/bin/env bash
# Android emulator journey for CI. Runs inside
# reactivecircus/android-emulator-runner (cwd = app/), which exports
# ANDROID_SERIAL=emulator-<port> for this script.
#
# Every adb call below is bounded by `timeout`. adb subcommands built on
# send_shell_command() - notably `adb logcat` - print "- waiting for device -"
# and then wait for the device with NO timeout when the emulator is offline;
# `adb wait-for-device` has no timeout either. That is how run 38775197302
# hung: the emulator went offline and the unbounded `adb logcat -c` blocked.
#
# `flutter drive` uninstalls the app when it finishes unless
# --keep-app-running is passed, which would wipe the progress that the
# relaunch and returning-player checks rely on.
#
# Limits in seconds; override them through the workflow step's `env:`.
#   ADB_ONLINE_TIMEOUT  adb must report the emulator as 'device'     (90)
#   BOOT_TIMEOUT        sys.boot_completed must be 1                (120)
#   JOURNEY_TIMEOUT     fresh-install integration journey          (1500)
#   RETURNING_TIMEOUT   returning-player integration journey        (900)
#   INSTALL_TIMEOUT     `adb install` of the regular debug APK      (300)
#   ADB_CMD_TIMEOUT     any other single adb command                 (60)
#   STARTUP_GRACE       ignore "no progress" right after a test       (240)
#                       starts, while the engine draws its first frames
#   PRE_TEST_TIMEOUT    stall limit while flutter drive still builds
#                       and installs the app                        (900)
#   PROGRESS_TIMEOUT    stall limit while the tests run              (300)
#   WATCHDOG_KILL_AFTER SIGKILL for a drive that ignores SIGTERM    (20)
#
# ci/check_test_progress.py watches each drive and stops it when the app
# restarts mid-test or stops making progress; the reason lands in
# ../emulator-stop-reason.txt (also uploaded with the diagnostics).
#
# Exit status: 0 when every phase ran - test failures are recorded in
# ../status.txt and reported by ci/report.py, as before. 1 when the emulator
# was unusable or something exceeded its limit; diagnostics are written to
# ../emulator-diagnostics/ first.
set -u

SERIAL=${ANDROID_SERIAL:-emulator-5554}
PKG=com.pyquest.pyquest
ADB_ONLINE_TIMEOUT=${ADB_ONLINE_TIMEOUT:-90}
BOOT_TIMEOUT=${BOOT_TIMEOUT:-120}
JOURNEY_TIMEOUT=${JOURNEY_TIMEOUT:-1500}
RETURNING_TIMEOUT=${RETURNING_TIMEOUT:-900}
INSTALL_TIMEOUT=${INSTALL_TIMEOUT:-300}
STARTUP_GRACE=${STARTUP_GRACE:-240}
PRE_TEST_TIMEOUT=${PRE_TEST_TIMEOUT:-900}
PROGRESS_TIMEOUT=${PROGRESS_TIMEOUT:-300}
# If the drive ignores the watchdog's SIGTERM it gets SIGKILL after this.
WATCHDOG_KILL_AFTER=${WATCHDOG_KILL_AFTER:-20}
ADB_CMD_TIMEOUT=${ADB_CMD_TIMEOUT:-60}
ADB_QUERY_TIMEOUT=${ADB_QUERY_TIMEOUT:-10}
LOGCAT_DUMP_TIMEOUT=${LOGCAT_DUMP_TIMEOUT:-90}
POLL_INTERVAL=${POLL_INTERVAL:-3}
WATCH_INTERVAL=${WATCH_INTERVAL:-10}
RELAUNCH_WAIT=${RELAUNCH_WAIT:-20}

OUT=..                                   # repository root (cwd is app/)
STATUS=$OUT/status.txt
PROGRESS=$OUT/emulator-progress.txt
DIAG=$OUT/emulator-diagnostics
STOP_REASON=$OUT/emulator-stop-reason.txt
OFFLINE_FLAG=${TMPDIR:-/tmp}/pyquest-emulator-offline.$$
EMU_PROC_RE='emulator/emulator|qemu-system|crashpad_handler|netsimd'   # the emulator's own binaries
LAST_STATE=""
LAST_BOOT=""

# ------------------------------------------------------------------ logging
# Progress goes to stdout (visible live in the GitHub Actions log) and to
# ../emulator-progress.txt (published in the report and the artifact).
log() {
  local line
  line=$(printf '[%s +%04ds] %s' "$(date -u +%H:%M:%S)" "$SECONDS" "$*")
  printf '%s\n' "$line"
  printf '%s\n' "$line" >> "$PROGRESS"
}

log_block() {  # indent stdin into both outputs
  sed 's/^/      /' | tee -a "$PROGRESS"
}

# ------------------------------------------------------------- adb helpers
is_timeout() { [ "$1" -eq 124 ] || [ "$1" -eq 137 ]; }

adb_devices() {
  timeout -k 2 "$ADB_QUERY_TIMEOUT" adb devices -l 2>&1 | tr -d '\r'
}

adb_devices_oneline() {
  local list
  list=$(adb_devices | sed -n '2,$p' | sed '/^[[:space:]]*$/d' | tr -s ' ' | paste -sd ';' -)
  printf '%s' "${list:-(no devices listed)}"
}

# Prints exactly "device" when the expected emulator is usable; otherwise the
# adb error ("adb: device offline", "... not found", ...) or a timeout note.
adb_state() {
  local out rc
  out=$(timeout -k 2 "$ADB_QUERY_TIMEOUT" adb -s "$SERIAL" get-state 2>&1)
  rc=$?
  out=$(printf '%s' "$out" | tr -d '\r' | sed '/^[[:space:]]*$/d' | tail -n 1)
  if is_timeout "$rc"; then out="get-state gave no answer within ${ADB_QUERY_TIMEOUT}s"; fi
  printf '%s' "${out:-no output (exit $rc)}"
}

boot_completed_value() {
  timeout -k 2 "$ADB_QUERY_TIMEOUT" adb -s "$SERIAL" shell getprop sys.boot_completed 2>&1 \
    | tr -d '\r' | sed '/^[[:space:]]*$/d' | tail -n 1
}

# run_adb <status-key|-> <seconds> <stdout-file> <stderr-file> <adb args...>
# Bounded adb call on $SERIAL. A call that runs out of time means the
# emulator stopped answering: collect diagnostics and stop.
run_adb() {
  local key=$1 secs=$2 out=$3 err=$4 rc t0=$SECONDS
  shift 4
  timeout -k 5 "$secs" adb -s "$SERIAL" "$@" >> "$out" 2>> "$err"
  rc=$?
  if [ "$key" != - ]; then echo "$key=$rc" >> "$STATUS"; fi
  if is_timeout "$rc"; then
    fail - "'adb -s $SERIAL $*' did not finish within ${secs}s (emulator state now: $(adb_state))."
  fi
  log "   adb $* -> exit $rc ($((SECONDS - t0))s)"
  return "$rc"
}

# ------------------------------------------------------- bounded waits
wait_for_adb_device() {
  local start=$SECONDS next=0 state
  log "==> START: Waiting for emulator connection ($SERIAL as 'device', limit ${ADB_ONLINE_TIMEOUT}s)"
  while :; do
    state=$(adb_state)
    LAST_STATE=$state
    if [ "$state" = device ]; then
      log "<== END: Waiting for emulator connection: online after $((SECONDS - start))s [$(adb_devices_oneline)]"
      return 0
    fi
    if [ $((SECONDS - start)) -ge "$ADB_ONLINE_TIMEOUT" ]; then
      log "<== END: Waiting for emulator connection: TIMED OUT after $((SECONDS - start))s; get-state: $state"
      return 1
    fi
    if [ $((SECONDS - start)) -ge "$next" ]; then
      log "   still waiting: get-state='$state'; adb devices: $(adb_devices_oneline)"
      next=$((SECONDS - start + 15))
    fi
    sleep "$POLL_INTERVAL"
  done
}

wait_for_boot_completed() {
  local start=$SECONDS next=0 value
  log "==> START: Waiting for Android boot completion (sys.boot_completed=1, limit ${BOOT_TIMEOUT}s)"
  while :; do
    value=$(boot_completed_value)
    LAST_BOOT=$value
    if [ "$value" = 1 ]; then
      log "<== END: Waiting for Android boot completion: sys.boot_completed=1 after $((SECONDS - start))s"
      return 0
    fi
    if [ $((SECONDS - start)) -ge "$BOOT_TIMEOUT" ]; then
      log "<== END: Waiting for Android boot completion: TIMED OUT after $((SECONDS - start))s; last value '$value'"
      return 1
    fi
    if [ $((SECONDS - start)) -ge "$next" ]; then
      log "   still waiting: sys.boot_completed='$value'"
      next=$((SECONDS - start + 15))
    fi
    sleep "$POLL_INTERVAL"
  done
}

# require_device <status-key> <what runs next>
# Nothing touches the app before adb reports the emulator as 'device' AND
# Android reports boot completion.
require_device() {
  local key=$1 next_step=$2
  log "   checking the emulator before: $next_step"
  if ! wait_for_adb_device; then
    fail "$key" "adb did not report $SERIAL as 'device' within ${ADB_ONLINE_TIMEOUT}s before the $next_step (last get-state: '$LAST_STATE'; adb devices: $(adb_devices_oneline))."
  fi
  if ! wait_for_boot_completed; then
    fail "$key" "$SERIAL is connected but sys.boot_completed was '$LAST_BOOT' (not 1) after ${BOOT_TIMEOUT}s, before the $next_step."
  fi
  echo "$key=0" >> "$STATUS"
}

# --------------------------------------------------------- diagnostics
collect_diagnostics() {
  local reason=$1 d=$DIAG avd
  mkdir -p "$d"
  log "   collecting diagnostics into emulator-diagnostics/ (adb and the emulator are NOT restarted)"
  {
    echo "reason: $reason"
    echo "utc: $(date -u '+%F %T')   script elapsed: ${SECONDS}s   serial: $SERIAL"
  } > "$d/00_reason.txt"

  { echo "\$ adb devices -l"; adb_devices; } > "$d/adb_devices.txt" 2>&1
  { echo "\$ adb -s $SERIAL get-state"
    timeout -k 2 "$ADB_QUERY_TIMEOUT" adb -s "$SERIAL" get-state 2>&1; echo "(exit $?)"; } > "$d/adb_get_state.txt"
  { echo "\$ adb -s $SERIAL shell getprop sys.boot_completed"
    timeout -k 2 15 adb -s "$SERIAL" shell getprop sys.boot_completed 2>&1; echo "(exit $?)"; } > "$d/boot_completed.txt"
  # The emulator console answers even when adbd inside Android does not.
  { echo "\$ adb -s $SERIAL emu avd status"
    timeout -k 2 15 adb -s "$SERIAL" emu avd status 2>&1; echo "(exit $?)"; } > "$d/emulator_console.txt"

  # Full ps columns (state, elapsed, CPU, RSS) are the point here, so not pgrep.
  # shellcheck disable=SC2009
  { echo "\$ ps (emulator, qemu, adb, flutter, gradle)"
    ps -eo pid,ppid,stat,etime,pcpu,rss,args --sort=-rss \
      | grep -E "^ *PID|$EMU_PROC_RE|adb|flutter|dart|java" | grep -vE 'grep|emulator_journey' | cut -c1-320
  } > "$d/emulator_processes.txt" 2>&1
  { echo "\$ free -m"; free -m
    echo; echo "loadavg: $(cat /proc/loadavg)   nproc: $(nproc)"
    echo; echo "\$ df -h /"; df -h /
    echo; echo "\$ top processes by RSS"; ps -eo pid,stat,etime,pcpu,rss,comm --sort=-rss | head -n 15
  } > "$d/host_resources.txt" 2>&1
  { echo "\$ dmesg -T | tail (host kernel; OOM-killer evidence)"
    if sudo -n true 2>/dev/null; then timeout 15 sudo -n dmesg -T; else timeout 15 dmesg -T; fi 2>&1 | tail -n 300
  } > "$d/host_dmesg_tail.txt" 2>&1

  for avd in "${ANDROID_AVD_HOME:-$HOME/.android/avd}"/*.avd; do
    [ -d "$avd" ] || continue
    ls -la "$avd" > "$d/avd_files.txt" 2>&1
    cp "$avd/config.ini" "$d/avd_config.ini" 2>/dev/null
    cp "$avd/hardware-qemu.ini" "$d/avd_hardware-qemu.ini" 2>/dev/null
  done
  # shellcheck disable=SC2012  # human-readable listing for the artifact
  { echo "\$ ls -laR /tmp/android-$(id -un) (emulator crash reports / temp files)"
    ls -laR "/tmp/android-$(id -un)" 2>&1 | head -n 120; } > "$d/emulator_crash_reports.txt" 2>&1

  # Bounded: on an offline emulator `adb logcat` would wait forever.
  timeout -k 5 "$LOGCAT_DUMP_TIMEOUT" adb -s "$SERIAL" logcat -b all -d > "$d/logcat_all.txt" 2>&1
  echo "(adb logcat -b all -d exit $?)" >> "$d/logcat_all.txt"
  timeout -k 2 30 adb -s "$SERIAL" shell getprop > "$d/getprop.txt" 2>&1

  cp "$STATUS" "$OUT/journey.txt" "$OUT/relaunch.txt" "$d/" 2>/dev/null
  cp "$STOP_REASON" "$d/" 2>/dev/null   # progress-watchdog reason, if any
  write_summary "$reason"
}

write_summary() {
  local oom emu logcat_rc
  oom=$(sed -n '2,$p' "$DIAG/host_dmesg_tail.txt" 2>/dev/null | grep -iE 'out of memory|oom-kill|killed process' | tail -n 5)
  emu=$(grep -E "$EMU_PROC_RE" "$DIAG/emulator_processes.txt" | head -n 6)
  logcat_rc=$(tail -n 1 "$DIAG/logcat_all.txt" | grep -oE 'exit [0-9]+' | grep -oE '[0-9]+')
  {
    echo "FAILURE: $1"
    echo "utc: $(date -u '+%F %T')   script elapsed: ${SECONDS}s"
    echo "--- adb devices -l";                 sed -n '2,$p' "$DIAG/adb_devices.txt"
    echo "--- adb get-state";                  sed -n '2,$p' "$DIAG/adb_get_state.txt"
    echo "--- sys.boot_completed";             sed -n '2,$p' "$DIAG/boot_completed.txt"
    echo "--- emulator console (avd status)";  sed -n '2,$p' "$DIAG/emulator_console.txt"
    echo "--- emulator processes (PID PPID STAT ELAPSED %CPU RSS COMMAND)"
    echo "${emu:-NONE: no emulator/qemu process is running - the emulator exited or was killed}"
    echo "--- host memory / load";             sed -n '2,4p' "$DIAG/host_resources.txt"
    grep '^loadavg' "$DIAG/host_resources.txt"
    echo "--- host OOM-killer lines";          echo "${oom:-(none in the dmesg tail)}"
    if [ "${logcat_rc:-1}" = 124 ] || [ "${logcat_rc:-1}" = 137 ]; then
      echo "--- logcat -b all -d: no answer within ${LOGCAT_DUMP_TIMEOUT}s (adb was waiting for the device)"
    else
      echo "--- logcat -b all -d: $(wc -l < "$DIAG/logcat_all.txt") lines (exit ${logcat_rc:-?})"
    fi
    echo "(Emulator stdout/stderr is in the 'Emulator journey' step log; full files in the artifact.)"
  } > "$DIAG/summary.txt" 2>&1
  log "   diagnostics summary:"
  log_block < "$DIAG/summary.txt"
}

# fail <status-key|-> <explanation>: diagnostics first, then a clear error.
fail() {
  local key=$1
  shift
  if [ "$key" != - ]; then echo "$key=1" >> "$STATUS"; fi
  log "FATAL: $*"
  collect_diagnostics "$*"
  echo "::error title=Android emulator journey stopped::$* Logs: emulator-logs artifact (emulator-diagnostics/)."
  log "Exiting with status 1."
  rm -f "$OFFLINE_FLAG"
  exit 1
}

# ---------------------------------------------------------- flutter drive
# Background watchdog: stop flutter drive (pid $1) if the emulator stays
# away from 'device' for ADB_ONLINE_TIMEOUT seconds, instead of letting the
# drive sit until its own (much longer) limit.
watch_device() {
  local pid=$1 label=$2 since=-1 state
  while kill -0 "$pid" 2>/dev/null; do
    sleep "$WATCH_INTERVAL"
    kill -0 "$pid" 2>/dev/null || break
    state=$(adb_state)
    if [ "$state" = device ]; then
      if [ "$since" -ge 0 ]; then log "   watchdog: $SERIAL is 'device' again"; fi
      since=-1
      continue
    fi
    if [ "$since" -lt 0 ]; then
      since=$SECONDS
      log "   watchdog: WARNING $SERIAL is '$state' during the $label"
    fi
    if [ $((SECONDS - since)) -ge "$ADB_ONLINE_TIMEOUT" ]; then
      log "   watchdog: $SERIAL not 'device' for ${ADB_ONLINE_TIMEOUT}s - stopping flutter drive"
      echo "$state" > "$OFFLINE_FLAG"
      kill -TERM "$pid" 2>/dev/null   # `timeout` forwards it to the whole drive process group
      return 0
    fi
  done
}

# run_drive <label> <status-key> <limit-seconds> <log-file> <test-target>
# Full output goes to <log-file> and is streamed into the Actions log. Two
# watchers run next to the drive: watch_device() for the emulator leaving the
# 'device' state, ci/check_test_progress.py for a restart or a stall (a stuck
# drive used to consume its whole 1500s limit - run 38782724298).
run_drive() {
  local label=$1 key=$2 secs=$3 logf=$4 target=$5 offset pid wpid ppid rc t0 state drive_start
  touch "$logf"
  offset=$(stat -c %s "$logf")
  rm -f "$OFFLINE_FLAG" "$STOP_REASON"
  log "   flutter drive $target (limit ${secs}s; output below and in $(basename "$logf"))"
  t0=$SECONDS
  drive_start=$(date +%s)
  timeout -k 30 "$secs" flutter drive --no-pub --keep-app-running \
    --driver=test_driver/integration_test.dart --target="$target" -d "$SERIAL" >> "$logf" 2>&1 &
  pid=$!
  watch_device "$pid" "$label" &
  wpid=$!
  python3 ../ci/check_test_progress.py --log "$logf" --pid "$pid" \
    --screenshots "$OUT/docs/screenshots" --since "$drive_start" \
    --reason-file "$STOP_REASON" --state-file "$DIAG/watch-state.json" \
    --startup-grace "$STARTUP_GRACE" --pre-test-limit "$PRE_TEST_TIMEOUT" \
    --idle-limit "$PROGRESS_TIMEOUT" --interval "$WATCH_INTERVAL" \
    --kill-after "$WATCHDOG_KILL_AFTER" &
  ppid=$!
  tail -c +"$((offset + 1))" -F --pid="$pid" "$logf" 2>/dev/null | sed -u 's/^/    | /'
  wait "$pid"
  rc=$?
  sleep 1   # let watch_device finish a poll, so an offline device is named as the cause
  kill "$wpid" "$ppid" 2>/dev/null
  wait "$wpid" 2>/dev/null
  wait "$ppid" 2>/dev/null
  echo "$key=$rc" >> "$STATUS"
  log "   flutter drive finished: exit $rc after $((SECONDS - t0))s"
  if [ -f "$OFFLINE_FLAG" ]; then
    state=$(cat "$OFFLINE_FLAG")
    fail - "Emulator $SERIAL left the 'device' state ('$state') for ${ADB_ONLINE_TIMEOUT}s during the $label; flutter drive was stopped after $((SECONDS - t0))s."
  fi
  if [ -f "$STOP_REASON" ]; then
    fail - "the progress watchdog stopped the $label after $((SECONDS - t0))s: $(cat "$STOP_REASON")"
  fi
  if is_timeout "$rc"; then
    fail - "flutter drive for the $label exceeded its ${secs}s limit (emulator state now: $(adb_state))."
  fi
  if [ "$rc" -ne 0 ]; then
    echo "::warning title=$label::flutter drive exited with $rc (test failures). See the step log or $(basename "$logf")."
  fi
  return 0
}

# ================================================================== main
mkdir -p "$OUT/docs/screenshots"
rm -f "$STOP_REASON"
: > "$PROGRESS"
log "PyQuest emulator journey on $SERIAL. Limits: adb online ${ADB_ONLINE_TIMEOUT}s, boot ${BOOT_TIMEOUT}s, journey ${JOURNEY_TIMEOUT}s, returning ${RETURNING_TIMEOUT}s, install ${INSTALL_TIMEOUT}s, adb command ${ADB_CMD_TIMEOUT}s."

log "==> START: Initial ADB status (observe only; nothing is restarted)"
log "   $(timeout -k 2 "$ADB_QUERY_TIMEOUT" adb version 2>&1 | head -n 1)"
log "   adb devices -l:"
adb_devices | log_block
log "   adb -s $SERIAL get-state: $(adb_state)"
log "<== END: Initial ADB status"

# --- 1. Fresh install + integration journey --------------------------------
log "==> START: Fresh-install integration journey"
require_device device_ready_journey "fresh-install integration journey"
: > "$OUT/journey.txt"
run_adb - "$ADB_CMD_TIMEOUT" "$OUT/journey.txt" "$OUT/journey.txt" shell getprop ro.build.version.release
run_adb - "$ADB_CMD_TIMEOUT" "$OUT/journey.txt" "$OUT/journey.txt" shell wm size
run_adb - "$ADB_CMD_TIMEOUT" "$OUT/journey.txt" "$OUT/journey.txt" uninstall "$PKG"   # fails harmlessly when not installed
echo "=== journey (fresh install) ===" >> "$OUT/journey.txt"
run_drive "fresh-install integration journey" journey "$JOURNEY_TIMEOUT" "$OUT/journey.txt" integration_test/journey_test.dart
log "<== END: Fresh-install integration journey"

# --- 2. Restart with the regular app build (same debug signature keeps data)
log "==> START: Regular APK installation and relaunch"
echo "=== restart with the regular app build (same debug signature keeps data) ===" > "$OUT/relaunch.txt"
require_device device_ready_relaunch "regular APK installation and relaunch"
run_adb - "$ADB_CMD_TIMEOUT" "$OUT/relaunch.txt" "$OUT/relaunch.txt" shell am force-stop "$PKG"
run_adb install_regular_apk "$INSTALL_TIMEOUT" "$OUT/relaunch.txt" "$OUT/relaunch.txt" install -r "$OUT/pyquest-debug.apk"
run_adb - "$ADB_CMD_TIMEOUT" "$OUT/relaunch.txt" "$OUT/relaunch.txt" logcat -c
run_adb - "$ADB_CMD_TIMEOUT" "$OUT/relaunch.txt" "$OUT/relaunch.txt" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
log "   waiting ${RELAUNCH_WAIT}s for the relaunched app"
sleep "$RELAUNCH_WAIT"
run_adb - "$ADB_CMD_TIMEOUT" "$OUT/relaunch.txt" "$OUT/relaunch.txt" shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS
sleep 2
shot=$OUT/docs/screenshots/34_relaunch_real_app.png
rm -f "$shot.part"
run_adb relaunch_screencap "$ADB_CMD_TIMEOUT" "$shot.part" "$OUT/relaunch.txt" exec-out screencap -p
if [ -s "$shot.part" ]; then mv "$shot.part" "$shot"; else rm -f "$shot.part"; log "   screencap returned no image"; fi
run_adb app_alive_after_relaunch "$ADB_CMD_TIMEOUT" "$OUT/relaunch.txt" "$OUT/relaunch.txt" shell pidof "$PKG"
run_adb - "$ADB_CMD_TIMEOUT" "$OUT/relaunch.txt" "$OUT/relaunch.txt" logcat -d -t 300 flutter:V AndroidRuntime:E '*:S'
run_adb - "$ADB_CMD_TIMEOUT" "$OUT/relaunch.txt" "$OUT/relaunch.txt" shell am force-stop "$PKG"
log "<== END: Regular APK installation and relaunch"

# --- 3. Returning player ----------------------------------------------------
log "==> START: Returning-player integration journey"
echo "=== returning player checks ===" >> "$OUT/relaunch.txt"
require_device device_ready_returning "returning-player integration journey"
run_drive "returning-player integration journey" returning "$RETURNING_TIMEOUT" "$OUT/relaunch.txt" integration_test/returning_test.dart
log "<== END: Returning-player integration journey"

log "All phases finished (no emulator or adb timeouts). Step results:"
log_block < "$STATUS"
exit 0
