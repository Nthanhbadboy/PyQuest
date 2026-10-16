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
emulator-log-analysis.txt, which is uploaded with the diagnostics. With
`--app-evidence <path>` it also writes a short extract (what happened to
com.pyquest.pyquest) that is small enough to be printed whole in the CI report,
so the check page can answer "did the app crash, get killed or restart?" without
anybody downloading the artifact.
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

# The two patterns that decide what happened to the app itself. Matching them on
# the package name keeps unrelated processes out: a restart, an ANR or a crash of
# com.pyquest.pyquest is what makes `flutter drive` lose its isolate, and it is
# the first thing anybody looks for when the journey dies mid-test.
APP_RE = APP.replace(".", r"\.")

PATTERNS += [
    ("APP ON THE DEVICE", "app process start / death (system buffer)",
     r"(am_proc_start|am_proc_died|Start proc|Force stopping|Process)"
     r"[^\n]{0,90}%s" % APP_RE),
    ("APP ON THE DEVICE", "app killed / ANR / crash",
     r"(%s[^\n]{0,90}(died|has died|killed|ANR|Exception))|"
     r"((ANR in|Killing|lmkd|LowMemoryKiller|FATAL EXCEPTION|AndroidRuntime)"
     r"[^\n]{0,90}%s)" % (APP_RE, APP_RE)),
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
    "APP ON THE DEVICE",       # first: this is the "why did the test lose the app" answer
    "ACTIVITY LIFECYCLE", "CONFIGURATION CHANGES", "RELAUNCH",
    "ANR / SYSTEM SERVER", "APP EVENTS (pid-filtered)",
]
APP_HEADING = "APP ON THE DEVICE"
APP_EVIDENCE_LIMIT = 45      # lines in the small extract the report prints
APP_EVIDENCE_WIDTH = 220     # characters per line, so the extract stays small
APP_LABELS = ("app process start / death (system buffer)",
              "app killed / ANR / crash")


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


def write_app_evidence(path, blocks):
    """A few dozen lines that say what happened to com.pyquest.pyquest.

    The check page has a text budget shared by several files, so the decisive
    lines are kept separate from the full analysis: this file is small enough to
    be printed whole in the report (see ci/job_summary.py), which means the
    question "did the app crash, get killed, or restart?" is answerable without
    downloading the artifact. Absent evidence is reported as 0 matches instead of
    being left out, so "nothing was found" cannot be mistaken for "not checked".
    """
    lines = []
    for (source, lines_count, first, last, counts, matched) in blocks:
        lines.append("APP ON THE DEVICE: %s" % APP)
        lines.append("  source: %s (%d lines, %s .. %s)"
                     % (source, lines_count, first or "(no timestamps)",
                        last or "(none)"))
        lines.append("  (system buffer; the full logcat dump is in the artifact)")
        for label in APP_LABELS:
            shown = [(text, matched_line) for text, matched_line in matched.get(label, [])
                     if text.strip()]
            lines.append("  [%s]  %d match(es)" % (label, counts.get(label, 0)))
            if not shown:
                continue
            lines.append("    \"> \" marks a matched line; the rest is context")
            for text, matched_line in shown:
                if len(lines) >= APP_EVIDENCE_LIMIT:
                    lines.append("    ... [more matches in emulator-log-analysis.txt]")
                    break
                lines.append(("    > " if matched_line else "      ")
                             + text.strip()[:APP_EVIDENCE_WIDTH])
    if not lines:
        lines = ["APP ON THE DEVICE: %s" % APP,
                 "  no logcat dump was read, so there is nothing to say about the app"]
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")
    return path


def split_args(argv):
    """(<log files>, <app-evidence path or None>) without argparse noise."""
    paths, evidence, index = [], None, 0
    while index < len(argv):
        if argv[index] == "--app-evidence" and index + 1 < len(argv):
            evidence = argv[index + 1]
            index += 2
            continue
        paths.append(argv[index])
        index += 1
    return paths, evidence


def main():
    paths, evidence = split_args(sys.argv[1:])
    if not paths:
        print("usage: analyze_logcat.py [--app-evidence <out>] <log-file> ...")
        return 2
    out = []
    blocks = []
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
        app_matched = {label: [] for label in APP_LABELS}
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
                    if heading == APP_HEADING:
                        app_matched.setdefault(label, []).append((text, matched))
        blocks.append((path, len(lines), first, last, counts, app_matched))
        say("")
        say("-" * 78)
        say("COUNTS (matches per pattern; 0 means the evidence is absent)")
        for label, _ in [(l, p) for _, l, p in PATTERNS + APP_PATTERNS]:
            say("  %4d  %s" % (counts.get(label, 0), label))
    print("\n".join(out))
    if evidence:
        write_app_evidence(evidence, blocks)
    return 0


if __name__ == "__main__":
    sys.exit(main())
