## Context

Totals are computed in more than one place.

## Goals / Non-Goals

**Goals:**
- One place computes totals.

**Non-Goals:**
- Changing payment adapters.

## Decisions

### D4: Validation lives in the gateway
Orders are checked before they reach the store.

### D9: Titles carry the decision label
Kept short for cross-reference.

## Risks / Trade-offs

- Gateway validation duplicates a few checks.
