#!/usr/bin/env bash
# Earth Kings dev launcher for Linux and macOS — the `test` half of ek.ps1.
#
#   ./ek.sh test                 run every smoke suite, one line each
#   ./ek.sh test walk world      run only those
#   ./ek.sh soak [seconds]       let the game play itself (default 120 s, seed 77)
#   ./ek.sh ledger               the Question Book and answers.md agree (tools/question_report)
#
# Godot is $EK_GODOT if set, else `godot` on the PATH. CI uses this script
# (.github/workflows/smoke.yml), so a green run here is a green run there.
#
# A suite fails on a non-zero exit, a FAIL/failure line, or any SCRIPT ERROR:
# Godot keeps running after a script error, so the exit code alone misses them.
set -uo pipefail
cd "$(dirname "$0")" || exit 1

GODOT="${EK_GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "Godot 4.7 was not found. Put it on the PATH or set EK_GODOT=/path/to/godot."
  exit 1
fi
SUITES=(battle skirmish experience dispatch names world walk area skein wishlist controls seams art)

# The first run of a fresh checkout has no .godot/ cache; importing first keeps
# the import chatter out of the first suite's output.
ensure_imported() {
  [ -d .godot/imported ] || "$GODOT" --headless --path . --import >/dev/null 2>&1 || true
}

run_tests() {
  local wanted=("$@") failed=0 name out code verdict errors
  [ ${#wanted[@]} -eq 0 ] && wanted=("${SUITES[@]}")
  ensure_imported
  for name in "${wanted[@]}"; do
    out="$("$GODOT" --headless --path . "res://tests/${name}_smoke_test.tscn" 2>&1)"
    code=$?
    verdict="$(grep -E 'PASS|FAIL|failure|victory:' <<<"$out" | tr '\n' ' ' | sed 's/ *$//')"
    errors="$(grep -c 'SCRIPT ERROR' <<<"$out")"
    if [ $code -ne 0 ] || grep -qE 'FAIL|failure' <<<"$verdict" || [ "$errors" -gt 0 ]; then
      failed=$((failed + 1))
      printf '%-10s FAILED (exit %s, %s script errors) %s\n' "$name" "$code" "$errors" "$verdict"
      grep -E 'FAIL|failure|SCRIPT ERROR|^ +at:' <<<"$out" | head -20 | sed 's/^/    /'
    else
      printf '%-10s %s\n' "$name" "$verdict"
    fi
  done
  if [ $failed -gt 0 ]; then echo; echo "$failed suite(s) failing"; return 1; fi
  return 0
}

run_soak() {
  local seconds="${1:-120}" out code
  ensure_imported
  out="$("$GODOT" --headless --path . res://tools/soak.tscn -- --seconds="$seconds" --seed=77 2>&1)"
  code=$?
  tail -n 25 <<<"$out"
  if grep -q 'SCRIPT ERROR' <<<"$out"; then
    echo; echo "soak: SCRIPT ERROR"; grep -A2 'SCRIPT ERROR' <<<"$out" | head -30; return 1
  fi
  [ $code -eq 0 ] || { echo; echo "soak: exit code $code"; return 1; }
  grep -q 'the same file: true' <<<"$out" || { echo; echo "soak: save, load, save did not give the same file"; return 1; }
  return 0
}

# The Question Book and the answer ledger must agree on which questions exist
# and what an answer may say (a source never settles one). question_report
# exits 1 on any drift; this prints only the verdict and the drift lines.
run_ledger() {
  local out code
  ensure_imported
  out="$("$GODOT" --headless --path . res://tools/question_report.tscn 2>&1)"
  code=$?
  grep -E 'DRIFT|problem\(s\)|no drift|SCRIPT ERROR' <<<"$out"
  if grep -q 'SCRIPT ERROR' <<<"$out"; then return 1; fi
  return $code
}

case "${1:-}" in
  test) shift; run_tests "$@" ;;
  soak) shift; run_soak "$@" ;;
  ledger) run_ledger ;;
  *) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
