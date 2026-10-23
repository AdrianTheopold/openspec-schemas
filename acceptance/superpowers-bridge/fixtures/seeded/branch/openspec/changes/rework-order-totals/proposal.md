## Why

Order totals are computed in several places and drift apart, so support sees different numbers for the same order.

## What Changes

- Record each order's fulfilment history.
- Validate orders before they are stored.
- Retire the separate listing operation.

## Capabilities

### New Capabilities

### Modified Capabilities
- `orders`: totals, validation and history.

## Impact

- Affected spec: `orders`.
- Affected code: the totals module.
