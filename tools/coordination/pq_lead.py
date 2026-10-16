#!/usr/bin/env python3
"""Lead loop for the PyQuest code branch — watch the design branch, queue work.

What it really does
-------------------
* ``fetch``   — fetch the design branch, compare against the last revision this
  lead processed, and when something changed: read the task header, list the
  diff, and drop an actionable note in the state dir (``inbox/``).
* ``status``  — print the contract state: design SHA/revision/task status, the
  three authorization scopes, our own branch tip, whether our ACK is published,
  and CI on that tip (needs ``gh``; optional).
* ``ack``     — record that a *specific* design commit was processed, refusing
  anything that is not an ancestor of the fetched design branch or has no
  readable task file, so a revision can never be marked read by accident.
* ``brief``   — print a work order together with a gate verdict for its scope.
* ``watch``   — repeat ``fetch`` on an interval, with bounded failure handling.

What it does NOT do — deliberately, so nobody is misled:
* it never commits, pushes, or touches the working tree; state lives outside
  the repository (default ``~/.pq-lead``);
* it cannot start an agent. Nothing here wakes a model: a new implementation
  pass happens when a session (or a real runner with model access) runs
  ``status`` and takes a queued brief. Detecting a revision is not the same as
  acting on it.

Gates are fail-closed: an authorization flag only counts when it says exactly
``yes``. ``yesterday``, ``no``, ``true`` or a missing field never opens a gate.

Stdlib only. Exit codes: 0 ok, 2 a fetch/git/state problem that could not be
handled, 3 the lock is held by another writer.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from contextlib import contextmanager
from datetime import datetime, timezone

REPO = os.environ.get('PQ_LEAD_REPO') or os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
DESIGN_BRANCH = os.environ.get('PQ_LEAD_DESIGN_BRANCH', 'arena/00838eb9-pyquest')
CODE_BRANCH = os.environ.get('PQ_LEAD_CODE_BRANCH', 'arena/b813b575-pyquest')
DESIGN_TASK = 'docs/design/coordination/tasks/PQD-001.md'
CODE_ACK = 'docs/implementation/coordination/tasks/PQD-001.md'
GIT_TIMEOUT = 120
LOCK_STALE_SECONDS = 900

# The header fields a design task may declare. Order matters for display.
SCOPES = ('runtime', 'test', 'coordination')
FIELDS = (
    'revision',
    'status',
    'design_branch',
    'intended_code_branch',
    'next_actor',
    'code_ack',
    'art_approval',
    'runtime_change_authorized_by_this_revision',
    'test_change_authorized_by_this_revision',
    'coordination_change_authorized_by_this_revision',
)


class LeadError(RuntimeError):
    pass


class LockHeld(LeadError):
    """Another process is mid-way through a read-modify-write of the state."""


def utcnow() -> str:
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')


# ---------------------------------------------------------------- git helpers


def git(*args, timeout: int = GIT_TIMEOUT, check: bool = True) -> subprocess.CompletedProcess:
    try:
        proc = subprocess.run(('git', '-C', REPO, *args), capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as err:
        raise LeadError(f'git {" ".join(args)} timed out after {timeout}s') from err
    except OSError as err:  # git missing, repo unreadable
        raise LeadError(f'git {" ".join(args)} could not run: {err}') from err
    if check and proc.returncode != 0:
        raise LeadError(f'git {" ".join(args)} -> {proc.returncode}: {(proc.stderr or "").strip()[:200]}')
    return proc


def rev_parse(rev: str, *, verify: bool = False) -> str:
    args = ('rev-parse', '--verify') if verify else ('rev-parse',)
    proc = git(*args, rev, check=False)
    if proc.returncode != 0 or not proc.stdout.strip():
        raise LeadError(f'not a usable revision: {rev!r}')
    return proc.stdout.strip().splitlines()[0]


def is_ancestor(sha: str, tip: str) -> bool | None:
    """True/false from ``merge-base --is-ancestor``; None when git could not answer."""
    proc = git('merge-base', '--is-ancestor', sha, tip, check=False)
    if proc.returncode == 0:
        return True
    if proc.returncode == 1 and not (proc.stderr or '').strip():
        return False
    return None


def read_file(sha: str, path: str) -> str:
    proc = git('show', f'{sha}:{path}', check=False)
    return proc.stdout if proc.returncode == 0 else ''


# ---------------------------------------------------------------- task header


def parse_task(md: str) -> dict:
    """Pull the `- key: `value`` header lines out of a task file. Nothing invented."""
    fields = {}
    for key in FIELDS:
        m = re.search(rf'^-\s+`?{re.escape(key)}`?\s*:\s*(.+)$', md, re.MULTILINE)
        if m:
            value = m.group(1).strip().strip('`').strip('*').strip().rstrip('.').strip('`*').strip()
            fields[key] = value
    return fields


def scope_flag(fields: dict, scope: str) -> tuple[str, str]:
    """Normalize one authorization flag -> (state, human note).

    state is 'yes' only for an exact yes; 'no' for an exact no; 'missing' when
    the task never declared the field; 'invalid:<raw>' for anything else, which
    is treated as closed.
    """
    key = f'{scope}_change_authorized_by_this_revision'
    if key not in fields:
        return 'missing', f'{key} not declared'
    raw = fields[key]
    lowered = raw.strip().lower().strip('`*').strip()
    if lowered == 'yes':
        return 'yes', f'{key}: yes'
    if lowered == 'no':
        return 'no', f'{key}: no'
    return f'invalid:{raw}', f'{key}={raw!r} is not exactly yes/no -> treated as no'


def classify(fields: dict) -> tuple[str, str, dict]:
    """(verdict, why, scopes) from a design task header. Fail-closed throughout."""
    if not fields:
        return 'NO_TASK_FILE', 'task file not found or unreadable at that design SHA', {}
    status = (fields.get('status') or '').strip().upper() or 'UNKNOWN'
    scopes = {}
    notes = []
    for scope in SCOPES:
        state, note = scope_flag(fields, scope)
        scopes[scope] = state
        notes.append(note)
    runtime = scopes['runtime']
    if status == 'READY_FOR_CODE':
        if runtime == 'yes':
            return 'READY_FOR_CODE', 'status=READY_FOR_CODE and runtime change authorized', scopes
        return 'GATE_CONFLICT', f'status=READY_FOR_CODE but runtime authorization is {runtime} -> no app edits', scopes
    if runtime == 'yes':
        return 'GATE_CONFLICT', f'runtime authorized but status={status} -> stop and ask design', scopes
    if status == 'CHANGES_REQUESTED':
        return 'CHANGES_REQUESTED', 'design asked for changes on the code side', scopes
    if status == 'ACCEPTED':
        return 'ACCEPTED', 'design accepted the last submission', scopes
    if status == 'BLOCKED':
        return 'BLOCKED_BY_DESIGN', 'design status=BLOCKED', scopes
    return 'INTAKE_ONLY', f'status={status} -> read, verify, ACK; no app edits', scopes


# ------------------------------------------------------------------- own state


def repo_dir(args) -> str:
    return getattr(args, 'repo', None) or REPO


def state_dir(args) -> str:
    path = getattr(args, 'state_dir', None) or os.environ.get('PQ_LEAD_STATE') or os.path.expanduser('~/.pq-lead')
    os.makedirs(os.path.join(path, 'inbox'), exist_ok=True)
    return path


def state_path(path: str) -> str:
    return os.path.join(path, 'state.json')


def load_state(path: str) -> dict:
    try:
        with open(state_path(path), encoding='utf-8') as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return {'processed_design_sha': None, 'processed_revision': None, 'queue': [], 'events': []}
    data.setdefault('queue', [])
    data.setdefault('events', [])
    return data


def save_state(path: str, state: dict) -> None:
    state['updated_at'] = utcnow()
    tmp = state_path(path) + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as handle:
        json.dump(state, handle, indent=2, ensure_ascii=False, sort_keys=True)
        handle.write('\n')
    os.replace(tmp, state_path(path))


@contextmanager
def state_lock(path: str, *, wait_seconds: int = 0):
    """Single writer at a time: os.replace alone does not protect read-modify-write."""
    lock = os.path.join(path, 'state.lock')
    deadline = time.time() + wait_seconds
    while True:
        try:
            handle = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        except FileExistsError:
            try:
                age = time.time() - os.path.getmtime(lock)
            except OSError:
                age = 0
            if age > LOCK_STALE_SECONDS:
                try:
                    os.remove(lock)
                    print(f'break: stale lock ({int(age)}s) at {lock}')
                    continue
                except OSError:
                    pass
            if time.time() >= deadline:
                raise LockHeld(f'state lock held by another writer: {lock} (wait with --wait, or stop the watcher)')
            time.sleep(0.25)
            continue
        try:
            os.write(handle, f'{os.getpid()} {utcnow()}\n'.encode())
            yield
        finally:
            os.close(handle)
            try:
                os.remove(lock)
            except OSError:
                pass
        return


def log_line(path: str, text: str) -> None:
    line = f'{utcnow()} {text}'
    print(line, flush=True)
    try:
        with open(os.path.join(path, 'lead.log'), 'a', encoding='utf-8') as handle:
            handle.write(line + '\n')
    except OSError:
        pass


# ---------------------------------------------------------------- subcommands


def design_tip() -> str:
    return rev_parse(f'origin/{DESIGN_BRANCH}')


def code_tip() -> str:
    return rev_parse(f'origin/{CODE_BRANCH}')


def describe(sha: str, since: str | None) -> tuple[str, dict]:
    """Summary of a design commit plus its parsed task header."""
    lines = [f'design commit: {sha}', f'task header ({DESIGN_TASK}):']
    fields = parse_task(read_file(sha, DESIGN_TASK))
    if not fields:
        lines.append('  (task file not readable at that SHA)')
    for key in FIELDS:
        if key in fields:
            lines.append(f'  {key}: {fields[key]}')
    if since and since != sha:
        names = git('diff', '--name-status', since, sha, check=False)
        stat = git('diff', '--stat', since, sha, check=False).stdout.splitlines()
        lines += ['', f'diff {since[:7]} -> {sha[:7]}  ({stat[-1].strip() if stat else "no files listed"})']
        lines += ['  ' + row for row in names.stdout.splitlines()]
    elif not since:
        lines += ['', 'no previously processed revision recorded yet']
    else:
        lines += ['', 'no new commit since the last processed revision']
    return '\n'.join(lines), fields


def write_inbox(path: str, sha: str, body: str) -> str:
    stamp = datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S')
    file_path = os.path.join(path, 'inbox', f'{stamp}-{sha[:7]}.md')
    with open(file_path, 'w', encoding='utf-8') as handle:
        handle.write(body)
    return file_path


def fetch_design() -> str:
    """Fetch only the design branch ref, then read the tip we now actually have."""
    git('fetch', '-q', 'origin', f'refs/heads/{DESIGN_BRANCH}:refs/remotes/origin/{DESIGN_BRANCH}')
    return design_tip()


def do_fetch(args) -> int:
    path = state_dir(args)
    try:
        with state_lock(path, wait_seconds=getattr(args, 'wait', 10)):
            state = load_state(path)
            try:
                fetch_design()
                sha = design_tip()
            except LeadError as err:
                log_line(path, f'FETCH_FAIL {err}')
                state['last_check'] = utcnow()
                state['last_error'] = str(err)
                save_state(path, state)
                return 2
            prev = state.get('processed_design_sha')
            text, fields = describe(sha, prev)
            verdict, why, scopes = classify(fields)
            state.pop('last_error', None)
            state['last_check'] = utcnow()
            state['fetched_design_sha'] = sha
            state['design'] = {'sha': sha, 'fields': fields, 'verdict': verdict, 'scopes': scopes, 'observed_at': utcnow()}
            if sha == prev:
                log_line(path, f'NO_CHANGE design={sha[:7]} rev={fields.get("revision")} status={fields.get("status")}')
                save_state(path, state)
                print(text)
                return 0
            files = [row for row in git('diff', '--name-only', prev, sha, check=False).stdout.splitlines() if row] if prev else []
            relevant = [f for f in files if f.startswith(('docs/design/coordination/', 'docs/design/village-kit/',
                                                          'docs/design/AI_IMPLEMENTATION_HANDOFF.md',
                                                          'docs/design/FULL_APP_REDESIGN_CHARTER.md',
                                                          'docs/design/CROSS_BRANCH_COLLABORATION.md',
                                                          'tools/design/'))]
            log_line(path, f'NEW_DESIGN {prev[:7] if prev else "-"} -> {sha[:7]} files={len(files)} '
                           f'relevant={len(relevant)} {verdict} scopes={scopes}')
            body = '\n'.join([
                f'# Design revision detected at {utcnow()}',
                '',
                text,
                '',
                f'verdict: **{verdict}** — {why}',
                'authorization scopes (exact ``yes`` only): '
                + ', '.join(f'{name}={scopes.get(name, "missing")}' for name in SCOPES),
                f'changed files: {len(files)} ({len(relevant)} inside the coordination/asset scope)',
                '',
                '## Next actor: a code-agent session (this tool cannot act by itself)',
                '',
                '1. `python3 tools/coordination/pq_lead.py status`',
                f'2. Read the design task file at the pinned SHA: `git show {sha}:{DESIGN_TASK}`',
                f'3. Read the review file if the task points at one (`docs/design/coordination/reviews/`).',
                '4. Apply the gate per scope: app/lib and assets only when runtime=yes *and* the task',
                '   says READY_FOR_CODE; test-only and coordination work follow their own flags.',
                '5. Take a work order: `python3 tools/coordination/pq_lead.py brief <PQC-id>`',
                f'6. Mark this exact SHA processed: `python3 tools/coordination/pq_lead.py ack {sha}`',
                '',
            ])
            inbox_file = write_inbox(path, sha, body)
            queue = [item for item in state['queue'] if item.get('sha') != sha]
            queue.append({'sha': sha, 'detected_at': utcnow(), 'verdict': verdict, 'scopes': scopes, 'inbox': inbox_file})
            state['queue'] = queue
            state['events'].append({'at': utcnow(), 'type': 'new_design', 'sha': sha, 'verdict': verdict, 'scopes': scopes})
            save_state(path, state)
            print(body)
            return 0
    except LockHeld as err:
        log_line(path, f'LOCKED {err}')
        print(str(err), file=sys.stderr)
        return 3


def ci_on(sha: str) -> str:
    try:
        proc = subprocess.run(('gh', 'run', 'list', '--branch', CODE_BRANCH, '--limit', '3',
                               '--json', 'headSha,status,conclusion,number'),
                              capture_output=True, text=True, timeout=60)
        if proc.returncode != 0:
            return f'(gh unavailable: {(proc.stderr or "").strip()[:80]})'
        for run in json.loads(proc.stdout or '[]'):
            if run.get('headSha', '').startswith(sha[:7]):
                return f"run #{run.get('number')} {run.get('status')}/{run.get('conclusion') or '-'}"
        return '(no run found for this commit)'
    except Exception as err:  # noqa: BLE001 - reporting only, never fatal
        return f'(gh error: {err})'


def do_status(args) -> int:
    path = state_dir(args)
    try:
        with state_lock(path, wait_seconds=getattr(args, 'wait', 5)):
            state = load_state(path)
            stale = 'verified'
            if not getattr(args, 'offline', False):
                try:
                    fetch_design()
                    git('fetch', '-q', 'origin', f'refs/heads/{CODE_BRANCH}:refs/remotes/origin/{CODE_BRANCH}')
                    state['fetched_design_sha'] = design_tip()
                    state['last_check'] = utcnow()
                    sha = state['fetched_design_sha']
                    fields = parse_task(read_file(sha, DESIGN_TASK))
                    verdict, why, scopes = classify(fields)
                    state['design'] = {'sha': sha, 'fields': fields, 'verdict': verdict, 'scopes': scopes,
                                       'observed_at': utcnow()}
                    save_state(path, state)
                except LeadError as err:
                    stale = f'STALE/UNVERIFIED ({err})'
                    state['last_error'] = str(err)
                    save_state(path, state)
            else:
                stale = 'STALE/UNVERIFIED (--offline; observation from ' + str(state.get('last_check')) + ')'
            design = state.get('design') or {}
            fields = design.get('fields') or {}
            scopes = design.get('scopes') or {}
            try:
                code_sha = code_tip()
                ack_present = git('cat-file', '-e', f'{code_sha}:{CODE_ACK}', check=False).returncode == 0
            except LeadError as err:
                code_sha, ack_present = f'(unreadable: {err})', False
            processed = state.get('processed_design_sha')
            unprocessed = design.get('sha') and design.get('sha') != processed
            print('## Lead status')
            print(f'- checked at:            {state.get("last_check") or "never"}  [{stale}]')
            print(f'- code branch:           {CODE_BRANCH}')
            print(f'- code tip (published):  {code_sha}')
            print(f'- code CI on tip:        {ci_on(code_sha)}')
            print(f'- our ACK on tip:        {CODE_ACK if ack_present else "MISSING"}')
            print(f'- design processed sha:  {processed or "never"}   rev {state.get("processed_revision") or "?"}')
            print(f'- design tip fetched:    {design.get("sha") or "never fetched"}')
            print(f'- design task status:    {fields.get("status") or "?"} (revision {fields.get("revision") or "?"})')
            print('- authorized scopes:       ' + ', '.join(f'{name}={scopes.get(name, "missing")}' for name in SCOPES))
            print(f'- art approval:          {fields.get("art_approval") or "?"}')
            print(f'- gate verdict:          {design.get("verdict") or "?"}')
            print(f'- next actor (per doc):  {fields.get("next_actor") or "?"}')
            if state.get('last_error'):
                print(f'- last error:            {state["last_error"]}')
            queue = state.get('queue') or []
            print(f'- unprocessed notes:     {len(queue)}')
            for item in queue[-3:]:
                print(f'    {item["sha"][:7]} {item["verdict"]} -> {item["inbox"]}')
            if unprocessed:
                print('- ACTION: the fetched design tip is newer than the processed revision; read the inbox note.')
            else:
                print('- nothing new from design; WAITING_FOR_PEER unless a work order is unblocked.')
            return 0
    except LockHeld as err:
        print(str(err), file=sys.stderr)
        return 3


def do_ack(args) -> int:
    path = state_dir(args)
    arg = (args.sha or '').strip()
    try:
        with state_lock(path, wait_seconds=getattr(args, 'wait', 10)):
            try:
                tip = design_tip()
            except LeadError as err:
                print(f'design branch not fetched yet: {err}', file=sys.stderr)
                return 2
            if not arg:
                state = load_state(path)
                observed = state.get('fetched_design_sha') or state.get('design', {}).get('sha')
                if not observed:
                    print('no sha given and nothing fetched this run: pass the SHA you actually read',
                          file=sys.stderr)
                    return 2
                arg = observed
                print(f'no sha given -> using the design tip just fetched: {arg}')
            try:
                sha = rev_parse(f'{arg}^{{commit}}', verify=True)
            except LeadError as err:
                print(f'rejecting ack: {err}', file=sys.stderr)
                return 2
            ancestor = is_ancestor(sha, tip)
            if ancestor is None:
                print(f'rejecting ack: cannot verify {sha[:7]} is on {DESIGN_BRANCH} (shallow clone? '
                      f'git fetch --unshallow, or ack the exact tip you read)', file=sys.stderr)
                return 2
            if ancestor is False:
                print(f'rejecting ack: {sha} is not in the fetched {DESIGN_BRANCH} history', file=sys.stderr)
                return 2
            fields = parse_task(read_file(sha, DESIGN_TASK))
            if not fields:
                print(f'rejecting ack: no readable task file at {sha[:7]}:{DESIGN_TASK}', file=sys.stderr)
                return 2
            state = load_state(path)
            state['processed_design_sha'] = sha
            state['processed_revision'] = fields.get('revision')
            state['processed_scopes'] = classify(fields)[2]
            state['queue'] = [item for item in state['queue'] if item.get('sha') != sha]
            state['events'].append({'at': utcnow(), 'type': 'ack', 'sha': sha, 'revision': state['processed_revision']})
            save_state(path, state)
            log_line(path, f'ACK design={sha[:7]} revision={state["processed_revision"]}')
            print(f'marked processed: design {sha} revision {state["processed_revision"]}')
            return 0
    except LockHeld as err:
        print(str(err), file=sys.stderr)
        return 3


def do_brief(args) -> int:
    root = os.path.join(repo_dir(args), 'docs', 'implementation', 'coordination')
    if args.task_id.upper() == 'BOARD':
        path = os.path.join(root, 'TASK_BOARD.md')
    else:
        path = os.path.join(root, 'tasks', f'{args.task_id}.md')
    if not os.path.exists(path):
        print(f'no work order at {path}  (BOARD prints the index: `brief BOARD`)')
        return 2
    with open(path, encoding='utf-8') as handle:
        body = handle.read()
    m = re.search(r'^-\s*`?scope`?\s*:\s*`?([A-Za-z_]+)`?\s*$', body, re.MULTILINE)
    scope = m.group(1) if m else None
    state = load_state(state_dir(args))
    design = state.get('design') or {}
    scopes = design.get('scopes') or {}
    if scope is None:
        # An undeclared scope must never default to something authorized.
        allowed = False
        gate = ('UNDECLARED - blocked: add a `- scope: runtime|test|coordination` line to the work order')
    elif scope not in SCOPES:
        allowed = False
        gate = f'UNKNOWN scope={scope!r} - blocked'
    elif scope == 'runtime':
        allowed = scopes.get('runtime') == 'yes' and design.get('verdict') == 'READY_FOR_CODE'
        gate = f'{("ALLOWED" if allowed else "BLOCKED")} for scope=runtime'
    else:
        allowed = scopes.get(scope) == 'yes'
        gate = f'{("ALLOWED" if allowed else "BLOCKED")} for scope={scope}'
    gate += ' (design scopes: ' + ', '.join(f'{name}={scopes.get(name, "unobserved")}' for name in SCOPES) + ')'
    print(f'--- {os.path.relpath(path, REPO)} ---')
    print(f'gate: {gate}')
    if not allowed:
        print('DO NOT START: return BLOCKED with the reason; do not widen scope on your own.\n')
        if scope is None:
            print('(this order is also missing its `- scope:` line, so the gate cannot be evaluated)')
    else:
        print('')
    print(body)
    return 0 if allowed else 1


def do_watch(args) -> int:
    if args.interval < 5:
        print('--interval must be >= 5 seconds (avoid hammering the network)', file=sys.stderr)
        return 2
    if args.max_minutes <= 0:
        print('--max-minutes must be > 0', file=sys.stderr)
        return 2
    if args.max_failures <= 0:
        print('--max-failures must be > 0', file=sys.stderr)
        return 2
    path = state_dir(args)
    stop_file = os.path.join(path, 'STOP')
    deadline = time.time() + args.max_minutes * 60
    log_line(path, f'WATCH start interval={args.interval}s max={args.max_minutes}min stop={stop_file}')
    misses = 0
    while time.time() < deadline:
        if os.path.exists(stop_file):
            log_line(path, 'WATCH stop: STOP file found')
            try:
                os.remove(stop_file)
            except OSError:
                pass
            return 0
        try:
            rc = do_fetch(argparse.Namespace(**vars(args)))
        except Exception as err:  # noqa: BLE001 - one bad cycle must not kill the loop
            rc = 2
            log_line(path, f'cycle raised: {err}')
        if rc == 0:
            misses = 0
        else:
            misses += 1
            log_line(path, f'cycle returned {rc} ({misses}/{args.max_failures})')
            if misses >= args.max_failures:
                log_line(path, 'GIVE_UP after the configured failure budget; rerun `watch` when the network is back')
                return 2
        remaining = deadline - time.time()
        if remaining <= 0:
            break
        time.sleep(min(args.interval, remaining))
    log_line(path, 'WATCH stop: max lifetime reached. This tool never wakes an agent by itself.')
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--state-dir', help='default ~/.pq-lead (outside the repo on purpose)')
    parser.add_argument('--repo', help='repository checkout to read (default: the one holding this script)')
    parser.add_argument('--wait', type=int, default=10, help='seconds to wait for the state lock')
    sub = parser.add_subparsers(dest='cmd', required=True)
    sub.add_parser('fetch', help='fetch design, queue anything new')
    status = sub.add_parser('status', help='print the contract state')
    status.add_argument('--offline', action='store_true', help='do not touch the network; the report says UNVERIFIED')
    ack = sub.add_parser('ack', help='record that a specific design revision was processed')
    ack.add_argument('sha', nargs='?', default='')
    brief = sub.add_parser('brief', help='print a work order plus a gate verdict for its scope')
    brief.add_argument('task_id')
    watch = sub.add_parser('watch', help='poll the design branch (needs a live sandbox)')
    watch.add_argument('--interval', type=int, default=120)
    watch.add_argument('--max-minutes', type=int, default=480)
    watch.add_argument('--max-failures', type=int, default=5)
    args = parser.parse_args(argv)
    handlers = {'fetch': do_fetch, 'status': do_status, 'ack': do_ack, 'brief': do_brief, 'watch': do_watch}
    try:
        return handlers[args.cmd](args)
    except LeadError as err:
        print(str(err), file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
