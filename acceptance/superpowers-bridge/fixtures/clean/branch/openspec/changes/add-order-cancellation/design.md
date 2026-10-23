## Context

Orders are held in a single store keyed by identifier. Cancellation needs a place to record that an order was withdrawn.

## Goals / Non-Goals

**Goals:**
- Let an unshipped order be cancelled.

**Non-Goals:**
- Refunds and customer notification.

## Decisions

### A cancelled order stays in the store
It is marked rather than removed, so support can still look it up.

**Alternatives considered**: deleting the entry; rejected because support loses the record.

## Risks / Trade-offs

- Cancelled orders accumulate; pruning is out of scope here.
