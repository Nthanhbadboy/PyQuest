#!/usr/bin/env python3
"""Bounded, stdlib-only regression checks for r47's two literal APK workflows.
Not a general shell/YAML security analyzer, secret scanner or APK verifier.
Does not invoke Flutter, CI or any network operation.
"""
import argparse
import json
from pathlib import Path
import re
import shlex

WORKFLOWS = ('.github/workflows/ci.yml', '.github/workflows/build-debug-apk.yml')
EMPTY_DEFINE = '--dart-define=GEMINI_API_KEY='


def build_commands(text):
    commands = []
    for match in re.finditer(r'\bflutter\s+build\s+apk\b[^\n]*', text):
        lexer = shlex.shlex(match.group(), posix=True, punctuation_chars=';&|<>')
        lexer.whitespace_split = True
        args = []
        for word in lexer:
            if word and all(c in ';&|<>' for c in word):
                break
            args.append(word)
        commands.append(args)
    return commands


def check_workflow(text):
    issues = []
    if re.search(r'secrets[^\n]*GEMINI_API_KEY|GEMINI_API_KEY[^\n]*secrets', text, re.I):
        issues.append('Gemini repository secret reference remains')
    if re.search(r'\$(?:GEMINI_API_KEY\b|\{GEMINI_API_KEY\b)', text):
        issues.append('Gemini environment substitution remains')
    commands = build_commands(text)
    if not commands:
        issues.append('No literal APK build command found; review checker coverage')
    for args in commands:
        if args.count(EMPTY_DEFINE) != 1:
            issues.append('Every APK command must explicitly define an empty Gemini key once')
        if any(a.startswith('--dart-define-from-file') for a in args):
            issues.append('An additional define file could override the empty key')
        defines = [a for a in args if 'GEMINI_API_KEY' in a]
        if defines != [EMPTY_DEFINE]:
            issues.append('Additional or non-empty Gemini define')
    return issues


def check_tree(root):
    errors, workflows = [], []
    for path in WORKFLOWS:
        text = (root / path).read_text()
        errors.extend(f'{path}: {message}' for message in check_workflow(text))
        workflows.append({'path': path, 'apk_commands': len(build_commands(text))})
    roadmap = (root / 'docs/ROADMAP.md').read_text()
    if re.search(r'^\s*- \[[ xX]\]', roadmap, re.M):
        errors.append('Roadmap still represents historical criteria as progress checkboxes')
    if roadmap.count('- **Tiêu chí kế hoạch:**') != 64:
        errors.append('The 64 historical roadmap criteria were not preserved')
    for old in ['Bắt đầu **giai đoạn 1 — Foundation**', 'ba mini-game', 'cần `GEMINI_API_KEY` của repo secret lúc build']:
        if old in roadmap:
            errors.append('Stale roadmap statement: ' + old)
    game = (root / 'docs/GAME_DESIGN.md').read_text()
    if 'Energy hồi theo thời gian, quảng cáo thưởng có giới hạn và lưu trong database.' in game:
        errors.append('Game Design still claims rewarded ads are implemented')
    readme = (root / 'README.md').read_text()
    if 'App không bao giờ chứa API key' in readme:
        errors.append('README still claims the entire app can never contain a key')
    if 'TECHNICAL_ARCHITURE.md' in readme:
        errors.append('README architecture link is misspelled')
    voice = (root / 'docs/experimental/GEMINI_LIVE_VOICE_TEST.md').read_text()
    if 'Bản Release trên CI lấy key' in voice:
        errors.append('Voice guide still directs users to CI key injection')
    for path in ['README.md', 'docs/PRODUCT_VISION.md', 'docs/GAME_DESIGN.md',
                 'docs/ROADMAP.md', 'docs/TECHNICAL_ARCHITECTURE.md']:
        if 'PROJECT_STATUS.md' not in (root / path).read_text():
            errors.append(path + ': missing source/evidence/status entry point')
    task18 = (root / 'docs/implementation/coordination/tasks/PQC-018.md').read_text()
    header = re.search(r'^- status: (.+)$', task18, re.M)
    if not header or 'REVIEWED_WITH_LIMITS — ART_SCOPE_COMPLETE' not in header.group(1):
        errors.append('PQC-018 current header is stale')
    task11 = (root / 'docs/implementation/coordination/tasks/PQC-011.md').read_text()
    if 'WAITING_FOR_PINNED_SDK_EVIDENCE' not in task11 or 'CHANGES_REQUESTED' not in task11:
        errors.append('PQC-011 blocker/disposition was lost')
    return {'result': 'PASS_STATIC_POLICY_ONLY' if not errors else 'FAIL',
            'workflows': workflows, 'historical_criteria': 64, 'errors': errors,
            'flutter': 'NOT_RUN', 'ci_triggered': False, 'apk_inspection': 'NOT_RUN'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    report = check_tree(args.root)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    raise SystemExit(bool(report['errors']))
