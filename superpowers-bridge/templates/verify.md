# Verification Report

> This file is produced by the `openspec-verify-change` skill after apply
> completes, to confirm the implementation is consistent with specs / design /
> tasks. Failed checks must return to the corresponding artifact for fixing,
> then re-run verify.

**Change**: `<change-name>`
**Verified at**: `YYYY-MM-DD HH:mm`
**Verifier**: `<who / which agent>`

---

## 1. Structural Validation (`openspec validate --all --json`)

- [ ] All items report `"valid": true`

**Result**:

```text
<paste a summary of the openspec validate --all output>
```

If any items fail, list id + issues:

| Item | Type | Issues |
|---|---|---|
| — | — | — |

---

## 2. Task Completion (`tasks.md` + `plan.md`)

- [ ] `tasks.md` — all `- [ ]` have become `- [x]`
- [ ] `plan.md` — all step boxes are `- [x]`, or `- [~]` where deliberately deferred

> Report the two separately. An all-unchecked `plan.md` beside a fully-ticked `tasks.md` is the
> signature of a bookkeeping miss rather than unfinished work — and it makes §7's `[~]` count
> meaningless, since the rows it reads were never written.

**Incomplete tasks** (if any):

| Task | Reason incomplete | Blocks archive? |
|---|---|---|
| — | — | — |

---

## 3. Delta Spec Sync State

For each capability directory under `openspec/changes/<name>/specs/`, compare
against `openspec/specs/<capability>/spec.md`:

| Capability | Sync status | Notes |
|---|---|---|
| — | ✓ synced / ✗ needs sync / N/A | — |

---

## 4. Design / Specs Coherence Spot Check

Spot-check whether `design.md`'s decisions are reflected in the Requirements
and Scenarios of `specs/*.md`:

| Sample | design description | specs counterpart | Gap |
|---|---|---|---|
| — | — | — | — |

**Drift warnings** (non-blocking):

- <list if any; otherwise write "none">

---

## 5. Implementation Signal

- [ ] No unstaged files in the worktree
- [ ] All code changes committed

**Commit range** (if known): `<from-sha>..<to-sha>`

> Scoped to *committed*, not pushed, on purpose: verify runs at apply step 3 and the branch is
> pushed at step 6, so a "pushed" box here could never be truthfully ticked. If you need the push
> recorded, it belongs to the finish step, not this report.

---

## 6. Front-Door Routing Leak Detector (warning, non-blocking)

Neither design nor plan output should land under `docs/superpowers/` — the brainstorm artifact's
output redirection routes design output to `openspec/changes/<name>/brainstorm.md`, and the plan
artifact's routes the plan to `openspec/changes/<name>/plan.md`. Both directories are checked,
because a detector watching only one of the two redirected paths reports clean while the other
leaks.

Detection:

```bash
ls docs/superpowers/specs/*.md docs/superpowers/plans/*.md 2>/dev/null
```

- [ ] No files, or any present are legitimate pre-schema-install holdovers

**Leak list** (if any):

| File | Content captured into change? | Suggested action |
|---|---|---|
| — | — | — |

> Does not block archive. Leaks produced by a new schema-installed cycle
> should be moved into `openspec/changes/<name>/brainstorm.md` or `design.md`,
> then the originals deleted.

---

## 7. Deferred Manual Dogfood vs Automated Test Equivalence

For each manual dogfood / smoke task marked `[~]` deferred in plan.md, list the
equivalent automated-test coverage. If no equivalent automated test exists,
treat that item as a **real gap** rather than a legitimate deferral, and record
it in the retrospective's Misses.

| Deferred dogfood (plan §) | Equivalent automated test | Coverage assessment | Real gap? |
|---|---|---|---|
| e.g. §11.3 `compose up + curl /actuator/health` | `LinebcIntegrationApplicationTests` (Testcontainers, 24s) | Spring context boot + Flyway migrations complete + key beans injected | ❌ already equivalently covered |
| — | — | — | — |

> **Interpretation rules**:
> - "Equivalent" = the automated test's assertion set is a superset of the manual dogfood's expected assertions
> - "Coverage assessment" = list the layers actually exercised (context / DB schema / wiring / HTTP path / etc.)
> - For any row where "Real gap = ✅", the Overall Decision may still be PASS, but a follow-up item must be left in the retrospective

> **When this section may be left blank**: if plan.md has no `[~]`-marked rows at all, this section need not be filled (blank = PASS).
> As soon as plan.md contains any `[~]`, this section must enumerate each one, otherwise the Overall Decision should be downgraded to FAIL.
>
> **But first confirm plan.md was maintained** (§2). A blank §7 means "nothing was deferred" only
> if the step ledger reflects the work. An all-unchecked plan.md means nobody maintained it, so the
> absence of `[~]` rows says nothing about whether steps were deferred — reconstruct the deferral
> state from the SDD ledger and the commits, tick plan.md to match, and re-run verify.

---

## 8. Spec Review

A fresh-context subagent reviews the delta specs against the bundle's `spec-review.md` (path:
`openspec schema which superpowers-bridge --json` → `path`). One block per run, newest first. When
verify is re-run, earlier runs are carried forward unchanged: the next run's subagent reads them
for the round cap, the no-repeat rule and the capped run's diff base.

### Run <n> of 3

<!-- n counts runs of check 8 that reported findings; a run reporting `No findings.` does not advance it. -->

**Reviewed commit**: `<git rev-parse HEAD at this run>`

**Count**: `<n> findings, <m> pre-existing` — or `No findings.`

| File:line | Rule | Quoted text | Outcome | pre-existing? |
|---|---|---|---|---|
| `<file>:<line>` | `rule <n>` or a bold rule name (`strict`, `archive-refusal`, `proposal`, `scenario-steps`, `scenario-header`, `purpose`, `authoring`, `sibling`, `code-label`) | "<quoted text>" | fixed / dismissed — `<reason>` / deviation — check 9 / open — review card | yes / no |

> **Outcomes**: *fixed* — the text or code was changed; *dismissed* — a one-line reason, and the
> quoted text stays as the no-repeat rule's reference; *deviation* — the fix would change behavior
> a governing source states, so check 9 reports it; *open — review card* — still open after the
> capped run (`Run 4 of 3`, which reviews only what changed since the previous run's reviewed
> commit) and handed to the human. The capped run's own findings are cleared like any other; one
> neither fixed nor dismissed is *open — review card*, and fixes made after the capped run are
> listed on the review card as not re-reviewed by check 8. An empty Outcome cell means the
> finding is uncleared, and Overall Decision is FAIL.

<!-- Earlier runs follow here, carried forward unchanged: ### Run <n-1> of 3 … -->

---

## 9. Deviation Report

A fresh-context subagent compares the change with the governing sources the adopter names in
`openspec/config.yaml` (`context`), under the adopter's verify rules (`rules.verify`). Each source
is read at the adopter's trunk, never from a branch that amends it. A deviation is a point where
the change contradicts, drops, or goes beyond what a source states, including a stated non-goal.

If no governing source is configured, write only `No governing sources configured` and stop here.

**Sources read**:

| Source | Read at | Review status as read |
|---|---|---|
| `<source>` | `<trunk, and the read used>` | `<status, or "no status stated">` — or *unreadable*: `<what the read returned>` |

Then one block per deviation, or `No deviations from the governing sources.`

### Deviation <n>: <short name>

- **Source and place**: `<source>`, `<section or line>`
- **What it says**: "<quoted text>"
- **What the change does instead**: <behavior, with the file or spec that carries it>
- **Why**: <the reason for moving away>
- **Cost if wrong**: <what it costs if that reason is wrong>
- **Proposed edit to the source**: <the edit, in the form the adopter's verify rules ask for>

> A deviation does not fail verify: accepting it, amending the source, or reversing the code is
> the human's decision at merge time, and the review card puts it in front of them. FAIL only
> when this section is missing, a deviation has no **Why**, or a configured source is
> *unreadable*.

---

## 10. Security Pass

A fresh-context review of the change's diff against the branch it merges into
(`git diff <base>..HEAD`) for security defects: untrusted input flow, trust boundaries,
secrets, injection, verification turned off. A fresh-context subagent runs it: with the
runtime's own security review where it can invoke one (in Claude Code, `/security-review`),
falling back to the reading list when that review does not cover exactly the files of
`git diff --name-only <base>..HEAD` or does not say what it covered; otherwise with the reading
list. Only what the diff adds or changes is reviewed. One block per run, newest first; earlier
runs are carried forward unchanged, as in §8.

### Run <n> of 3

<!-- n counts runs of check 10 that reported findings, as §8 counts check 8's runs. -->

**Reviewed by**: subagent with `/security-review` / subagent with the reading list (`/security-review` covered other files) / subagent with the reading list

**Reviewed commit**: `<git rev-parse HEAD at this run>`

**Count**: `<n> findings` — or `No findings.`

| File:line | Defect | Outcome |
|---|---|---|
| `<file>:<line>` | `<defect>`: "<quoted code>" | fixed / dismissed — `<reason>` / deviation — check 9 / open — review card |

> **Outcomes** read as in §8: *fixed* — the code was changed; *dismissed* — a one-line reason,
> and the quoted code stays as the no-repeat rule's reference; *deviation* — the fix would
> change behavior a governing source states, so check 9 reports it; *open — review card* —
> still open after the capped run and handed to the human. An empty Outcome cell means the
> finding is uncleared, and Overall Decision is FAIL.

<!-- Earlier runs follow here, carried forward unchanged: ### Run <n-1> of 3 … -->

---

## Overall Decision

- [ ] ✅ PASS — proceed in order: retrospective → archive → invoke
  **superpowers:finishing-a-development-branch** (its push option publishes the branch)
- [ ] ⚠️ PASS WITH WARNINGS — may proceed, but note: `<explanation>`
- [ ] ❌ FAIL — return to the failing artifact, fix it, and re-run verify. Always FAIL while
  §8 holds a finding that is not fixed, dismissed with a reason, marked a deviation, or carried
  to the review card after the capped run; findings carried to the review card make it PASS WITH
  WARNINGS at best. The same holds for §10's findings, and §10 must hold a report. Also FAIL
  while §9 has no report, a deviation without its **Why**, or a configured source that could
  not be read — deviations themselves never fail verify

**Next step**:

<describe the next action>

> **A PASS here is mid-cycle, not the end.** Do not open — and never merge — the
> PR/MR before `retrospective.md` and the archived change (spec delta synced into
> `openspec/specs/`, folder moved under `openspec/changes/archive/`) are committed
> on THIS branch. A branch that merges with the change still active leaves the main
> spec stale and forces a later session to reconstruct the retrospective cold
> (schema apply steps 4–6 are the canonical sequence). This binds any session that
> picks the branch up after verify — deploy gates and click-throughs do not reorder it.
> The publish step goes through **superpowers:finishing-a-development-branch** (skill
> invocation, not a bare `git push`): it re-runs the full suite on the tree being
> integrated and leaves the integration decision to your human partner.

---

## Review Card

> The apply controller fills this card once verify has no blocking issue left, and copies it to
> the top of the pull request description when the branch is published. It is a one-screen view
> of the sections above, which stay the record: no style or nit-level content, and no inline
> review comments. The first two parts ask the human to read; the other four are for a glance.
> A part with nothing to list says so in words — an empty part reads as unchecked.

### Deviations

<!-- Copied from §9: each deviation with its source and place, what the source says, what the change does instead, why, the cost if wrong, and the proposed edit. Or `No deviations from the governing sources.` — or `No governing sources configured`. The only part that asks for decisions. -->

### What the checks did not cover

<!-- Derived by the controller, not copied: the sensitive areas the adopter's verify rules (`rules.verify`) name that the diff touches; every check verify did not run or ran on a fallback path (for example §10's **Reviewed by** naming the reading list, or verify's checks run by hand); the findings marked `open — review card` in §8 and §10; and the fixes made after a capped run (`Run 4 of 3`), not re-reviewed by the check that raised them. This tells the human where to read the code itself. -->

### Evidence

<!-- The commands verify ran and their results, one line each: `openspec validate --all --json` (§1), the strict validation of §8, the task and step counts (§2), and the commit range (§5). -->

### Security pass

<!-- From §10: the latest run line, which path reviewed it, its count line, and the outcomes (fixed / dismissed / deviation / open). -->

### How to revert

<!-- What undoing the change takes: the commits or merge to revert, and anything a revert does not undo — data written, configuration applied outside the repository, the spec sync of the archive. -->

### Rulings

<!-- The number of rulings the executor made, with a pointer to the list in §4. -->
