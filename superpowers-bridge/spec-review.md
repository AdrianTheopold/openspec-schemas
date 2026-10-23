# Spec review

Rules for reviewing a change's delta specs before they become the source of truth.
At archive, OpenSpec copies the delta specs into `openspec/specs/`, where people and
agents read them long after the change folder is gone. `openspec validate --strict`
checks their structure; this file covers what it does not.

Every rule below has a test that says what failure looks like. Style — line width,
heading wording, spelling variants, prose taste — is never a finding: a rule two
reviewers would apply differently does not belong in a review that blocks.

## 1. When this file is used

- **Draft-time self-check.** Before finishing a delta spec, the drafting agent runs
  sections 2 to 6 against it and fixes what they find. The template's note points here.
- **Verify check 8.** After apply and before archive, verify dispatches a subagent with
  no prior context, giving it the change name and this file's path. It runs sections 2
  to 6 and reports in the format of section 7.

A **finding** is a quoted piece of text that fails one of the tests here, with its
`<file>:<line>`. Every finding blocks verify until it is cleared, and the agent clears
it: it fixes the text or the code, or dismisses the finding with a one-line reason
recorded in `verify.md`. A finding whose fix would change behavior that a governing
source states — a document the project names in `openspec/config.yaml` as governing
its behavior — is not cleared here: it is a deviation, and check 9 reports it to the
human instead.

Three rules keep the loop converging:

- **Round cap.** After three runs of check 8 with uncleared findings, the next run
  reviews only what changed since the previous run. A finding still open after that run
  goes to the human as an item of the review card, not into another run.
- **No repeats.** Read the dismissals already recorded in the change's `verify.md`. A
  dismissed finding is not raised again unless the text it quoted has changed.
- **`pre-existing`.** A finding about text this change did not add — a sibling change,
  a main-spec sentence — is tagged `pre-existing`. It is still cleared, but it is not
  counted against the change. A main-spec sentence that rule 7 flags is the exception:
  the change caused it, so it is not `pre-existing`.

**A change with no delta specs** (OpenSpec 1.14.3 accepts one only with
`skip_specs: true` in the change's `.openspec.yaml`): skip sections 2, 3, 4 and 6, still
run section 5, and report `No findings.` if it finds nothing.

## 2. What OpenSpec already checks

Run these first and read their output as below; do not restate them as judgement. Rows
hold for OpenSpec 1.14.3. A finding from a row is reported under the name in bold.

| Check | Command | How to read it |
|---|---|---|
| Structure, duplicate requirements, cross-section contradictions, a MODIFIED block dropping a main-spec scenario, an empty scenario, an ADDED requirement over 500 characters | `openspec validate <change> --strict --json` | **strict**: on `"valid": false`, each ERROR or WARNING issue is a finding. |
| Archive will refuse the delta | same output | **archive-refusal**: an INFO issue whose message begins `Archive would refuse this delta` is a finding. |
| `proposal.md` parses | `openspec show <change> --json` | **proposal**: an entry with `"severity": "error"` in `status` is a finding; when the proposal parses there is no `status` key. Fix this first: while the proposal does not parse, `--deltas-only` returns no deltas, so the next row has nothing to read. |
| Scenario content, MODIFIED length, delta count | `openspec show <change> --json --deltas-only` | Read each `requirement.text`, each `scenarios[].rawText`, and `deltaCount`. **scenario-steps**: a `rawText` with no WHEN or THEN step is a finding. **scenario-header**: a level-4 header that is not `#### Scenario:` is a finding — OpenSpec counts any level-4 header as a scenario, and the JSON `name` drops the `Scenario:` prefix, so find it in the markdown with the command below the table. Length and delta count follow section 6. |
| A main spec the change touches still has the `TBD` Purpose placeholder | `openspec validate <capability> --type spec --strict --json` for each capability with a delta and an existing main spec | **purpose**: a warning whose message begins `Purpose section is still a placeholder` is a finding. Match the message, not `valid`: the same command also fails on any long requirement in the main spec, including ones this change never touched. A delta's `## Purpose` only seeds a spec that does not exist yet, so the fix is an edit to the main spec itself. |

Level-4 headers that are not scenarios, with their line numbers:

```bash
grep -Hn '^#### ' openspec/changes/<change>/specs/*/spec.md | grep -v ':#### Scenario:'
```

When **strict** reports a MODIFIED block dropping a main-spec scenario because the block
rewrote it under a new title, carry the scenario under its old title, reworded if the
behavior changed — archive matches scenarios by title. Copying the old text back
unchanged is right only if the old wording is still true.

## 3. OpenSpec's authoring rules

Behavior versus implementation, observability, error conditions, ADDED versus MODIFIED,
and one behavior per ADDED requirement are OpenSpec's own rules. Read them from the
specs instruction — `openspec instructions specs --change <name> --json`, field
`instruction` — and apply its "Good spec content" list, its "Avoid in specs" list and
its "Quick test". They are not copied here.

The Quick test decides what a review may flag: a detail belongs in the spec if it is
visible outside the implementation. A detail other systems rely on passes even when it
names a mechanism. Report a failure under the rule name **authoring**.

## 4. Rules this bundle adds

OpenSpec's instructions carry none of these. Report each under its number.

**Rule 1 — One behavior per requirement, in MODIFIED blocks too.**
Source: OpenSpec `docs/writing-specs.md`: "One statement, one SHALL/MUST."
Test: an ADDED requirement is covered by section 3. For a MODIFIED block: does the
modification add a behavior the requirement did not have, which could stand as its own
requirement with its own SHALL or MUST and its own scenario? If yes, it fails: the new
behavior belongs in an ADDED requirement, and the MODIFIED block keeps the existing
requirement whole.
Before: a MODIFIED "Orders are stored" that now also says "Every order MUST carry a
checksum of its lines."
After: "Orders are stored" unchanged apart from its own behavior; an ADDED requirement
"Orders carry a line checksum".

**Rule 2 — A scenario exercises its requirement, and its title names the case.**
Source: `docs/writing-specs.md`: "A scenario that just restates the requirement in
other words tests nothing."
Test: could a test be written from the scenario alone that fails when the requirement
is violated? A scenario whose outcome only restates the requirement, or whose WHEN
presupposes what its THEN denies, fails.
Before: "Scenario: Order is stored — WHEN an order is placed THEN it is stored as an
immutable document."
After: "Scenario: A resubmitted order does not overwrite the first — WHEN the same order
is submitted twice with different totals THEN two documents exist and the first is
unchanged."

**Rule 3 — Nothing refers to the change.**
Source: archive copies ADDED and MODIFIED blocks verbatim into the main spec.
Test: read the sentence as part of `openspec/specs/` a year after archive. Does it still
refer to something that exists? "This change", "the change that adds …", "for now", and
"new" used as a time word fail.
Before: "This change SHALL add no deletion endpoint."
After: "The service SHALL offer no operation that deletes an order."

**Rule 4 — Readable without the change folder.**
Source: at archive the change folder moves to `openspec/changes/archive/`; only the
specs merge.
Tests: every term is introduced before it is relied on. No cross-reference points into
the change folder — design decision labels, task numbers, plan steps — because it
dangles once the folder is archived; a reference to another requirement in the same
spec is fine. A THEN states an observable outcome; rationale belongs in the requirement
text. Any of these failing is a finding.
Before: "THEN the order is rejected, because design D4 keeps validation in the gateway."
After: "THEN the order is rejected before it is stored."

**Rule 5 — Titles name the behavior, never a planning label.**
Source: OpenSpec matches requirements by title — a MODIFIED block must use the exact
same normalized header, and a new title needs a RENAMED entry (`templates/spec.md`) —
and `docs/writing-specs.md` asks for scenario titles that name the case.
Test: does a requirement or scenario title carry a decision, task, phase or item label —
"(D9)", "(L1)", "Task 3", "P6" — or anything else a reader cannot decode from the spec
alone? It fails. A parenthesis that describes behavior, such as "(admin only)", is fine.
Before: "### Requirement: Order validation (D4)"
After: "### Requirement: Orders are validated before they are stored"
A label in a title outlives the decision it named: the title is the identity archive
matches on, so every later change that modifies the requirement must repeat or rename it.

**Rule 6 — A claim matches its enforcement.**
Source: archive turns the delta into the source of truth; a requirement that overstates
what is checked becomes a false guarantee there.
Test: where a requirement names how it is enforced or verified — a test suite, an index,
a validation step — does that mechanism exist and cover exactly what the sentence says?
Check quantifiers and counts ("all", "every", "four", "always") against the code and
tests, not against the design. A mismatch fails: reword the claim to what is enforced,
or add the missing enforcement.
Before: "The parity suite MUST keep all three payment adapters in agreement." — the
suite runs two of them.
After: "The parity suite MUST keep the card and invoice adapters in agreement; the
wallet adapter is pinned by tests of its request shape."

**Rule 7 — A removed or renamed name leaves no reference behind.**
Source: archive applies only the blocks a change carries; a requirement the change does
not touch keeps its old wording.
Test: for every public name the change removes or renames — a REMOVED or RENAMED
requirement, or an API the proposal retires — search the main specs of the touched
capabilities. Any other requirement that still names it, without a MODIFIED block in
this change, fails.
Before: the change removes `list_orders()`; the main spec's requirement "Orders expose
their totals" still says "`list_orders()` SHALL return …".
After: the change carries a MODIFIED block for that requirement naming the replacement.

## 5. Beyond the delta specs

**Sibling changes** (report as **sibling**, tagged `pre-existing`). For every capability
the change has a delta for, list the other unarchived changes that touch it:
`ls -d openspec/changes/*/specs/<capability>/`. Another change that MODIFIES, RENAMES or
REMOVES a requirement this change also MODIFIES, RENAMES or REMOVES fails: both were
written against the same main-spec text, and `openspec validate` checks each change
against the current main spec only, so it cannot see the collision — whichever archives
second overwrites the first's wording or is refused. Fix: archive the earlier change
first, then rewrite the later change's block against the archived text. A sibling that
only ADDs requirements does not collide.

**Planning labels in code** (report as **code-label**). Comments, docstrings and
messages in the code a change adds state their reason in words. A planning label stops
resolving once the change folder is archived, and two changes can each have a `D9`.
Search the lines the change adds outside `openspec/` for six patterns:

- `\bD[0-9]+\b` — a design decision (`D9`)
- `\bTasks? [0-9]` — a task number (`Task 5`)
- `\bStep [0-9]` — a plan step (`Step 2`)
- `\bFIX-[0-9]` — a review fix tag (`FIX-2`)
- `design\.md` — the change's design file
- `plan\.md` — the change's plan file

```bash
git diff -U0 <base>...HEAD -- . ':(exclude)openspec' | grep -E '^\+' | grep -vE '^\+\+\+' | grep -E '\bD[0-9]+\b|\bTasks? [0-9]|\bStep [0-9]|\bFIX-[0-9]|design\.md|plan\.md'
```

`<base>` is the branch the change merges into. If that is not known, use the merge base
that verify's PRECHECK computes in its first command. Each hit, located in its file with
`grep -n`, is a finding unless it is scoped by the change's name, as in "decision D9 of
the change `add-order-validation`". A token that only looks like a label — a variable
`D2`, a domain code — is dismissed with that reason.
Repair: state the reason in words. If the source still matters, scope it with the
change's name; the commit message is where the link to a decision or task belongs.
Before: `# Task 3: recompute totals after a line is removed`
After: `# Recompute totals after a line is removed, so a removed line never leaves a stale total.`

## 6. Thresholds

- **ADDED requirement over 500 characters**: a finding through **strict** in section 2,
  cleared like any other. The usual fix is OpenSpec's own: move examples and edge cases
  into scenarios, or split the requirement.
- **MODIFIED requirement over 500 characters** (`requirement.text`): OpenSpec does not
  check it, on purpose. The length prompts you to apply rule 1; the length alone is
  never a finding.
- **More than 10 deltas** (`deltaCount`): read only by the draft-time self-check. Confirm
  the change still has one intent you can say in a sentence. If it does not, split the
  change before tasks are written; if it does, record that sentence in the proposal.
  Verify check 8 does not read the delta count.

## 7. Report format

The count comes first, then one line per finding:

```text
3 findings, 1 pre-existing
<file>:<line> — rule <n> — "<quoted text>" — <suggested fix>
```

`<n>` is a rule number from section 4 or a rule name in bold from sections 2, 3 and 5.
Every finding quotes the text it is about; a finding without `<file>:<line>` and a quote
is not reported. Append `(pre-existing)` to a `pre-existing` finding's line. Where one
defect recurs, report one finding that names the class and lists every place, not one
line per place:

```text
specs/orders/spec.md:12, :31, :47 — rule 3 — "This change …" (3 places) — state each behavior without referring to the change
```

With nothing to report, the whole report is:

```text
No findings.
```
