#!/usr/bin/env python3
"""Write a self-contained failure report for an Android emulator run.

Why: the Actions job log is served from blob storage through a redirect, so in
some environments (the development sandbox that debugged this CI) the only
readable evidence is the job page itself and the check run. Run 38794903944
failed 73 s into the emulator step with a 1,687 byte artifact and nothing else
to look at, and run 38797124392 lost its emulator mid-test with the reason
split across files that only existed inside the artifact.

This script reads what the job left in the workspace - the emulator script's
progress file, its EXIT trap record, the phase status keys, the diagnostics
directory, the captured step log - and prints one short markdown report. CI
appends it to $GITHUB_STEP_SUMMARY (the job page), publishes it as the check
run's text and keeps a copy in the workspace. Nothing here needs a download, a
ZIP or a redirect.

Usage:
    python3 ci/job_summary.py --run-id 123 --job android --out emulator-report.md \
        --step "Build debug APK=success" --step "Emulator journey=failure" \
        --upload-outcome success --artifact-name emulator-logs-attempt-1
"""

import argparse
import os
import re
import sys
import time

REPO = os.environ.get("GITHUB_REPOSITORY", "Nthanhbadboy/PyQuest")
TAIL_LINES = 100            # the user-visible "last 100 relevant lines"
MAX_REPORT_BYTES = 60000    # stays well below the check-run text limit
PHASE_MARKER = "==> PHASE: "
ERROR_HINTS = re.compile(
    r"::error|FATAL:|DriverError|Unhandled exception|AndroidRuntime|"
    r"FATAL EXCEPTION|error:|Error:|Exception|FAILED|not found|refused|"
    r"timed out|TIMED OUT|disappeared|no longer")
SKIP_ERROR_LINES = re.compile(r"^\s*(phase markers|last \d+ lines|exit_code:|"
                              r"phase:|utc:|error hints|\[)")
STATUS_OK = ("success", "skipped", "neutral")


def read_lines(path, limit=None):
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            lines = handle.read().splitlines()
    except OSError:
        return None
    return lines[:limit] if limit else lines


def tail(path, count):
    lines = read_lines(path)
    return lines[-count:] if lines else None


def trim(line, width=180):
    return line if len(line) <= width else line[:width] + " …"


def first_error(paths):
    """The first line that looks like an error, in file order."""
    for path in paths:
        for line in read_lines(path) or []:
            if SKIP_ERROR_LINES.search(line):
                continue
            if ERROR_HINTS.search(line):
                return line.strip()[:400], path
    return None, None


def status_keys(root):
    keys = []
    for line in read_lines(os.path.join(root, "status.txt")) or []:
        if "=" in line:
            name, _, value = line.partition("=")
            keys.append((name.strip(), value.strip()))
    return keys


def trap_fields(root):
    """phase / exit_code / utc from the emulator script's EXIT trap record."""
    fields = {}
    for line in read_lines(os.path.join(root, "emulator-trap.txt")) or []:
        if ": " in line and not line.startswith(" "):
            key, _, value = line.partition(": ")
            if key in ("phase", "exit_code", "utc"):
                fields[key] = value.strip()
    return fields


def progress_facts(root):
    """Markers that matter: the phases that started, plus first/last output."""
    lines = read_lines(os.path.join(root, "emulator-progress.txt"))
    if not lines:
        return None
    phases = []
    for line in lines:
        if PHASE_MARKER in line:
            name = line.split(PHASE_MARKER, 1)[1].split("    #")[0].strip()
            if name not in phases:
                phases.append(name)
    return {"first": lines[0], "last": lines[-1], "phases": phases,
            "count": len(lines)}


def diagnostics(root):
    directory = os.path.join(root, "emulator-diagnostics")
    try:
        names = sorted(os.listdir(directory))
    except OSError:
        return 0, [], False
    files = [n for n in names if os.path.isfile(os.path.join(directory, n))]
    return len(files), files, "summary.txt" in files


def diagnostics_state(root):
    """The few lines that answer 'what was the device doing?', if collected."""
    directory = os.path.join(root, "emulator-diagnostics")
    wanted = [
        ("adb devices -l", "adb_devices.txt", 4),
        ("adb get-state", "adb_get_state.txt", 3),
        ("sys.boot_completed", "boot_completed.txt", 3),
        ("emulator console", "emulator_console.txt", 3),
        ("emulator processes", "emulator_processes.txt", 5),
    ]
    out = []
    for label, name, count in wanted:
        lines = read_lines(os.path.join(directory, name))
        if not lines:
            continue
        body = [trim(line) for line in lines[1:1 + count] if line.strip()]
        out.append("$ %s" % label)
        out.extend("  " + line for line in body)
    if out:
        return out
    # No diagnostics: fall back to whatever the runner-state steps captured.
    for name in ("runner-state.txt", "runner-state-before.txt"):
        lines = read_lines(os.path.join(root, name))
        if not lines:
            continue
        keep = [trim(line) for line in lines
                if re.search(r"^kvm:|^Mem:|^Filesystem|emulator-5554|qemu|not found|"
                             r"refused|config.ini", line)]
        if keep:
            return ["$ %s (selected lines)" % name] + ["  " + line for line in keep[:8]]
    return ["(no device state was collected - see the step log on the job page)"]


def step_table(entries):
    rows = []
    for entry in entries or []:
        name, _, outcome = entry.rpartition("=")
        if not name:
            name, outcome = entry, "unknown"
        rows.append((name.strip(), outcome.strip() or "unknown"))
    return rows


def report(args, root):
    steps = step_table(args.step)
    failed_steps = [(n, o) for n, o in steps if o not in STATUS_OK]
    keys = status_keys(root)
    bad_keys = [(n, v) for n, v in keys if v != "0"]
    trap = trap_fields(root)
    progress = progress_facts(root)
    diag_count, diag_files, has_summary = diagnostics(root)
    step_log = os.path.join(root, args.step_log)
    error_line, error_source = first_error([
        step_log,
        os.path.join(root, "emulator-progress.txt"),
        os.path.join(root, "emulator-stop-reason.txt"),
    ])

    out = []
    state = "failed" if failed_steps or bad_keys or trap.get("exit_code", "0") != "0" \
        else "passed"
    out.append("## PyQuest emulator run %s (attempt %s) - %s"
               % (args.run_id, args.run_attempt, state))
    out.append("")
    out.append("`%s` job · branch `%s` · commit `%s` · event `%s` · report written %s UTC"
               % (args.job, args.ref, args.sha[:7], args.event,
                  time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime())))
    out.append("")
    out.append("[Full run log](https://github.com/%s/actions/runs/%s) - everything below "
               "is assembled from files this job left behind, so no download is needed."
               % (REPO, args.run_id))
    out.append("")

    # --- where it stopped ---------------------------------------------------
    out.append("### Where it stopped")
    out.append("")
    if trap:
        exit_code = trap.get("exit_code", "?")
        out.append("- the journey script ended during: **%s**" % trap.get("phase", "?"))
        out.append("- script exit code: **%s**%s"
                   % (exit_code, " (signalled, 128+N)" if exit_code.isdigit()
                      and int(exit_code) > 128 else ""))
        out.append("- recorded: %s" % trap.get("utc", "?"))
    else:
        out.append("- **no `emulator-trap.txt`**: the journey script never reached its "
                   "exit trap")
    if progress:
        if progress["phases"]:
            completed = [p for p in progress["phases"] if p != trap.get("phase")]
            out.append("- phases seen running: %s"
                       % ", ".join("`%s`" % p for p in progress["phases"]))
            out.append("- phases that had finished before the script ended: %s"
                       % (", ".join("`%s`" % p for p in completed) if completed
                          else "none"))
        out.append("- first output: `%s`" % trim(progress["first"], 150))
        out.append("- last output: `%s`" % trim(progress["last"], 150))
    if not progress and not trap:
        out.append("- **no emulator script output at all**: `emulator-progress.txt` and "
                   "`emulator-trap.txt` are missing")
        out.append("- that means the emulator step failed *before* the journey script "
                   "started its first phase, i.e. inside the emulator action itself "
                   "(SDK install / AVD creation / emulator start), not in the app tests")
    out.append("")

    # --- steps, exit codes --------------------------------------------------
    if steps:
        out.append("### Steps in this job")
        out.append("")
        out.append("| step | outcome |")
        out.append("|---|---|")
        out.extend("| %s | %s |" % (name, outcome) for name, outcome in steps)
        out.append("")
    if failed_steps:
        out.append("**Failed step(s)**: %s"
                   % ", ".join("`%s` (%s)" % (n, o) for n, o in failed_steps))
    if keys:
        out.append("**Phase status keys**: %s"
                   % ", ".join("`%s=%s`" % (n, v) for n, v in keys))
    if bad_keys:
        out.append("")
        out.append("**Non-zero phases**: %s"
                   % ", ".join("`%s=%s`" % (n, v) for n, v in bad_keys))
    elif keys and not failed_steps:
        out.append("")
        out.append("Every phase key is 0, so the app tests themselves passed.")
    if failed_steps and not keys and not progress:
        out.append("")
        out.append("The emulator step failed before the journey script wrote any status "
                   "key, so there is no phase exit code: the failing command is inside "
                   "`reactivecircus/android-emulator-runner@v2`, whose own output is only "
                   "in the job log linked above (step `%s`)." % failed_steps[0][0])
    reason = read_lines(os.path.join(root, "emulator-stop-reason.txt"))
    if reason:
        out.append("")
        out.append("**Progress watchdog reason**: %s" % trim(reason[0], 220))
    out.append("")

    # --- first error and the tail ------------------------------------------
    out.append("### First error in the captured output")
    out.append("")
    if error_line:
        out.append("```")
        out.append(trim(error_line, 400))
        out.append("```")
        out.append("")
        out.append("(from `%s`)" % os.path.basename(error_source or "?"))
    else:
        out.append("_no line matched the usual error patterns; see the tail below_")
    out.append("")

    out.append("### Last %d lines of the captured step output" % TAIL_LINES)
    out.append("")
    tail_lines = tail(step_log, TAIL_LINES)
    tail_source = args.step_log
    if not tail_lines:
        tail_lines = tail(os.path.join(root, "emulator-progress.txt"), TAIL_LINES)
        tail_source = "emulator-progress.txt"
    if tail_lines:
        out.append("<sub>%s</sub>" % tail_source)
        out.append("")
        out.append("```")
        out.extend(trim(line) for line in tail_lines)
        out.append("```")
    else:
        out.append("_no step output was captured (`%s` and `emulator-progress.txt` are "
                   "both missing)_" % args.step_log)
    out.append("")

    # --- device state -------------------------------------------------------
    out.append("### ADB / emulator state")
    out.append("")
    out.append("```")
    out.extend(diagnostics_state(root))
    out.append("```")
    out.append("")

    # --- diagnostics + artifact --------------------------------------------
    out.append("### Diagnostics and artifact")
    out.append("")
    out.append("- diagnostics collected: %s (%d file(s) in `emulator-diagnostics/`%s)"
               % ("yes" if diag_count else "**no**", diag_count,
                  ", `summary.txt` present" if has_summary else ""))
    out.append("- artifact upload (`%s`): **%s**"
               % (args.artifact_name, args.upload_outcome))
    present = [name for name in (
        "emulator-progress.txt", "emulator-trap.txt", "emulator-step.log",
        "emulator-sampler.txt", "emulator-stop-reason.txt", "emulator-report.md",
        "runner-state-before.txt", "runner-state.txt", "status.txt", "journey.txt",
        "relaunch.txt", "shrink.txt", "emulator-log-analysis.txt")
        if os.path.exists(os.path.join(root, name))]
    out.append("- files this report could read: %s"
               % (", ".join("`%s`" % n for n in present) if present else "_(none)_"))
    if diag_count:
        out.append("- diagnostics: %s" % ", ".join("`%s`" % n for n in diag_files[:14]))
    out.append("")
    out.append("The same report is the text of the `%s` check run; full logs stay in the "
               "run's artifact for details." % args.check_name)
    text = "\n".join(out) + "\n"
    if len(text.encode()) > MAX_REPORT_BYTES:
        text = text[:MAX_REPORT_BYTES] + "\n… [report trimmed]\n"
    return text


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-id", default=os.environ.get("GITHUB_RUN_ID", "?"))
    parser.add_argument("--run-attempt", default=os.environ.get("GITHUB_RUN_ATTEMPT", "?"))
    parser.add_argument("--job", default=os.environ.get("GITHUB_JOB", "android"))
    parser.add_argument("--sha", default=os.environ.get("GITHUB_SHA", "?"))
    parser.add_argument("--ref", default=os.environ.get("GITHUB_REF_NAME", "?"))
    parser.add_argument("--event", default=os.environ.get("GITHUB_EVENT_NAME", "push"))
    parser.add_argument("--step", action="append", default=[],
                        help="name=outcome, repeatable")
    parser.add_argument("--upload-outcome", default="unknown")
    parser.add_argument("--artifact-name", default="emulator-logs-attempt-?")
    parser.add_argument("--check-name", default="PyQuest emulator")
    parser.add_argument("--step-log", default="emulator-step.log")
    parser.add_argument("--out", default="emulator-report.md")
    parser.add_argument("--repo-root", default=".")
    args = parser.parse_args()
    text = report(args, args.repo_root)
    with open(os.path.join(args.repo_root, args.out), "w", encoding="utf-8") as handle:
        handle.write(text)
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if not summary_path:
        # Local runs still exercise the same path, one directory up.
        summary_path = os.path.join(args.repo_root, "..", "step-summary.md")
    try:
        with open(summary_path, "a", encoding="utf-8") as handle:
            handle.write(text)
    except OSError as error:
        print("could not write the step summary: %s" % error, file=sys.stderr)
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
