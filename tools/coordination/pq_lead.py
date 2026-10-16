#!/usr/bin/env python3
"""Lead loop for the PyQuest code branch — watch the design branch, queue work.

What it really does
-------------------
* ``fetch``   — fetch the design branch, compare against the last revision this
  lead processed, and when something changed: read the task header, list the
  diff, and drop an actionable note in the state dir (``inbox/``).
* ``status``  — print the current contract state: design SHA/revision/task
  status, whether runtime changes are authorized, our own branch tip, whether
  our ACK is published, and CI on that tip (needs ``gh``; optional).
* ``brief``   — print a work order from ``TASK_BOARD.md`` so it can be handed
  to another agent/model session.
* ``watch``   — repeat ``fetch`` on an interval and keep a heartbeat log.

What it does NOT do — deliberately, so nobody is misled:
* it never commits, pushes, or touches the working tree; state lives outside
  the repository (default ``~/.pq-lead``);
* it cannot start an agent. Nothing here wakes a model: a new implementation
  pass happens when a session (or a real runner with model access) runs
  ``status`` and takes a queued brief. Detecting a revision is not the same as
  acting on it.

Stdlib only. Exit codes: 0 ok, 2 git/gh failure that could not be handled.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timezone

REPO = os.environ.get('PQ_LEAD_REPO') or os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
DESIGN_BRANCH = 'arena/00838eb9-pyquest'
CODE_BRANCH = 'arena/b813b575-pyquest'
DESIGN_TASK = 'docs/design/coordination/tasks/PQD-001.md'
CODE_ACK = 'docs/implementation/coordination/tasks/PQD-001.md'
FIELDS = (
    'revision',
    'status',
    'design_branch',
    'intended_code_branch',
    'next_actor',
    'code_ack',
    'runtime_change_authorized_by_this_revision',
)


def utcnow() -> str:
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')


def state_dir(args) -> str:
    path = args.state_dir or os.environ.get('PQ_LEAD_STATE') or os.path.expanduser('~/.pq-lead')
    os.makedirs(os.path.join(path, 'inbox'), exist_ok=True)
    return path


def state_path(path: str) -> str:
    return os.path.join(path, 'state.json')


def load_state(path: str) -> dict:
    try:
        with open(state_path(path), encoding='utf-8') as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return {'processed_design_sha': None, 'processed_revision': None, 'queue': [], 'events': []}


def save_state(path: str, state: dict) -> None:
    state['updated_at'] = utcnow()
    tmp = state_path(path) + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as handle:
        json.dump(state, handle, indent=2, ensure_ascii=False, sort_keys=True)
        handle.write('\n')
    os.replace(tmp, state_path(path))


def log_line(path: str, text: str) -> None:
    line = f'{utcnow()} {text}'
    print(line, flush=True)
    try:
        with open(os.path.join(path, 'lead.log'), 'a', encoding='utf-8') as handle:
            handle.write(line + '\n')
    except OSError:
        pass


def git(*args, check: bool = True) -> str:
    proc = subprocess.run(('git', '-C', REPO, *args), capture_output=True, text=True)
    if check and proc.returncode != 0:
        raise RuntimeError(f'git {" ".join(args)} -> {proc.returncode}: {proc.stderr.strip()[:200]}')
    return proc.stdout.strip()


def design_ref() -> str:
    return f'refs/heads/{DESIGN_BRANCH}:refs/remotes/origin/{DESIGN_BRANCH}'


def code_ref() -> str:
    return f'refs/heads/{CODE_BRANCH}:refs/remotes/origin/{CODE_BRANCH}'


def parse_task(md: str) -> dict:
    """Pull the `- key: `value`` header out of a task file. Only what is there."""
    fields = {}
    for key in FIELDS:
        m = re.search(rf'^-\s+`?{re.escape(key)}`?\s*:\s*(.+)$', md, re.MULTILINE)
        if m:
            fields[key] = m.group(1).strip().strip('`').strip('*').strip().rstrip('.')
    return fields


def read_file(sha: str, path: str) -> str:
    return git('show', f'{sha}:{path}', check=False) or ''


def describe(sha: str, since: str | None) -> tuple[str, dict]:
    """A human-readable summary of the design tip plus its parsed task header."""
    lines = [f'design commit: {sha}', f'task header ({DESIGN_TASK}):']
    fields = parse_task(read_file(sha, DESIGN_TASK))
    if not fields:
        lines.append('  (task file not readable at that SHA)')
    for key in FIELDS:
        if key in fields:
            lines.append(f'  {key}: {fields[key]}')
    if since and since != sha:
        names = git('diff', '--name-status', since, sha, check=False)
        stat = git('diff', '--stat', since, sha, check=False).splitlines()
        lines += ['', f'diff {since[:7]} -> {sha[:7]}  ({stat[-1].strip() if stat else "no files listed"})']
        lines += ['  ' + row for row in names.splitlines()]
    elif not since:
        lines += ['', 'no previously processed revision recorded yet']
    else:
        lines += ['', 'no new commit since the last processed revision']
    return '\n'.join(lines), fields


def changed_files(sha: str, since: str) -> list[str]:
    out = git('diff', '--name-only', since, sha, check=False)
    return [row for row in out.splitlines() if row]


def classify(sha: str, since: str | None, fields: dict) -> tuple[str, str]:
    """Return (verdict, why) using only what the design task declares."""
    status = (fields.get('status') or '').upper()
    authorized = (fields.get('runtime_change_authorized_by_this_revision') or '').lower()
    if not fields:
        return 'NO_TASK_FILE', 'task file not found at that design SHA'
    if status == 'READY_FOR_CODE' and authorized.startswith('yes'):
        return 'READY_FOR_CODE', f'status={status}, runtime change authorized'
    if status == 'READY_FOR_CODE':
        return 'GATE_CONFLICT', f'status={status} but runtime_change_authorized={authorized or "unset"}'
    if status == 'CHANGES_REQUESTED':
        return 'CHANGES_REQUESTED', 'design asked for changes on the code side'
    if status == 'ACCEPTED':
        return 'ACCEPTED', 'design accepted the last submission'
    if status == 'BLOCKED':
        return 'BLOCKED_BY_DESIGN', f'design status={status}'
    return 'INTAKE_ONLY', f'status={status or "unknown"} -> read, verify, ACK; no app edits'


def write_inbox(path: str, sha: str, body: str) -> str:
    stamp = datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S')
    file_path = os.path.join(path, 'inbox', f'{stamp}-{sha[:7]}.md')
    with open(file_path, 'w', encoding='utf-8') as handle:
        handle.write(body)
    return file_path


def do_fetch(args) -> int:
    path = state_dir(args)
    state = load_state(path)
    try:
        git('fetch', '-q', 'origin', design_ref())
        sha = git('rev-parse', f'origin/{DESIGN_BRANCH}')
    except RuntimeError as err:
        log_line(path, f'FETCH_FAIL {err}')
        return 2

    prev = state.get('processed_design_sha')
    text, fields = describe(sha, prev)
    verdict, why = classify(sha, prev, fields)
    if sha == prev:
        log_line(path, f'NO_CHANGE design={sha[:7]} rev={fields.get("revision")} status={fields.get("status")}')
        state['last_check'] = utcnow()
        state['design'] = {'sha': sha, 'fields': fields, 'verdict': verdict}
        save_state(path, state)
        print(text)
        return 0

    files = changed_files(sha, prev) if prev else []
    relevant = [f for f in files if f.startswith(('docs/design/coordination/', 'docs/design/village-kit/',
                                                  'docs/design/AI_IMPLEMENTATION_HANDOFF.md',
                                                  'docs/design/FULL_APP_REDESIGN_CHARTER.md', 'tools/design/'))]
    log_line(path, f'NEW_DESIGN {prev[:7] if prev else "-"} -> {sha[:7]} files={len(files)} relevant={len(relevant)} {verdict}')
    body = '\n'.join([
        f'# Design revision detected at {utcnow()}',
        '',
        text,
        '',
        f'verdict: **{verdict}** — {why}',
        f'changed files: {len(files)} ({len(relevant)} inside the coordination/asset scope)',
        '',
        '## Next actor: a code-agent session (this tool cannot act by itself)',
        '',
        f'1. `python3 tools/coordination/pq_lead.py status`',
        f'2. Read the design task file at the pinned SHA: `git show {sha}:{DESIGN_TASK}`',
        '3. Apply the gate: app edits only when verdict is READY_FOR_CODE.',
        '4. Take a work order: `python3 tools/coordination/pq_lead.py brief <PQC-id>`',
        '5. Mark it processed so this revision is not re-ACKed:',
        f'   `python3 tools/coordination/pq_lead.py ack {sha}`',
        '',
    ])
    inbox_file = write_inbox(path, sha, body)
    queue = [item for item in (state.get('queue') or []) if item.get('sha') != sha]
    queue.append({'sha': sha, 'detected_at': utcnow(), 'verdict': verdict, 'inbox': inbox_file})
    state['queue'] = queue
    state['events'].append({'at': utcnow(), 'type': 'new_design', 'sha': sha, 'verdict': verdict})
    state['last_check'] = utcnow()
    state['design'] = {'sha': sha, 'fields': fields, 'verdict': verdict}
    save_state(path, state)
    print(body)
    return 0


def ci_on(sha: str) -> str:
    try:
        proc = subprocess.run(('gh', 'run', 'list', '--branch', CODE_BRANCH, '--limit', '1',
                               '--json', 'headSha,status,conclusion,number'),
                              capture_output=True, text=True, timeout=45)
        if proc.returncode != 0:
            return f'(gh unavailable: {proc.stderr.strip()[:80]})'
        runs = json.loads(proc.stdout or '[]')
        for run in runs:
            if run.get('headSha', '').startswith(sha[:7]):
                return f"run #{run.get('number')} {run.get('status')}/{run.get('conclusion') or '-'}"
        return f'(latest run {runs[0]["headSha"][:7] if runs else "n/a"} is not for this commit)'
    except Exception as err:  # noqa: BLE001 - reporting only, never fatal
        return f'(gh error: {err})'


def do_status(args) -> int:
    path = state_dir(args)
    state = load_state(path)
    try:
        git('fetch', '-q', 'origin', code_ref())
        code_sha = git('rev-parse', f'origin/{CODE_BRANCH}')
        ack = git('cat-file', '-e', f'{code_sha}:{CODE_ACK}') or 'present'
    except RuntimeError as err:
        print(f'repo state could not be read: {err}')
        return 2
    design = state.get('design') or {}
    fields = design.get('fields') or {}
    print('## Lead status')
    print(f'- checked at:            {state.get("last_check") or "never"}')
    print(f'- code branch:           {CODE_BRANCH}')
    print(f'- code tip (published):  {code_sha}')
    print(f'- code CI on tip:        {ci_on(code_sha)}')
    print(f'- our ACK on tip:        {CODE_ACK if ack else "MISSING"}')
    print(f'- design processed sha:  {state.get("processed_design_sha") or "never"}')
    print(f'- design processed rev:  {state.get("processed_revision") or "never"}')
    print(f'- design tip fetched:    {design.get("sha") or "never fetched"}')
    print(f'- design task status:    {fields.get("status") or "?"} (revision {fields.get("revision") or "?"})')
    print(f'- runtime authorized:    {fields.get("runtime_change_authorized_by_this_revision") or "?"}')
    print(f'- gate verdict:          {design.get("verdict") or "?"}')
    print(f'- next actor (per doc):  {fields.get("next_actor") or "?"}')
    queue = state.get('queue') or []
    print(f'- unprocessed notes:     {len(queue)}')
    for item in queue[-3:]:
        print(f'    {item["sha"][:7]} {item["verdict"]} -> {item["inbox"]}')
    if design.get('sha') and design.get('sha') != state.get('processed_design_sha'):
        print('- ACTION: the fetched design tip is newer than the processed revision; read the inbox note.')
    else:
        print('- nothing new from design; WAITING_FOR_PEER unless a work order is unblocked.')
    return 0


def do_ack(args) -> int:
    path = state_dir(args)
    state = load_state(path)
    sha = args.sha
    try:
        sha = git('rev-parse', sha if len(sha) == 40 else f'origin/{DESIGN_BRANCH}')
    except RuntimeError:
        pass
    fields = parse_task(read_file(sha, DESIGN_TASK))
    state['processed_design_sha'] = sha
    state['processed_revision'] = fields.get('revision')
    state['queue'] = [item for item in (state.get('queue') or []) if item['sha'] != sha]
    state.setdefault('events', []).append({'at': utcnow(), 'type': 'ack', 'sha': sha,
                                           'revision': state['processed_revision']})
    save_state(path, state)
    log_line(path, f'ACK design={sha[:7]} revision={state["processed_revision"]}')
    print(f'marked processed: design {sha} revision {state["processed_revision"]}')
    return 0


def do_brief(args) -> int:
    board = os.path.join(REPO, 'docs', 'implementation', 'coordination', 'TASK_BOARD.md')
    task_file = os.path.join(REPO, 'docs', 'implementation', 'coordination', 'tasks', f'{args.task_id}.md')
    for path in (task_file, board):
        if os.path.exists(path):
            body = open(path, encoding='utf-8').read()
            print(f'--- {os.path.relpath(path, REPO)} ---\n')
            print(body)
            return 0
    print(f'no work order {args.task_id} in {task_file}')
    return 2


def do_watch(args) -> int:
    path = state_dir(args)
    deadline = time.time() + args.max_minutes * 60
    log_line(path, f'WATCH start interval={args.interval}s max={args.max_minutes}min repo={REPO}')
    misses = 0
    while time.time() < deadline:
        try:
            do_fetch(argparse.Namespace(**vars(args)))
            misses = 0
        except Exception as err:  # noqa: BLE001 - a transient network error must not kill the loop
            misses += 1
            log_line(path, f'cycle error ({misses}): {err}')
            if misses >= 5:
                log_line(path, 'GIVE_UP after 5 consecutive failed cycles; rerun `watch` when the network is back')
                return 2
        time.sleep(args.interval)
    log_line(path, 'WATCH stop: max lifetime reached. This tool never wakes an agent by itself.')
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--state-dir', help='default ~/.pq-lead (outside the repo on purpose)')
    sub = parser.add_subparsers(dest='cmd', required=True)
    for name, help_text in (('fetch', 'fetch design, queue anything new'),
                            ('status', 'print the contract state')):
        sub.add_parser(name, help=help_text)
    ack = sub.add_parser('ack', help='record that a design revision was processed')
    ack.add_argument('sha', nargs='?', default='')
    brief = sub.add_parser('brief', help='print a work order to hand to another agent')
    brief.add_argument('task_id')
    watch = sub.add_parser('watch', help='poll the design branch (needs a live sandbox)')
    watch.add_argument('--interval', type=int, default=120)
    watch.add_argument('--max-minutes', type=int, default=480)
    args = parser.parse_args()
    handlers = {'fetch': do_fetch, 'status': do_status, 'ack': do_ack, 'brief': do_brief, 'watch': do_watch}
    return handlers[args.cmd](args)


if __name__ == '__main__':
    sys.exit(main())
