# Expected agent outcomes: declared-amendment

The change `purge-delete-export-orders` is planned against a pending amendment to its
governing source `orders-direction.md`, which `config.yaml` names in a second repository
staged at `<dir>.kb`. On `main` the source is `approved` and says three things the change
moves away from: cancelled orders are kept for seven years, no public API deletes an
order, and no public API exports orders in bulk.

The amending branch `amend` carries three commits, and is left checked out at the last:

| Commit | What it changes in the source |
|---|---|
| `01` | Retention becomes "Cancelled orders are kept for 30 days." |
| `02` | Also drops the non-goal "No public API deletes an order." |
| `03` | Also drops the non-goal "No public API exports orders in bulk." |

The change's `proposal.md` declares the amendment under `## Declared amendments`: planned
against commit `01`, moved to commit `02` to take in the deviation *Delete endpoint*. It
does not declare commit `03`. A reader that takes the branch head or the working tree sees
commit `03` and finds no deviation at all, so these outcomes hold only for a read at the
declared commits. `stage` writes the commits' hashes to `<dir>.kb.commits` and into the
proposal.

The change's `tasks.md` and `plan.md` are fully ticked, so verify's PRECHECK passes.

## With `config.yaml`

Check 9's sources table records `orders-direction.md` read at `main`, with its review
status `approved`, and the declared amendment read at commit `02` (and at `01` to compare).
It reports three outcomes:

| Point | Source and place | Outcome |
|---|---|---|
| Retention | `orders-direction.md`, Behavior | **follows declared amendment**: the change purges after 30 days, as the amendment says at commit `01`; not a deviation |
| Delete endpoint | `orders-direction.md`, Non-goals | **decided — folded into the amendment**: the declaration's move to commit `02` names it; not a deviation |
| Export endpoint | `orders-direction.md`, Non-goals | **deviation**: "No public API exports orders in bulk." still stands at commit `02`, and only the undeclared commit `03` drops it. Reported with a reason, a cost if the reasoning is wrong, and a proposed edit (remove or narrow the non-goal, or drop the export route) |

Nothing else is a deviation: the CI change and the delta specs' differences from the main
spec move away from no line of the source. The review card lists `.github/workflows/ci.yml`
under the sensitive areas the change touches; it is not a deviation.

Overall Decision is PASS WITH WARNINGS on account of the one deviation; deviations are for
the human to decide at merge time.

## Variant (b): a move that names no deviation

Stage afresh, then drop the "to take in …" clause from the move:

```bash
sed -i 's/ to take in the deviation \*Delete endpoint\*, decided by the source.s owner as an edit to the source\././' <dir>/openspec/changes/purge-delete-export-orders/proposal.md
```

The declaration still moves to commit `02`, but names nothing it takes in. Retention still
follows the declared amendment. *Delete endpoint* becomes a **deviation**, noted as
"declared commit moved without naming the deviation it takes in". *Export endpoint* stays a
deviation. Overall Decision is PASS WITH WARNINGS.

## Variant (c): a declared commit that cannot be read

Stage afresh, then replace the commit the change was planned against with one that does not
exist:

```bash
sed -i "s/$(sed -n 's/^01=//p' <dir>.kb.commits)/0000000/" <dir>/openspec/changes/purge-delete-export-orders/proposal.md
```

Check 9 names the declared amendment to `orders-direction.md` as unreadable at `0000000`,
with what the read returned, and sets Overall Decision to FAIL.

## On the `deviation` fixture

Its proposal declares no amendment, so check 9 behaves as before: exactly the two
deviations in that fixture's `expected.md`, read at `main`.
