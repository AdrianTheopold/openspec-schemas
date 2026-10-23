#!/usr/bin/env bash
# Mechanical acceptance for the superpowers-bridge schema bundle.
#
#   run.sh check                          run every fixture's assertions
#   run.sh stage <fixture> <dir> [--config <file>]
#                                         build a throwaway repository for a fixture
#
# Set OPENSPEC to run the same assertions against another CLI binary.
set -u

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUNDLE=$(cd "$HERE/../../superpowers-bridge" && pwd)

# The runner must never phone home, and CI runners have no git identity.
export OPENSPEC_TELEMETRY=0
export OPENSPEC_NO_UPDATE_CHECK=1
export GIT_AUTHOR_NAME=fixture GIT_AUTHOR_EMAIL=fixture@example.invalid
export GIT_COMMITTER_NAME=fixture GIT_COMMITTER_EMAIL=fixture@example.invalid

# Every OpenSpec call, including those inside assertion commands, goes through here.
openspec() { command "${OPENSPEC:-openspec}" "$@"; }

# Planning labels that stop resolving once a change folder is archived.
LABEL_PATTERNS='\bD[0-9]+\b|\bTasks? [0-9]|\bStep [0-9]|\bFIX-[0-9]|design\.md|plan\.md'

FAILED=0
TMPROOT=""

cleanup() { [ -n "$TMPROOT" ] && rm -rf "$TMPROOT"; }
trap cleanup EXIT

# The source repository that stands in for governing documents. Fixtures without
# a kb/ directory have none, so the placeholder stays unresolved for them.
kb_source() {
  [ -d "$HERE/fixtures/$1/kb" ] && echo "$HERE/fixtures/$1/kb"
  return 0
}

stage() {
  local fixture=$1 dir=$2 config=""
  shift 2
  while [ $# -gt 0 ]; do
    case $1 in
      --config) config=$2; shift 2 ;;
      *) echo "stage: unknown argument $1" >&2; return 2 ;;
    esac
  done
  local fx="$HERE/fixtures/$fixture"
  [ -d "$fx" ] || { echo "stage: no fixture named $fixture" >&2; return 2; }

  local trunk
  trunk=$(tr -d '[:space:]' < "$fx/trunk")
  mkdir -p "$dir"
  (
    cd "$dir" || exit 1
    git init -q -b "$trunk" . || exit 1
    git config commit.gpgsign false
    # label_hits diffs against this, so it never has to guess the trunk.
    git config bridge.trunk "$trunk"
    [ -d "$fx/base" ] && cp -R "$fx/base/." .
    git add -A && git commit -q --allow-empty -m "base" || exit 1
    git checkout -q -b change || exit 1
    [ -d "$fx/branch" ] && cp -R "$fx/branch/." .
    git add -A && git commit -q --allow-empty -m "change" || exit 1

    # The bundle is copied in after the commits and excluded, so it never
    # shows up in the diff the assertions read.
    mkdir -p openspec/schemas
    cp -R "$BUNDLE" openspec/schemas/superpowers-bridge
    mkdir -p .git/info
    echo "openspec/schemas/" >> .git/info/exclude

    local kb
    kb=$(kb_source "$fixture")
    if [ -n "$config" ]; then
      src=$config
    elif [ -f "$fx/config.yaml" ]; then
      src="$fx/config.yaml"
    else
      src=""
    fi
    if [ -n "$src" ]; then
      sed "s|@KB@|$kb|g" "$src" > openspec/config.yaml
    else
      echo "schema: superpowers-bridge" > openspec/config.yaml
    fi
  ) || return 1
  echo "$dir"
}

# Added lines outside openspec/ that carry a planning label.
label_hits() {
  local dir=$1 trunk base
  trunk=$(git -C "$dir" config bridge.trunk) || { echo "label_hits: $dir was not staged by run.sh" >&2; return 1; }
  base=$(git -C "$dir" merge-base HEAD "$trunk")
  git -C "$dir" diff -U0 "$base" HEAD -- . ':(exclude)openspec' \
    | grep -E '^\+' | grep -vE '^\+\+\+' | grep -E "$LABEL_PATTERNS"
  return 0
}

report() { # <PASS|FAIL> <fixture> <name> [detail]
  if [ "$1" = PASS ]; then
    echo "PASS $2: $3"
  else
    echo "FAIL $2: $3 — ${4:-no detail}"
    FAILED=1
  fi
}

assert_true() { # <fixture> <name> <command>; runs in $DIR
  local out
  if out=$(cd "$DIR" && eval "$3" 2>&1); then
    report PASS "$1" "$2"
  else
    report FAIL "$1" "$2" "command failed: $3 ${out:+| $(echo "$out" | head -c 300 | tr '\n' ' ')}"
  fi
}

assert_json() { # <fixture> <name> <json-producing command> <python expression over j>
  local json out errfile
  errfile=$(mktemp "$TMPROOT/stderr.XXXXXX")
  # validate exits non-zero on findings but still prints JSON, so the exit
  # status is ignored. Only stdout is parsed; stderr is kept for the failure detail.
  json=$(cd "$DIR" && eval "$3" 2>"$errfile")
  if out=$(printf '%s' "$json" | python3 -c '
import json, sys
j = json.load(sys.stdin)
sys.exit(0 if eval(sys.argv[1]) else 1)
' "$4" 2>&1); then
    report PASS "$1" "$2"
  else
    report FAIL "$1" "$2" "expression false or output not JSON: $4 | $(echo "${out:-$json}" | head -c 300 | tr '\n' ' ') | stderr: $(head -c 300 "$errfile" | tr '\n' ' ')"
  fi
}

check_clean() {
  local fixture=clean
  if [ ! -d "$HERE/fixtures/$fixture" ]; then
    report FAIL "$fixture" fixture-present "no fixtures/$fixture directory"
    return
  fi
  DIR="$TMPROOT/$fixture"
  stage "$fixture" "$DIR" >/dev/null || { report FAIL "$fixture" stage "staging failed"; return; }

  assert_json clean strict-valid "openspec validate add-order-cancellation --strict --json" 'j["items"][0]["valid"] is True'
  assert_json clean no-archive-refusal "openspec validate add-order-cancellation --strict --json" 'not any(i["message"].startswith("Archive would refuse this delta") for it in j["items"] for i in it["issues"])'
  assert_json clean proposal-parses "openspec show add-order-cancellation --json" 'not any(s.get("severity")=="error" for s in j.get("status",[]))'
  assert_json clean delta-count "openspec show add-order-cancellation --json --deltas-only" 'j["deltaCount"]==2'
  assert_json clean scenarios-have-steps "openspec show add-order-cancellation --json --deltas-only" 'all("WHEN" in s["rawText"] and "THEN" in s["rawText"] for d in j["deltas"] for s in d["requirement"]["scenarios"])'
  assert_true clean only-scenario-headers "! grep -nP '^#### (?!Scenario:)' openspec/changes/add-order-cancellation/specs/orders/spec.md"
  assert_true clean purpose-set "! openspec validate orders --type spec --strict --json | grep -q 'Purpose section is still a placeholder'"
  assert_true clean no-label-hits '[ -z "$(label_hits .)" ]'
}

check_seeded() {
  local fixture=seeded
  DIR="$TMPROOT/$fixture"
  stage "$fixture" "$DIR" >/dev/null || { report FAIL "$fixture" stage "staging failed"; return; }

  assert_json seeded strict-fails "openspec validate rework-order-totals --strict --json" 'j["items"][0]["valid"] is False'
  assert_json seeded archive-refusal-info "openspec validate rework-order-totals --strict --json" 'sum(i["message"].startswith("Archive would refuse this delta") for it in j["items"] for i in it["issues"])==1'
  assert_json seeded one-stepless-scenario "openspec show rework-order-totals --json --deltas-only" 'sum(not("WHEN" in s["rawText"] and "THEN" in s["rawText"]) for d in j["deltas"] for s in d["requirement"]["scenarios"])==1'
  assert_true seeded one-non-scenario-header '[ "$(grep -cP "^#### (?!Scenario:)" openspec/changes/rework-order-totals/specs/orders/spec.md)" = 1 ]'
  assert_true seeded placeholder-purpose "openspec validate orders --type spec --strict --json | grep -q 'Purpose section is still a placeholder'"
  assert_true seeded one-label-hit '[ "$(label_hits . | wc -l)" = 1 ] && label_hits . | grep -q "Task 3: recompute"'
  assert_true seeded sibling-collision 'for c in rework-order-totals adjust-order-totals; do awk "/^## MODIFIED/{m=1;next} /^## /{m=0} m" openspec/changes/$c/specs/orders/spec.md | grep -q "^### Requirement: Orders are priced$" || exit 1; done'
}

check_seeded_proposal() {
  local fixture=seeded-proposal
  DIR="$TMPROOT/$fixture"
  stage "$fixture" "$DIR" >/dev/null || { report FAIL "$fixture" stage "staging failed"; return; }

  assert_json seeded-proposal proposal-error "openspec show fix-order-rounding --json" 'any(s.get("severity")=="error" for s in j.get("status",[]))'
  assert_json seeded-proposal no-deltas-while-unparsed "openspec show fix-order-rounding --json --deltas-only" 'j.get("deltaCount",0)==0'
}

check() {
  TMPROOT=$(mktemp -d)
  check_clean
  check_seeded
  check_seeded_proposal
  exit "$FAILED"
}

case ${1:-} in
  check) check ;;
  stage) shift; stage "$@" ;;
  *) echo "usage: run.sh check | stage <fixture> <dir> [--config <file>]" >&2; exit 2 ;;
esac
