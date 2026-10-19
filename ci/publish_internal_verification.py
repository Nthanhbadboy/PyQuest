#!/usr/bin/env python3
"""Publish non-secret source verification evidence through the GitHub Checks API.
Runner logs/artifact downloads may be unreachable from the agent's network.
No provider secret is present in this job; the GitHub token is only used as auth.
"""
import json
import os
from pathlib import Path
import urllib.request


def payload(env):
    folder = Path(env['EVIDENCE_DIR'])
    outcome = env.get('VERIFY_OUTCOME', 'skipped')
    conclusion = {'success': 'success', 'cancelled': 'cancelled'}.get(outcome, 'failure')
    summary = [f"Source: `{env['SOURCE_SHA']}`", f"Workflow: `{env['WORKFLOW_SHA']}`",
               f"Run: {env['GITHUB_RUN_ID']}; verification outcome: {outcome}",
               'Not APK, device, voice, or production acceptance.']
    for name in ['provenance.txt', 'flutter-version.json', 'status.txt', 'test-counts.json']:
        p = folder / name
        summary.append(f'### {name}\n```\n' + (p.read_text() if p.exists() else 'NOT PRODUCED') + '\n```')
    detail = []
    for name in ['format', 'analyze', 'settings', 'integration', 'ordinary', 'render', 'sdk_pin', 'localization_helpers', 'localization_evidence', 'tracked_source_unchanged']:
        p = folder / (name + '.log')
        if p.exists():
            # End of full suite log plus first diagnostic excerpts; no success inferred from excerpts.
            text = p.read_text(errors='replace')
            if len(text) > 4500:
                text = text[:2000] + '\n[excerpt; full log in verification artifact]\n' + text[-2500:]
            detail.append(f'### {name}\n```text\n{text}\n```')
    result = {'name': 'PQC-011 pinned source verification', 'head_sha': env['SOURCE_SHA'],
            'status': 'completed', 'conclusion': conclusion,
            'details_url': f"https://github.com/{env['GITHUB_REPOSITORY']}/actions/runs/{env['GITHUB_RUN_ID']}",
            'output': {'title': f'Pinned SDK verification: {outcome}', 'summary': '\n\n'.join(summary),
                       'text': '\n\n'.join(detail).encode()[:62000].decode(errors='ignore')}}
    if outcome == 'in_progress':
        result['status'] = 'in_progress'
        del result['conclusion']
    return result


def main():
    env = os.environ
    body = payload(env)
    record_file = Path(env['EVIDENCE_DIR']) / 'published-check.json'
    previous = json.loads(record_file.read_text()) if record_file.exists() else None
    url = f"https://api.github.com/repos/{env['GITHUB_REPOSITORY']}/check-runs"
    if previous:
        url += '/' + str(previous['id'])
        body.pop('head_sha', None)  # PATCH keeps the immutable source association
    request = urllib.request.Request(
        url, data=json.dumps(body).encode(), method='PATCH' if previous else 'POST',
        headers={'Authorization': 'Bearer ' + env['GH_TOKEN'], 'Accept': 'application/vnd.github+json',
                 'Content-Type': 'application/json', 'X-GitHub-Api-Version': '2022-11-28'})
    with urllib.request.urlopen(request, timeout=30) as response:
        result = json.load(response)
    record = {key: result[key] for key in ['id', 'head_sha', 'html_url', 'conclusion']}
    (Path(env['EVIDENCE_DIR']) / 'published-check.json').write_text(json.dumps(record, indent=2) + '\n')
    print(json.dumps(record))


if __name__ == '__main__':
    main()
