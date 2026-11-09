## Why

Cancelled orders stay in the store forever, support staff have no way to remove an order a customer asked to have erased, and finance has no way to pull orders out in bulk for its monthly reconciliation.

## What Changes

- Purge cancelled orders 30 days after they were cancelled, on a nightly schedule.
- Add a delete endpoint to the public API that removes a cancelled order on request.
- Add an export endpoint to the public API that returns every stored order.

## Capabilities

### New Capabilities

### Modified Capabilities
- `orders`: cancelled orders are purged after 30 days, a cancelled order can be deleted through the public API, and stored orders can be exported through it.

## Impact

- Affected spec: `orders`.
- Affected code: the order storage module, the public API module, a new purge module.
- Affected configuration: the CI workflow gains a nightly job that runs the purge.

## Declared amendments

- `orders-direction.md`: pending amendment on branch `amend` of the source repository.
  - Planned against commit `@KB_COMMIT_01@`.
  - Moved to commit `@KB_COMMIT_02@` to take in the deviation *Delete endpoint*, decided by the source's owner as an edit to the source.
