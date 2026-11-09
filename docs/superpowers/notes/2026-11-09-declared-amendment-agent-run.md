# Agent run: verify check 9 with declared amendments

Date: 2026-11-09. OpenSpec 1.14.3. Bundle: branch `feat/declared-amendments` at commit
`6d138b4` (check 9 reading declared amendments), as copied into each staged project by
`run.sh stage`, so the run reads this branch and not a user-tier install.

## How it ran

Each item was staged afresh with `acceptance/superpowers-bridge/run.sh stage` into its own
scratch directory; variants (b) and (c) were then edited with the `sed` commands in
`fixtures/declared-amendment/expected.md`. For each, a fresh general-purpose subagent got only
what check 9 passes its subagent: the change name, the working directory, the `context` and
`rules` fields of `openspec instructions verify --json`, and check 9's own text, cut from that
instruction. It was told the merge target is `main`, to change nothing, and to return
section 9 as it would be written into `verify.md` together with its effect on Overall Decision.

## Outcomes

| Run | Expected (`expected.md`) | Reported | Result |
|---|---|---|---|
| `declared-amendment`, as staged | Retention `follows declared amendment`; *Delete endpoint* `decided — folded into the amendment`; *Export endpoint* a deviation; PASS WITH WARNINGS | The three outcomes as expected, each with its place and commit; the undeclared commit 03 named and not read; PASS WITH WARNINGS naming *Export endpoint* | pass |
| Variant (b), the move names no deviation | *Delete endpoint* a deviation, noted "declared commit moved without naming the deviation it takes in"; *Export endpoint* a deviation; Retention follows; PASS WITH WARNINGS | As expected, with the note quoted | pass |
| Variant (c), planned-against commit `0000000` | FAIL naming the declared amendment as unreadable | FAIL naming it, with `fatal: invalid object name '0000000'.`; also Retention reported as a deviation, since nothing can be credited to an unreadable planned-against text | pass; `expected.md` corrected to state the Retention deviation, which the first draft left out |
| `deviation` (regression, no declarations) | Exactly two deviations, read at `main` | Exactly the two, read at `main`; the `amend` branch named and not read, since nothing declares it; PASS WITH WARNINGS | pass |

## Observations

- In variants (b) and (c) the subagent noticed on its own that the staged `proposal.md` differed
  from its committed text, because the variant edit is left uncommitted. It judged the
  working-tree text, as the proposal "as it will be archived", and flagged the edit as
  something to resolve before archiving. Check 9 itself has no rule on this.
- In the run as staged, the subagent raised one judgement it had settled as covered: the
  amended retention line ("kept for 30 days") says nothing about the delete endpoint removing
  a cancelled order sooner. It treated that as part of the folded *Delete endpoint* move.

## Second run, after the final review's fixes

Bundle at commit `c07f6a7`: a declared commit is credited only on the amendment's branch, the
declaration's provenance is reported, a landed amendment stops earning credit, a departure
from the amendment is a deviation, a move counts only with its place and its decider, and the
review card lists every point credited to an amendment. The fixture's context now gives the
branch check (`merge-base --is-ancestor`), and the move names its place. Same procedure, with
four new variants; variant (c) was not re-run, since the unreadable-commit rule did not change.

| Run | Expected (`expected.md`) | Reported | Result |
|---|---|---|---|
| As staged | As in the first run, plus provenance "with the code" and "relies on the unmerged amendment … at `02`" on the card | The three outcomes; both card lines | pass, after the fixture fix below |
| (b) move names nothing | *Delete endpoint* a deviation with the moved-without-naming note | As expected | pass |
| (d) declaration committed after the code | Outcomes as staged; provenance names the later commit | Provenance: first carried by "declare the pending amendment", after the code commit; on the card | pass, after the fixture fix below |
| (e) amendment landed as 60 days | `declared amendment merged`; trunk alone: Retention and *Export endpoint* deviations, no credit, no "relies on" line | As expected | pass |
| (f) change keeps seven years | Retention `departs from declared amendment` | As expected; *Delete endpoint* folded, *Export endpoint* a deviation | pass |
| (g) move without a decider | As (b) | As expected | pass, after the fixture fix below |
| `deviation` (regression) | Exactly the two deviations at `main` | As expected; it also writes a provenance line saying nothing is declared | pass |

**Fixture fix.** In three runs (as staged, (d), (g)) the subagent also reported the amended
retention line, then "Cancelled orders are kept for 30 days.", as contradicted by the delete
endpoint, reading "kept for" as a minimum. The fixture meant a purge horizon, so its amended
line became "Cancelled orders are purged 30 days after they were cancelled."; re-run, the run
as staged and (g) reported exactly the expected outcomes.

**Observations.** Two subagents (in (e) and (f)) ran `git show` on the amending branch's head
while mapping history, against "never at its branch head"; both said so, and neither result
used it. Every subagent noticed when the variant's edit to `proposal.md` was left uncommitted
and reported the declaration as not committed yet.
