## Why

Cancelled orders stay in the store forever, and support staff have no way to remove an order a customer asked to have erased.

## What Changes

- Purge cancelled orders 30 days after they were cancelled, on a nightly schedule.
- Add a delete endpoint to the public API that removes a cancelled order on request.

## Capabilities

### New Capabilities

### Modified Capabilities
- `orders`: cancelled orders are purged after 30 days, and a cancelled order can be deleted through the public API.

## Impact

- Affected spec: `orders`.
- Affected code: the order storage module, the public API module, a new purge module.
- Affected configuration: the CI workflow gains a nightly job that runs the purge.
