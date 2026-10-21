# Spec review and deviation report — design spec

> Validated design from brainstorming session, 2026-09-24. Revised 2026-10-15 with the
> findings of a second review round (Context, rule groups 6 and 7, Decision 10).
> Revised 2026-10-21 (third revision): re-checked against OpenSpec CLI 1.14.2 and
> Superpowers 7.0.0, and re-scoped around where human review happens. Spec-review
> findings are now cleared by the agent, not triaged by the human; the human gate is a
> deviation report against the adopter's governing sources (Decisions 6, 11–13).
> Target: superpowers-bridge 1.5.0, against OpenSpec CLI 1.14.3, built on bundle 1.4.1
> (see [Migration Plan](#migration-plan)).
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
[Decision 4](#decision-4-openspecs-authoring-rules-by-pointer): a rule is only as good
as its test.

**What `openspec validate` does not report.** Each row was verified with a probe change
on 1.13.0 and again on 1.14.2.

| Probe content | 1.13.0 | 1.14.2 |
|---|---|---|
| A requirement over 500 characters with five `MUST`s | Nothing on the change path; one INFO on the main-spec path | ADDED: a WARNING, so `--strict` reports `"valid": false`. MODIFIED: still nothing — deliberate, per the specs instruction |
| `#### Notes` as a requirement's only level-4 header | Counted as a scenario | Unchanged — any level-4 header satisfies "at least one scenario" |
| A `#### Scenario:` with no body | Nothing | An ERROR — closed upstream, no longer a gap |
| A scenario with a body but no WHEN or THEN step | Nothing | Nothing. No check reads step content |
| 12 deltas (OpenSpec's advisory ceiling is 10) | Only archive reports it, as a non-blocking proposal warning | Unchanged |
| A `proposal.md` without `## Why` | "valid"; `openspec show` errors on the same change | Unchanged |
| An ADDED requirement whose header already exists in the main spec | "valid", with an INFO: "Archive would refuse this delta". Archive then aborted | Unchanged, same message text |
| Two unarchived changes modifying the same requirement | Both valid; whichever archived second silently overwrote the first's wording | Unchanged |

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

**Where human review happens.** The first two revisions of this design made every
spec-review finding block verify until the human fixed or dropped it. That put the
heaviest review load on the delta specs. Some adopters steer from one level up: they
keep their intent, decisions, contracts and non-goals in governing documents outside
the repository — a knowledge base, an architecture-decision log — and those documents,
not the repository's specs, are the surface they review thoroughly. For them, delta
specs are a secondary reading layer, consulted when the governing document is too vague,
and implementation detail is delegated to the agent as long as it follows good practice
and the adopter's safety rules. Specs may drift from their first draft while the work
runs; what such an adopter needs to see is a deviation that the governing documents do
not yet reflect, together with its reason.

Two lessons from outside this repository point the same way. Generated plans and specs
are hard to review: readers skim long AI-written text, so a review gate built on reading
it gives a false sense of control. And autonomous work goes best when the agent may
explore and revise its approach, with the human attending to the few points where their
attention changes the outcome.

## Goals

- Before archive, catch what `openspec validate` cannot: departures from OpenSpec's
  authoring guidance, text that will not read correctly once merged into the main spec,
  and deltas that would corrupt the main spec at archive.
- Clear those findings without spending human review on them: the agent fixes each one,
  or dismisses it with a recorded reason.
- Spend human attention on one artifact: a report of every way the change deviates from
  the adopter's governing sources, each with its reason and a proposed edit to the
  source.
- Let each adopter keep its governing sources, its deviation threshold and its safety
  rules outside this bundle, so they can evolve without a bundle release.
- Use OpenSpec's shipped commands, configuration and instruction text first, and keep
  the rules this repository maintains to the ones OpenSpec does not carry.
- Add no code, no new dependency, no new PRECHECK, and no lines to the four
  instructions inherited from upstream (proposal, specs, design, tasks).

## Non-Goals

- Changing OpenSpec. Gaps in `openspec validate` go upstream as separate issues and
  PRs ([Upstream changes](#upstream-changes)). This bundle works with the CLI as
  shipped.
- Style: line width, heading wording, spelling variants, prose taste. A rule two
  reviewers would apply differently does not belong in a review that blocks.
- A human waiver mechanism for spec-review findings. The agent clears them; its
  dismissals are recorded in `verify.md` for anyone who wants to read them.
- Reviewing the content of `proposal.md`, `design.md` or `tasks.md`. The one proposal
  check included — that it parses — is there because archive depends on it.
- Defining what an adopter's governing sources, deviation threshold or safety rules
  say. The bundle defines how they are read and where their results go; the content is
  the adopter's.

## Decisions

### Decision 1: Two review points, one rule file

**Decision**: The spec review runs twice against the same rule file: a self-check while
the delta spec is being drafted, and a pass in a fresh context inside verify, before
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
always at `<path>/spec-review.md` (verified on 1.13.0 and 1.14.2; `openspec schema
validate` passes with the extra file in the bundle on both). A local wrapper outside
this repository can point an agent at that copy for review on demand. The schema
neither references nor requires such a wrapper.

The rule file carries only rules that hold for every OpenSpec user. Adopter-specific
rules — governing sources, deviation threshold, safety — stay outside it
([Decision 13](#decision-13-adopter-rulesets-come-from-openspecconfigyaml)).

**Alternatives considered**:
- A Claude Code skill — can carry scripts and evals, but becomes a PRECHECKed
  dependency this public schema cannot assume, and adopters on other runtimes lose the
  step.
- The rules written inline in both touchpoint instructions — two copies that drift the
  first time a rule is refined.

### Decision 3: OpenSpec's commands first

**Decision**: The rule file opens with a section that maps each mechanical check to the
OpenSpec command that already computes it, and says how to read the output. Rows are
stated for 1.14.2:

| Check | Command | How to read it |
|---|---|---|
| Structure, duplicate requirements, cross-section contradictions, a MODIFIED block dropping a main-spec scenario, an empty scenario, an ADDED requirement over 500 characters | `openspec validate <change> --strict --json` | `"valid": false` is a finding |
| Archive will refuse the delta | same output | An INFO issue whose message begins `Archive would refuse this delta` is a finding |
| `proposal.md` parses | `openspec show <change> --json` | An entry with `"severity": "error"` in `status` is a finding. Fix it first: while the proposal does not parse, `--deltas-only` returns no deltas, so the next row has nothing to read |
| Scenario content, MODIFIED requirement length, delta count | `openspec show <change> --json --deltas-only` | Read each `requirement.text`, each `scenarios[].rawText`, and `deltaCount`. A scenario whose `rawText` has no WHEN or THEN step is a finding. A level-4 header that is not `#### Scenario:` is a finding; find it in the markdown, because the JSON `name` drops the `Scenario:` prefix. Length and delta count follow [Decision 7](#decision-7-thresholds-follow-upstream-where-upstream-has-one) |
| A main spec the change touches still has the `TBD` Purpose placeholder | `openspec validate <capability> --type spec --strict` for each capability with a delta | A warning whose message begins `Purpose section is still a placeholder` is a finding. Match the message, not `valid`: on 1.14.x the same command also fails on any long requirement in the main spec, including ones this change never touched. A delta's `## Purpose` only seeds a spec that does not exist yet, so the fix is an edit to the main spec itself |

When the first row reports a MODIFIED block dropping a main-spec scenario because the
block rewrote it under a new title, the fix is to carry the scenario under its old
title, reworded if the behavior changed — archive matches scenarios by title. Copying
the old text back unchanged is right only if the old wording is still true.

**Why**: OpenSpec already computes most of what `validate <change>` leaves out:
archive refusals are reported at INFO, `show` parses the proposal, and `--deltas-only`
exposes every requirement's text and scenarios as JSON. Reading those is cheaper to
maintain than restating each check as a prose rule, and each row retires when the
matching upstream change lands — the empty-scenario and ADDED-length checks already
moved into the first row this way between 1.13.0 and 1.14.1.

**Alternatives considered**: restating every check as a prose rule — roughly fifteen
rules to keep current instead of the seven groups in Decision 5.

### Decision 4: OpenSpec's authoring rules, by pointer

**Decision**: For behavior versus implementation, observability, error conditions, the
choice between ADDED and MODIFIED, and one behavior per ADDED requirement, the rule file
points the reviewer to the specs artifact instruction —
`openspec instructions specs --change <name> --json`, field `instruction` — and to its
"Good spec content" list, its "Avoid in specs" list and its "Quick test". It does not
restate them.

**Why**: That text is already maintained here: it is one of the four instructions
refreshed from upstream at each bundle release, and 1.14.x added the one-behavior rule
for new requirements to it. The Quick test — "if the implementation can change without
changing externally visible behavior, it likely does not belong in the spec" — is also
the right test for a review that blocks. It asks whether a detail is visible outside,
not whether it names a mechanism, so a detail that other systems rely on passes. Under
this test the rejected finding in Context would not be raised.

**Alternatives considered**: copying the rules into the rule file — a second copy of
text the bundle already refreshes.

### Decision 5: The rules this bundle adds

**Decision**: Seven rule groups that OpenSpec carries in no instruction. Each is written
in the rule file as the rule, the test a reviewer applies, and one before/after example.

1. **One behavior per requirement, in MODIFIED blocks too.**
   Source: OpenSpec `docs/writing-specs.md` — "One statement, one SHALL/MUST. If a
   requirement has three 'and also' clauses, it's really three requirements." The
   1.14.x specs instruction applies this to new requirements and asks MODIFIED blocks
   to keep the existing requirement whole; this group covers the case between them.
   Test: for an ADDED requirement, Decision 4's pointer applies. For a MODIFIED block,
   does the modification add a behavior the requirement did not have, which could stand
   as its own requirement with its own SHALL or MUST and its own scenario? If yes, it is
   a finding: the new behavior belongs in an ADDED requirement, and the MODIFIED block
   keeps the existing requirement whole.
   Before: a MODIFIED "Orders are stored" that now also says "Every order MUST carry a
   checksum of its lines."
   After: "Orders are stored" unchanged apart from its own behavior; an ADDED
   requirement "Orders carry a line checksum".

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
own guidance, published in its docs; 1.14.x moved the ADDED half of group 1 into the
specs instruction, and the upstream change that moves the rest there would retire both
groups here. Groups 3 and 4 follow from how archive works and are not written down
upstream; group 5 follows from how archive matches requirements, and upstream states the
matching rule but not this consequence of it. Groups 6 and 7 are the review-time form of
a check the verification step already intends — that spec, code and tests agree —
narrowed to the two ways the second round in Context showed it failing.

**Alternatives considered**: a larger rule set that includes style — excluded because a
style rule has no test two reviewers would apply the same way.

### Decision 6: Spec-review findings block verify, and the agent clears them

**Decision**: Every spec-review finding blocks verify's PASS until it is cleared, and
clearing is the agent's job. For each finding the agent either fixes the text or code,
or dismisses the finding with a one-line reason recorded in `verify.md`. A finding is
escalated to the human only when its fix would change behavior that a governing source
states; it then becomes a deviation and goes into the deviation report
([Decision 11](#decision-11-the-deviation-report-is-the-human-gate)). Spec-review
findings have no warning-only class.

**Why**: The delta spec becomes the source of truth at archive and is read most after
that, so its defects must not reach archive — non-blocking hints are what OpenSpec
already offers, and they did not stop the defects in Context. But the human's review
belongs on the governing sources and on deviations from them, not on sentence-level
findings in a secondary layer; a gate that makes the human triage "this sentence refers
to the change" spends attention where it changes nothing. Every rule here has a test the
agent can apply and a fix it can make. The dismissal reason keeps a false positive from
blocking for good, and keeps the record honest: the dismissals are in `verify.md` for
anyone who wants to audit them.

**Alternatives considered**:
- Every finding blocks until the human fixes or drops it — the previous revision. It
  makes the human the triage step for the layer they read least.
- All findings advisory — matches upstream `/opsx:verify`, whose 1.14.2 template says
  "Verification is advisory", but depends on someone reading the section.
- Only the command-based checks of Decision 3 block — blocks definite harm, leaves
  judgement unattended.

### Decision 7: Thresholds follow upstream where upstream has one

**Decision**:
- **ADDED requirement length**: an ADDED requirement over 500 characters fails
  `openspec validate --strict` on 1.14.1 and later, so it is a finding through
  Decision 3's first row, cleared like any other (Decision 6). The usual fix is
  upstream's own advice: move examples and edge cases into scenarios, or split the
  requirement.
- **MODIFIED requirement length**: upstream deliberately does not check it. A MODIFIED
  requirement over 500 characters prompts the reviewer to apply rule 1; the length alone
  is never a finding.
- **Delta count**: read only by the draft-time pass. More than 10 deltas prompts the
  drafting agent to confirm the change still has one intent. If it does not, the agent
  splits the change before tasks are written; if it does, it records the one intent in a
  sentence in the proposal. The verify pass does not read the delta count.

**Why**: Following upstream keeps this bundle's verdict and `validate --strict` in
agreement: a check that blocks where strict validation passes, or passes where it fails,
is a second standard to learn. The MODIFIED exemption is upstream's choice, made so that
a small edit to a long existing requirement is not forced into a rewrite; rule 1 still
catches a MODIFIED block that grows a new behavior. A delta-count finding at verify
would block a change for good — splitting compound requirements, which rule 1 asks for,
raises the count — and re-scoping an implemented change is not a spec-review outcome,
so the one-intent question belongs at draft time, while the change can still be split
cheaply. `docs/writing-specs.md` states that question: "A good change has one intent
you can say in a sentence."

**Alternatives considered**:
- The previous revision: length only prompts rule 1 everywhere — contradicts
  `validate --strict` from 1.14.1 on.
- Raising the one-intent question with the human — interrupts autonomous work for a
  decision the agent can make and record.

### Decision 8: The draft-time pass is a note in the spec template

**Decision**: `templates/spec.md` gains a short note in its header comment: before
finishing the delta spec, run the draft-time self-check in `spec-review.md` — found at
`<path>/spec-review.md`, with `path` from `openspec schema which superpowers-bridge
--json` — and fix what it finds. No line is added to the inherited specs instruction.

**Why**: `openspec instructions specs --json` delivers the template's full content in
the same payload as the instruction (verified on 1.13.0 and 1.14.2: 3,021 characters of
template beside the instruction), so the note reaches the drafting agent at the same
moment. The note stays inside the header's HTML comment: 1.14.2 warns on prose before a
spec's first section, and a probe showed HTML comments do not trigger it. The template
is authored in this repository; the specs instruction is refreshed from upstream at each
release, and every line added there has to be carried through each refresh. A note in a
template is a softer channel than an instruction; the verify pass is the one that blocks.

**Alternatives considered**:
- A paragraph in the specs instruction — the strongest channel, at the cost of one more
  adapted paragraph per upstream refresh. The instruction already carries one
  bridge-only paragraph, on MODIFIED completeness.
- A step in the tasks instruction — also inherited, and later than necessary.

### Decision 9: The verify pass is check 8

**Decision**: The verify instruction gains check 8, **Spec review**, after the existing
seven, and `templates/verify.md` gains a matching `## 8.` section. Check 8 dispatches a
subagent with no prior context, giving it only the change name and the rule file's
path, resolved as in Decision 2. The subagent runs the commands of Decision 3, applies
Decisions 4, 5 and 7 to every delta spec of the change, and reports each finding with
file, line, rule, the quoted text and a suggested fix — or reports "No findings." The
apply controller then clears each finding (Decision 6) and re-runs check 8 until it
reports no uncleared finding.

Check 8 also runs two checks that look beyond the change's own delta specs:

- **Sibling changes.** For every capability the change has a delta for, list
  `openspec/changes/*/specs/<capability>/`. Another unarchived change that MODIFIES,
  RENAMES or REMOVES a requirement this change also MODIFIES, RENAMES or REMOVES is a
  finding: both were written against the same main-spec text, and `openspec validate`
  checks each change against the current main spec only, so it cannot see the
  collision (verified on 1.14.2: the second archive silently overwrote the first's
  wording). The fix is an archive order — the earlier change first — and a rewrite of
  the later change's block against the archived text. A sibling that only ADDs
  requirements does not collide.
- **Planning labels in code**, per [Decision 10](#decision-10-code-comments-carry-reasons-commits-carry-the-trace).

**Why**: The bridge's artifact graph has no archive node: archive runs through
OpenSpec's `/opsx:archive`, which this repository does not own. Verify is authored
here, runs after apply and before archive, and already decides whether a change is
ready to archive. The schema already requires a subagent-capable platform, so the fresh
context adds no dependency. The dispatch follows the pattern Superpowers'
`requesting-code-review` uses for its final review: a general-purpose subagent, a
template file, and no session history. Check 1 runs `openspec validate --all --json`
without `--strict`; check 8 runs its own strict validation of the change.

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

1. **Prevention, through the plan.** The plan instruction — authored in this
   repository — puts this rule into `plan.md`'s `## Global Constraints` section, and
   writes each task's commit step so that its message names the decision and the task.
   The apply instruction repeats the rule for the controller, as a backup.
2. **Detection.** Check 8 searches the lines the change adds outside `openspec/` —
   `git diff <base>...HEAD` against the branch the change merges into — for
   `\bD[0-9]+\b`, `\bTasks? [0-9]`, `\bStep [0-9]`, `\bFIX-[0-9]`, `design\.md` and
   `plan\.md`. Each hit that is not scoped by the change's name is a finding, cleared
   like any other (Decision 6). `git` is already required, so this adds no dependency.
3. **Repair guidance.** In the rule file: state the reason; if the source still
   matters, scope it with the change's name.

**Why**: Implementing subagents copy decision and task labels into comments as
traceability. A label is local to the document that defines it. Once the change folder
is archived it no longer says which document it means, task lists are renumbered as
work moves, and two changes each have a `D9`, so the same label in one codebase means
two different things (Context, second round). The traceability is real and worth
keeping; a commit message keeps it without leaving it in the code, and stays resolvable
as long as the history is kept.

The plan is the channel that reaches the implementing subagent. Superpowers'
subagent-driven development builds each implementer's brief by copying that task's
section of `plan.md` verbatim (`skills/subagent-driven-development/scripts/task-brief`,
present at v6.3.0 and v7.0.0). The controller wraps the brief in a fixed dispatch, and
the skill limits what it adds: "A fresh subagent needs its task, the interfaces it
touches, and the global constraints. Nothing else." The task reviewer's prompt has a
fixed `[GLOBAL_CONSTRAINTS]` slot, filled from the plan's Global Constraints section,
and commit messages are written in the plan's commit steps. An instruction to the
controller alone reaches the brief only if the controller follows it, and not at all
when the whole loop runs as one nested orchestrator subagent. Prevention is still
partial — writing instructions is a known weak control for comment content — which is
why detection does the enforcing.

**Alternatives considered**:
- A line in the apply instruction only — the previous revision. It rests on the
  controller composing the brief freely, which the latest Superpowers does not do.
- Banning labels without a replacement — loses the traceability, which then comes
  back as labels.
- A per-repository convention only — each adopter would rediscover it, and the
  bundle's own task briefs would keep producing the labels.

### Decision 11: The deviation report is the human gate

**Decision**: The verify instruction gains check 9, **Deviation report**, and
`templates/verify.md` a matching `## 9.` section. Check 9 dispatches a subagent with no
prior context. It reads:

- the governing sources the adopter names ([Decision 13](#decision-13-adopter-rulesets-come-from-openspecconfigyaml));
- the change's proposal, design and delta specs as they will be archived;
- the diff of the change against the branch it merges into;
- the executor's "Rulings I made" list, which the apply controller already hands to
  verify (check 4).

It reports every **deviation**: a point where the change contradicts, drops, or goes
beyond what a governing source states — including a stated non-goal — so that the
governing source would need an edit to stay true. For each deviation: the source and
the place in it, what it says, what the change does instead, why, what it costs if the
reasoning is wrong, and the proposed edit to the source. Or it reports "No deviations
from the governing sources."

The adopter's rules can narrow or widen what counts as a deviation; the default is the
definition above. Drift between the delta specs and their own first draft is not a
deviation: the specs are rewritten to match what was built before archive, and only a
drift that also moves away from a governing source is reported.

The report is the artifact the human reads. Apply step 6 carries it into the pull
request description: Superpowers' `finishing-a-development-branch` creates the pull
request with the forge's tooling but prescribes no body, so the apply instruction tells
the controller to put `verify.md` § 9 into the description it writes, and to edit the
description afterwards if the request was created without it. `verify.md` itself stays
the record — it travels in the pull request diff as part of the archived change. The
adopter's rules say how each proposed edit reaches its source — for example, as a change request to the knowledge base that holds it. A
deviation does not fail verify: whether to accept it, amend the source, or reverse the
code is the human's decision at merge time. What fails verify is a missing report, a
deviation without a reason, or a governing source named in the configuration that the
subagent could not read.

If the adopter names no governing sources, check 9 records "No governing sources
configured" and passes: stock behavior is unchanged.

**Why**: Human attention goes to the few places where it changes the outcome. For an
adopter who steers from governing sources, those places are the points where the work
moved away from what the sources say — the rest is implementation detail delegated to
the agent. A fresh-context reviewer writes the report because the implementing agent
leaves out what it did not think counted as a deviation; this is the same reason check
8 runs fresh. The proposed edit is what keeps the governing sources current: each
deviation either amends its source or is reversed in code, so the sources do not drift
from the system they govern. The executor's rulings already record decisions made
during apply; the report is where a ruling that crosses a governing source reaches the
human instead of dying with the ledger.

**Alternatives considered**:
- Deviations recorded in the retrospective — written for the next cycle, read after the
  merge, too late to change the outcome.
- The human reviews the delta specs and the plan before apply — the plan-review gate
  that the Context lessons describe failing: long generated text, skimmed.
- Deviations block verify — makes the agent wait for a decision that belongs at merge
  time, where the human already looks.

### Decision 12: Safety rules bind every task

**Decision**: The plan instruction carries the adopter's safety rules
([Decision 13](#decision-13-adopter-rulesets-come-from-openspecconfigyaml)) into
`plan.md`'s `## Global Constraints` section, beside the rule of Decision 10, so that
they reach every implementer brief and the task reviewer's constraint slot. They go in
the form the configuration gives them: the rules themselves, or a pointer with the
command that loads them — in which case the constraint tells every implementer to load
the rules before its first action. An adopter whose rules live in a governed source
gives the pointer, so `plan.md`, which is tracked in the repository, does not become a
second copy that ages. The apply
instruction tells the controller to stop and ask the human before any action a safety
rule reserves for them. The bundle defines no safety content of its own.

**Why**: Autonomy is only safe where the boundaries are explicit and enforced. Many of
them are enforced outside the agent — permissions, credentials, protected branches, CI
— and those stay the primary control; an instruction not to do something is a weak
control on its own. The safety rules cover what such mechanisms cannot express, and they
must reach the subagent that acts, which is the same channel problem as Decision 10.
Superpowers' subagent-driven development already stops for four classes — irreversible
or destructive operations, security-sensitive actions, side effects outside the
worktree, and a plan where every path is a guess. An adopter's rules add the classes it
cares about beyond those (for example, cost) and name the concrete cases (which data,
which systems).

**Alternatives considered**:
- Safety rules written into the bundle — they differ per adopter and evolve faster than
  the bundle is released.
- Relying on Superpowers' stop classes alone — they are generic, and they do not name
  the adopter's systems.

### Decision 13: Adopter rulesets come from `openspec/config.yaml`

**Decision**: The bundle reads the adopter's governing sources, deviation threshold and
safety rules from OpenSpec's project configuration, `openspec/config.yaml`:

- `context` — delivered with every artifact's instructions. The adopter names its
  governing sources here and how to read them (a file path, a URL, or a command).
- `rules.verify` — delivered with the verify artifact's instructions. Narrows or widens
  what check 9 counts as a deviation, and says how a proposed edit reaches its source.
- `rules.plan` — delivered with the plan artifact's instructions. The safety rules, or a
  pointer to where they live.
- `operations.apply.guidance` — delivered with the apply instructions. Anything the
  controller must hold to during apply, such as which actions to stop for.

The configuration carries pointers, not copies: it names where a ruleset lives and how
to load it, and the ruleset itself stays in the adopter's source, so a rule changes in
one place. `README.md` documents the keys the bundle reads and what each one is for.

**Why**: OpenSpec already ships this channel. All four fields are part of its project
configuration schema on 1.13.0 and 1.14.2 (`dist/core/project-config.d.ts`), and
`openspec instructions` returns `context` and the artifact's `rules` as separate fields
beside the instruction and template (`dist/core/artifact-graph/instruction-loader.js`).
The bundle stays free of adopter content and needs no release when a ruleset changes,
and an adopter without the configuration gets stock behavior.

**Alternatives considered**:
- Rulesets as files inside the bundle — adopter content in a public bundle, and a bundle
  release for every rule change.
- A bundle-specific configuration file — a second configuration format for what
  OpenSpec's own already carries.

## The rule file

Outline of `superpowers-bridge/spec-review.md`:

1. **When this file is used** — the draft-time self-check (Decision 8) and verify check
   8 (Decision 9); what counts as a finding and how it is cleared (Decision 6).
2. **What OpenSpec already checks** — the table of Decision 3.
3. **OpenSpec's authoring rules** — the pointer of Decision 4.
4. **Rules this bundle adds** — the seven groups of Decision 5, each with source, test and
   before/after.
5. **Beyond the delta specs** — the sibling-change check of Decision 9 and the code-label
   check of Decision 10, with its search patterns and repair guidance.
6. **Thresholds** — Decision 7, including which pass reads the delta count.
7. **Report format** — one line per finding:
   `<file>:<line> — rule <n> — "<quoted text>" — <suggested fix>`, or `No findings.`

The deviation report of Decision 11 has its own section in `templates/verify.md`, not in
this file: its rules come from the adopter.

## Upstream changes

Proposed to Fission-AI/OpenSpec separately. Its contribution guide asks for an issue or
discussion before a PR, so each item is its own issue first. The last column names what
each change retires from `spec-review.md` once it reaches a bundle refresh. State as of
2026-10-15.

| # | Change | State | Retires |
|---|---|---|---|
| 1 | Make the sample `validate` output in `docs/cli.md` match the tool: it shows `proposal.md` and `design.md` checks that do not exist | Not landed; no issue found | — |
| 2 | Align the proposal example in `docs/concepts.md` (Intent / Scope / Approach) with the proposal template | Not landed; no issue found | — |
| 3 | Add the scenario rule from `docs/writing-specs.md` to the `spec-driven` specs instruction | The one-behavior rule landed for new requirements in 1.14.x; the scenario rule has not | Rule group 2 |
| 4 | Run the proposal parse (Why, What Changes, delta count) in `openspec validate <change>` | Not landed | The `openspec show` row |
| 5 | Check requirement length on MODIFIED blocks | Landed for ADDED requirements and main specs in 1.14.1 (#2020); MODIFIED is exempt by design; a configurable limit is proposed in #2069 | The MODIFIED length prompt |
| 6 | Report definite archive refusals as errors | Unlikely: #1918 was closed as a duplicate of #1112, with the INFO level described as deliberate so that a valid stack of changes is not blocked. #1112 is open | The INFO reading |
| 7 | Count only `#### Scenario:` headers toward "at least one scenario" | Not landed; the any-level-4 match is restated as deliberate in PR #2079 | The non-scenario header reading |
| 8 | Warn on a scenario without a WHEN or THEN step | Open PR #2079, at WARNING level | The step reading |
| 9 | Detect two active changes claiming the same requirement | Open PR #1698 (with change proposal #1963), awaiting a design call. Support it rather than file a new issue | The sibling-change check |

The earlier row on task numbering for custom schemas is withdrawn: 1.14.2 comments the
`spec-driven`-only scope as deliberate, and this bundle numbers no tasks.

## Risks / Trade-offs

- [Risk] A false positive blocks an otherwise finished change → Mitigation: every rule
  carries a test; style is excluded; the agent dismisses a false positive with a
  recorded reason.
- [Risk] The agent dismisses a real finding to get past verify → Mitigation: each
  dismissal is recorded with its reason in `verify.md`; a dismissal that changes
  behavior a governing source states is a deviation and reaches the human through
  check 9.
- [Risk] The INFO reading in Decision 3 matches on message text. If upstream rewords
  "Archive would refuse this delta", the reading matches nothing and reports clean —
  OpenSpec's own source names this failure: "a check that matches nothing looks exactly
  like a check that found nothing" → Mitigation: the per-release re-attestation checks
  that this message, the Purpose placeholder message and the `--deltas-only` JSON fields
  still exist.
- [Risk] Upstream is questioning header-based archive matching (#2033) and how a renamed
  scenario is treated (#1697). If archive stops matching by title, rule group 5's
  reasoning and the INFO reading change → Mitigation: re-attestation reads both issues;
  rule group 5 still holds as a readability rule.
- [Risk] OpenSpec marks its `schema` commands experimental, and both touchpoints locate
  the rule file through `openspec schema which` → Mitigation: re-attestation checks that
  it still reports `path`.
- [Risk] The drafting agent skips the template note → Mitigation: check 8 blocks
  regardless.
- [Risk] The deviation report omits a deviation → Mitigation: a fresh-context subagent
  writes it, from the governing sources and the diff rather than from the implementer's
  account; verify fails on a governing source it could not read.
- [Risk] Governing sources are vague, so nearly nothing counts as a deviation →
  Accepted: the report is only as sharp as the sources it compares against. A vague
  source is the adopter's signal to sharpen it, or to read the delta specs instead.
- [Risk] The rule file drifts from the upstream docs it cites → Mitigation: every rule
  names its source, and re-attestation re-reads the sources.
- [Trade-off] Every adopter's verify gains a blocking check → Accepted: it runs once per
  verify, the agent clears its findings, and the only part that reads code is a search
  of the change's added lines.
- [Risk] The code-label search flags a token that is not a planning label — a variable
  `D2`, a domain code → Mitigation: the hit is shown with its line, and the agent
  dismisses it with a reason; the patterns are anchored to word boundaries.
- [Risk] A change is merged before it is archived, as both changes in the second round
  were, although the apply instruction already archives before the pull request →
  Not mitigated by this design: verify runs before archive and cannot see a merge. See
  Open Questions.

## Migration Plan

Two releases. The first brings the bundle up to its current upstreams without changing
its behavior; this design ships in the second, built on that base.

**Bundle 1.4.1 — current upstreams, behavior unchanged.** Ships first, independently of
this design, because its corrections are due now: the executing-plans claim has been
false since Superpowers 6.4.1, and the brainstorming and writing-plans claims are stale
from 7.0.0. Keeping it separate also keeps 1.5.0's rollback clean — reverting the new
blocking checks must not revert the upstream corrections — and lets 1.5.0's plan and
acceptance runs start from instruction text that is already current.

- Re-attestation against Superpowers 7.0.0: brainstorming (sizing as quick task / small
  change / project with a written design, the skip-the-questions exit closed for this
  flow, design approval in short playback chunks), writing-plans (steps as "one action
  with a checkable result", code bodies only where signature and tests do not settle
  them, the execution-method handoff answered with subagent-driven development),
  executing-plans (the reason this schema does not fall back to it, restated: it now
  loads test-driven development and ends with a fresh review, but has no per-task review
  and no fresh context per task), and the README's re-attestation notes for 6.4.1
  through 7.0.0.
- The four inherited instructions (proposal, specs, design, tasks) refreshed from the
  OpenSpec 1.14.3 `spec-driven` schema. This brings in the one-behavior rule Decision 4
  points to.
- CI pins OpenSpec 1.14.3.

**Bundle 1.5.0 — this design.**

- `spec-review.md`; the note in `templates/spec.md`; verify checks 8 and 9
  with the `## 8.` and `## 9.` sections in `templates/verify.md`; the Global Constraints
  and commit-step rules in the plan instruction (Decisions 10 and 12); the controller
  backup, the stop rule and the deviation report in the pull request description in the
  apply instruction; `README.md` and `README.zh-TW.md` (lifecycle, verify description,
  and the configuration keys of Decision 13); `VERSION`.
- CI: `openspec schema validate superpowers-bridge` must still pass with the extra file
  in the bundle, on the CLI version the workflow pins.
- Acceptance before release, on 1.14.3:
  - check 8 against a delta spec with no defects — expect `No findings.`;
  - check 8 against a delta spec seeded with one defect per rule group and per row of
    Decision 3's table that 1.14.2 does not already fail, plus a sibling change modifying
    the same requirement and one labelled code comment — expect each seeded defect found
    exactly once, and nothing else;
  - check 9 against a probe governing source with one stated behavior and one non-goal,
    and a change that contradicts each — expect two deviations, each with a proposed
    edit; and with no governing sources configured — expect the pass-through line.
- Adopters refresh their installed bundle and set the configuration keys of Decision 13
  if they want checks 9 and the safety rules to read their sources. A change already past
  verify is unaffected; a change that re-runs verify gets checks 8 and 9.
- Rollback: reinstall 1.4.1.

## Open Questions

- Whether the acceptance fixtures are committed to this repository, as documentation of
  what each rule catches, or stay in a scratch project. Deferrable: it changes neither
  the rules nor the touchpoints.
- How to keep a change from being merged before it is archived. The apply instruction
  already orders archive before the pull request; the second round shows it is
  skipped. A guard would sit outside the bundle (a local check that an adopter repo's
  default branch carries no change whose implementation is merged but whose folder is
  not archived), so it is not part of 1.5.0. Upstream #1683 proposes a lifecycle status
  that CI could enforce.
