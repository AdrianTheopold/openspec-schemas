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
