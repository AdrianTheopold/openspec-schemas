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

## Overall Decision

- [ ] ✅ PASS — proceed to retrospective → archive → finishing (push), in that order
- [ ] ⚠️ PASS WITH WARNINGS — may proceed, but note: `<explanation>`
- [ ] ❌ FAIL — return to the failing artifact, fix it, and re-run verify

**Next step**:

<describe the next action>

> **A PASS here is mid-cycle, not the end.** Do not open — and never merge — the
> PR/MR before `retrospective.md` and the archived change (spec delta synced into
> `openspec/specs/`, folder moved under `openspec/changes/archive/`) are committed
> on THIS branch. A branch that merges with the change still active leaves the main
> spec stale and forces a later session to reconstruct the retrospective cold
> (schema apply steps 4–6 are the canonical sequence). This binds any session that
> picks the branch up after verify — deploy gates and click-throughs do not reorder it.
