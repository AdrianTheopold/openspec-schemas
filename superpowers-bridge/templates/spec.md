<!--
Delta spec template for a change.

This template demonstrates the 4 delta section types; use whichever you
actually need:
- ADDED / MODIFIED / REMOVED / RENAMED
Filename & location: openspec/changes/<change-name>/specs/<capability-path>/spec.md
(`<capability-path>` matches the openspec/specs/<capability-path>/ directory,
nested paths such as `identity/user-auth` included)

Hard format rules (validated by OpenSpec):
- A Requirement sentence MUST contain `SHALL` or `MUST`
- Every Requirement MUST have at least one `#### Scenario:`
- Scenarios MUST use level-4 headings (`####`); level-3 or bullets fail silently
- A MODIFIED block MUST keep every scenario the main spec still has
-->

## Purpose

<!--
New capabilities only: one or two sentences (50+ characters) on what this
capability is for. Archive copies it into the new main spec; without it the
main spec is left with a "TBD" placeholder. DELETE this whole section for a
delta on an existing capability — its Purpose is already set and a delta's is
ignored.
-->

## ADDED Requirements

<!-- New behavior. List the new Requirements this change adds to the capability. -->

### Requirement: <!-- requirement name -->
<!-- requirement text — must contain SHALL or MUST -->

#### Scenario: <!-- scenario name -->
- **WHEN** <!-- condition -->
- **THEN** <!-- expected outcome -->

---

## MODIFIED Requirements

<!--
Modify an existing Requirement. **MUST use the exact same normalized header
as in openspec/specs/<capability>/spec.md** (compared case-sensitively after
trimming), otherwise the delta apply at archive time will fail because it
can't find the matching requirement.

**MUST paste the full modified content** (not just a diff), because OpenSpec
archive applies MODIFIED by full-text replacement — including every scenario
the main spec still has. `openspec validate` errors on a MODIFIED block that
omits one, and archive refuses to drop scenarios silently.
-->

### Requirement: <!-- the same header as in the existing spec -->
<!-- the full modified requirement text — contains SHALL or MUST -->

#### Scenario: <!-- scenario name (may be added or modified) -->
- **WHEN** <!-- condition -->
- **THEN** <!-- expected outcome -->

---

## REMOVED Requirements

<!--
Remove an existing Requirement. MUST include Reason and Migration notes so the
reviewer understands why it's being retired and how existing references should
migrate.
-->

### Requirement: <!-- the header to remove, identical to the existing spec -->

**Reason**: <!-- why it's being retired -->

**Migration**: <!-- how existing callers / dependents should adapt -->

---

## RENAMED Requirements

<!--
Rename a Requirement header. Fixed format: FROM / TO using code-fenced headers.
If both the name and the content change, list the name change under RENAMED
**and** write the full content under MODIFIED using the **new** header.

Apply order at archive time: RENAMED → REMOVED → MODIFIED → ADDED
-->

- FROM: `### Requirement: <Old Name>`
- TO: `### Requirement: <New Name>`
