# SDD ledger — plan: openspec/changes/purge-cancelled-orders/plan.md

Task 1: Ruling: retention counts from `cancelled_at`, not from when the order was placed — the spec counts 30 days from cancellation — an order placed long ago but cancelled yesterday would otherwise be purged at once
Task 1: complete
Task 2: Ruling: deleting an order that is not cancelled answers 409 Conflict, not 403 Forbidden — the refusal depends on the order's state, not on the caller's rights — a client that branches on 403 misreads the refusal
Task 2: complete
