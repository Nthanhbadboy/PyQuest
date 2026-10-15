#!/usr/bin/env python3
"""Publish CI step results + logs as a GitHub check run.

Why: workflow logs live on blob storage that is not reachable from every
development sandbox, while check runs are readable through api.github.com.

Usage: report.py <check-name> <status-file> [<log-file> ...]
The status file contains lines "<step>=<exit-code>".

The first log file is the emulator job's own report (emulator-report.md). It is
what somebody sees first on the check page, so it gets most of the text budget;
the remaining files share what is left. Markdown files are embedded as
markdown (no code fence), everything else as plain text.
"""
import json
import os
import subprocess
import sys

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


def main():
    name, status_file, *logs = sys.argv[1:]
    statuses = []
    for line in read(status_file).splitlines():
        if "=" in line:
            step, code = line.split("=", 1)
            statuses.append((step.strip(), code.strip()))
    failed = [s for s, c in statuses if c != "0"]
    conclusion = "failure" if failed or not statuses else "success"
    summary_lines = ["| step | exit |", "|---|---|"]
    summary_lines += ["| %s | %s |" % (s, c) for s, c in statuses]
    title = ("FAILED: " + ", ".join(failed)) if failed else "All steps passed"

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
        "name": name,
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
