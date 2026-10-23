# Purge Cancelled Orders Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development
> to implement this plan task-by-task.

**Spec:** openspec/changes/purge-cancelled-orders/specs/ and design.md

**Goal:** Purge cancelled orders 30 days after cancellation and let a client delete a cancelled order through the public API.

**Architecture:** A purge module removes cancelled orders past their retention; a nightly CI job runs it. The public API gains a delete route that refuses orders that are not cancelled.

**Tech Stack:** Python, GitHub Actions

---

## Task 1: Purge

- [x] **Step 1:** Write a failing test: an order cancelled 31 days ago is purged, one cancelled 29 days ago is kept
- [x] **Step 2:** Run it and see it fail
- [x] **Step 3:** Add `store.delete`, `store.all_ids` and `purge.purge_cancelled`
- [x] **Step 4:** Run the test and see it pass
- [x] **Step 5:** Add the nightly purge job to the CI workflow

## Task 2: Delete endpoint

- [x] **Step 1:** Write a failing test: deleting a cancelled order removes it, deleting an order that is not cancelled is refused
- [x] **Step 2:** Run it and see it fail
- [x] **Step 3:** Add the delete route to the public API
- [x] **Step 4:** Run the test and see it pass
