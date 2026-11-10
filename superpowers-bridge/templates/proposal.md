# Proposal

## Why

<!--
Explain the motivation for this change. What problem does this solve? Why now?

Hard limit: 50 ≤ character count ≤ 1000 (validated by OpenSpec's zod schema)
- Too short: you'll get a `Why section must be at least 50 characters` error
- Too long: you'll get a `Why section should not exceed 1000 characters` error

Suggested structure: current pain point → why address it now → expected
benefit (1-2 sentences each)
-->

## What Changes

<!--
Describe what will change. Be specific about new capabilities, modifications, or removals.

For behavior changes with a clear before/after contrast, use the From/To
format (markdown has no inline diff):

**<Section or Behavior Name>**
- From: <current state / requirement>
- To: <future state / requirement>
- Reason: <why this change is needed>
- Impact: <breaking / non-breaking, who's affected>

Repeat this block for multiple changes; pure additions or pure removals can
be described with a simple list.
-->

## Capabilities

### New Capabilities
<!--
Capabilities being introduced. Name each capability for a cohesive system
behavior that can own related requirements as the system evolves — not for
an implementation task or a proposal section — and avoid broad catch-all
names. Replace <capability-path> with a kebab-case
identifier that follows the project's existing spec organization (flat
`user-auth`, or nested `identity/user-auth` only where the project already
nests). Naming rule (see openspec/specs/README.md): use a compound noun (at
least 2 words), e.g. `user-auth`, `data-export`, `api-rate-limiting` — not a
single bare word. Run `openspec list --specs` first so a new name does not
near-duplicate an existing capability.
Each creates specs/<capability-path>/spec.md
-->
- `<capability-path>`: <brief description of what this capability covers>

### Modified Capabilities
<!--
Existing capabilities whose REQUIREMENTS are changing (not just implementation).
Only list here if spec-level behavior changes. Each needs a delta spec file.
Use the exact existing path under openspec/specs/. Leave empty if no
requirement changes. A change with no capabilities at all (pure refactor,
tooling, docs) must set `skip_specs: true` in its .openspec.yaml — openspec
validate rejects a zero-delta change without that marker. Do not invent a
requirement just to satisfy validation.
-->
- `<existing-capability-path>`: <what requirement is changing>

## Impact

<!-- Affected code, APIs, dependencies, systems -->

## Declared amendments

<!--
Optional: delete this section when the change is planned against no pending
amendment. List each pending amendment to a governing source that the change
is planned against, so that verify reads it at the declared commit instead of
reporting the planned text as a deviation. Give the commit as the
full commit hash, never shortened or a branch name: a short hash can turn ambiguous, a
branch moves, and the work must not rewrite the rules it is judged by. When
the amendment later takes in a deviation, add a move to the new commit naming
the deviation, its place in the source and who decided it; a move that names
no decider or no place takes in nothing. Write the entries below this comment,
in this form:

- `<source>`: pending amendment on `<where it lives, e.g. a branch or merge request>`.
  - Planned against commit `<full hash>`.
  - Moved to commit `<full hash>` to take in the deviation *<name>* (<section>: "<the source text it changes>"), decided by <who> as an edit to the source.
-->
