---
status: draft
---

# Orders direction

The order service records what customers ordered.

## Behavior

- An order is identified by the identifier it receives when it is accepted.
- Cancelled orders are purged 30 days after they were cancelled.

## Non-goals

- No public API deletes an order.
- No public API exports orders in bulk.
