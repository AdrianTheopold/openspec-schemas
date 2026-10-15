# Spec review step — design spec

> Validated design from brainstorming session, 2026-09-24. Revised 2026-10-15 with the
> findings of a second review round (Context, rule groups 6 and 7, Decision 10).
> Target: superpowers-bridge 1.5.0, against OpenSpec CLI 1.13.0.
> Companion work: changes proposed to Fission-AI/OpenSpec itself are listed under
> [Upstream changes](#upstream-changes). They are not part of this bundle.

---

## Context

At archive, a change's delta specs are merged into `openspec/specs/` and become the
source of truth. After a change ships, they are the artifact people and agents read
most. `openspec validate --strict` checks their structure. It does not check whether
they follow OpenSpec's own authoring guidance, or whether they read correctly to
someone who never saw the change.

A delta spec in an adopter repository passed `openspec validate --strict` while
carrying three kinds of defect, found only by a manual review after implementation:

- a requirement of about 1,500 characters bundling several independent rules;
- sentences phrased against the change itself ("This change SHALL …"). Archive copies
  them verbatim into the main spec, where they no longer refer to anything;
- a scenario whose WHEN presupposed what its THEN denied, so no test could exist for it.

The same review raised a fourth finding — implementation mechanism named inside
requirements — which the author rejected: other systems writing the same data relied
on that mechanism, so it was externally visible. That rejection shapes
[Decision 4](#decision-4-openspecs-authoring-rules-by-pointer) and
[Decision 6](#decision-6-every-spec-review-finding-blocks-verifys-pass): in a review
that blocks, a rule is only as good as its test.

**What `openspec validate` does not report** (1.13.0, each verified with a probe
change):

| Probe content | What validate did |
|---|---|
| A 924-character requirement with five `MUST`s | Nothing on the change path. The same text as a main spec produced one INFO. The length check exists on the main-spec path only |
| `#### Notes` as a requirement's only level-4 header | Counted it as a scenario — any level-4 header satisfies "at least one scenario" |
| A `#### Scenario:` with no steps at all | Nothing. No check reads scenario content |
| 12 deltas (OpenSpec's advisory ceiling is 10) | Nothing. Only archive reports it, as a non-blocking proposal warning |
| A `proposal.md` without `## Why` | "valid". `openspec show` errors on the same change |
| An ADDED requirement whose header already exists in the main spec | "valid", with an INFO: "Archive would refuse this delta". Archive then aborted |

`openspec validate <change>` reads the delta specs only. OpenSpec does compute most of
the missing facts, just elsewhere — which is what Decision 3 relies on.

**A second round** — archiving two related changes in the same repository, months after
both were merged — found five more classes of defect, again all past
`openspec validate --strict`:

- a requirement claiming its test suite keeps four interpreters in agreement, when the
  suite compared three; verify had accepted the claim;
- a requirement in the main spec still naming a public function that a merged change
  had removed;
- two unarchived changes that both modified one requirement, each written against the
  same old text — whichever archived second would have been refused, or would have
  restored the old wording;
- both changes merged unarchived, although the bundle's apply instruction archives
  before the pull request, so the main spec described a removed API for months;
- about 140 code comments citing planning labels — design decisions (`D9`), task
  numbers (`Task 5`), review fix tags (`FIX-2`) — which no longer resolve once the
  change folder is archived, and which collide across changes: two designs each had a
  `D9`. Rewriting them was the largest part of the cleanup.

## Goals

- Before archive, catch what `openspec validate` cannot: departures from OpenSpec's
  authoring guidance, and text that will not read correctly once merged into the main
  spec.
- Use OpenSpec's shipped commands and instruction text first, and keep the rules this
  repository maintains to the ones OpenSpec does not carry.
- Add no code, no new dependency, no new PRECHECK, and no lines to the four
  instructions inherited from upstream (proposal, specs, design, tasks).

## Non-Goals

- Changing OpenSpec. Gaps in `openspec validate` go upstream as separate issues and
  PRs ([Upstream changes](#upstream-changes)). This bundle works with the CLI as
  shipped.
- Style: line width, heading wording, spelling variants, prose taste. A rule two
  reviewers would apply differently does not belong in a review that blocks.
- A waiver mechanism for findings.
- Reviewing the content of `proposal.md`, `design.md` or `tasks.md`. The one proposal
  check included — that it parses — is there because archive depends on it.

## Decisions

### Decision 1: Two review points, one rule file

**Decision**: The review runs twice against the same rule file: a self-check while the
delta spec is being drafted, and a pass in a fresh context inside verify, before
archive.

**Why**: The draft-time pass is cheap, and it fixes requirement shape before tasks and
plan are derived from it. It is weak because the drafting agent reviews its own output.
The verify pass runs after apply, in a separate context, at the last point before the
delta becomes the source of truth, and it also catches drift introduced during apply.
One file keeps both passes judging by the same rules.

**Alternatives considered**:
- Draft-time only — the weakest reviewer, at the only moment the review runs.
- Before archive only — requirement shape can no longer be fixed before tasks derive
  from it.
- On demand only — runs when someone remembers. The defects in Context were found that
  way, after implementation.

### Decision 2: The rule file lives in the bundle

**Decision**: `superpowers-bridge/spec-review.md`, beside `schema.yaml`. Not under
`templates/`: it scaffolds no artifact.

**Why**: Self-contained, offline, runtime-independent, and versioned and re-attested
together with the rest of the bundle. It is installed with the bundle, and
`openspec schema which superpowers-bridge --json` reports the installed bundle's
directory in `path` — for a project, user or package install alike — so the file is
always at `<path>/spec-review.md`. A local wrapper outside this repository can point an
agent at that copy for review on demand. The schema neither references nor requires such a wrapper.

**Alternatives considered**:
- A Claude Code skill — can carry scripts and evals, but becomes a PRECHECKed
  dependency this public schema cannot assume, and adopters on other runtimes lose the
  step.
- The rules written inline in both touchpoint instructions — two copies that drift the
  first time a rule is refined.

### Decision 3: OpenSpec's commands first

**Decision**: The rule file opens with a section that maps each mechanical check to the
OpenSpec command that already computes it, and says how to read the output:

| Check | Command | How to read it |
|---|---|---|
| Structure, duplicate requirements, cross-section contradictions, a MODIFIED block dropping a main-spec scenario | `openspec validate <change> --strict --json` | `"valid": false` is a finding |
| Archive will refuse the delta | same output | An INFO issue whose message begins `Archive would refuse this delta` is a finding |
| `proposal.md` parses | `openspec show <change> --json` | An entry with `"severity": "error"` in `status` is a finding |
| Requirement length, scenario content, delta count | `openspec show <change> --json --deltas-only` | Read each `requirement.text`, each `scenarios[].rawText`, and `deltaCount`. A scenario whose `rawText` has no WHEN or THEN step is a finding. Length and delta count follow [Decision 7](#decision-7-length-and-delta-count-thresholds-prompt-a-rule) |
| A main spec the change touches still has the `TBD` Purpose placeholder | `openspec validate <capability> --type spec --strict` for each capability with a delta | The placeholder warning is a finding. A delta's `## Purpose` only seeds a spec that does not exist yet, so the fix is an edit to the main spec itself |

When the first row reports a MODIFIED block dropping a main-spec scenario because the
block rewrote it under a new title, the fix is to carry the scenario under its old
title, reworded if the behavior changed — archive matches scenarios by title. Copying
the old text back unchanged is right only if the old wording is still true.

**Why**: OpenSpec already computes most of what `validate <change>` leaves out:
archive refusals are reported at INFO, `show` parses the proposal, and `--deltas-only`
exposes every requirement's text and scenarios as JSON. Reading those is cheaper to
maintain than restating each check as a prose rule, and each row retires when the
matching upstream change lands.

**Alternatives considered**: restating every check as a prose rule — roughly fifteen
rules to keep current instead of the seven groups in Decision 5.

### Decision 4: OpenSpec's authoring rules, by pointer

**Decision**: For behavior versus implementation, observability, error conditions, and
the choice between ADDED and MODIFIED, the rule file points the reviewer to the specs
artifact instruction — `openspec instructions specs --change <name> --json`, field
`instruction` — and to its "Good spec content" list, its "Avoid in specs" list and its
"Quick test". It does not restate them.

**Why**: That text is already maintained here: it is one of the four instructions
refreshed from upstream at each bundle release. The Quick test — "if the implementation
can change without changing externally visible behavior, it likely does not belong in
the spec" — is also the right test for a review that blocks. It asks whether a detail
is visible outside, not whether it names a mechanism, so a detail that other systems
rely on passes. Under this test the rejected finding in Context would not be raised.

**Alternatives considered**: copying the rules into the rule file — a second copy of
text the bundle already refreshes.

### Decision 5: The rules this bundle adds

**Decision**: Seven rule groups that OpenSpec carries in no instruction. Each is written
in the rule file as the rule, the test a reviewer applies, and one before/after example.

1. **One behavior per requirement.**
   Source: OpenSpec `docs/writing-specs.md` — "One statement, one SHALL/MUST. If a
   requirement has three 'and also' clauses, it's really three requirements."
   Test: can the text be split into two requirements, each with its own SHALL or MUST
   and its own scenario, without either losing meaning? If yes, it is a finding.
   Before: "The service SHALL store each order as an immutable document carrying `id`,
   `customer`, `lines` and `total`. A stored order MUST NOT be modified or deleted.
   Every order MUST carry a checksum of its lines."
   After: three requirements — the order document's fields; stored orders are
   immutable; orders carry a line checksum.

2. **A scenario exercises its requirement, and its title names the case.**
   Source: `docs/writing-specs.md` — "A scenario that just restates the requirement in
   other words tests nothing."
   Test: could a test be written from the scenario alone that fails when the
   requirement is violated? A scenario whose outcome only restates the requirement, or
   whose WHEN presupposes what its THEN denies, fails.
   Before: "Scenario: Order is stored — WHEN an order is placed THEN it is stored as an
   immutable document."
   After: "Scenario: A resubmitted order does not overwrite the first — WHEN the same
   order is submitted twice with different totals THEN two documents exist and the
   first is unchanged."

3. **Nothing refers to the change.**
   Source: archive copies ADDED and MODIFIED blocks verbatim into the main spec.
   Test: read the sentence as part of `openspec/specs/` a year after archive. Does it
   still refer to something that exists? "This change", "the change that adds …",
   "for now", and "new" used as a time word fail.
   Before: "This change SHALL add no deletion endpoint."
   After: "The service SHALL offer no operation that deletes an order."

4. **Readable without the change folder.**
   Source: at archive the change folder moves to `openspec/changes/archive/`; only the
   specs merge.
   Tests: every term is introduced before it is relied on. No cross-reference points
   into the change folder — design decision labels, task numbers, plan steps — because
   the pointer dangles once the folder is archived. A cross-reference to another
   requirement in the same spec is fine. A THEN states an observable outcome; rationale
   belongs in the requirement text.
   Before: "THEN the order is rejected, because design D4 keeps validation in the
   gateway."
   After: "THEN the order is rejected before it is stored."

5. **Titles name the behavior, never a planning label.**
   Source: OpenSpec matches requirements by title — a MODIFIED block must use "the
   exact same normalized header", and changing a title needs a RENAMED entry
   (this bundle's `templates/spec.md`) — and `docs/writing-specs.md`
   asks for scenario titles that name the case.
   Test: does a requirement or scenario title carry a decision, task, phase or item
   label — "(D9)", "(L1)", "Task 3", "P6" — or anything else a reader cannot decode
   from the spec alone? It fails. A parenthesis that describes behavior, such as
   "(admin only)", is fine.
   Before: "### Requirement: Order validation (D4)"
   After: "### Requirement: Orders are validated before they are stored"
   A label in a title is worse than one in body text: the title is the identity
   archive matches on, so the label outlives the decision it named, and every later
   change that modifies the requirement must repeat it or rename it. In a survey of
   thirteen public repositories using OpenSpec, none labelled a title this way.

6. **A claim matches its enforcement.**
   Source: archive turns the delta into the source of truth; a requirement that
   overstates what is checked becomes a false guarantee there.
   Test: where a requirement names how it is enforced or verified — a test suite, an
   index, a validation step — does that mechanism exist and cover exactly what the
   sentence says? Quantifiers and counts ("all", "every", "four", "always") are checked
   against the code and tests, not against the design. A mismatch fails: reword the
   claim to what is enforced, or add the missing enforcement.
   Before: "The parity suite MUST keep all three payment adapters in agreement." — the
   suite runs two of them.
   After: "The parity suite MUST keep the card and invoice adapters in agreement; the
   wallet adapter is pinned by tests of its request shape."

7. **A removed or renamed name leaves no reference behind.**
   Source: archive applies only the blocks a change carries; a requirement the change
   does not touch keeps its old wording.
   Test: for every public name the change removes or renames — a REMOVED or RENAMED
   requirement, or an API the proposal retires — search the main specs of the touched
   capabilities. Any other requirement that still names it needs a MODIFIED block in
   this change.
   Before: the change removes `list_orders()`; the main spec's requirement "Orders
   expose their totals" still says "`list_orders()` SHALL return …".
   After: the change carries a MODIFIED block for that requirement naming the
   replacement.

**Why**: These are the gaps left after Decisions 3 and 4. Groups 1 and 2 are OpenSpec's
own guidance, published in its docs but missing from the specs instruction; the
upstream change that moves them there would retire both groups here. Groups 3 and 4
follow from how archive works and are not written down upstream; group 5 follows
from how archive matches requirements, and upstream states the matching rule but not
this consequence of it. Groups 6 and 7 are the review-time form of a check the
verification step already intends — that spec, code and tests agree — narrowed to the
two ways the second round in Context showed it failing.

**Alternatives considered**: a larger rule set that includes style — excluded by
Decision 6.

### Decision 6: Every spec-review finding blocks verify's PASS

**Decision**: Any finding that is neither fixed nor dropped by the human makes verify's
Overall Decision ❌ FAIL. Spec-review findings have no warning-only class.

**Why**: The delta spec becomes the source of truth at archive and is read most after
that. Non-blocking hints are what OpenSpec already offers — the INFO lines above — and
they did not stop the defects in Context. The cost of blocking is that precision
matters more than recall: every rule needs a test a second reviewer would apply the
same way, which is why style is a Non-Goal and why thresholds do not block
(Decision 7). A false positive has two exits: fix the text, or the human drops the
finding.

**Alternatives considered**:
- All findings advisory — matches upstream `/opsx:verify`, which does not block
  archive, but depends on someone reading the section.
- Only the command-based checks of Decision 3 block — blocks definite harm, leaves
  judgement advisory.
- Blocking, with waivers recorded in `verify.md` — the most rigorous, and a new format
  every adopter has to learn.

### Decision 7: Length and delta-count thresholds prompt a rule

**Decision**: A requirement longer than 500 characters prompts the reviewer to apply
rule 1 to it. Crossing a threshold is never a finding by itself. The delta count is
read only by the draft-time pass: more than 10 deltas prompts the drafting agent to
confirm the change still has one intent, and to raise it with the human before tasks
are written if it does not. The verify pass does not read the delta count.

**Why**: OpenSpec states both thresholds as non-blocking hints — "Requirement text is
very long (>500 characters). Consider breaking it down." and "Consider splitting
changes with more than 10 deltas" — and does not tie either to its rules. A long
requirement can still be one statement: a single rule with a long list of fields
passes rule 1. Under Decision 6, a delta-count finding would block a change for good,
because splitting compound requirements, which rule 1 asks for, raises the count.
Re-scoping an implemented change is not a spec-review outcome, so the one-intent
question belongs at draft time, while the change can still be split cheaply.
`docs/writing-specs.md` states that question: "A good change has one intent you can say
in a sentence."

**Alternatives considered**:
- Thresholds as findings — contradicts OpenSpec's own framing and blocks well-formed
  changes.
- Ignoring the thresholds — loses a cheap signal for where to look.

### Decision 8: The draft-time pass is a note in the spec template

**Decision**: `templates/spec.md` gains a short note in its header comment: before
finishing the delta spec, run the draft-time self-check in `spec-review.md` — found at
`<path>/spec-review.md`, with `path` from `openspec schema which superpowers-bridge
--json` — and fix what it finds. No line is added to the inherited specs instruction.

**Why**: `openspec instructions specs --json` delivers the template's full content in
the same payload as the instruction (verified on 1.4.0: 3,021 characters of template
beside the instruction), so the note reaches the drafting agent at the same moment. The
template is authored in this repository. The specs instruction is refreshed from
upstream at each release, and every line added there has to be carried through each
refresh. A note in a template is a softer channel than an instruction; the verify pass
is the one that blocks.

**Alternatives considered**:
- A paragraph in the specs instruction — the strongest channel, at the cost of one more
  adapted paragraph per upstream refresh. The instruction already carries one
  bridge-only paragraph, on MODIFIED completeness.
- A step in the tasks instruction — also inherited, and later than necessary.

### Decision 9: The verify pass is check 8

**Decision**: The verify instruction gains check 8, **Spec review**, after the existing
seven, and `templates/verify.md` gains a matching `## 8.` section. Check 8 dispatches a
subagent with no prior context, giving it only the change name and the rule file's
path, resolved as in Decision 2. The subagent runs the commands of Decision 3, applies Decisions 4,
5 and 7 to every delta spec of the change, and reports each finding with file, line,
rule, the quoted text and a suggested fix — or reports "No findings." Any finding makes
the Overall Decision ❌ FAIL (Decision 6).

Check 8 also runs two checks that look beyond the change's own delta specs:

- **Sibling changes.** For every capability the change has a delta for, list
  `openspec/changes/*/specs/<capability>/`. Another unarchived change that MODIFIES,
  RENAMES or REMOVES a requirement this change also MODIFIES, RENAMES or REMOVES is a
  finding: both were written against the same main-spec text, and `openspec validate`
  checks each change against the current main spec only, so it cannot see the
  collision. The fix is an archive order — the earlier change first — and a rewrite of
  the later change's block against the archived text. A sibling that only ADDs
  requirements does not collide.
- **Planning labels in code**, per [Decision 10](#decision-10-code-comments-carry-reasons-commits-carry-the-trace).

**Why**: The bridge's artifact graph has no archive node: archive runs through
OpenSpec's `/opsx:archive`, which this repository does not own. Verify is authored
here, runs after apply and before archive, and already decides whether a change is
ready to archive. The schema already requires a subagent-capable platform, so the fresh
context adds no dependency. Check 1 runs `openspec validate --all --json` without
`--strict`; check 8 runs its own strict validation of the change.

**Alternatives considered**:
- A new artifact after verify — a second document at the same point in the flow, and a
  new node for every adopter.
- A review on demand only — see Decision 1.

### Decision 10: Code comments carry reasons, commits carry the trace

**Decision**: Comments, docstrings and messages in the code a change adds state the
reason in words. They do not cite planning labels — design decisions (`D9`), task or
step numbers (`Task 5`, `Step 2`), review fix tags (`FIX-2`), or files of the change
folder (`design.md`, `plan.md`). Where a comment still needs its source, it names the
change: "decision D9 of the change `add-order-validation`". The link from code to
decision and task lives in the commit message, which names both.

Three parts:

1. **Prevention.** The apply instruction — authored in this repository, not inherited —
   tells the controller to include this rule in every task brief it hands an
   implementing subagent, and to name the decision and task in the commit message
   instead.
2. **Detection.** Check 8 searches the lines the change adds outside `openspec/` —
   `git diff <base>...HEAD` against the branch the change merges into — for
   `\bD[0-9]+\b`, `\bTasks? [0-9]`, `\bStep [0-9]`, `\bFIX-[0-9]`, `design\.md` and
   `plan\.md`. Each hit that is not scoped by the change's name is a finding. `git` is
   already required, so this adds no dependency.
3. **Repair guidance.** In the rule file: state the reason; if the source still
   matters, scope it with the change's name.

**Why**: Implementing subagents work from task briefs that name decisions and tasks,
and they copy those labels into comments as traceability. A label is local to the
document that defines it. Once the change folder is archived it no longer says which
document it means, task lists are renumbered as work moves, and two changes each have
a `D9`, so the same label in one codebase means two different things (Context, second
round). The traceability is real and worth keeping; a commit message keeps it without
leaving it in the code, and stays resolvable as long as the history is kept.

**Alternatives considered**:
- A line in the plan instruction only — the plan is read by the controller, not by the
  subagent that writes the comment, so it does not reach the point where labels are
  written.
- Banning labels without a replacement — loses the traceability, which then comes
  back as labels.
- A per-repository convention only — each adopter would rediscover it, and the
  bundle's own task briefs would keep producing the labels.

## The rule file

Outline of `superpowers-bridge/spec-review.md`:

1. **When this file is used** — the draft-time self-check (Decision 8) and verify check
   8 (Decision 9); what counts as a finding (Decision 6).
2. **What OpenSpec already checks** — the table of Decision 3.
3. **OpenSpec's authoring rules** — the pointer of Decision 4.
4. **Rules this bundle adds** — the seven groups of Decision 5, each with source, test and
   before/after.
5. **Beyond the delta specs** — the sibling-change check of Decision 9 and the code-label
   check of Decision 10, with its search patterns and repair guidance.
6. **Thresholds** — Decision 7, including which pass reads the delta count.
7. **Report format** — one line per finding:
   `<file>:<line> — rule <n> — "<quoted text>" — <suggested fix>`, or `No findings.`

## Upstream changes

Proposed to Fission-AI/OpenSpec separately. Its contribution guide asks for an issue or
discussion before a PR, so each item is its own issue first. The last column names what
each change retires from `spec-review.md` once it reaches a bundle refresh.

| # | Change | Evidence | Retires |
|---|---|---|---|
| 1 | Make the sample `validate` output in `docs/cli.md` match the tool: it shows `proposal.md` and `design.md` checks that do not exist | Probe; no code path reads either file | — |
| 2 | Align the proposal example in `docs/concepts.md` (Intent / Scope / Approach) with the proposal template | `openspec show` errors on that shape | — |
| 3 | Add the two authoring rules from `docs/writing-specs.md` to the `spec-driven` specs instruction | Published in the docs, absent from the instruction | Rule groups 1 and 2 |
| 4 | Run the proposal parse (Why, What Changes, delta count) in `openspec validate <change>` | The schema and messages exist; validate calls a different function | The `openspec show` row |
| 5 | Run the requirement-length check on delta specs as well as main specs | Same constant and message, main-spec path only | The length reading |
| 6 | Report archive refusals that are definite, such as an ADDED header that already exists, as errors; keep contingent ones as info | A MODIFIED block that drops a scenario is already an error, so that "the change fails at authoring time instead of days later at archive time". Needs a discussion: INFO was chosen deliberately | The INFO reading |
| 7 | Count only `#### Scenario:` headers toward "at least one scenario", and report other level-4 headers the way stray `###` headers already are | The any-level-4 match is deliberate, for parity between the two paths — discussion first | Part of the scenario-content reading |
| 8 | Warn on a scenario without a WHEN or THEN step, accepting both `- **WHEN**` and `- WHEN` | `docs/concepts.md` uses the plain form, so a bold-only check would flag upstream's own docs | The rest of the scenario-content reading |
| 9 | Run the task-numbering check for custom schemas, not only the built-in `spec-driven` | Source-read: the check returns early for any other schema | — |

## Risks / Trade-offs

- [Risk] A false positive blocks an otherwise finished change → Mitigation: every rule
  carries a test; style is excluded; thresholds prompt but never block; the human can
  drop a finding.
- [Risk] The INFO reading in Decision 3 matches on message text. If upstream rewords
  "Archive would refuse this delta", the reading matches nothing and reports clean —
  OpenSpec's own source names this failure: "a check that matches nothing looks exactly
  like a check that found nothing" → Mitigation: the per-release re-attestation checks
  that this message and the `--deltas-only` JSON fields still exist.
- [Risk] OpenSpec marks its `schema` commands experimental, and both touchpoints locate
  the rule file through `openspec schema which` → Mitigation: re-attestation checks that
  it still reports `path`.
- [Risk] The drafting agent skips the template note → Mitigation: check 8 blocks
  regardless.
- [Risk] The rule file drifts from the upstream docs it cites → Mitigation: every rule
  names its source, and re-attestation re-reads the sources.
- [Trade-off] Every adopter's verify gains a blocking check → Accepted: it runs once per
  verify, and the only part that reads code is a search of the change's added lines.
- [Risk] The code-label search flags a token that is not a planning label — a variable
  `D2`, a domain code → Mitigation: the hit is shown with its line, and the human can
  drop it (Decision 6); the patterns are anchored to word boundaries.
- [Risk] A change is merged before it is archived, as both changes in the second round
  were, although the apply instruction already archives before the pull request →
  Not mitigated by this design: verify runs before archive and cannot see a merge. See
  Open Questions.

## Migration Plan

- Bundle 1.5.0: `spec-review.md`, the note in `templates/spec.md`, verify check 8 (with
  the sibling-change and code-label checks), the `## 8.` section in
  `templates/verify.md`, the task-brief rule and commit-message trace in the apply
  instruction (Decision 10), `README.md` and `README.zh-TW.md` (lifecycle and verify
  description), `VERSION`.
- CI: `openspec schema validate superpowers-bridge` must still pass with the extra file
  in the bundle.
- Acceptance before release: run check 8 against a delta spec with no defects —
  expect `No findings.` — and against a delta spec seeded with one defect per rule group
  and per row of Decision 3's table, plus a sibling change modifying the same
  requirement and one labelled code comment — expect each seeded defect found exactly
  once, and nothing else.
- Adopters refresh their installed bundle. A change already past verify is unaffected;
  a change that re-runs verify gets check 8.
- Rollback: reinstall 1.4.0.

## Open Questions

- Whether the acceptance fixtures are committed to this repository, as documentation of
  what each rule catches, or stay in a scratch project. Deferrable: it changes neither
  the rules nor the touchpoints.
- How to keep a change from being merged before it is archived. The apply instruction
  already orders archive before the pull request; the second round shows it is
  skipped. A guard would sit outside the bundle (a local check that an adopter repo's
  default branch carries no change whose implementation is merged but whose folder is
  not archived), so it is not part of 1.5.0.
