# superpowers-bridge 1.5.0 — Spec Review and Deviation Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship bundle 1.5.0: a spec-review rule file, verify checks 8 (spec review), 9 (deviation report) and 10 (security pass), the plan and apply rules that carry adopter rulesets to every task, a review card for the pull request, and committed acceptance fixtures.

**Architecture:** The bundle stays prose: one new file (`spec-review.md`) and edits to `schema.yaml` and the templates. Adopter content arrives only through `openspec/config.yaml` (`context`, `rules.plan`, `rules.verify`, `operations.apply.guidance`). Outside the bundle, `acceptance/superpowers-bridge/` holds fixture projects and a shell runner: `run.sh check` asserts everything OpenSpec computes deterministically and runs in CI; `run.sh stage` materializes a fixture as a git project for the agent-judged acceptance runs of Task 12.

**Tech Stack:** OpenSpec CLI 1.14.3, YAML, Markdown, bash, git, python3 (JSON parsing in the runner only), GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-24-spec-review-design.md` (fourth revision). Decisions are cited as "Decision n" of that document.

## Global Constraints

- The repository is public. No file names an adopter, its organization, its systems, its knowledge base or its page IDs. Examples use the design's neutral `orders` domain.
- OpenSpec CLI 1.14.3 locally and in CI (`npm install -g @fission-ai/openspec@1.14.3`).
- The bundle gains no code, no dependency and no PRECHECK, and no PRECHECK is removed. No line is added to the four instructions inherited from upstream: `proposal`, `specs`, `design`, `tasks` (Goals of the design).
- No instruction tells an agent to run `git add` or `git commit` on the user's behalf (`CLAUDE.md` red flags). Commit steps inside a generated plan are writing-plans' own and stay as they are.
- `openspec schema validate superpowers-bridge` passes after every task that touches `superpowers-bridge/`.
- Pinned values: ADDED requirement limit 500 characters (Decision 7); delta-count prompt above 10 (Decision 7); round cap 3 runs (Decision 6).
- Pinned strings, verbatim wherever they appear: `No findings.` · `No deviations from the governing sources.` · `No governing sources configured` · `pre-existing` · the INFO prefix `Archive would refuse this delta` · the warning prefix `Purpose section is still a placeholder`.
- Pinned label patterns (Decision 10), verbatim: `\bD[0-9]+\b`, `\bTasks? [0-9]`, `\bStep [0-9]`, `\bFIX-[0-9]`, `design\.md`, `plan\.md`.
- Comments and docstrings in `run.sh` and the fixtures' code state reasons in words and cite no planning labels — no decision numbers, task or step numbers, no `plan.md`. Commit messages carry the trace: each ends with a trailer `Refs: spec-review design Decision <n>[, <n>…]; plan Task <n>`.
- Commits use the clone's configured GitHub noreply author; verify with `git show -s --format='%ae'` before any push. Commit messages in English, conventional-commit prefixes (`feat:`, `docs:`, `ci:`, `test:`).
- English is canonical for `README.md`, `schema.yaml` and templates; `README.zh-TW.md` is synced in the same task as its English counterpart. `README.vi-VN.md` is community-maintained and is not edited.
- Pushing `feat/spec-review` is approved. Opening the pull request, and merging, are not: the branch reaches `main` only after the pilot of Task 13 and the owner's verdict.

## Review Focus

1. A change with no delta specs (docs-only, refactor) — check 8 must still run the code-label search and report `No findings.`, not fail on an empty `--deltas-only`. Test: Task 3, assertion `no-deltas`.
2. A repository whose trunk is `master`, not `main` — the code-label search, the deviation report and the security pass must diff against the branch the change merges into. Test: the `seeded` fixture's trunk is `master` (Task 2), and Task 12 runs check 8 on it.
3. A governing source that cannot be read (a missing path, a command that fails) — verify must FAIL naming the source, not report "No deviations". Test: Task 6 `deviation-unreadable` config, run in Task 12.
4. A governing source whose checked-out copy is a branch that amends it — check 9 must read the trunk version. Test: the `deviation` fixture checks out the amending branch in its source repository (Task 6), run in Task 12.
5. A re-run of verify after the agent dismissed a finding — the dismissed finding must not come back unless its quoted text changed. Test: Task 12, item 2b.

---

## File Structure

| Path | Responsibility |
|---|---|
| `superpowers-bridge/spec-review.md` (create) | The rule file both review points read (Decisions 1–7, 9, 10) |
| `superpowers-bridge/schema.yaml` (modify) | `plan`, `verify`, `retrospective` and `apply` instructions only |
| `superpowers-bridge/templates/spec.md` (modify) | Draft-time note inside the header comment (Decision 8) |
| `superpowers-bridge/templates/plan.md` (modify) | Global Constraints and Review Focus placeholders |
| `superpowers-bridge/templates/verify.md` (modify) | Sections 8, 9, 10 and the review card |
| `superpowers-bridge/templates/retrospective.md` (modify) | Dismissal tally |
| `superpowers-bridge/README.md`, `README.zh-TW.md`, `VERSION` (modify) | Lifecycle, checks, configuration keys, release line |
| `acceptance/superpowers-bridge/run.sh` (create) | `check` and `stage` subcommands |
| `acceptance/superpowers-bridge/README.md` (create) | What each fixture proves; how to run the agent acceptance |
| `acceptance/superpowers-bridge/fixtures/<name>/` (create) | `trunk` (branch name), `base/` (trunk tree), `branch/` (overlay committed on branch `change`), optional `config.yaml`, `kb/`, `expected.md` |
| `.github/workflows/validate-schemas.yml` (modify) | Runs `run.sh check` |
| `CLAUDE.md` (modify) | Repository tree gains `acceptance/` and `spec-review.md` |

Reuse check for the two `Create:` entries outside fixtures: the repository has no test harness (`git ls-files` shows only the bundle, docs and one workflow), and the workbench `bridge` tests exercise a different tool. The fixtures live outside `superpowers-bridge/` so that installing the bundle does not install them.

---

### Task 1: Acceptance runner and the clean fixture

**Files:**
- Create: `acceptance/superpowers-bridge/run.sh`, `acceptance/superpowers-bridge/README.md`
- Create: `acceptance/superpowers-bridge/fixtures/clean/` — `trunk` (`main`), `base/openspec/specs/orders/spec.md`, `base/src/orders/store.py`, `branch/openspec/changes/add-order-cancellation/{proposal.md,design.md,tasks.md,specs/orders/spec.md}`, `branch/src/orders/cancel.py`, `expected.md`
- Modify: `.github/workflows/validate-schemas.yml`

**Interfaces:**
- Produces: `run.sh check` — runs every fixture's assertions; prints one `PASS <fixture>: <assertion>` or `FAIL <fixture>: <assertion> — <detail>` line each; exits 0 only if none failed.
- Produces: `run.sh stage <fixture> <dir> [--config <file>]` — creates a git repository at `<dir>`: commits `base/` on the branch named in `trunk`, creates branch `change` with `branch/` committed on top and checked out, copies `superpowers-bridge/` to `<dir>/openspec/schemas/superpowers-bridge` and lists `openspec/schemas/` in `.git/info/exclude`, writes `openspec/config.yaml` from `--config`, else from the fixture's `config.yaml`, else `schema: superpowers-bridge`, replacing `@KB@` with the path of the fixture's source repository (Task 6). Prints `<dir>`.
- Produces: every OpenSpec call in `run.sh` goes through `${OPENSPEC:-openspec}`, so the same assertions can run against another CLI version (Task 2, Step 5).
- Produces (internal helpers, used by every later task): `assert_true <fixture> <name> <command>`; `assert_json <fixture> <name> <json-producing command> <python expression over j>`; `label_hits <dir>` — prints added lines outside `openspec/` matching the pinned label patterns, diffing against `$(git merge-base HEAD <trunk>)`.

- [ ] **Step 1: Write the failing assertions for `clean`**

In `run.sh`, a `check_clean` function that stages `clean` into a temp dir and asserts:

```bash
assert_json clean strict-valid "openspec validate add-order-cancellation --strict --json" 'j["items"][0]["valid"] is True'
assert_json clean no-archive-refusal "openspec validate add-order-cancellation --strict --json" 'not any(i["message"].startswith("Archive would refuse this delta") for it in j["items"] for i in it["issues"])'
assert_json clean proposal-parses "openspec show add-order-cancellation --json" 'not any(s.get("severity")=="error" for s in j.get("status",[]))'
assert_json clean delta-count "openspec show add-order-cancellation --json --deltas-only" 'j["deltaCount"]==2'
assert_json clean scenarios-have-steps "openspec show add-order-cancellation --json --deltas-only" 'all("WHEN" in s["rawText"] and "THEN" in s["rawText"] for d in j["deltas"] for s in d["requirement"]["scenarios"])'
assert_true clean only-scenario-headers "! grep -nP '^#### (?!Scenario:)' openspec/changes/add-order-cancellation/specs/orders/spec.md"
assert_true clean purpose-set "! openspec validate orders --type spec --strict --json | grep -q 'Purpose section is still a placeholder'"
assert_true clean no-label-hits '[ -z "$(label_hits .)" ]'
```

The JSON paths above are the 1.14.3 shapes recorded in the design (Decision 3: `requirement.text`, `scenarios[].rawText`, `deltaCount`). If a path differs on 1.14.3, correct the expression and note the real shape in the commit message — do not loosen the assertion.

- [ ] **Step 2: Run it to verify it fails**

Run: `acceptance/superpowers-bridge/run.sh check`
Expected: exit 1, `FAIL clean: …` lines naming the missing fixture.

- [ ] **Step 3: Write the `clean` fixture**

Main spec `orders` with a real Purpose and one requirement "Orders are stored" (two scenarios). The change `add-order-cancellation` carries one ADDED requirement ("Orders can be cancelled before shipping", one SHALL, two scenarios with WHEN and THEN, under 500 characters) and one MODIFIED block of "Orders are stored" that keeps both main-spec scenarios by their titles and changes only its own behavior. `cancel.py` has a comment that states a reason in words. `expected.md` states the expected agent outcomes: check 8 `No findings.`; check 9 with no configuration `No governing sources configured`; check 10 zero findings.

- [ ] **Step 4: Run it to verify it passes**

Run: `acceptance/superpowers-bridge/run.sh check`
Expected: exit 0, eight `PASS clean:` lines.

- [ ] **Step 5: Wire CI**

In `validate-schemas.yml`, after "List schemas (smoke test)", add a step `Mechanical acceptance` that runs `acceptance/superpowers-bridge/run.sh check` from the checkout root. It needs no install: the runner copies the bundle itself.

- [ ] **Step 6: Commit**

```bash
git add acceptance/ .github/workflows/validate-schemas.yml
git commit -m "test(bridge): add the acceptance runner and a clean fixture" -m "Refs: spec-review design Decision 3; plan Task 1"
```

---

### Task 2: Seeded fixtures

**Files:**
- Create: `acceptance/superpowers-bridge/fixtures/seeded/` — `trunk` (`master`), `base/…`, `branch/…`, `expected.md`
- Create: `acceptance/superpowers-bridge/fixtures/seeded-proposal/` — `trunk` (`main`), `base/…`, `branch/…`
- Modify: `acceptance/superpowers-bridge/run.sh` (`check_seeded`, `check_seeded_proposal`)

**Interfaces:**
- Consumes: `stage`, `assert_json`, `assert_true`, `label_hits` from Task 1.
- Produces: `fixtures/seeded/expected.md` — one row per seed: id, file, rule or table row, quoted text. Task 12 compares agent findings against it.

The `seeded` change is `rework-order-totals`; its sibling is `adjust-order-totals`. One seed per rule group and per Decision 3 row, none overlapping:

| Seed | Where | Text (exact) |
|---|---|---|
| T1 (strict length) | ADDED "Orders record their fulfilment history" | a 520–600 character requirement with five `MUST`s |
| T2 (archive refusal) | ADDED "Orders are stored" | header that already exists in the main spec |
| T4a (step-less scenario) | scenario "Totals are visible" | body without WHEN or THEN |
| T4b (non-scenario header) | requirement "Orders expose their totals" | `#### Notes` as a level-4 header |
| T5 (placeholder Purpose) | main spec `orders` | `TBD - created by archiving change …` Purpose |
| R1 | MODIFIED "Orders are priced" | adds "Every order MUST carry a checksum of its lines." |
| R2 | scenario "Order is stored" | "WHEN an order is placed THEN it is stored as an immutable document." |
| R3 | ADDED requirement text | "This change SHALL add no deletion endpoint." |
| R4 | a THEN | "THEN the order is rejected, because design D4 keeps validation in the gateway." |
| R5 | requirement title | "### Requirement: Order validation (D9)" |
| R6 | ADDED requirement | "The parity suite MUST keep all three payment adapters in agreement." while `base/tests/test_parity.py` compares two |
| R7 | REMOVED "Orders can be listed" naming `list_orders()` | main-spec requirement "Orders expose their totals" still says "`list_orders()` SHALL return …" |
| S1 (sibling) | `adjust-order-totals` | MODIFIED "Orders are priced", the same requirement R1's block modifies |
| L1 (code label) | `branch/src/orders/totals.py` | `# Task 3: recompute totals after a line is removed` |

The `seeded-proposal` change carries a `proposal.md` without `## Why` and one clean delta.

- [ ] **Step 1: Write the failing assertions**

```bash
assert_json seeded strict-fails "openspec validate rework-order-totals --strict --json" 'j["items"][0]["valid"] is False'
assert_json seeded archive-refusal-info "openspec validate rework-order-totals --strict --json" 'sum(i["message"].startswith("Archive would refuse this delta") for it in j["items"] for i in it["issues"])==1'
assert_json seeded one-stepless-scenario "openspec show rework-order-totals --json --deltas-only" 'sum(not("WHEN" in s["rawText"] and "THEN" in s["rawText"]) for d in j["deltas"] for s in d["requirement"]["scenarios"])==1'
assert_true seeded one-non-scenario-header '[ "$(grep -cP "^#### (?!Scenario:)" openspec/changes/rework-order-totals/specs/orders/spec.md)" = 1 ]'
assert_true seeded placeholder-purpose "openspec validate orders --type spec --strict --json | grep -q 'Purpose section is still a placeholder'"
assert_true seeded one-label-hit '[ "$(label_hits . | wc -l)" = 1 ] && label_hits . | grep -q "Task 3: recompute"'
assert_true seeded sibling-collision 'for c in rework-order-totals adjust-order-totals; do awk "/^## MODIFIED/{m=1;next} /^## /{m=0} m" openspec/changes/$c/specs/orders/spec.md | grep -q "^### Requirement: Orders are priced$" || exit 1; done'
assert_json seeded-proposal proposal-error "openspec show fix-order-rounding --json" 'any(s.get("severity")=="error" for s in j.get("status",[]))'
assert_json seeded-proposal no-deltas-while-unparsed "openspec show fix-order-rounding --json --deltas-only" 'j.get("deltaCount",0)==0'
```

- [ ] **Step 2: Run to verify they fail**

Run: `acceptance/superpowers-bridge/run.sh check`
Expected: `clean` passes; every `seeded*` assertion FAILs (fixtures missing).

- [ ] **Step 3: Write both fixtures and `seeded/expected.md`**

Seed exactly the table above. `expected.md` lists the fourteen seeds, says "each found exactly once, and nothing else", and marks T1–T5 as found by commands and R1–R7, S1, L1 as found by reading.

- [ ] **Step 4: Run to verify they pass**

Run: `acceptance/superpowers-bridge/run.sh check`
Expected: exit 0. An assertion that fails because 1.14.3 behaves differently from the design's table is a finding about the design, not the fixture: stop and report it with the actual output.

- [ ] **Step 5: Test whether `check` earns its place**

`check` is worth keeping only if it catches something no other step catches: OpenSpec changing the behavior the rule file relies on when the pin moves. Run it once under OpenSpec 1.13.0, where the design records different behavior (no strict failure on a long ADDED requirement, no error on an empty scenario): `OPENSPEC="npx -y @fission-ai/openspec@1.13.0" acceptance/superpowers-bridge/run.sh check` (`run.sh` calls `${OPENSPEC:-openspec}` everywhere).
Expected: `seeded: strict-fails` FAILs, and every failure traces to a row of the design's 1.13.0/1.14.2 table.
This downloads and runs a tool outside the declared dependencies: ask the owner before running it locally, or run it once in CI on this branch with the pin temporarily set to 1.13.0 and reverted in the next commit.
Decision rule: if no assertion fails under 1.13.0, the `check` mode guards nothing — remove it and its CI step, keep `stage`, and say so in the commit message. Otherwise keep it, and record in the commit message which assertions caught the difference.

- [ ] **Step 6: Commit**

```bash
git add acceptance/
git commit -m "test(bridge): seed one defect per spec-review rule and command check" -m "Refs: spec-review design Decision 3, 5, 9, 10; plan Task 2"
```

---

### Task 3: The rule file

**Files:**
- Create: `superpowers-bridge/spec-review.md`
- Create: `acceptance/superpowers-bridge/fixtures/no-deltas/` — `trunk` (`main`), `base/…`, `branch/` with a change that has `proposal.md` and `tasks.md` but no `specs/`, plus one code file with a reason comment
- Modify: `acceptance/superpowers-bridge/run.sh` (`check_rule_file`, `check_no_deltas`)

**Interfaces:**
- Produces: `superpowers-bridge/spec-review.md`, located at runtime as `<path>/spec-review.md` with `path` from `openspec schema which superpowers-bridge --json`. Its section 7 report format is what checks 8 and 10 (Tasks 5, 7) and the review card (Task 9) consume.

- [ ] **Step 1: Write the failing assertions**

```bash
assert_json clean rule-file-resolves "openspec schema which superpowers-bridge --json" '__import__("os").path.isfile(j["path"]+"/spec-review.md")'
for s in 'Archive would refuse this delta' 'Purpose section is still a placeholder' 'No findings.' 'pre-existing' '\bD[0-9]+\b' '\bTasks? [0-9]' '\bStep [0-9]' '\bFIX-[0-9]' 'design\.md' 'plan\.md'; do
  assert_true rule-file "pins $s" "grep -qF -- '$s' \"$BUNDLE/spec-review.md\""
done
assert_true rule-file patterns-match-runner '[ "$(grep -oF -- "$LABEL_PATTERNS" "$BUNDLE/spec-review.md" | head -1)" = "$LABEL_PATTERNS" ]'
assert_json no-deltas empty-deltas "openspec show tidy-order-module --json --deltas-only" 'j.get("deltaCount",0)==0'
assert_true no-deltas no-label-hits '[ -z "$(label_hits .)" ]'
```

`LABEL_PATTERNS` is the one alternation string `label_hits` already uses, so the rule file and the runner cannot drift apart silently.

- [ ] **Step 2: Run to verify they fail**

Run: `acceptance/superpowers-bridge/run.sh check`
Expected: `rule-file` and `no-deltas` assertions FAIL.

- [ ] **Step 3: Write `spec-review.md`**

Seven sections, in the design's outline order ("The rule file"):

1. **When this file is used** — the draft-time self-check and verify check 8; a finding is cleared by a fix or by a one-line dismissal reason in `verify.md`; a fix that would change behavior a governing source states is a deviation, reported by check 9 instead; the round cap (3 runs, then only what changed since the previous run, then the card), no repeats unless the quoted text changed, `pre-existing` for text the change did not add (Decision 6). A change with no delta specs: skip sections 2–4 and 6, still run section 5, and report `No findings.` if it finds nothing.
2. **What OpenSpec already checks** — Decision 3's table for 1.14.3, including the "fix the proposal first" ordering and the scenario-title note for a MODIFIED block that drops a scenario.
3. **OpenSpec's authoring rules** — Decision 4's pointer (`openspec instructions specs --change <name> --json`, field `instruction`; "Good spec content", "Avoid in specs", "Quick test"), not a copy.
4. **Rules this bundle adds** — the seven groups of Decision 5, each as rule, test, one before/after; the before/after texts are the design's.
5. **Beyond the delta specs** — the sibling-change check (Decision 9) and the code-label search with the six patterns, the diff `git diff <base>...HEAD` where `<base>` is the branch the change merges into, falling back to the merge base verify's PRECHECK computes, and the repair guidance (state the reason; scope a needed source by the change's name) (Decision 10).
6. **Thresholds** — Decision 7; only the draft-time pass reads the delta count.
7. **Report format** — count first (`3 findings, 1 pre-existing`), then `<file>:<line> — rule <n> — "<quoted text>" — <suggested fix>`, or `No findings.`; a recurring defect is one finding naming its class and every place.

Short: aim under 250 lines. Every rule has a test that says what failure looks like; style is excluded in one sentence.

- [ ] **Step 4: Run to verify they pass, and validate the bundle**

Run: `acceptance/superpowers-bridge/run.sh check` — Expected: exit 0.
Run (in a staged fixture dir): `openspec schema validate superpowers-bridge` — Expected: valid.

- [ ] **Step 5: Commit**

```bash
git add superpowers-bridge/spec-review.md acceptance/
git commit -m "feat(bridge): add the spec-review rule file" -m "Refs: spec-review design Decision 1-7, 9, 10; plan Task 3"
```

---

### Task 4: The draft-time note in the spec template

**Files:**
- Modify: `superpowers-bridge/templates/spec.md` (header comment only)
- Modify: `acceptance/superpowers-bridge/run.sh`

**Interfaces:**
- Consumes: the rule file's location rule from Task 3.

- [ ] **Step 1: Write the failing assertions**

```bash
assert_json clean template-carries-note "openspec instructions specs --change add-order-cancellation --json" '"spec-review.md" in j["template"] and "schema which superpowers-bridge" in j["template"]'
assert_true template note-inside-comment 'python3 - "$BUNDLE/templates/spec.md" <<'"'"'PY'"'"'
import re,sys; t=open(sys.argv[1]).read(); i=t.index("spec-review.md")
assert t.rfind("<!--",0,i) > t.rfind("-->",0,i)
PY'
```

- [ ] **Step 2: Run to verify they fail** — `run.sh check`; Expected: both FAIL.

- [ ] **Step 3: Add the note**

Inside the first HTML comment, after the hard-format rules: before finishing the delta spec, run the draft-time self-check in `spec-review.md` — at `<path>/spec-review.md`, `path` from `openspec schema which superpowers-bridge --json` — fix what it finds, and if the change has more than 10 deltas, confirm it has one intent: split it, or state the intent in one sentence in the proposal. Three to five lines.

- [ ] **Step 4: Run to verify they pass** — `run.sh check`; Expected: exit 0, `clean: strict-valid` still PASS.

- [ ] **Step 5: Commit** — `git commit -m "feat(bridge): point the spec template at the draft-time self-check" -m "Refs: spec-review design Decision 7, 8; plan Task 4"`

---

### Task 5: Verify check 8 — spec review

**Files:**
- Modify: `superpowers-bridge/schema.yaml` (`verify.instruction`: new check 8 after check 7; the closing paragraphs)
- Modify: `superpowers-bridge/templates/verify.md` (new `## 8. Spec Review`; Overall Decision)
- Modify: `acceptance/superpowers-bridge/run.sh`

**Interfaces:**
- Consumes: `spec-review.md` sections 1, 5 and 7.
- Produces: `verify.md` § 8 layout — a count line, a findings table (`File:line | Rule | Quoted text | Outcome: fixed / dismissed — <reason> | pre-existing?`), and a run counter `Run <n> of 3` that the apply loop (Task 9) reads.

The assertions in this task guard against an instruction lost in a later refresh; whether check 8 works is proven by the agent runs of Task 12.

- [ ] **Step 1: Write the failing assertions**

```bash
assert_json clean verify-has-check-8 "openspec instructions verify --change add-order-cancellation --json" '"8. **Spec review**" in j["instruction"] and "spec-review.md" in j["instruction"]'
assert_json clean verify-template-8 "openspec instructions verify --change add-order-cancellation --json" '"## 8. Spec Review" in j["template"]'
```

- [ ] **Step 2: Run to verify they fail** — Expected: both FAIL.

- [ ] **Step 3: Write check 8**

It says: dispatch a general-purpose subagent with no prior context, passing only the change name and the rule file's path (resolved as in the rule file's section 1), the way `requesting-code-review` dispatches its final reviewer; the subagent applies the whole rule file and returns its report in the section 7 format. The controller clears every finding — fix, or dismiss with a reason recorded in § 8 — and re-runs check 8 under the round cap, no-repeat and `pre-existing` rules of the rule file. A finding still open after the cap is carried to the review card. Check 8 runs its own `openspec validate <change> --strict`; check 1 stays non-strict. Any uncleared finding sets Overall Decision to FAIL.

- [ ] **Step 4: Write § 8 in the template and the FAIL condition** in Overall Decision.

- [ ] **Step 5: Run to verify they pass** — `run.sh check`; Expected: exit 0; `openspec schema validate` valid.

- [ ] **Step 6: Commit** — `git commit -m "feat(bridge): add verify check 8, spec review" -m "Refs: spec-review design Decision 6, 9; plan Task 5"`

---

### Task 6: Verify check 9 — deviation report

**Files:**
- Modify: `superpowers-bridge/schema.yaml` (`verify.instruction`: check 9)
- Modify: `superpowers-bridge/templates/verify.md` (`## 9. Deviation Report`)
- Create: `acceptance/superpowers-bridge/fixtures/deviation/` — `trunk` (`main`), `base/…`, `branch/…` (change `purge-cancelled-orders`, which also edits `.github/workflows/ci.yml`), `config.yaml`, `config.unreadable.yaml`, `kb/trunk/orders-direction.md`, `kb/amend/orders-direction.md`, `expected.md`
- Modify: `acceptance/superpowers-bridge/run.sh` (`stage` handles `kb/`; `check_deviation`)

**Interfaces:**
- Consumes: `stage` from Task 1.
- Produces: `stage` for a fixture with `kb/`: a second git repository at `<dir>.kb` with `kb/trunk/` committed on `main`, then branch `amend` with `kb/amend/` committed and **checked out**; `@KB@` in the config becomes `<dir>.kb`.
- Produces: `verify.md` § 9 layout — the sources read with their review status as read, then either one block per deviation (source and place; what it says; what the change does instead; why; cost if wrong; proposed edit to the source) or `No deviations from the governing sources.`, or `No governing sources configured`.

The probe source `orders-direction.md` on `main` states one behavior ("Cancelled orders are kept for seven years") and one non-goal ("No public API deletes an order"); on `amend` both lines are gone. The change purges cancelled orders after 30 days and adds a delete endpoint. `config.yaml`:

```yaml
schema: superpowers-bridge
context: |
  Governing sources: orders-direction.md in the repository at @KB@.
  Read it at that repository's trunk with `git -C @KB@ show main:orders-direction.md`,
  never from its working tree.
rules:
  verify:
    - "Sensitive areas: CI configuration (.github/workflows/)."
```

`config.unreadable.yaml` is the same with `missing-direction.md`.

- [ ] **Step 1: Write the failing assertions**

```bash
assert_json deviation context-delivered "openspec instructions verify --change purge-cancelled-orders --json" '"show main:orders-direction.md" in j.get("context","")'
assert_json deviation verify-rules-delivered "openspec instructions verify --change purge-cancelled-orders --json" 'any("Sensitive areas" in r for r in j.get("rules",[]))'
assert_true deviation source-on-amend-branch '[ "$(git -C "$DIR.kb" branch --show-current)" = amend ]'
assert_json clean verify-has-check-9 "openspec instructions verify --change add-order-cancellation --json" '"9. **Deviation report**" in j["instruction"] and "No governing sources configured" in j["instruction"]'
```

`context` and `rules` are OpenSpec's own fields beside `instruction` (Decision 13). If 1.14.3 names them differently, use the real names and say so in the commit message.

- [ ] **Step 2: Run to verify they fail** — Expected: the four FAIL.

- [ ] **Step 3: Write the fixture and the `stage` extension.** `expected.md`: with `config.yaml`, two deviations, each with a proposed edit, and the CI file listed as a sensitive area on the card; with `config.unreadable.yaml`, FAIL naming `missing-direction.md`; on the `clean` fixture, `No governing sources configured`.

- [ ] **Step 4: Write check 9 and § 9** — from Decision 11: a fresh-context subagent reads the sources the configuration names, at the adopter's trunk and never from a branch that amends them, recording each source's review status as read; plus proposal, design, delta specs, the diff against the merge target, and the executor's "Rulings I made". Deviations never fail verify; a missing report, a deviation without a reason, or an unreadable configured source does. Spec drift that does not move away from a source is not a deviation. The adopter's `rules.verify` may narrow or widen the definition and says how a proposed edit reaches its source.

- [ ] **Step 5: Run to verify they pass** — `run.sh check`; Expected: exit 0.

- [ ] **Step 6: Commit** — `git commit -m "feat(bridge): add verify check 9, deviation report" -m "Refs: spec-review design Decision 11, 13; plan Task 6"`

---

### Task 7: Verify check 10 — security pass

**Files:**
- Modify: `superpowers-bridge/schema.yaml` (`verify.instruction`: check 10)
- Modify: `superpowers-bridge/templates/verify.md` (`## 10. Security Pass`)
- Create: `acceptance/superpowers-bridge/fixtures/security/` — `trunk` (`main`), `base/…`, `branch/src/orders/payment_client.py`, `expected.md`
- Modify: `acceptance/superpowers-bridge/run.sh`

**Interfaces:**
- Produces: `verify.md` § 10 layout — count first, then `File:line | Defect | Outcome: fixed / dismissed — <reason>`; the review card (Task 9) copies the count and outcomes.

`payment_client.py` carries exactly two seeds: `API_PASSWORD = "fixture-only-not-a-real-secret"` and a `requests.post(…, verify=False)`. The value matches no provider's token format, so repository secret scanning has nothing to block.

- [ ] **Step 1: Probe how check 10 can run the runtime's own review**

In this session, check whether `security-review` appears among the skills the Skill tool can invoke. Record yes or no in this task's commit message. It decides only the order of the two paths in Step 4.

- [ ] **Step 2: Write the failing assertions**

```bash
assert_json clean verify-has-check-10 "openspec instructions verify --change add-order-cancellation --json" '"10. **Security pass**" in j["instruction"]'
assert_true security two-seeds '[ "$(git diff main...HEAD -U0 | grep -cE "^\+.*(API_PASSWORD = |verify=False)")" = 2 ]'
```

- [ ] **Step 3: Run to verify they fail; write the fixture; re-run** — Expected: `security: two-seeds` PASS, `verify-has-check-10` still FAIL.

- [ ] **Step 4: Write check 10 and § 10** — from Decision 14: review the diff against the merge target in a fresh context; where the runtime ships a security review the agent can invoke (in Claude Code, the built-in `/security-review`), use it; otherwise dispatch a fresh subagent with the diff and the reading list (data flow, trust boundaries, secrets, injection, disabled verification). Clear findings as in Decision 6; one whose fix changes behavior a governing source states goes to check 9 as a deviation. Uncleared findings set FAIL. A repository-wide deep scan is out of scope.

- [ ] **Step 5: Run to verify they pass** — `run.sh check`; Expected: exit 0.

- [ ] **Step 6: Commit** — `git commit -m "feat(bridge): add verify check 10, security pass" -m "Refs: spec-review design Decision 14; plan Task 7"`

---

### Task 8: The plan instruction carries the code-comment rule and the safety rules

**Files:**
- Modify: `superpowers-bridge/schema.yaml` (`plan.instruction`)
- Modify: `superpowers-bridge/templates/plan.md`
- Create: `acceptance/superpowers-bridge/fixtures/clean/config.safety.yaml`
- Modify: `acceptance/superpowers-bridge/run.sh`

**Interfaces:**
- Produces: the Global Constraints line every bridge plan carries, verbatim:
  `Code comments, docstrings and messages state the reason in words. They cite no planning labels — design decisions (D9), task or step numbers (Task 5, Step 2), review fix tags (FIX-2) or change-folder files (design.md, plan.md). Where a comment needs its source, it names the change: "decision D9 of the change <change-name>". Commit messages carry the trace.`
- Produces: the commit-message trailer a bridge plan's commit steps write: `Refs: <change-name> decision D<n>; task <n>`.

`config.safety.yaml` adds `rules.plan: ["Safety rules: see SAFETY.md at the repository root; every implementer reads it before its first action."]`.

- [ ] **Step 1: Write the failing assertions**

```bash
assert_json clean plan-rules-delivered "openspec instructions plan --change add-order-cancellation --json" 'any("SAFETY.md" in r for r in j.get("rules",[]))'   # staged with --config config.safety.yaml
assert_json clean plan-instruction-label-rule "openspec instructions plan --change add-order-cancellation --json" '"cite no planning labels" in j["instruction"] and "Refs: <change-name> decision D<n>; task <n>" in j["instruction"]'
assert_json clean plan-template-sections "openspec instructions plan --change add-order-cancellation --json" '"## Global Constraints" in j["template"] and "## Review Focus" in j["template"]'
```

- [ ] **Step 2: Run to verify they fail** — Expected: the last two FAIL (the first proves the OpenSpec channel and may already pass).

- [ ] **Step 3: Edit the plan instruction** — a paragraph after the Global Constraints note: (a) put the line above into `## Global Constraints` verbatim; (b) if the instructions carry `rules` for this artifact, carry each into Global Constraints in the form given — text as text; a pointer as the pointer plus "load it before your first action" — and never copy pointed-to content into `plan.md`, which is tracked; with no `rules`, add nothing and no empty heading; (c) every commit step ends its message with the trailer above. Explain why in two sentences: subagent-driven development copies each task verbatim into the implementer's brief and fills the task reviewer's constraint slot from Global Constraints, so this is the channel that reaches the acting subagent.

- [ ] **Step 4: Add `## Global Constraints` and `## Review Focus` placeholders** to `templates/plan.md` between the header and Task 1.

- [ ] **Step 5: Run to verify they pass** — `run.sh check`; Expected: exit 0.

- [ ] **Step 6: Commit** — `git commit -m "feat(bridge): carry the comment rule and safety rules into every plan" -m "Refs: spec-review design Decision 10, 12, 13; plan Task 8"`

---

### Task 9: The apply instruction — backup rule, stop rule, review loop, review card

**Files:**
- Modify: `superpowers-bridge/schema.yaml` (`apply.instruction`: steps 2, 3 and 6)
- Modify: `superpowers-bridge/templates/verify.md` (new final section `## Review Card`)
- Create: `acceptance/superpowers-bridge/fixtures/clean/config.apply.yaml`
- Modify: `acceptance/superpowers-bridge/run.sh`

**Interfaces:**
- Consumes: § 8 run counter (Task 5), § 9 layout (Task 6), § 10 count (Task 7).
- Produces: `## Review Card` in `verify.md`, six parts in this order: `### Deviations`, `### What the checks did not cover`, `### Evidence`, `### Security pass`, `### How to revert`, `### Rulings`.

`config.apply.yaml` adds `operations.apply.guidance: ["Stop before any database migration."]`.

- [ ] **Step 1: Write the failing assertions**

```bash
assert_json clean apply-guidance-delivered "openspec instructions apply --change add-order-cancellation --json" 'any("database migration" in g for g in (j.get("operationGuidance") or j.get("guidance") or []))'   # staged with --config config.apply.yaml
assert_json clean apply-card-rule "openspec instructions apply --change add-order-cancellation --json" '"Review Card" in j["instruction"] and "cite no planning labels" in j["instruction"]'
assert_true template card-order 'python3 - "$BUNDLE/templates/verify.md" <<'"'"'PY'"'"'
import sys; t=open(sys.argv[1]).read()
parts=["### Deviations","### What the checks did not cover","### Evidence","### Security pass","### How to revert","### Rulings"]
idx=[t.index(p) for p in parts]; assert idx==sorted(idx) and t.index("## Review Card")<idx[0]
PY'
```

Find the real field name for apply guidance in `openspec instructions apply --json` on 1.14.3 first (`loadOperationInputs` returns `operationGuidance`); keep only that name in the expression.

- [ ] **Step 2: Run to verify they fail** — Expected: the last two FAIL.

- [ ] **Step 3: Edit apply step 2** — tell the executor the Global Constraints comment rule as a backup to the plan, and: before any action that the configuration's safety rules or `operations.apply` guidance reserve for a human, stop and ask, in addition to subagent-driven development's own four stop classes.

- [ ] **Step 4: Edit apply step 3** — the verify loop: clear check 8 and check 10 findings and re-run under the rule file's round cap; after the cap, carry what is still open to the card.

- [ ] **Step 5: Edit apply step 6 and write the card section** — from Decision 15: the controller fills `## Review Card` in `verify.md` and writes it at the top of the pull request description; if `finishing-a-development-branch` created the request without it, edit the description afterwards with the forge's CLI. "What the checks did not cover" is derived from what verify ran plus the sensitive areas the adopter's `rules.verify` names that the diff touches; an empty part says so. The bundle posts no inline review comments. Name the per-edit check option of Decision 12 in one sentence (adopter configuration, not bundle content).

- [ ] **Step 6: Run to verify they pass** — `run.sh check`; Expected: exit 0; `openspec schema validate` valid.

- [ ] **Step 7: Commit** — `git commit -m "feat(bridge): review card, stop rule and review loop in apply" -m "Refs: spec-review design Decision 6, 10, 12, 15; plan Task 9"`

---

### Task 10: The retrospective tallies dismissals

**Files:**
- Modify: `superpowers-bridge/schema.yaml` (`retrospective.instruction`, §0 and §6 descriptions)
- Modify: `superpowers-bridge/templates/retrospective.md`
- Modify: `acceptance/superpowers-bridge/run.sh`

- [ ] **Step 1: Write the failing assertion**

```bash
assert_json clean retro-tally "openspec instructions retrospective --change add-order-cancellation --json" '"dismissal" in j["instruction"] and "Dismissals by rule" in j["template"]'
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.

- [ ] **Step 3: Edit** — §0 gains a row "Dismissals by rule" (checks 8 and 10: per rule, findings fixed vs dismissed, with the reasons grouped); §6 says a rule whose findings were mostly dismissed is a promote candidate to sharpen or drop that rule, destination "schema".

- [ ] **Step 4: Run to verify it passes** — Expected: exit 0.

- [ ] **Step 5: Commit** — `git commit -m "feat(bridge): tally spec-review and security dismissals in the retrospective" -m "Refs: spec-review design Decision 6; plan Task 10"`

---

### Task 11: READMEs, repository guide, version

**Files:**
- Modify: `superpowers-bridge/README.md`, `superpowers-bridge/README.zh-TW.md`, `superpowers-bridge/VERSION`, `CLAUDE.md`

- [ ] **Step 1: Write the failing assertion**

```bash
assert_true release version '[ "$(tr -d "[:space:]" < "$BUNDLE/VERSION")" = 1.5.0 ] && grep -q "1.5.0" "$BUNDLE/README.md" && grep -q "1.5.0" "$BUNDLE/README.zh-TW.md"'
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.

- [ ] **Step 3: Edit the English README** — lifecycle (two review points; verify checks 8–10; the card); a "Configuration keys" section documenting `context`, `rules.plan`, `rules.verify`, `operations.apply.guidance` as pointers not copies, and the per-edit check option; the design-touchpoints section on verify timing, now that checks 8 and 10 block; the re-attestation checklist gains "`acceptance/superpowers-bridge/run.sh check` passes on the new pin" (it pins the message texts the design's Risks name); "Current bundle release: 1.5.0".

- [ ] **Step 4: Sync `README.zh-TW.md`**, set `VERSION` to `1.5.0`, and add `acceptance/` and `spec-review.md` to the tree in `CLAUDE.md` (zh-TW prose).

- [ ] **Step 5: Run** — `run.sh check`; Expected: exit 0.

- [ ] **Step 6: Commit** — `git commit -m "docs(bridge): document 1.5.0 and bump VERSION" -m "Refs: spec-review design Migration Plan; plan Task 11"`

---

### Task 12: Agent acceptance

**Files:**
- Modify: fixture `expected.md` files only if a run shows the expectation, not the bundle, was wrong — say which in the commit message.

Each item runs in a fresh subagent, cwd inside a directory produced by `run.sh stage`, on OpenSpec 1.14.3. The staged project's own copy of the bundle shadows any user-tier install, so the run reads this branch. Record each outcome (expected, actual, pass or fail) for the pull request description.

- [ ] **Step 1: Check 8, clean** — `stage clean`; run check 8. Expected: `No findings.`
- [ ] **Step 2: Check 8, seeded** — `stage seeded`; run check 8. Expected: each of the fourteen seeds in `expected.md` once, nothing else; `T5` and `R7` marked by place in the main spec.
- [ ] **Step 2b: No repeats** — dismiss `L1` with a reason in § 8, re-run check 8. Expected: `L1` not raised again; the other thirteen still raised.
- [ ] **Step 3: Check 9** — `stage deviation`: two deviations, each with a proposed edit, read from `main` although `amend` is checked out. `stage deviation --config config.unreadable.yaml`: FAIL naming `missing-direction.md`. `stage clean`: `No governing sources configured`.
- [ ] **Step 4: Check 10** — `stage security`; run check 10. Expected: both seeds found; each fixed or dismissed with a reason.
- [ ] **Step 5: End-to-end card** — `stage deviation`; run verify (checks 1–10) and fill the card. Expected: six parts in order, deviations first, `.github/workflows/ci.yml` named under "What the checks did not cover". No pull request is created.
- [ ] **Step 6: Fix and re-run** — a miss in the bundle goes back to its task (fix, `run.sh check`, commit with that task's trailer); re-run the failed item. A real miss becomes a new seed.
- [ ] **Step 7: Push and hand over** — confirm the author with `git log --format='%ae' origin/main..HEAD | sort -u`, push `feat/spec-review`, and stop. The pilot (Task 13) comes next; the release pull request, merge and `bridge install` wait until the pilot is done.

---

### Task 13: Pilot in a real repository before merging

The review card, the blocking checks 8 and 10, and the safety stop change how every adopter's apply ends. `main` is what `bridge install` ships to every adopter, so the branch is tried on real work first, in one repository, while every other adopter keeps 1.4.1. The pilot mechanics (a project-tier copy of the branch bundle in the pilot repository only) are in the workbench plan; this task is what the pilot must show.

- [ ] **Step 1: One real change, full cycle** — in the pilot repository, with its adopter configuration, run one real change from brainstorm to archive on the branch bundle. Record: check 8's findings and how each was cleared; check 9's deviations; check 10's findings; the card as written into the pull request description; where the flow stopped for a human, and why.
- [ ] **Step 2: Without adopter configuration** — run checks 8–10 on the `clean` fixture staged with no `config.yaml` keys beyond `schema`. Expected: the bundle works with no governing sources (`No governing sources configured`), so it still stands without any particular knowledge base.
- [ ] **Step 3: The owner's verdict** — present the card and the records of Step 1. The owner decides: merge as is, revise (a fix goes back to its task, then the pilot repeats), or drop a part. A part found not to work under a single knowledge base belongs to the later decision on whether the bundle splits from its public form; record that observation, do not act on it here.
