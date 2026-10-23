## Context

Cancelled orders are marked rather than removed, so the store only grows. Support staff receive requests to erase an order and have no way to act on them.

## Goals / Non-Goals

**Goals:**
- Remove cancelled orders once they are no longer needed for support lookups.
- Let support delete a cancelled order on request.

**Non-Goals:**
- Deleting orders that are not cancelled.

## Decisions

### Purge cancelled orders after 30 days
Support looks up a cancelled order within days of the cancellation, rarely later, so 30 days covers every lookup seen so far.

**Alternatives considered**: keeping cancelled orders indefinitely; rejected because the store only grows.

### The nightly purge runs as a scheduled CI job
The service has no scheduler of its own, and the CI system already runs on a schedule.

**Alternatives considered**: a scheduler inside the service; rejected as more than this change needs.

### A delete endpoint for cancelled orders
Support needs to act on an erasure request without waiting for the purge.

**Alternatives considered**: an internal script run by an operator; rejected because support has no shell access.

## Risks / Trade-offs

- A cancelled order needed after 30 days is gone for good.
