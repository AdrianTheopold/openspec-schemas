# Order Cancellation Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development
> to implement this plan task-by-task.

**Spec:** `openspec/changes/add-order-cancellation/specs/` and `openspec/changes/add-order-cancellation/design.md`

**Goal:** Let an unshipped order be cancelled and stay retrievable.

**Architecture:** A `cancel` function in `src/orders/cancel.py` marks the stored order as cancelled through the existing store.

**Tech Stack:** Python

---

## Global Constraints

- Code comments, docstrings and messages state the reason in words. They cite no planning labels — design decisions (D9), task or step numbers (Task 5, Step 2), review fix tags (FIX-2) or change-folder files (design.md, plan.md). Where a comment needs its source, it names the change: "decision D9 of the change <change-name>". Commit messages carry the trace.

## Review Focus

- An order that does not exist is refused, not created.

---

## Task 1: Cancellation

- [ ] **Step 1:** Write a test that cancelling an unshipped order marks it cancelled and a shipped one is refused
- [ ] **Step 2:** Run it and expect it to fail
- [ ] **Step 3:** Add `cancel(order_id: str) -> bool` in `src/orders/cancel.py`
- [ ] **Step 4:** Run the test and expect it to pass
- [ ] **Step 5:** Commit with the trailer `Refs: add-order-cancellation decision D1; task 1.1`
