#!/usr/bin/env bash
# Invoked from the workflow-control checkout, with cwd set to exact source/app.
# Non-mutating formatter. All test gates get a result even when another gate fails.
set -u -o pipefail
: "${EVIDENCE_DIR:?}" "${SOURCE_SHA:?}" "${WORKFLOW_SHA:?}"
mkdir -p "$EVIDENCE_DIR"
: > "$EVIDENCE_DIR/status.txt"
printf 'source_sha=%s\nworkflow_sha=%s\n' "$SOURCE_SHA" "$WORKFLOW_SHA" > "$EVIDENCE_DIR/provenance.txt"
if [[ "$(git rev-parse HEAD)" != "$SOURCE_SHA" ]]; then
  echo 'source_pin=1' >> "$EVIDENCE_DIR/status.txt"
  exit 1
fi
run_gate() {
  local name="$1"; shift
  "$@" 2>&1 | tee "$EVIDENCE_DIR/$name.log"
  local -a codes=("${PIPESTATUS[@]}")
  local code=${codes[0]}
  if (( code == 0 && codes[1] != 0 )); then code=${codes[1]}; fi
  printf '%s=%s\n' "$name" "$code" >> "$EVIDENCE_DIR/status.txt"
  return "$code"
}
flutter --version --machine > "$EVIDENCE_DIR/flutter-version.json" || exit 1
run_gate sdk_pin python3 - "$EVIDENCE_DIR/flutter-version.json" <<'PY'
import json,sys
v=json.load(open(sys.argv[1]))
assert v['frameworkVersion']=='3.47.7', v['frameworkVersion']
assert v['frameworkRevision']=='abaf9c523780a608bd46686fd5e53740a07077f8', v['frameworkRevision']
assert v['dartSdkVersion'].split()[0]=='3.13.5', v['dartSdkVersion']
print('Flutter 3.47.7 / Dart 3.13.5 / pinned framework revision verified')
PY
if [[ $? != 0 ]]; then exit 1; fi
run_gate pub_get flutter pub get || exit 1
run_gate format dart format --output=none --set-exit-if-changed \
  lib/modules/main_quest/lesson_screen.dart \
  lib/modules/tutor/board/authored_board_repository.dart \
  lib/modules/tutor/board/board_view.dart \
  test/lesson_board_integration_test.dart test/board test/tutor_board_content_pack_test.dart
run_gate localization_helpers python3 ../ci/test_l10n_evidence.py
run_gate localization_evidence python3 ../ci/l10n_evidence.py collect --repo-root .. --app-dir . --output "$EVIDENCE_DIR/l10n-evidence.json"
run_gate analyze flutter analyze --no-fatal-infos
run_gate settings timeout 300 flutter test --reporter expanded --timeout 45s test/l10n/settings_sheet_localization_test.dart
run_gate integration timeout 600 flutter test --reporter expanded --timeout 90s test/lesson_board_integration_test.dart
run_gate ordinary timeout 900 flutter test --reporter expanded --exclude-tags render
run_gate render timeout 600 flutter test --reporter expanded --tags render test/render
run_gate tracked_source_unchanged git diff --exit-code -- .
# Machine-readable actual counts, not an assumed 406+N or a sum of overlapping suites.
python3 - "$EVIDENCE_DIR" <<'PY'
import json,pathlib,re,sys
p=pathlib.Path(sys.argv[1]);counts={};good=True
for name,minimum,exact in [('settings',12,True),('integration',7,False),('ordinary',406,False),('render',10,False)]:
 text=(p/f'{name}.log').read_text(errors='replace')
 matches=re.findall(r'\+(\d+)(?:\s+~\d+)?(?:\s+-\d+)?:\s+All tests passed!',text)
 count=int(matches[-1]) if matches else None
 counts[name]={'passed':count,'minimum':minimum,'overlaps_ordinary':name in ('settings','integration')}
 if count is None or (count!=minimum if exact else count<minimum):good=False
(p/'test-counts.json').write_text(json.dumps(counts,indent=2)+'\n')
with (p/'status.txt').open('a') as f:f.write(f'count_gate={0 if good else 1}\n')
print(json.dumps(counts,indent=2))
PY
cat "$EVIDENCE_DIR/status.txt"
# A failed gate cannot be hidden by a later successful command.
if grep -qv '=0$' "$EVIDENCE_DIR/status.txt"; then exit 1; fi
