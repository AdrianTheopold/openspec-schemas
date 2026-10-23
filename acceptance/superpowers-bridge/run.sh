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

# A second repository beside the staged one stands in for an adopter's governing
# documents: kb/trunk/ is its accepted state on main, kb/amend/ a branch that
# amends it. The amending branch is left checked out, so the working tree shows
# the amended text and only a read at the trunk shows what was accepted.
stage_kb() { # <fixture dir> <kb repository dir>
  local fx=$1 kb=$2
  mkdir -p "$kb"
  (
    cd "$kb" || exit 1
    git init -q -b main . || exit 1
    git config commit.gpgsign false
    cp -R "$fx/kb/trunk/." . || exit 1
    git add -A && git commit -q -m "accepted" || exit 1
    git checkout -q -b amend || exit 1
    # Replace the tree rather than overlay it, so a file the branch removes is gone.
    git rm -rq . || exit 1
    cp -R "$fx/kb/amend/." . || exit 1
    git add -A && git commit -q --allow-empty -m "amend" || exit 1
  )
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
  if [ -n "$config" ]; then
    # Absolute, because the config is read after changing into the staged directory.
    [ -f "$config" ] || { echo "stage: no config file $config" >&2; return 2; }
    config="$(cd "$(dirname "$config")" && pwd)/$(basename "$config")"
  fi

  local trunk kb=""
  trunk=$(tr -d '[:space:]' < "$fx/trunk")
  mkdir -p "$dir"
  if [ -d "$fx/kb" ]; then
    # Absolute, because the path is written into the staged configuration.
    kb="$(cd "$dir" && pwd).kb"
    stage_kb "$fx" "$kb" || return 1
  fi
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

    # The executor's ledger, where its rulings are recorded, is scratch the
    # executor never commits; it is placed where the executor keeps it and
    # excluded for the same reason as the bundle.
    if [ -d "$fx/sdd" ]; then
      mkdir -p .superpowers/sdd
      cp -R "$fx/sdd/." .superpowers/sdd/
      echo ".superpowers/" >> .git/info/exclude
    fi

    if [ -n "$config" ]; then
      src=$config
    elif [ -f "$fx/config.yaml" ]; then
      src="$fx/config.yaml"
    else
      src=""
    fi
    # A fixture without kb/ has no source repository, so its placeholder stays.
    if [ -n "$src" ] && [ -n "$kb" ]; then
      sed "s|@KB@|$kb|g" "$src" > openspec/config.yaml
    elif [ -n "$src" ]; then
      cp "$src" openspec/config.yaml
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
  # Verify's spec review must survive a later refresh of the instruction and template.
  assert_json clean verify-has-check-8 "openspec instructions verify --change add-order-cancellation --json" '"8. **Spec review**" in j["instruction"] and "spec-review.md" in j["instruction"]'
  assert_json clean verify-template-8 "openspec instructions verify --change add-order-cancellation --json" '"## 8. Spec Review" in j["template"]'
  # The deviation report must survive a later refresh too, including the line
  # an adopter without governing sources gets.
  assert_json clean verify-has-check-9 "openspec instructions verify --change add-order-cancellation --json" '"9. **Deviation report**" in j["instruction"] and "No governing sources configured" in j["instruction"]'
  # The security pass must survive a later refresh of the instruction as well.
  assert_json clean verify-has-check-10 "openspec instructions verify --change add-order-cancellation --json" '"10. **Security pass**" in j["instruction"]'
  # The retrospective must keep tallying dismissed findings, the signal that a rule needs sharpening.
  assert_json clean retro-tally "openspec instructions retrospective --change add-order-cancellation --json" '"dismissal" in j["instruction"] and "Dismissals by rule" in j["template"]'
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

# The rule file both review points read: it must be found where agents look for
# it, and it must carry the strings and patterns the checks and the card match on.
check_rule_file() {
  DIR="$TMPROOT/rule-file"
  stage clean "$DIR" >/dev/null || { report FAIL rule-file stage "staging failed"; return; }

  assert_json clean rule-file-resolves "openspec schema which superpowers-bridge --json" '__import__("os").path.isfile(j["path"]+"/spec-review.md")'
  local s
  for s in 'Archive would refuse this delta' 'Purpose section is still a placeholder' 'No findings.' 'pre-existing' '\bD[0-9]+\b' '\bTasks? [0-9]' '\bStep [0-9]' '\bFIX-[0-9]' 'design\.md' 'plan\.md'; do
    assert_true rule-file "pins $s" "grep -qF -- '$s' \"$BUNDLE/spec-review.md\""
  done
  # The rule file and label_hits must search for the same thing, so the runner's
  # alternation has to appear in the rule file exactly as written here.
  assert_true rule-file patterns-match-runner '[ "$(grep -oF -- "$LABEL_PATTERNS" "$BUNDLE/spec-review.md" | head -1)" = "$LABEL_PATTERNS" ]'
  assert_json clean template-carries-note "openspec instructions specs --change add-order-cancellation --json" '"spec-review.md" in j["template"] and "schema which superpowers-bridge" in j["template"]'
  assert_true template note-inside-comment 'note_inside_comment "$BUNDLE/templates/spec.md"'
}

# The template's note must sit inside an HTML comment: OpenSpec warns on prose
# above a spec's first section, and a comment does not trigger it.
note_inside_comment() { # <template file>
  python3 - "$1" <<'PY'
import sys
t = open(sys.argv[1]).read()
i = t.index("spec-review.md")
assert t.rfind("<!--", 0, i) > t.rfind("-->", 0, i)
PY
}

# A change with code but no delta specs still gets the code-label search.
check_no_deltas() {
  local fixture=no-deltas
  if [ ! -d "$HERE/fixtures/$fixture" ]; then
    report FAIL "$fixture" fixture-present "no fixtures/$fixture directory"
    return
  fi
  DIR="$TMPROOT/$fixture"
  stage "$fixture" "$DIR" >/dev/null || { report FAIL "$fixture" stage "staging failed"; return; }

  assert_json no-deltas empty-deltas "openspec show tidy-order-module --json --deltas-only" 'j.get("deltaCount",0)==0'
  assert_true no-deltas no-label-hits '[ -z "$(label_hits .)" ]'
}

# The plan is the channel that reaches the implementing subagent, so the
# comment rule, the commit trailer and the adopter's safety rules must reach it.
# Staged with a configuration that carries a safety rule as a pointer, so the
# rule is shown arriving through OpenSpec's own channel.
check_plan() {
  DIR="$TMPROOT/plan"
  stage clean "$DIR" --config "$HERE/fixtures/clean/config.safety.yaml" >/dev/null || { report FAIL clean plan-stage "staging failed"; return; }

  assert_json clean plan-rules-delivered "openspec instructions plan --change add-order-cancellation --json" 'any("SAFETY.md" in r for r in j.get("rules",[]))'
  assert_json clean plan-instruction-label-rule "openspec instructions plan --change add-order-cancellation --json" '"cite no planning labels" in j["instruction"] and "Refs: <change-name> decision D<n>; task <n>" in j["instruction"]'
  assert_json clean plan-template-sections "openspec instructions plan --change add-order-cancellation --json" '"## Global Constraints" in j["template"] and "## Review Focus" in j["template"]'
}

# The apply controller holds to the adopter's apply guidance and ends by writing
# the review card into the pull request, so the guidance must arrive through
# OpenSpec's own channel and the instruction must carry the card and the comment
# rule. Staged with a configuration that carries one apply guidance line.
check_apply() {
  DIR="$TMPROOT/apply"
  stage clean "$DIR" --config "$HERE/fixtures/clean/config.apply.yaml" >/dev/null || { report FAIL clean apply-stage "staging failed"; return; }

  assert_json clean apply-guidance-delivered "openspec instructions apply --change add-order-cancellation --json" 'any("database migration" in g for g in (j.get("operationGuidance") or []))'
  assert_json clean apply-card-rule "openspec instructions apply --change add-order-cancellation --json" '"Review Card" in j["instruction"] and "cite no planning labels" in j["instruction"]'
  assert_true template card-order 'card_order "$BUNDLE/templates/verify.md"'
}

# The review card's six parts in their fixed order, under a final section of
# verify.md, so the card the controller copies into the pull request reads the
# same in every change.
card_order() { # <template file>
  python3 - "$1" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
parts = ["### Deviations", "### What the checks did not cover", "### Evidence",
         "### Security pass", "### How to revert", "### Rulings"]
card = t.index("## Review Card")
idx = [t.index(p, card) for p in parts]
assert idx == sorted(idx)
assert not re.search(r"^## ", t[card + 1:], re.M), "a section follows the review card"
PY
}

# A change that moves away from its governing source. The source repository has
# a branch amending that source checked out, so a reader that takes the working
# tree instead of the trunk sees no deviation at all.
check_deviation() {
  local fixture=deviation
  if [ ! -d "$HERE/fixtures/$fixture" ]; then
    report FAIL "$fixture" fixture-present "no fixtures/$fixture directory"
    return
  fi
  DIR="$TMPROOT/$fixture"
  stage "$fixture" "$DIR" >/dev/null || { report FAIL "$fixture" stage "staging failed"; return; }

  assert_json deviation context-delivered "openspec instructions verify --change purge-cancelled-orders --json" '"show main:orders-direction.md" in j.get("context","")'
  assert_json deviation verify-rules-delivered "openspec instructions verify --change purge-cancelled-orders --json" 'any("Sensitive areas" in r for r in j.get("rules",[]))'
  assert_true deviation source-on-amend-branch '[ "$(git -C "$DIR.kb" branch --show-current)" = amend ]'
}

# A change whose code carries two security defects for the security pass to find:
# a hard-coded credential and a request with certificate verification turned off.
# The assertion only proves both reach the diff against the trunk; finding them
# is the agent's part.
check_security() {
  local fixture=security
  if [ ! -d "$HERE/fixtures/$fixture" ]; then
    report FAIL "$fixture" fixture-present "no fixtures/$fixture directory"
    return
  fi
  DIR="$TMPROOT/$fixture"
  stage "$fixture" "$DIR" >/dev/null || { report FAIL "$fixture" stage "staging failed"; return; }

  assert_true security two-seeds '[ "$(git diff main...HEAD -U0 | grep -cE "^\+.*(API_PASSWORD = |verify=False)")" = 2 ]'
}

# The release number the bundle announces must agree in VERSION and in both
# maintained READMEs.
check_release() {
  DIR="$TMPROOT/release"
  mkdir -p "$DIR"
  assert_true release version '[ "$(tr -d "[:space:]" < "$BUNDLE/VERSION")" = 1.5.0 ] && grep -q "1.5.0" "$BUNDLE/README.md" && grep -q "1.5.0" "$BUNDLE/README.zh-TW.md"'
}

check() {
  TMPROOT=$(mktemp -d)
  check_clean
  check_plan
  check_apply
  check_seeded
  check_seeded_proposal
  check_rule_file
  check_no_deltas
  check_deviation
  check_security
  check_release
  exit "$FAILED"
}

case ${1:-} in
  check) check ;;
  stage) shift; stage "$@" ;;
  *) echo "usage: run.sh check | stage <fixture> <dir> [--config <file>]" >&2; exit 2 ;;
esac
