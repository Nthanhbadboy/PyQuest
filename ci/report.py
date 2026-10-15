#!/usr/bin/env python3
"""Publish CI step results + logs as a GitHub check run.

Why: workflow logs live on blob storage that is not reachable from every
development sandbox, while check runs are readable through api.github.com.

Usage: report.py <check-name> <status-file> [<log-file> ...] \
           [--step Name=outcome ...] [--optional-step Name ...]
The status file contains lines "<step>=<exit-code>".

The conclusion comes from the phase status keys AND from the workflow's own step
outcomes (see ci/step_outcomes.py): run 38794903944 failed in the emulator step
with a status file that only said `build_apk_debug=0`, and a conclusion derived
from that file alone called the failed job a success.

The first log file is the emulator job's own report (emulator-report.md). It is
what somebody sees first on the check page, so it gets most of the text budget;
the remaining files share what is left. Markdown files are embedded as
markdown (no code fence), everything else as plain text.
"""
import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import step_outcomes                        # noqa: E402  (same directory)

MAX_TEXT = 64000


def read(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            return handle.read()
    except FileNotFoundError:
        return "(missing: %s)" % path


def trim(text, budget):
    if len(text) <= budget:
        return text
    head = budget // 3
    tail = budget - head - 40
    return text[:head] + "\n\n... [trimmed] ...\n\n" + text[-tail:]


def status_rows(status_file):
    """[(key, value), ...] from status.txt; empty when the file is missing."""
    statuses = []
    for line in read(status_file).splitlines():
        if "=" in line:
            step, code = line.split("=", 1)
            statuses.append((step.strip(), code.strip()))
    return statuses


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("check_name")
    parser.add_argument("status_file")
    parser.add_argument("logs", nargs="*")
    parser.add_argument("--step", action="append", default=[],
                        help="Name=outcome of a workflow step, in workflow order")
    parser.add_argument("--optional-step", action="append", default=[],
                        help="a step whose skipped outcome is expected")
    args = parser.parse_args()
    name, status_file, logs = args.check_name, args.status_file, args.logs

    status_file_missing = not os.path.exists(status_file)
    statuses = status_rows(status_file)
    verdict, reasons = step_outcomes.conclusion(
        statuses, args.step, args.optional_step,
        status_note=" (%s is missing)" % os.path.basename(status_file))
    conclusion = verdict
    labels = step_outcomes.failure_labels(statuses, args.step, args.optional_step)
    title = ("FAILED: " + ", ".join(labels)) if labels else "All steps passed"

    summary_lines = ["| phase key | exit |", "|---|---|"]
    summary_lines += ["| %s | %s |" % (s, c) for s, c in statuses]
    if status_file_missing:
        summary_lines.append("| _(status file missing)_ | %s |"
                             % os.path.basename(status_file))
    if args.step:
        summary_lines += ["", "| workflow step | outcome |", "|---|---|"]
        summary_lines += ["| %s | %s |" % (step, outcome)
                          for step, outcome in step_outcomes.parse_steps(args.step)]
    if reasons:
        summary_lines += ["", "**Why not success**: " + "; ".join(reasons)]

    # Careful: the loop variable must not be called `name`, that would shadow
    # the check-run name below (it did once; the check run came out named after
    # the last log file).
    marked = [(path, os.path.basename(path)) for path in logs]
    primary = max(20000, int(MAX_TEXT * 0.6))
    rest = max(1, len(marked) - 1)
    budgets = ([primary] if marked else []) + [
        max(2000, (MAX_TEXT - primary) // rest) for _ in marked[1:]]
    sections = []
    for (path, base), budget in zip(marked, budgets):
        body = trim(read(path), budget - 200)
        if base.endswith(".md"):
            sections.append(body.rstrip())
        else:
            sections.append("### %s\n```\n%s\n```" % (base, body))
    text = trim("\n\n---\n\n".join(sections), MAX_TEXT)

    payload = {
        "name": name,           # the workflow passes exactly "PyQuest emulator"
        "head_sha": os.environ["GITHUB_SHA"],
        "status": "completed",
        "conclusion": conclusion,
        "output": {
            "title": title[:200],
            "summary": "\n".join(summary_lines),
            "text": text,
        },
    }
    with open("/tmp/check_payload.json", "w", encoding="utf-8") as handle:
        json.dump(payload, handle)
    repo = os.environ["GITHUB_REPOSITORY"]
    subprocess.run(
        ["gh", "api", "repos/%s/check-runs" % repo, "--method", "POST",
         "--input", "/tmp/check_payload.json", "--silent"],
        check=False,
    )
    print(title)


if __name__ == "__main__":
    main()
