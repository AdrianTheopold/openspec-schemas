# Expected agent outcomes: declared-amendment

The change `purge-delete-export-orders` is planned against a pending amendment to its
governing source `orders-direction.md`, which `config.yaml` names in a second repository
staged at `<dir>.kb`. On `main` the source is `approved` and says three things the change
moves away from: cancelled orders are kept for seven years, no public API deletes an
order, and no public API exports orders in bulk.

The amending branch `amend` carries three commits, and is left checked out at the last:

| Commit | What it changes in the source |
|---|---|
| `01` | Retention becomes "Cancelled orders are purged 30 days after they were cancelled." |
| `02` | Also drops the non-goal "No public API deletes an order." |
| `03` | Also drops the non-goal "No public API exports orders in bulk." |

The change's `proposal.md` declares the amendment under `## Declared amendments`: planned
against commit `01`, moved to commit `02` to take in the deviation *Delete endpoint*, naming
its place ("No public API deletes an order.") and its decider (the source's owner). It
does not declare commit `03`. A reader that takes the branch head or the working tree sees
commit `03` and finds no deviation at all, so these outcomes hold only for a read at the
declared commits. `stage` writes the commits' hashes to `<dir>.kb.commits` and into the
proposal.

The change's `tasks.md` and `plan.md` are fully ticked, so verify's PRECHECK passes.

## With `config.yaml`

Check 9's sources table records `orders-direction.md` read at `main`, with its review
status `approved`, and the declared amendment read at commits `01` and `02`, both found on
branch `amend` with `merge-base --is-ancestor` and neither an ancestor of `main`. The
`Declaration provenance` line says the declaration was first committed in the change's only
commit, together with the code, so not before it. It reports three outcomes:

| Point | Source and place | Outcome |
|---|---|---|
| Retention | `orders-direction.md`, Behavior | **follows declared amendment**: the change purges after 30 days, as the amendment says at commit `01`; not a deviation |
| Delete endpoint | `orders-direction.md`, Non-goals | **decided — folded into the amendment**: the declaration's move to commit `02` names it; not a deviation |
| Export endpoint | `orders-direction.md`, Non-goals | **deviation**: "No public API exports orders in bulk." still stands at commit `02`, and only the undeclared commit `03` drops it. Reported with a reason, a cost if the reasoning is wrong, and a proposed edit (remove or narrow the non-goal, or drop the export route) |

Nothing else is a deviation: the CI change and the delta specs' differences from the main
spec move away from no line of the source. The review card lists `.github/workflows/ci.yml`
under the sensitive areas the change touches; it is not a deviation.

The review card's Deviations part carries the *Export endpoint* deviation, the Retention and
*Delete endpoint* points with their place and declared commit (for *Delete endpoint*, the
owner as decider and the non-goal it folded in), the provenance line, and "relies on the
unmerged amendment" on branch `amend` at commit `02`.

Overall Decision is PASS WITH WARNINGS on account of the one deviation; deviations are for
the human to decide at merge time.

## Variant (b): a move that names no deviation

Stage afresh, then drop the "to take in …" clause from the move:

```bash
sed -i 's/ to take in the deviation .*\.$/./' <dir>/openspec/changes/purge-delete-export-orders/proposal.md
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
with what the read returned, and sets Overall Decision to FAIL. An amendment with an unreadable
declared commit earns no credit, so `orders-direction.md` is judged by its trunk text alone:
Retention, *Delete endpoint* and *Export endpoint* are all deviations, and nothing is reported as
following or folded into the amendment.

## Variant (d): the declaration committed after the code

Stage afresh, then split the change so the declaration arrives in a later commit:

```bash
cp <dir>/openspec/changes/purge-delete-export-orders/proposal.md <dir>/proposal.full
python3 -c 'import sys;p=sys.argv[1];t=open(p).read();open(p,"w").write(t[:t.index("## Declared amendments")].rstrip()+"\n")' <dir>/openspec/changes/purge-delete-export-orders/proposal.md
git -C <dir> commit -q -a --amend --no-edit
mv <dir>/proposal.full <dir>/openspec/changes/purge-delete-export-orders/proposal.md
git -C <dir> commit -q -a -m "declare the pending amendment"
```

The outcomes are those of the run as staged. Provenance is reported, never gated: the
`Declaration provenance` line names the later commit as the first to carry the declaration,
after the change's first commit outside `openspec/`, and the review card carries that line.

## Variant (e): the amendment has landed, in a different form

Stage afresh, then land commit `02` on the source's trunk and let the owner change it on the
way, to 60 days and `approved`:

```bash
git -C <dir>.kb checkout -q main
git -C <dir>.kb merge -q --no-ff "$(sed -n 's/^02=//p' <dir>.kb.commits)" -m "land the amendment"
sed -i 's/purged 30 days/purged 60 days/; s/^status: draft/status: approved/' <dir>.kb/orders-direction.md
git -C <dir>.kb commit -q -a -m "owner: 60 days, approved"
git -C <dir>.kb checkout -q amend
```

Both declared commits are ancestors of `main`, so check 9 reports `declared amendment merged`
and judges `orders-direction.md` by its trunk text alone; nothing is credited as following or
folded into the amendment, and no "relies on the unmerged amendment" line appears. Retention
is a deviation (the change purges after 30 days, the trunk purges them after 60).
*Delete endpoint* is no deviation, since the trunk no longer carries that non-goal. *Export
endpoint* stays a deviation. Overall Decision is PASS WITH WARNINGS, naming the two.

## Variant (f): the change departs from the amendment, and the trunk agrees

Stage afresh, then make the change keep cancelled orders for seven years, as the trunk says,
instead of the 30 days the amendment it was planned against says:

```bash
grep -rlF '30 days' <dir>/openspec/changes/purge-delete-export-orders | xargs sed -i 's/30 days/seven years/g'
sed -i 's/timedelta(days=30)/timedelta(days=7 * 365)/' <dir>/src/orders/purge.py
git -C <dir> commit -q -a --amend --no-edit
```

Retention is a deviation reported as **departs from declared amendment**: the amendment at
commit `01` says 30 days, and its proposed edit is aimed at the amendment or at the change.
*Delete endpoint* is still folded in, *Export endpoint* is still a deviation. Overall
Decision is PASS WITH WARNINGS, naming the two deviations.

## Variant (g): a move that names no decider

Stage afresh, then drop the decider from the move, keeping its place:

```bash
sed -i 's/, decided by the source.s owner as an edit to the source\././' <dir>/openspec/changes/purge-delete-export-orders/proposal.md
```

The move takes in nothing, so the outcomes are those of variant (b): *Delete endpoint* is a
deviation noted "declared commit moved without naming the deviation it takes in".

## On the `deviation` fixture

Its proposal declares no amendment, so check 9 behaves as before: exactly the two
deviations in that fixture's `expected.md`, read at `main`.
