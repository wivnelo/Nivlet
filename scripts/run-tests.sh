#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"
failed=0
run() { if "$@" >"${TMPDIR:-/tmp}/nivlet-test.log" 2>&1; then echo "PASS $*"; else echo "FAIL $*"; tail -20 "${TMPDIR:-/tmp}/nivlet-test.log"; failed=1; fi; }
for test_file in tests/*.lua; do run lua "$test_file"; done
for test_file in tests/*.py; do [ "$test_file" = tests/updates.py ] || run python3 "$test_file"; done
for test_file in tests/*.js; do case "$test_file" in *_ui.js) ;; *) run node "$test_file" ;; esac; done
run python3 scripts/check-privacy.py --repo .
exit "$failed"
