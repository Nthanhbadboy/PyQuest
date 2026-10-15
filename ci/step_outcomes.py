#!/usr/bin/env python3
"""Shared step-outcome policy for the two CI report writers.

`ci/report.py` decides the custom check run's conclusion and `ci/job_summary.py`
decides which step the report blames. Both must agree on what a step outcome
means, so the outcome sets and the verdict rule live here instead of being
duplicated with a chance to drift apart.

Why this exists at all: run 38794903944 failed in the emulator step after 73 s
while `status.txt` held only `build_apk_debug=0`, because the journey script
never started. A conclusion derived from `status.txt` alone therefore said
"success" for a failed job. The verdict below needs the workflow's own step
outcomes as well.

GitHub supplies step outcomes through `${{ steps.<id>.outcome }}`; the values
the runner produces are `success`, `failure`, `cancelled` and `skipped`
(actions/runner `ActionResult`). The expression renders as an empty string when
the id does not exist in the job, which is a workflow wiring bug rather than a
result, so it is reported as UNKNOWN and never silently treated as a pass.
"""

FAILED_OUTCOMES = frozenset({
    "failure", "cancelled", "timed_out", "action_required", "startup_failure",
    "stale",
})
OK_OUTCOMES = frozenset({"success", "neutral"})
SKIPPED = "skipped"
UNKNOWN = "unknown"


def parse_steps(entries):
    """['Name=outcome', ...] -> [('Name', 'outcome'), ...] in the given order.

    The order of the arguments is the workflow's step order, and that order is
    what makes "the earliest failed step" meaningful.
    """
    steps = []
    for entry in entries or []:
        name, sep, outcome = entry.rpartition("=")
        if not sep:                      # bare name: no outcome reported
            name, outcome = entry, ""
        steps.append((name.strip(), (outcome.strip() or UNKNOWN)))
    return steps


def classify(entries, optional=None):
    """Sort the outcomes into failed / not_run / optional_skipped / ok / unknown.

    `optional` names the steps whose *skipped* outcome the workflow expects
    (best-effort steps). A skipped step outside that set did not run when it
    should have, which is not a success.
    """
    optional = set(optional or [])
    result = {"failed": [], "not_run": [], "optional_skipped": [], "ok": [],
              "unknown": []}
    for name, outcome in parse_steps(entries):
        entry = (name, outcome)
        if outcome in FAILED_OUTCOMES:
            result["failed"].append(entry)
        elif outcome == SKIPPED:
            result["optional_skipped" if name in optional else "not_run"].append(entry)
        elif outcome in OK_OUTCOMES:
            result["ok"].append(entry)
        else:
            result["unknown"].append(entry)
    return result


def conclusion(statuses=None, entries=None, optional=None, status_note=""):
    """('success'|'failure', [reasons]) from the phase status keys AND the steps.

    `statuses` is the parsed content of status.txt as [(key, value), ...] and
    `entries` the workflow step outcomes as ['Name=outcome', ...]. A failure is
    reported for a non-zero phase key, a step that failed, a step that was
    skipped although it is not optional, a step whose outcome is missing, or
    when nothing at all proves the run succeeded.
    """
    result = classify(entries, optional)
    reasons = ["phase key %s=%s" % (name, code) for name, code in statuses or []
               if code != "0"]
    reasons += ["step '%s' ended with '%s'" % (name, outcome)
                for name, outcome in result["failed"]]
    reasons += ["step '%s' reported no outcome (the workflow wiring may be wrong)"
                % name for name, _outcome in result["unknown"]]
    reasons += ["step '%s' was skipped although it is not optional" % name
                for name, _outcome in result["not_run"]]
    if not reasons and not (statuses or result["ok"] or result["optional_skipped"]):
        reasons.append("no step outcome and no phase status key records a success"
                       + status_note)
    return ("failure" if reasons else "success"), reasons


def failure_labels(statuses=None, entries=None, optional=None):
    """Short labels for the check-run title: ['journey=143', 'Build (failure)']."""
    result = classify(entries, optional)
    labels = ["%s=%s" % (name, code) for name, code in statuses or [] if code != "0"]
    labels += ["%s (%s)" % (name, outcome) for name, outcome in result["failed"]]
    labels += ["%s (no outcome)" % name for name, _outcome in result["unknown"]]
    labels += ["%s (skipped)" % name for name, _outcome in result["not_run"]]
    return labels
