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

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from step_outcomes import (SKIPPED, UNKNOWN, classify, conclusion,   # noqa: E402
                          parse_steps)

REPO = os.environ.get("GITHUB_REPOSITORY", "Nthanhbadboy/PyQuest")
EMULATOR_STEP = "Emulator journey"   # the step that runs android-emulator-runner@v2
# The status keys ci/emulator_journey.sh writes, i.e. evidence that it ran.
JOURNEY_KEYS = frozenset({
    "device_ready_journey", "journey", "device_ready_relaunch",
    "install_regular_apk", "relaunch_screencap", "relaunch_screen_blank",
    "app_alive_after_relaunch", "device_ready_returning", "returning",
})
TAIL_LINES = 100            # the user-visible "last 100 relevant lines"
MAX_REPORT_BYTES = 60000    # stays well below the check-run text limit
PHASE_MARKER = "==> PHASE: "
ERROR_HINTS = re.compile(
    r"::error|FATAL:|DriverError|Unhandled exception|AndroidRuntime|"
    r"FATAL EXCEPTION|error:|Error:|Exception|FAILED|not found|refused|"
    r"timed out|TIMED OUT|disappeared|no longer")
SKIP_ERROR_LINES = re.compile(r"^\s*(phase markers|last \d+ lines|exit_code:|"
                              r"phase:|utc:|error hints|\[)")


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


def relaunch_evidence(root, limit=45):
    """The display/window/frame lines that explain the phase-2 screenshot.

    ci/emulator_journey.sh writes them while it captures
    `34_relaunch_real_app.png`; the file is small on purpose, so the report can
    print it in full and a black capture is explainable from the check page.
    """
    lines = read_lines(os.path.join(root, "emulator-relaunch-evidence.txt"))
    if not lines:
        return None
    if len(lines) > limit:
        lines = lines[:limit] + ["… [truncated - full file in the artifact]"]
    return lines


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


def root_cause(failed_steps, not_run, bad_keys, keys, trap, script_ran,
               emulator_step_present=True):
    """(markdown lines, blamed step) for the failure, from explicit outcomes only.

    The rule the report must follow: attribute a pre-script emulator setup
    failure only when the Emulator journey step itself failed *and* the journey
    script produced neither progress output nor its EXIT-trap file. An earlier
    failing step (APK build, runner state, ...) is named instead, and when the
    evidence does not establish a cause the report says exactly that.
    """
    if failed_steps:
        name, outcome = failed_steps[0]
        if name == EMULATOR_STEP and not script_ran:
            return [
                "**The `%s` step failed (outcome `%s`) before the journey script "
                "produced any output**: neither `emulator-progress.txt` nor "
                "`emulator-trap.txt` exists, and the script writes the trap file on "
                "every exit path." % (name, outcome),
                "So the failure happened inside "
                "`reactivecircus/android-emulator-runner@v2` before our script's first "
                "line, and the app tests never ran. Which command inside the action "
                "failed is not in the data this report can read - the action's own "
                "stdout is only in the job log. No specific SDK, AVD or emulator "
                "command is assumed here.",
            ], name
        if name == EMULATOR_STEP:
            return [
                "**The `%s` step failed (outcome `%s`) while the journey script was "
                "running**; the script's own record below says which phase it was in."
                % (name, outcome),
            ], name
        detail = ""
        if not script_ran and emulator_step_present:
            # only said when the job actually has an emulator step to talk about
            detail = (" The emulator step produced no output at all, which follows from "
                      "this earlier failure rather than from the emulator itself.")
        return [
            "**The earliest failed step is `%s` (outcome `%s`)**; every later step in "
            "this job depends on it.%s" % (name, outcome, detail),
        ], name
    if bad_keys or (trap.get("exit_code") and trap.get("exit_code") != "0"):
        phase = trap.get("phase") or "(phase not recorded)"
        code = trap.get("exit_code") or "(exit code not recorded)"
        keys_text = ", ".join("`%s=%s`" % (k, v) for k, v in bad_keys) \
            if bad_keys else "no phase key was recorded"
        lines = []
        if str(code) == "0":
            # A phase key can fail while the script still exits 0 (a drive that
            # reports test failures, or a frame that cannot show the app), so
            # "failed with exit code 0" must not be printed.
            lines.append("**A phase failed while the journey script ran to the "
                         "end (last phase: `%s`)**: %s." % (phase, keys_text))
        else:
            lines.append("**The workflow steps all succeeded; the journey script "
                         "itself failed during `%s` with exit code `%s`** (%s)."
                         % (phase, code, keys_text))
        if any(name == "relaunch_screen_blank" and value != "0"
               for name, value in bad_keys):
            lines.append(
                "The screenshot that is published as proof that the app renders "
                "after a normal launch "
                "(`docs/screenshots/34_relaunch_real_app.png`) is an all-black "
                "frame, so that proof is missing. The display, window and frame "
                "state recorded while it was captured is in `Screen and frame "
                "state at the relaunch capture` below.")
        return lines, None
    if not_run:
        return [
            "**No step reported a failure, but `%s` did not run.**"
            % ", ".join("`%s`" % name for name, _outcome in not_run),
        ], None
    return ["**Root cause not determined from available evidence.**"], None


def report(args, root):
    steps = parse_steps(args.step)      # same parser the verdict uses
    classification = classify(args.step, args.optional_step)
    all_steps = classification["failed"] + classification["not_run"] + \
        classification["ok"] + classification["unknown"] + \
        classification["optional_skipped"]
    emulator_outcome = dict(all_steps).get(EMULATOR_STEP, UNKNOWN)
    # a step list without the emulator step (the temporary selftest workflow)
    # must not be told anything about "the emulator step"
    emulator_step_present = any(name == EMULATOR_STEP for name, _o in all_steps)
    failed_steps = classification["failed"]
    not_run = classification["not_run"]
    unknown_steps = classification["unknown"]
    optional_skipped = classification["optional_skipped"]
    keys = status_keys(root)
    bad_keys = [(n, v) for n, v in keys if v != "0"]
    trap = trap_fields(root)
    progress = progress_facts(root)
    # `build_apk_debug` is written by the workflow's build step, not by the
    # journey script, so only the script's own keys count as "it ran".
    script_ran = bool(progress or trap) or any(
        name in JOURNEY_KEYS for name, _value in keys)
    diag_count, diag_files, has_summary = diagnostics(root)
    step_log = os.path.join(root, args.step_log)
    error_line, error_source = first_error([
        step_log,
        os.path.join(root, "emulator-progress.txt"),
        os.path.join(root, "emulator-stop-reason.txt"),
    ])
    out = []
    verdict, _reasons = conclusion(keys, args.step, args.optional_step)
    if verdict == "failure" or (trap.get("exit_code") and trap.get("exit_code") != "0"):
        causes, blamed = root_cause(failed_steps, not_run, bad_keys, keys, trap,
                                    script_ran, emulator_step_present)
    else:
        causes, blamed = ["**No failure to explain: every workflow step and every "
                          "phase key reports success.**"], None
    state = "failed" if verdict == "failure" else "passed"
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
    if not script_ran:
        out.append("- **no emulator script output at all**: `emulator-progress.txt` and "
                   "`emulator-trap.txt` are missing, so the journey script never reached "
                   "its first log line")
        if blamed == EMULATOR_STEP:
            out.append("- the `%s` step is the earliest failure, so this happened before "
                       "the journey script started - inside the emulator action, not in "
                       "the app tests" % EMULATOR_STEP)
        elif blamed:
            out.append("- the earliest failure is `%s`, so the missing emulator output "
                       "follows from that step; nothing here says the emulator itself "
                       "failed" % blamed)
    out.append("")

    # --- root cause ---------------------------------------------------------
    out.append("### Root cause")
    out.append("")
    out.extend(causes)
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
    if not_run:
        out.append("**Steps that did not run**: %s (skipped although the step is "
                   "not declared optional)"
                   % ", ".join("`%s`" % n for n, _o in not_run))
    if unknown_steps:
        out.append("**Steps with no reported outcome**: %s (the workflow wiring may be "
                   "wrong - the outcome expression resolved to nothing)"
                   % ", ".join("`%s`" % n for n, _o in unknown_steps))
    if optional_skipped:
        out.append("**Optional steps skipped (expected)**: %s"
                   % ", ".join("`%s`" % n for n, _o in optional_skipped))
    if keys:
        out.append("**Phase status keys**: %s"
                   % ", ".join("`%s=%s`" % (n, v) for n, v in keys))
    if bad_keys:
        out.append("")
        out.append("**Non-zero phases**: %s"
                   % ", ".join("`%s=%s`" % (n, v) for n, v in bad_keys))
    elif keys and not failed_steps and not not_run and not unknown_steps:
        out.append("")
        out.append("Every phase key is 0, so the app tests themselves passed.")
    if not [k for k in keys if k[0] in JOURNEY_KEYS]:
        out.append("")
        if emulator_outcome == SKIPPED:
            out.append("The `%s` step was **skipped**, so it wrote no phase key and "
                       "there is no phase exit code." % EMULATOR_STEP)
        else:
            out.append("The journey script recorded no phase status key at all, so "
                       "there is no phase exit code - see `Root cause` above.")
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

    # --- relaunch evidence --------------------------------------------------
    evidence = relaunch_evidence(root)
    if evidence:
        out.append("### Screen and frame state at the relaunch capture")
        out.append("")
        out.append("```")
        out.extend(trim(line) for line in evidence)
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
        "relaunch.txt", "shrink.txt", "emulator-log-analysis.txt",
        "emulator-relaunch-evidence.txt")
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
                        help="name=outcome, repeatable, in workflow order")
    parser.add_argument("--optional-step", action="append", default=[],
                        help="a step whose skipped outcome is expected")
    parser.add_argument("--upload-outcome", default="unknown")
    parser.add_argument("--artifact-name", default="emulator-logs-attempt-?")
    parser.add_argument("--check-name", default="PyQuest emulator")
    parser.add_argument("--step-log", default="emulator-step.log")
    parser.add_argument("--out", default="emulator-report.md",
                        help="report file, relative to --repo-root")
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
