#!/usr/bin/env python3
"""Watch an integration-test run and stop it as soon as it is provably stuck.

Why: in run 38782724298 the app's activity was recreated 70 s into the test.
The Flutter engine restarted, the test runner began again from scratch in a new
isolate, and `flutter drive` waited for its original isolate until its 1500 s
limit - 25 minutes of CI time for a run that could never finish.

This watcher runs next to the drive. It counts *independent* progress signals
rather than one log format:

  1. test-runner progress lines (`00:12 +3: ...`) - highest counter seen;
  2. fresh files in the screenshot directory (the test writes one per step);
  3. new bytes appended to the log at all;
  4. restarts: more than one test-runner start line, more than one
     "Using the Impeller rendering backend" engine boot, or more than one
     "VMServiceFlutterDriver: Connecting" handshake.

A restart signal, or a long absence of signals 1-3 while the drive is alive,
means the run cannot finish. The watcher then writes the reason to
--reason-file, sends SIGTERM to the drive (to `timeout`, which forwards it), and
exits 3. It never restarts adb or the emulator.

Phases: before the first test-runner line the drive is still building and
installing the app, where silence is normal, so the much longer
--pre-test-limit applies instead of --idle-limit.

Usage:
    check_test_progress.py --log FILE --pid PID --reason-file FILE \
        [--screenshots DIR] [--state-file FILE] [--since EPOCH] \
        [--idle-limit 300] [--pre-test-limit 900] [--startup-grace 240] \
        [--interval 20] [--log-status-every 60] [--kill-after 20]
Exit codes:
    0  the watched process finished without any failure signal
    3  failure detected: reason written to --reason-file, drive signalled
    2  usage error
"""

import argparse
import json
import os
import re
import signal
import sys
import time

# --- progress signals -------------------------------------------------------
# Log lines look like "I/flutter ( 5710): 00:12 +3: 04 dragon jump run", so the
# test-runner timestamps are matched anywhere in the line, not at its start.
START_LINE = re.compile(r"\d\d:\d\d \+\d+:\s")            # "+5: ..."
START_LINE_ZERO = re.compile(r"\d\d:\d\d \+0:")             # a test started, 0 done
PASSED_COUNTER = re.compile(r"\d\d:[\d:.]+ \+(\d+)")        # tests finished
ENGINE_BOOT = re.compile(r"Using the Impeller rendering backend")
APP_OUTPUT = re.compile(r"I/flutter \(\s*\d+\):")           # the app's own prints
DRIVER_CONNECT = re.compile(r"VMServiceFlutterDriver: Connecting to Flutter application")
PRE_TEST_PHASE = re.compile(r"Running Gradle task|Installing build")

RESTART_REASON = (
    "the app restarted in the middle of the integration test: %s. "
    "The test runner began again from the start, so the driver can never "
    "receive results for the run it started (this is how run 38782724298 "
    "burned its whole limit)."
)
STALL_REASON = (
    "no integration-test progress for %(idle).0fs: last test signal "
    "'%(last)s' %(since_test).0fs ago, no app output for %(since_app).0fs, "
    "newest screenshot %(shot)s -> the test runner is not advancing"
)
PRE_TEST_STALL_REASON = (
    "the build/install phase wrote nothing for %(quiet).0fs (limit "
    "%(idle).0fs) while flutter drive was still running -> it is stuck "
    "before the tests started"
)


def log_line(text):
    print(text, flush=True)


def drive_children(pid):
    """Direct children of pid, read from procfs (Linux-only), [] if unknown."""
    try:
        with open("/proc/%d/task/%d/children" % (pid, pid),
                  encoding="utf-8") as handle:
            return [int(part) for part in handle.read().split()]
    except (OSError, ValueError):
        return []


class Watcher:
    def __init__(self, args):
        self.args = args
        self.offset = 0
        self.buffer = ""
        self.since = args.since or time.time()
        self.starts = []
        self.zero_starts = 0
        self.engine_boots = 0
        self.driver_connects = 0
        self.best_passed = 0
        self.last_progress_at = None
        self.last_progress_text = "(none yet)"
        self.last_app_output_at = time.monotonic()
        self.last_change_at = time.monotonic()
        self.last_size = 0
        self.in_test = False
        self.next_status = 0.0
        self.shots_seen = {}
        self.started_at = time.monotonic()

    # --- inputs -------------------------------------------------------------
    def read_new_bytes(self):
        try:
            size = os.path.getsize(self.args.log)
        except OSError:
            return ""
        if size < self.last_size:
            self.last_size = size  # truncated (a new drive started writing)
            return ""
        if size == self.last_size:
            return ""
        self.last_size = size
        with open(self.args.log, encoding="utf-8", errors="replace") as handle:
            handle.seek(self.offset)
            chunk = handle.read()
            self.offset = handle.tell()
        return chunk

    def newest_screenshot(self):
        """(path, mtime) of the newest screenshot written by this drive."""
        directory = self.args.screenshots
        best = (None, 0.0)
        if not directory or not os.path.isdir(directory):
            return best
        for name in os.listdir(directory):
            path = os.path.join(directory, name)
            try:
                mtime = os.path.getmtime(path)
            except OSError:
                continue
            if mtime > self.since and mtime > best[1]:
                best = (name, mtime)
        return best

    def alive(self):
        """False once the drive exited - including while it is a zombie, so a
        finished run can never be blamed on the watcher."""
        pid = self.args.pid
        if pid <= 0:
            return True
        try:
            with open("/proc/%d/stat" % pid, "rb") as handle:
                # "pid (comm) state ..." - comm may contain ')', hence rsplit.
                state = handle.read().rsplit(b")", 1)[1].split()[0]
            if state == b"Z":
                return False
            return True
        except (OSError, IndexError):
            pass
        try:
            os.kill(pid, 0)
        except OSError:
            return False
        return True

    def drive_still_ours(self):
        """Guard against killing a recycled PID."""
        try:
            with open("/proc/%d/cmdline" % self.args.pid, "rb") as handle:
                cmdline = handle.read().decode("utf-8", "replace")
        except OSError:
            return False
        return "drive" in cmdline and ("flutter" in cmdline or "dart" in cmdline)

    # --- state --------------------------------------------------------------
    def absorb(self, chunk):
        self.buffer += chunk
        lines = self.buffer.splitlines(keepends=True)
        self.buffer = lines.pop() if lines and not lines[-1].endswith("\n") else ""
        text = "".join(lines)
        if not text:
            return
        now = time.monotonic()
        for match in START_LINE_ZERO.finditer(text):
            self.zero_starts += 1
            self.starts.append(match.group(0).strip())
            if not self.in_test:
                self.in_test = True
                # Grace measured from the first test start: a cold engine on a
                # slow emulator can take a while to draw its first frame.
                self.grace_until = now + self.args.startup_grace
                log_line("   watchdog: first test started (%s); no failure verdict "
                         "for the next %.0fs" % (match.group(0).strip(),
                                                 self.args.startup_grace))
        counter = 0
        for match in PASSED_COUNTER.finditer(text):
            counter = max(counter, int(match.group(1)))
        if counter > self.best_passed:
            self.best_passed = counter
            self.last_progress_text = "+%d tests passed" % counter
            self.last_progress_at = now
            log_line("   watchdog: progress %s" % self.last_progress_text)
        if APP_OUTPUT.search(text):
            self.last_app_output_at = now
        boots = len(ENGINE_BOOT.findall(text))
        connects = len(DRIVER_CONNECT.findall(text))
        if boots:
            self.engine_boots += boots
            log_line("   watchdog: engine boot #%d (Impeller started)" % self.engine_boots)
        if connects:
            self.driver_connects += connects
            self.last_progress_at = now
            self.last_progress_text = "driver connected (#%d)" % self.driver_connects
        if counter == 0 and (boots or connects or START_LINE.search(text)) \
                and self.last_progress_at is None:
            self.last_progress_at = now
            self.last_progress_text = "driver connecting"

    def state(self):
        return {
            "in_test": self.in_test,
            "zero_starts": self.zero_starts,
            "engine_boots": self.engine_boots,
            "driver_connects": self.driver_connects,
            "best_passed": self.best_passed,
            "tests_started": self.starts,
            "last_progress": self.last_progress_text,
            "elapsed_s": round(time.monotonic() - self.started_at, 1),
        }

    # --- verdicts -----------------------------------------------------------
    def restart_verdict(self):
        if self.engine_boots > 1 and self.in_test:
            return ("the Flutter engine started %d times during one drive"
                    % self.engine_boots)
        if self.zero_starts > 1 and self.best_passed == 0:
            return ("the test runner printed its start line %d times "
                    "(00:00 +0) and no test ever finished" % self.zero_starts)
        # A second handshake only means a restart if no test ever passed;
        # a healthy run can reconnect while the engine is still warming up.
        if self.driver_connects > 1 and self.best_passed == 0:
            return ("the driver connected %d times during one drive and no "
                    "test finished" % self.driver_connects)
        return None

    def stall_verdict(self, now):
        shot_name, shot_mtime = self.newest_screenshot()
        shot = ("%s at %s" % (shot_name,
                              time.strftime("%H:%M:%S", time.localtime(shot_mtime)))
                if shot_name else "(none)")
        if not self.in_test:
            # Still building/installing: the only signal is log output.
            quiet = now - self.last_change_at
            if quiet < self.args.pre_test_limit:
                return None
            return PRE_TEST_STALL_REASON % {"quiet": quiet,
                                            "idle": self.args.pre_test_limit}
        if now < getattr(self, "grace_until", 0):
            return None
        # A running test is alive if any of these moved: the test counter, a
        # saved screenshot, a driver connect, or the app's own prints. Frame
        # statistics keep the log busy while a stuck runner does none of this.
        base = max(self.last_progress_at or self.started_at, self.last_app_output_at)
        quiet = now - base
        if quiet < self.args.idle_limit:
            return None
        return STALL_REASON % {
            "idle": quiet,
            "last": self.last_progress_text,
            "shot": shot,
            "since_test": now - (self.last_progress_at or self.started_at),
            "since_app": now - self.last_app_output_at,
        }

    # --- loop ---------------------------------------------------------------
    def run(self):
        os.makedirs(os.path.dirname(os.path.abspath(self.args.reason_file)) or ".",
                    exist_ok=True)
        log_line("   watchdog: watching pid %d, log %s, idle limit %.0fs"
                 % (self.args.pid, self.args.log, self.args.idle_limit))
        while True:
            chunk = self.read_new_bytes()
            shot_name, shot_mtime = self.newest_screenshot()
            fresh_shot = shot_name is not None and shot_name not in self.shots_seen
            if chunk or fresh_shot:
                self.last_change_at = time.monotonic()
            if fresh_shot:
                self.shots_seen[shot_name] = shot_mtime
                self.last_progress_at = time.monotonic()
                self.last_progress_text = "screenshot %s" % shot_name
                self.in_test = True
                log_line("   watchdog: new screenshot %s" % shot_name)
            if chunk:
                self.absorb(chunk)
            now = time.monotonic()
            if not self.alive():
                log_line("   watchdog: watched process exited; %s"
                         % ("last progress " + self.last_progress_text
                            if self.best_passed or self.shots_seen else "no progress seen"))
                return 0
            verdict = self.restart_verdict()
            if verdict:
                self.finish(RESTART_REASON % verdict)
                return 3
            verdict = self.stall_verdict(now)
            if verdict:
                self.finish(verdict)
                return 3
            if now >= self.next_status:
                self.next_status = now + self.args.log_status_every
                log_line("   watchdog: %s | last test signal %s | app output %.0fs "
                         "ago | log quiet %.0fs"
                         % ("test running" if self.in_test else "building/installing",
                            self.last_progress_text,
                            now - self.last_app_output_at,
                            now - self.last_change_at))
            time.sleep(self.args.interval)

    def finish(self, reason):
        # Order matters: record the reason, stop the drive, then decorate.
        # Nothing here may raise before the drive is signalled.
        with open(self.args.reason_file, "w", encoding="utf-8") as handle:
            handle.write(reason + "\n")
        log_line("   watchdog: STOPPING - %s" % reason)
        self.stop_drive()
        self.write_state()

    def stop_drive(self):
        """SIGTERM the drive, then SIGKILL it if it ignores that.

        Both steps are bounded, and this runs inline (not in a thread) so the
        watcher stays alive while the shell blocks in `wait` - a daemon thread
        would be killed by sys.exit() and the drive would survive to its
        timeout, which is the failure this watchdog exists to prevent.
        """
        if not self.drive_still_ours():
            log_line("   watchdog: pid %d is no longer the flutter drive; "
                     "not signalling" % self.args.pid)
            return
        try:
            os.kill(self.args.pid, signal.SIGTERM)
        except OSError as error:
            log_line("   watchdog: could not signal pid %d: %s"
                     % (self.args.pid, error))
            return
        log_line("   watchdog: sent SIGTERM to pid %d" % self.args.pid)
        if self.args.kill_after <= 0:
            return
        if self.wait_gone(self.args.kill_after):
            return
        for pid in [self.args.pid] + drive_children(self.args.pid):
            try:
                os.kill(pid, signal.SIGKILL)
                log_line("   watchdog: pid %d ignored SIGTERM for %.0fs; "
                         "SIGKILL sent" % (pid, self.args.kill_after))
            except OSError:
                pass                     # already gone: the usual case
        self.wait_gone(self.args.kill_after)

    def wait_gone(self, secs):
        """Wait (bounded) for the drive to disappear; True when it is gone."""
        deadline = time.time() + max(secs, 0.0)
        while time.time() < deadline:
            if not self.alive():
                return True
            time.sleep(0.5)
        return not self.alive()

    def write_state(self):
        """Best effort snapshot for the uploaded diagnostics; never breaks the stop."""
        if not self.args.state_file:
            return
        try:
            directory = os.path.dirname(os.path.abspath(self.args.state_file))
            os.makedirs(directory, exist_ok=True)
            with open(self.args.state_file, "w", encoding="utf-8") as handle:
                json.dump(self.state(), handle, indent=2)
        except OSError as error:
            log_line("   watchdog: could not write %s: %s"
                     % (self.args.state_file, error))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", required=True)
    parser.add_argument("--pid", type=int, required=True)
    parser.add_argument("--reason-file", required=True)
    parser.add_argument("--screenshots", default="")
    parser.add_argument("--state-file", default="")
    parser.add_argument("--since", type=float, default=0.0)
    parser.add_argument("--idle-limit", type=float, default=300.0)
    parser.add_argument("--pre-test-limit", type=float, default=900.0)
    parser.add_argument("--startup-grace", type=float, default=240.0)
    parser.add_argument("--interval", type=float, default=20.0)
    parser.add_argument("--kill-after", type=float, default=20.0)
    parser.add_argument("--log-status-every", type=float, default=60.0)
    args = parser.parse_args()
    if args.interval <= 0 or args.idle_limit <= 0:
        parser.error("--interval and --idle-limit must be positive")
    return Watcher(args).run()


if __name__ == "__main__":
    sys.exit(main())
