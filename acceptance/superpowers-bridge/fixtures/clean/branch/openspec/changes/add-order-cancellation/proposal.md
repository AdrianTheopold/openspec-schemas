## Why

Customers who change their mind before an order ships have no way to withdraw it, so support staff remove such orders by hand.

## What Changes

- Add the ability to cancel an order that has not shipped yet.
- Keep a cancelled order retrievable so that support can still see what was cancelled.

## Capabilities

### New Capabilities

### Modified Capabilities
- `orders`: orders gain a cancelled state and remain retrievable after cancellation.

## Impact

- Affected spec: `orders`.
- Affected code: the order storage module and a new cancellation module.
