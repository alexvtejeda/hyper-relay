#!/usr/bin/env bash
# Run every companion test. From scripts/:  ./run-tests.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
rc=0
for t in "$HERE"/test-*.cjs; do
  echo "== $(basename "$t")"
  node "$t" || rc=1
done
exit "$rc"
