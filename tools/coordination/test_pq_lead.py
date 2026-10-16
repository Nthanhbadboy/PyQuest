#!/usr/bin/env python3
"""Unit tests for the lead tool — stdlib only, no network, no git.

Run: ``python3 tools/coordination/test_pq_lead.py``

These cover exactly the cases the design review (PQD-001 r3) said must not be
able to open a gate by accident: loose authorization values, a short/unknown SHA
being ACKed as if it had been read, a watch loop that survives failing fetches,
a stale status being presented as current, and two writers touching state at
once.
"""

from __future__ import annotations

import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
from argparse import Namespace

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location('pq_lead', os.path.join(HERE, 'pq_lead.py'))
pq = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pq)


def cp(rc: int = 0, stdout: str = '', stderr: str = '') -> subprocess.CompletedProcess:
    return subprocess.CompletedProcess(args=('git',), returncode=rc, stdout=stdout, stderr=stderr)


R3_HEADER = """# PQD-001

- revision: `3`
- status: `CHANGES_REQUESTED`
- next_actor: code agent
- code_ack: đã review ACK r1/r2
- art_approval: `pending`
- runtime_change_authorized_by_this_revision: **no**
- test_change_authorized_by_this_revision: **yes**
- coordination_change_authorized_by_this_revision: **yes**
"""


def header(status: str, **flags) -> str:
    lines = ['# PQD-001', '', '- revision: `9`', f'- status: `{status}`']
    for key, value in flags.items():
        lines.append(f'- {key}: {value}')
    return '\n'.join(lines) + '\n'


class ParsingTest(unittest.TestCase):
    def test_reads_declared_fields_only(self):
        fields = pq.parse_task(R3_HEADER)
        self.assertEqual(fields['revision'], '3')
        self.assertEqual(fields['status'], 'CHANGES_REQUESTED')
        self.assertEqual(fields['art_approval'], 'pending')
        self.assertEqual(fields['runtime_change_authorized_by_this_revision'], 'no')
        # Nothing in the file -> nothing invented.
        self.assertNotIn('made_up_field', pq.parse_task('- status: `X`\n'))

    def test_bold_and_backtick_values_still_parse(self):
        scopes = pq.classify(pq.parse_task(R3_HEADER))[2]
        self.assertEqual(scopes, {'runtime': 'no', 'test': 'yes', 'coordination': 'yes'})


class GateTest(unittest.TestCase):
    def test_exact_yes_only(self):
        for raw, expected in (('yes', 'yes'), ('`yes`', 'yes'), ('**yes**', 'yes'), ('YES', 'yes'),
                              ('no', 'no'), ('yesterday', 'invalid:yesterday'), ('true', 'invalid:true'),
                              ('', 'invalid:')):
            with self.subTest(raw=raw):
                fields = pq.parse_task(header('READY_FOR_CODE',
                                              runtime_change_authorized_by_this_revision=raw))
                verdict, _, scopes = pq.classify(fields)
                if expected == 'yes':
                    self.assertEqual(verdict, 'READY_FOR_CODE')
                else:
                    self.assertEqual(verdict, 'GATE_CONFLICT', f'{raw!r} must not open the runtime gate')

    def test_missing_field_fails_closed(self):
        verdict, why, scopes = pq.classify(pq.parse_task(header('READY_FOR_CODE')))
        self.assertEqual(verdict, 'GATE_CONFLICT')
        self.assertEqual(scopes['runtime'], 'missing')
        self.assertIn('no app edits', why)

    def test_authorized_without_ready_status_is_a_conflict(self):
        verdict, why, _ = pq.classify(pq.parse_task(header('READY_FOR_INTAKE',
                                                            runtime_change_authorized_by_this_revision='yes')))
        self.assertEqual(verdict, 'GATE_CONFLICT')
        self.assertIn('ask design', why)

    def test_other_statuses(self):
        for status, verdict in (('CHANGES_REQUESTED', 'CHANGES_REQUESTED'), ('ACCEPTED', 'ACCEPTED'),
                                ('BLOCKED', 'BLOCKED_BY_DESIGN'), ('DRAFT', 'INTAKE_ONLY')):
            with self.subTest(status=status):
                self.assertEqual(pq.classify(pq.parse_task(header(status)))[0], verdict)

    def test_no_task_file(self):
        self.assertEqual(pq.classify({})[0], 'NO_TASK_FILE')


class FakeGit:
    """Answers just enough git for these code paths; records every call."""

    def __init__(self, *, tip='f' * 40, files=None, ancestors=(), show_rc=0):
        self.tip = tip
        if files is None:
            # Mặc định phục vụ đúng file mà tool đang theo dõi, để test không phụ
            # thuộc state thật của máy (~/.pq-lead).
            files = {f'{pq.DESIGN_TASK_DIR}/{pq.TASK_IDS[0]}.md': R3_HEADER}
        self.files = files
        self.ancestors = set(ancestors)
        self.show_rc = show_rc
        self.calls = []

    def __call__(self, *args, **kwargs):
        self.calls.append(args)
        cmd = ' '.join(args)
        if args[0] == 'rev-parse':
            rev = args[-1].replace('^{commit}', '')
            if rev == f'origin/{pq.DESIGN_BRANCH}' or rev == f'origin/{pq.CODE_BRANCH}':
                return cp(0, self.tip + '\n')
            if self.tip.startswith(rev) or rev == self.tip:
                return cp(0, self.tip + '\n')
            for known in self.ancestors | set(self.files):
                if known == rev or known.startswith(rev):
                    return cp(0, known + '\n')
            return cp(128, '', 'fatal: Needed a single revision')
        if args[0] == 'merge-base':
            return cp(0 if args[2] in self.ancestors or args[2] == self.tip else 1)
        if args[0] == 'show':
            path = args[1].split(':', 1)[1]
            if self.show_rc or path not in self.files:
                return cp(128, '', 'fatal: path does not exist')
            return cp(0, self.files[path])
        if args[0] == 'cat-file' and args[1] == '-e':
            return cp(0)
        if args[0] == 'diff':
            return cp(0, '')
        if args[0] == 'fetch':
            return cp(0)
        raise AssertionError(f'unexpected git call: {cmd}')


class AckTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        os.makedirs(os.path.join(self.tmp.name, 'inbox'), exist_ok=True)
        # Hermetic: tracked-task resolution must not read the developer's real state.
        os.environ['PQ_LEAD_STATE'] = self.tmp.name
        self.addCleanup(os.environ.pop, 'PQ_LEAD_STATE', None)
        self.args = Namespace(state_dir=self.tmp.name, wait=0, sha='')

    def _state(self):
        return pq.load_state(self.tmp.name)

    def test_full_sha_on_the_fetched_history_is_recorded(self):
        ancestor = 'a' * 40
        git = FakeGit(tip='f' * 40, ancestors={ancestor})
        original = pq.git
        pq.git = git
        try:
            self.args.sha = ancestor
            self.assertEqual(pq.do_ack(self.args), 0)
        finally:
            pq.git = original
        state = self._state()
        self.assertEqual(state['processed_design_sha'], ancestor)
        self.assertEqual(state['processed_revision'], '3')
        self.assertEqual(state['processed_scopes'], {'runtime': 'no', 'test': 'yes', 'coordination': 'yes'})

    def test_unknown_sha_is_refused_and_state_untouched(self):
        git = FakeGit()
        original, original_log = pq.git, pq.log_line
        pq.git, pq.log_line = git, lambda *a, **k: None
        try:
            self.args.sha = 'deadbeef'
            self.assertEqual(pq.do_ack(self.args), 2)
        finally:
            pq.git, pq.log_line = original, original_log
        self.assertIsNone(self._state()['processed_design_sha'])

    def test_sha_outside_design_history_is_refused(self):
        stranger = 'b' * 40
        git = FakeGit(ancestors=set())  # nothing is an ancestor except the tip
        git.files[f'{stranger}'] = ''  # resolvable but not on the branch
        original, original_log = pq.git, pq.log_line
        pq.git, pq.log_line = git, lambda *a, **k: None
        try:
            self.args.sha = stranger
            self.assertEqual(pq.do_ack(self.args), 2)
        finally:
            pq.git, pq.log_line = original, original_log
        self.assertIsNone(self._state()['processed_design_sha'])

    def test_commit_without_task_file_is_refused(self):
        ancestor = 'c' * 40
        git = FakeGit(ancestors={ancestor}, files={})
        original, original_log = pq.git, pq.log_line
        pq.git, pq.log_line = git, lambda *a, **k: None
        try:
            self.args.sha = ancestor
            self.assertEqual(pq.do_ack(self.args), 2)
        finally:
            pq.git, pq.log_line = original, original_log
        self.assertIsNone(self._state()['processed_design_sha'])

    def test_empty_argument_never_marks_a_random_revision(self):
        original, original_log = pq.git, pq.log_line
        pq.git, pq.log_line = FakeGit(), lambda *a, **k: None
        try:
            self.assertEqual(pq.do_ack(self.args), 2)  # nothing fetched yet
            pq.save_state(self.tmp.name, {'fetched_design_sha': 'f' * 40, 'queue': [], 'events': []})
            self.assertEqual(pq.do_ack(self.args), 0)  # falls back to the tip just fetched
        finally:
            pq.git, pq.log_line = original, original_log
        self.assertEqual(self._state()['processed_design_sha'], 'f' * 40)


class FetchWatchStatusTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        os.makedirs(os.path.join(self.tmp.name, 'inbox'), exist_ok=True)

    def test_watch_counts_failed_cycles_and_gives_up(self):
        calls = {'n': 0}

        def failing_fetch(args):
            calls['n'] += 1
            return 2

        original = pq.do_fetch
        pq.do_fetch = failing_fetch
        try:
            rc = pq.do_watch(Namespace(state_dir=self.tmp.name, wait=0, interval=5, max_minutes=1,
                                       max_failures=3, offline=False))
        finally:
            pq.do_fetch = original
        self.assertEqual(rc, 2)
        self.assertEqual(calls['n'], 3)

    def test_watch_rejects_bad_intervals(self):
        for kwargs in ({'interval': 0, 'max_minutes': 10, 'max_failures': 5},
                       {'interval': 30, 'max_minutes': 0, 'max_failures': 5},
                       {'interval': 30, 'max_minutes': 10, 'max_failures': 0}):
            with self.subTest(**kwargs):
                rc = pq.do_watch(Namespace(state_dir=self.tmp.name, wait=0, offline=False, **kwargs))
                self.assertEqual(rc, 2)

    def test_watch_stops_on_stop_file(self):
        with open(os.path.join(self.tmp.name, 'STOP'), 'w', encoding='utf-8') as handle:
            handle.write('stop\n')
        rc = pq.do_watch(Namespace(state_dir=self.tmp.name, wait=0, interval=5, max_minutes=1,
                                    max_failures=5, offline=False))
        self.assertEqual(rc, 0)
        self.assertFalse(os.path.exists(os.path.join(self.tmp.name, 'STOP')))

    def test_fetch_failure_records_state_and_returns_two(self):
        def boom(*args, **kwargs):
            raise pq.LeadError('network down')

        original = pq.git
        pq.git = boom
        try:
            rc = pq.do_fetch(Namespace(state_dir=self.tmp.name, wait=0, offline=False))
        finally:
            pq.git = original
        self.assertEqual(rc, 2)
        self.assertEqual(pq.load_state(self.tmp.name)['last_error'], 'network down')

    def test_status_labels_unverified_data(self):
        original, original_ci = pq.git, pq.ci_on
        pq.git, pq.ci_on = FakeGit(show_rc=1), lambda sha: '(skipped in test)'
        out = []
        real_print = print
        try:
            import builtins
            builtins.print = lambda *a, **k: out.append(' '.join(str(x) for x in a))
            rc = pq.do_status(Namespace(state_dir=self.tmp.name, wait=0, offline=True))
        finally:
            builtins.print = real_print
            pq.git, pq.ci_on = original, original_ci
        self.assertEqual(rc, 0)
        self.assertIn('STALE/UNVERIFIED', '\n'.join(out))

    def test_status_reports_scopes_and_action(self):
        pq.save_state(self.tmp.name, {
            'fetched_design_sha': 'd' * 40,
            'processed_design_sha': 'e' * 40,
            'processed_revision': '2',
            'queue': [], 'events': [],
            'design': {'sha': 'd' * 40, 'fields': pq.parse_task(R3_HEADER), 'verdict': 'CHANGES_REQUESTED',
                       'scopes': {'runtime': 'no', 'test': 'yes', 'coordination': 'yes'}, 'observed_at': 'now'},
        })
        original, original_ci = pq.git, pq.ci_on
        pq.git, pq.ci_on = FakeGit(show_rc=1), lambda sha: '(skipped in test)'
        out = []
        real_print, builtins = print, __import__('builtins')
        try:
            builtins.print = lambda *a, **k: out.append(' '.join(str(x) for x in a))
            rc = pq.do_status(Namespace(state_dir=self.tmp.name, wait=0, offline=True))
        finally:
            builtins.print = real_print
            pq.git, pq.ci_on = original, original_ci
        text = '\n'.join(out)
        self.assertEqual(rc, 0)
        self.assertIn('runtime=no, test=yes, coordination=yes', text)
        self.assertIn('ACTION', text)


class TaskTrackingTest(unittest.TestCase):
    """`fetch` follows a forward pointer to a newer design task, once."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        os.makedirs(os.path.join(self.tmp.name, 'inbox'), exist_ok=True)
        os.environ['PQ_LEAD_STATE'] = self.tmp.name
        self.addCleanup(os.environ.pop, 'PQ_LEAD_STATE', None)

    def _fetch(self, files, *, tracked=None):
        if tracked:  # bắt đầu từ một task id cũ hơn để kiểm tra chiều theo con trỏ
            pq.save_state(self.tmp.name, {'processed_design_sha': None, 'queue': [],
                                          'events': [], 'tracked_task': tracked})
        git = FakeGit(files=files)
        original, original_log = pq.git, pq.log_line
        pq.git, pq.log_line = git, lambda *a, **k: None
        try:
            rc = pq.do_fetch(Namespace(state_dir=self.tmp.name, wait=0, task=None))
        finally:
            pq.git, pq.log_line = original, original_log
        return rc, pq.load_state(self.tmp.name)

    def test_forward_pointer_is_followed_once(self):
        rc, state = self._fetch({
            f'{pq.DESIGN_TASK_DIR}/PQD-001.md':
                R3_HEADER + '\nĐọc docs/design/coordination/tasks/PQD-002.md để biết việc mới.\n',
            f'{pq.DESIGN_TASK_DIR}/PQD-002.md':
                '- revision: 1\n- status: READY_FOR_INTAKE\n- runtime_change_authorized_by_this_revision: no\n',
        }, tracked='PQD-001')
        self.assertEqual(rc, 0)
        self.assertEqual(state['tracked_task'], 'PQD-002')

    def test_pointer_never_moves_backwards(self):
        rc, state = self._fetch({
            f'{pq.DESIGN_TASK_DIR}/PQD-001.md': '- revision: 4\n- status: ACCEPTED\n',
            f'{pq.DESIGN_TASK_DIR}/PQD-002.md':
                R3_HEADER + '\nQuay lại docs/design/coordination/tasks/PQD-001.md\n',
            f'{pq.DESIGN_TASK_DIR}/PQD-001.md': '- revision: 4\n- status: ACCEPTED\n',
        }, tracked='PQD-002')
        self.assertEqual(rc, 0)
        self.assertEqual(state['tracked_task'], 'PQD-002', 'con trỏ ngược về id cũ phải bị bỏ qua')

    def test_pointer_to_a_missing_file_is_ignored(self):
        rc, state = self._fetch({
            f'{pq.DESIGN_TASK_DIR}/PQD-001.md':
                R3_HEADER + '\nViệc mới ở docs/design/coordination/tasks/PQD-009.md\n',
        }, tracked='PQD-001')
        self.assertEqual(rc, 0)
        self.assertEqual(state['tracked_task'], 'PQD-001', 'trỏ tới file không tồn tại thì không được đổi con trỏ')

    def test_explicit_task_flag_wins_over_state(self):
        args = Namespace(state_dir=self.tmp.name, wait=0, sha='f' * 40, task='PQD-042')
        git = FakeGit(files={'docs/design/coordination/tasks/PQD-042.md': R3_HEADER})
        original, original_log = pq.git, pq.log_line
        pq.git, pq.log_line = git, lambda *a, **k: None
        try:
            self.assertEqual(pq.do_ack(args), 0)
        finally:
            pq.git, pq.log_line = original, original_log
        self.assertEqual(pq.load_state(self.tmp.name)['processed_design_sha'], 'f' * 40)


class BriefTest(unittest.TestCase):
    def _fixture(self, tmp: str) -> str:
        root = os.path.join(tmp, 'docs', 'implementation', 'coordination')
        os.makedirs(os.path.join(root, 'tasks'), exist_ok=True)
        os.makedirs(os.path.join(tmp, 'inbox'), exist_ok=True)
        for name, scope in (('PQC-T', 'test'), ('PQC-R', 'runtime'), ('PQC-C', 'coordination')):
            with open(os.path.join(root, 'tasks', f'{name}.md'), 'w', encoding='utf-8') as handle:
                handle.write(f'# {name}\n\n- scope: {scope}\n')
        with open(os.path.join(root, 'TASK_BOARD.md'), 'w', encoding='utf-8') as handle:
            handle.write('board\n')
        pq.save_state(tmp, {'queue': [], 'events': [],
                            'design': {'sha': 'x', 'fields': {}, 'verdict': 'CHANGES_REQUESTED',
                                       'scopes': {'runtime': 'no', 'test': 'yes', 'coordination': 'yes'}}})
        return root

    def _run(self, tmp: str, task_id: str) -> tuple[int, str]:
        out: list[str] = []
        real_print, builtins = print, __import__('builtins')
        try:
            builtins.print = lambda *a, **k: out.append(' '.join(str(x) for x in a))
            rc = pq.do_brief(Namespace(state_dir=tmp, repo=tmp, task_id=task_id))
        finally:
            builtins.print = real_print
        return rc, '\n'.join(out)

    def test_allowed_scope_prints_the_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            self._fixture(tmp)
            rc, text = self._run(tmp, 'PQC-T')
            self.assertEqual(rc, 0)
            self.assertIn('ALLOWED for scope=test', text)
            self.assertIn('# PQC-T', text)
            self.assertNotIn('DO NOT START', text)

    def test_runtime_scope_stays_blocked_even_when_test_is_open(self):
        with tempfile.TemporaryDirectory() as tmp:
            self._fixture(tmp)
            rc, text = self._run(tmp, 'PQC-R')
            self.assertEqual(rc, 1)
            self.assertIn('DO NOT START', text)
            self.assertIn('runtime=no', text)

    def test_coordination_scope_follows_its_own_flag(self):
        with tempfile.TemporaryDirectory() as tmp:
            self._fixture(tmp)
            rc, _ = self._run(tmp, 'PQC-C')
            self.assertEqual(rc, 0)

    def test_undeclared_scope_is_blocked_not_allowed(self):
        with tempfile.TemporaryDirectory() as tmp:
            self._fixture(tmp)
            root = os.path.join(tmp, 'docs', 'implementation', 'coordination', 'tasks')
            with open(os.path.join(root, 'PQC-X.md'), 'w', encoding='utf-8') as handle:
                handle.write('# PQC-X\n\nno scope line here\n')
            out: list[str] = []
            real_print, builtins = print, __import__('builtins')
            try:
                builtins.print = lambda *a, **k: out.append(' '.join(str(x) for x in a))
                rc = pq.do_brief(Namespace(state_dir=tmp, repo=tmp, task_id='PQC-X'))
            finally:
                builtins.print = real_print
            self.assertEqual(rc, 1)
            self.assertIn('UNDECLARED', '\n'.join(out))

    def test_unreadable_order_is_reported(self):
        with tempfile.TemporaryDirectory() as tmp:
            self._fixture(tmp)
            rc, _ = self._run(tmp, 'PQC-NOPE')
            self.assertEqual(rc, 2)



class ScopedRuntimeTest(unittest.TestCase):
    def state(self):
        fields = pq.parse_task(header('READY_FOR_CODE',
            task_id='PQD-003', runtime_change_authorized_by_this_revision='yes',
            authorized_runtime_work_orders='PQC-010,PQC-014,PQC-015',
            dependency_change_authorized_by_this_revision='yes',
            authorized_dependency_work_orders='PQC-015'))
        verdict, _, scopes = pq.classify(fields)
        return {'fields': fields, 'verdict': verdict, 'scopes': scopes}

    def order(self, ident, *, status='READY_FOR_CODE', source='PQD-003', dependency='no'):
        return (f'- work_order: {ident}\n- scope: runtime\n- status: {status}\n'
                f'- source_task: {source}\n- dependency_change_required: {dependency}\n')

    def test_only_three_explicit_runtime_orders_open(self):
        for ident in ('PQC-010', 'PQC-014', 'PQC-015'):
            self.assertTrue(pq.runtime_order_gate(self.state(), ident,
                self.order(ident, dependency='yes' if ident == 'PQC-015' else 'no'))[0])

    def test_old_orders_stay_blocked_even_if_their_header_claims_ready(self):
        for ident in ('PQC-002','PQC-004','PQC-005','PQC-008','PQC-011','PQC-012','PQC-013','PQC-016','PQC-017'):
            self.assertFalse(pq.runtime_order_gate(self.state(), ident, self.order(ident))[0])

    def test_allowlist_missing_wildcard_or_partial_match_fails_closed(self):
        for value in ('', '*', 'PQC-*', 'PQC-0100', 'PQC-010,PQC-*', 'PQC-010;PQC-008'):
            state=self.state();state['fields']['authorized_runtime_work_orders']=value
            self.assertFalse(pq.runtime_order_gate(state,'PQC-010',self.order('PQC-010'))[0])

    def test_blocked_order_and_source_mismatch_are_not_authorized(self):
        for body in (self.order('PQC-010',status='BLOCKED'),self.order('PQC-010',source='PQD-002'),self.order('PQC-008')):
            self.assertFalse(pq.runtime_order_gate(self.state(),'PQC-010',body)[0])

    def test_dependency_requires_its_own_exact_permission_and_order(self):
        for value in ('no', 'yesterday', 'true', ''):
            state=self.state();state['fields']['dependency_change_authorized_by_this_revision']=value
            self.assertFalse(pq.runtime_order_gate(state,'PQC-015',self.order('PQC-015',dependency='yes'))[0])
        state=self.state();state['fields']['authorized_dependency_work_orders']='PQC-005'
        self.assertFalse(pq.runtime_order_gate(state,'PQC-015',self.order('PQC-015',dependency='yes'))[0])
        self.assertFalse(pq.runtime_order_gate(self.state(),'PQC-010',self.order('PQC-010',dependency='yes'))[0])

    def test_missing_requirement_and_cached_verdict_cannot_open_gate(self):
        self.assertFalse(pq.runtime_order_gate(self.state(),'PQC-010',self.order('PQC-010',dependency=''))[0])
        state=self.state();state['fields']['runtime_change_authorized_by_this_revision']='no'
        self.assertFalse(pq.runtime_order_gate(state,'PQC-010',self.order('PQC-010'))[0])

    def test_brief_applies_order_gate_not_just_global_flag(self):
        helper=BriefTest()
        with tempfile.TemporaryDirectory() as tmp:
            root=helper._fixture(tmp)
            for ident in ('PQC-010','PQC-008'):
                with open(os.path.join(root,'tasks',ident+'.md'),'w') as f: f.write(self.order(ident))
            pq.save_state(tmp,{'design':self.state()})
            self.assertEqual(helper._run(tmp,'PQC-010')[0],0)
            self.assertEqual(helper._run(tmp,'PQC-008')[0],1)


class LockTest(unittest.TestCase):
    def test_second_writer_is_refused(self):
        with tempfile.TemporaryDirectory() as tmp:
            os.makedirs(os.path.join(tmp, 'inbox'))
            with pq.state_lock(tmp, wait_seconds=0):
                with self.assertRaises(pq.LeadError):
                    with pq.state_lock(tmp, wait_seconds=0):
                        pass

    def test_status_reports_lock_as_three(self):
        with tempfile.TemporaryDirectory() as tmp:
            os.makedirs(os.path.join(tmp, 'inbox'))
            original, original_ci = pq.git, pq.ci_on
            pq.git, pq.ci_on = FakeGit(show_rc=1), lambda sha: '(skipped in test)'
            try:
                with pq.state_lock(tmp, wait_seconds=0):
                    rc = pq.do_status(Namespace(state_dir=tmp, repo=tmp, wait=0, offline=True))
            finally:
                pq.git, pq.ci_on = original, original_ci
            self.assertEqual(rc, 3)

    def test_stale_lock_is_broken(self):
        with tempfile.TemporaryDirectory() as tmp:
            os.makedirs(os.path.join(tmp, 'inbox'))
            lock = os.path.join(tmp, 'state.lock')
            with open(lock, 'w', encoding='utf-8') as handle:
                handle.write('999999 old\n')
            os.utime(lock, (0, 0))
            with pq.state_lock(tmp, wait_seconds=0):
                self.assertTrue(os.path.exists(lock))


if __name__ == '__main__':
    unittest.main(verbosity=2)
