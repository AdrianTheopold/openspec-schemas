# Expected agent outcomes: deviation

The change `purge-cancelled-orders` moves away from the governing source
`orders-direction.md`, which `config.yaml` names in a second repository staged at
`<dir>.kb`. That repository has a branch, `amend`, checked out: it drops the two lines
the change moves away from and marks the page `draft`. A reader that takes the working
tree instead of the trunk sees no deviation, so these outcomes hold only for a read at
`main`.

## With `config.yaml`

Check 9 records the source as read at `main`, with its review status `approved`, and
reports exactly two deviations, each with a reason, a cost if the reasoning is wrong,
and a proposed edit to the source:

| Deviation | Source and place | What it says | What the change does instead | Proposed edit |
|---|---|---|---|---|
| Retention | `orders-direction.md`, Behavior | "Cancelled orders are kept for seven years." | Purges a cancelled order 30 days after it was cancelled | Replace the line with the 30-day retention, or reverse the purge |
| Delete endpoint | `orders-direction.md`, Non-goals | "No public API deletes an order." | Adds `DELETE /orders/{order_id}` for cancelled orders | Remove the non-goal, or narrow it to orders that are not cancelled |

Nothing else is a deviation: the CI change and the delta specs' differences from the
main spec move away from no line of the source. The review card lists
`.github/workflows/ci.yml` under the sensitive areas the change touches, because the
adopter's verify rules name CI configuration as one; it is not a deviation.

Overall Decision is not FAIL on account of check 9: deviations are for the human to
decide at merge time.

## With `config.unreadable.yaml`

The configured source `missing-direction.md` does not exist at `main`. Check 9 names
`missing-direction.md` as unreadable and sets Overall Decision to FAIL.

## On the `clean` fixture

No configuration names a governing source, so check 9 records
`No governing sources configured` and passes.
