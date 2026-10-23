# Expected agent outcomes: seeded

The change `rework-order-totals` (sibling: `adjust-order-totals`) carries fourteen
seeds. Each is found exactly once, and nothing else. T1 to T5 are found by running
OpenSpec commands; R1 to R7, S1 and L1 are found by reading.

Paths are relative to the staged repository. `spec.md` below is
`openspec/changes/rework-order-totals/specs/orders/spec.md` unless noted.

| Seed | Found by | File | Rule or table row | Quoted text |
|---|---|---|---|---|
| T1 | command | `spec.md` | strict validation: ADDED requirement over 500 characters | ADDED "Orders record their fulfilment history" (530 characters, five `MUST`s) |
| T2 | command | `spec.md` | archive would refuse the delta | ADDED "Orders are stored", a header the main spec already has |
| T4a | command | `spec.md` | scenario without WHEN or THEN | scenario "Totals are visible": "Staff can see the total of an order in the order summary." |
| T4b | command | `spec.md` | level-4 header that is not a scenario | `#### Notes` under "Orders report their totals" |
| T5 | command | `openspec/specs/orders/spec.md` | placeholder Purpose | "TBD - created by archiving change add-orders. Update Purpose after archive." |
| R1 | reading | `spec.md` | one behavior per requirement, MODIFIED blocks too | MODIFIED "Orders are priced" adds "Every order MUST carry a checksum of its lines." |
| R2 | reading | `spec.md` | a scenario exercises its requirement | scenario "Order is stored": WHEN an order is placed THEN it is stored as an immutable document. |
| R3 | reading | `spec.md` | nothing refers to the change | "This change SHALL add no deletion endpoint." |
| R4 | reading | `spec.md` | readable without the change folder | "THEN the order is rejected, because design D4 keeps validation in the gateway." |
| R5 | reading | `spec.md` | titles name the behavior | "### Requirement: Order validation (D9)" |
| R6 | reading | `spec.md`, `tests/test_parity.py` | a claim matches its enforcement | "The parity suite MUST keep all three payment adapters in agreement." while the suite compares two |
| R7 | reading | `spec.md`, `openspec/specs/orders/spec.md` | a removed name leaves no reference behind | REMOVED "Orders can be listed" retires `list_orders()`; the main-spec requirement "Orders expose their totals" still says "`list_orders()` SHALL return each order together with its total." |
| S1 | reading | `openspec/changes/adjust-order-totals/specs/orders/spec.md` | sibling change on the same requirement | MODIFIED "Orders are priced", the requirement R1's block also modifies |
| L1 | reading | `src/orders/totals.py` | planning label in a code comment | `# Task 3: recompute totals after a line is removed` |

