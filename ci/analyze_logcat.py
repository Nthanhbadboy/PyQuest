#!/usr/bin/env python3
"""Deterministically extract the interesting lines from emulator log captures.

Why: run 38782724298 saw the app's activity recreated at 18:22:05, which left
`flutter drive` waiting for an isolate that no longer existed. The reasons for
a relaunch live in the *system* logcat buffers (`am_proc_start`,
`Config changes:`, `ANR in ...`), which are unreadable from a development
sandbox: GitHub only hands out a signed URL to blob storage.

This script does no interpretation. It prints matching lines with their
timestamps and a little surrounding context, split by category, so the report
and the artifact carry the evidence itself.

Usage:
    python3 ci/analyze_logcat.py <log-file> [<log-file> ...]

Output goes to stdout only; the CI step redirects it to
emulator-log-analysis.txt, which is uploaded with the diagnostics.
"""

import re
import sys

CONTEXT = 2          # lines of context on each side of a match
MAX_PER_PATTERN = 40  # matches printed per pattern

APP = "com.pyquest.pyquest"

# (heading, label, pattern). Order inside a heading is the print order.
PATTERNS = [
    # --- activity lifecycle -------------------------------------------------
    ("ACTIVITY LIFECYCLE", "process start (am_proc_start)",
     r"am_proc_start|Start proc \d+:"),
    ("ACTIVITY LIFECYCLE", "activity start (am_create_activity / START)",
     r"am_create_activity|ActivityTaskManager:\s+START u0|ActivityManager:\s+START u0"),
    ("ACTIVITY LIFECYCLE", "activity finish / destroy",
     r"am_finish_activity|am_destroy_activity|ActivityTaskManager:\s+Destroying|ActivityManager:\s+Destroying"),
    ("ACTIVITY LIFECYCLE", "app launched / displayed (launch timing)",
     r"Displayed %s|Displayed com\.pyquest" % APP),
    ("ACTIVITY LIFECYCLE", "app process killed (lmk / am_kill / Killing)",
     r"am_kill|LowMemoryKiller|ActivityManager:\s+Killing|Killing %s" % APP),

    # --- configuration changes ---------------------------------------------
    ("CONFIGURATION CHANGES", "Config changes reported to the activity",
     r"Config changes[=:]"),
    ("CONFIGURATION CHANGES", "configuration update on the process",
     r"Updating configuration|updateConfiguration|handleConfigurationChanged|"
     r"Configuration changes|WindowConfiguration"),
    ("CONFIGURATION CHANGES", "display / orientation changes",
     r"am_display_changed|DisplayDeviceInfo|Rotation changed|"
     r"screen frozen for|orientation change"),

    # --- relaunch -----------------------------------------------------------
    ("RELAUNCH", "activity relaunch / recreate",
     r"relaunch|Relayout.*relaunch|scheduleRelaunch|recreate\(\)|"
     r"ActivityTaskManager:\s+Relaunching|Relaunching"),
    ("RELAUNCH", "window / surface teardown around the recreate",
     r"SurfaceSyncGroup|WindowOnBackDispatcher|"
     r"ActivityTaskManager:\s+Removing|WindowManager:\s+Destroying|Destroying surface"),

    # --- ANR / system_server ------------------------------------------------
    ("ANR / SYSTEM SERVER", "ANR reported by the system",
     r"ANR in |am_anr|ANRManager|Input dispatching timed out|"
     r"Application is not responding|not responding: key"),
    ("ANR / SYSTEM SERVER", "ANR reason / CPU usage snapshot",
     r"Reason:|CPU usage from|anr_helper|Broadcast of Intent.*TIME"),
    ("ANR / SYSTEM SERVER", "system_server watchdog / restart",
     r"Watchdog:|WATCHDOG KILLING|system_server.*(died|crash)|"
     r"Process system_server"),
    ("ANR / SYSTEM SERVER", "system slowness markers",
     r"Slow operation|Slow dispatch|Timed out waiting|"
     r"Blocked in handler|Service.*took \d+ms|"
     r"Long monitor contention|Timeout executing service"),
]

# App-side lines worth keeping next to the system evidence.
APP_PATTERNS = [
    ("APP EVENTS (pid-filtered)", "flutter test runner progress",
     r"I/flutter.*\d\d:\d\d \+\d+:"),
    ("APP EVENTS (pid-filtered)", "engine / rendering backend start",
     r"Using the Impeller rendering backend|FlutterActivityAndFragmentDelegate|"
     r"FlutterRenderer|FlutterJNI"),
    ("APP EVENTS (pid-filtered)", "frame skips and surface sync",
     r"Choreographer.*Skipped|SurfaceSyncGroup|Davey!"),
    ("APP EVENTS (pid-filtered)", "audio pipeline churn",
     r"CCodec.*allocate\(|MediaPlayer.*resetDrmState|CCodecBufferChannel"),
]

TS = re.compile(r"^\s*(\d\d-\d\d \d\d:\d\d:\d\d\.\d+|\d{4}-\d\d-\d\d[T ]\d\d:\d\d:\d\d)")
BUCKET = re.compile(r"^-{5,} beginning of (\w+)")
SECTION_ORDER = [
    "ACTIVITY LIFECYCLE", "CONFIGURATION CHANGES", "RELAUNCH",
    "ANR / SYSTEM SERVER", "APP EVENTS (pid-filtered)",
]


def read_lines(path):
    with open(path, encoding="utf-8", errors="replace") as handle:
        return handle.read().splitlines()


def coverage(lines):
    """Time range and logcat buffer sections present in the file."""
    first = last = ""
    sections = []
    for line in lines:
        match = BUCKET.match(line)
        if match:
            sections.append(match.group(1))
            continue
        if not first and TS.match(line):
            first = line.strip()[:18]
        if TS.match(line):
            last = line.strip()[:18]
    return first, last, sections


def windows(lines, pattern, limit=MAX_PER_PATTERN):
    """Match indexes plus CONTEXT lines around them, merged and deduped."""
    regex = re.compile(pattern, re.IGNORECASE)
    hits = [i for i, line in enumerate(lines) if regex.search(line)]
    shown = []
    ranges = []
    for hit in hits[:limit]:
        start, end = max(0, hit - CONTEXT), min(len(lines), hit + CONTEXT + 1)
        if ranges and start <= ranges[-1][1]:
            ranges[-1][1] = max(ranges[-1][1], end)
        else:
            ranges.append([start, end])
    for start, end in ranges:
        for index in range(start, end):
            shown.append((lines[index], bool(regex.search(lines[index]))))
        shown.append(("", False))
    return len(hits), shown


def main():
    paths = sys.argv[1:]
    if not paths:
        print("usage: analyze_logcat.py <log-file> [<log-file> ...]")
        return 2
    out = []
    say = out.append
    for path in paths:
        try:
            lines = read_lines(path)
        except OSError as error:
            say("could not read %s: %s" % (path, error))
            continue
        first, last, sections = coverage(lines)
        say("=" * 78)
        say("FILE %s (%d lines)" % (path, len(lines)))
        say("  logcat buffers present: %s" % (", ".join(sections) or "(none / not a logcat dump)"))
        say("  timestamps covered: %s .. %s" % (first or "(none)", last or "(none)"))
        if "main" in sections and "system" not in sections:
            say("  NOTE: no system/events buffer in this file - ANR and config-change"
                " evidence lives there.")
        counts = {}
        for heading in SECTION_ORDER:
            entries = [(label, pat) for where, label, pat in PATTERNS + APP_PATTERNS
                       if where == heading]
            if not entries:
                continue
            say("")
            say("-" * 78)
            say("%s" % heading)
            say("-" * 78)
            for label, pattern in entries:
                total, shown = windows(lines, pattern)
                counts[label] = total
                say("")
                say("[%s]  %d match(es)" % (label, total))
                if not total:
                    continue
                if total > MAX_PER_PATTERN:
                    say("  (showing the first %d; full file: %s)"
                        % (MAX_PER_PATTERN, path))
                for text, matched in shown:
                    if not text:
                        say("  ...")
                    else:
                        say(("  > " if matched else "    ") + text[:400])
        say("")
        say("-" * 78)
        say("COUNTS (matches per pattern; 0 means the evidence is absent)")
        for label, _ in [(l, p) for _, l, p in PATTERNS + APP_PATTERNS]:
            say("  %4d  %s" % (counts.get(label, 0), label))
    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
