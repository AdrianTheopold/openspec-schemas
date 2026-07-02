# superpowers-bridge Fork + Correctness Pass — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fork the (stalled) `JiangWay/openspec-schemas` superpowers-bridge into Adrian's own maintained copy, fold in the audited correctness fixes (2 HIGH + correctness MEDs + Superpowers-6 re-attestation + OpenSpec 1.5.0 pin bump + cosmetics), re-point the vendored copy in `anomaly-detection` to the fork, and retire the now-pointless drift-vs-JiangWay apparatus.

**Architecture:** The bridge is a prompt-layer OpenSpec schema (one `schema.yaml` + `README.md`/`README.zh-TW.md` + `templates/` + `VERSION`). All fixes are edits to YAML instruction prose and Markdown docs — **there is no code and no unit-test harness** (that absence is why these bugs shipped; adding a harness is explicitly OUT of scope for this pass — see Global Constraints). The source of truth becomes the GitHub fork; the vendored copy at `anomaly-detection/openspec/schemas/superpowers-bridge/` is re-synced from it at the end.

**Tech Stack:** GitHub (`gh` CLI), git, OpenSpec CLI (`@fission-ai/openspec`, installed 1.4.1 → target baseline 1.5.0), Superpowers plugin (installed 6.1.0 → target baseline 6.1.0). YAML + Markdown only.

## Verification model (read before starting)

This plan has no `pytest`. Each editing task verifies with:
1. **Structural:** `cd /develop/anomaly-detection && openspec schema validate superpowers-bridge` → must print `✓ valid` (run against the *vendored* copy after re-sync in Task 8; during fork editing run it against a temporary symlink/copy — see Task 1 Step 6).
2. **Content grep:** an explicit `grep` proving the old string is gone / the new string is present (given per task).
3. **Behavioral fixes (H1/H2):** a careful re-read confirming the instruction composes with the installed Superpowers 6.1.0 skill flow. A full end-to-end `/opsx:apply` dry cycle on a throwaway change is the gold standard but is heavy (creates a worktree + dispatches subagents); it is OPTIONAL and called out in Task 8.

## Global Constraints

- **Fork namespace:** `github.com/AdrianTheopold/openspec-schemas` (matches the author of the existing upstream PR #12). **Creating the fork is outward-facing — confirm the namespace with Adrian before Task 1 Step 1 runs.**
- **Public-push identity:** BEFORE any push to the public fork, set the commit author email to Adrian's GitHub noreply `83468052+AdrianTheopold@users.noreply.github.com` (the `/develop` container's git default is his work email and leaks by SHA into the public fork network). Set it locally in the fork clone (Task 1 Step 4).
- **Keep EN + zh-TW in sync:** every README fix applies to BOTH `README.md` and `README.zh-TW.md` (the zh-TW is a faithful mirror that reproduces every bug).
- **No schema-graph structural change:** these are prose/instruction fixes only. `openspec schema validate superpowers-bridge` must stay `✓ valid` after every task. Do not add/remove artifacts or `requires:` edges.
- **Vendored copy stays byte-identical to the fork's `superpowers-bridge/`** after Task 8 (the re-vendor contract is a whole-dir copy).
- **OUT of scope this pass:** an end-to-end test harness; the upstream `post_apply` phase (still absent upstream — the evidence-PRECHECK workaround stays); any Stores-model migration (1.5.0 Stores is opt-in beta the bridge doesn't use).
- **Baselines to land:** OpenSpec `1.4.1 → 1.5.0`; Superpowers `v5.1.0 → 6.1.0`.

---

### Task 1: Create the fork, working clone, and land this plan

**Files:**
- Create (remote): `github.com/AdrianTheopold/openspec-schemas` (fork of `JiangWay/openspec-schemas`)
- Create (local): a working clone + branch `fix/correctness-pass-v1.1`
- Create: `<fork>/docs/plans/2026-07-02-correctness-pass.md` (this plan, committed at the fork REPO ROOT — NOT under `superpowers-bridge/`, so it never rides into adopters' vendored bundles)

**Interfaces:**
- Produces: `$FORK` = local clone path (all later tasks edit files under `$FORK/superpowers-bridge/`); the fork's default branch (`main`) and the working branch `fix/correctness-pass-v1.1`.

- [ ] **Step 1: Confirm namespace, then fork** (outward-facing — do not run before Adrian confirms)

```bash
gh repo fork JiangWay/openspec-schemas --clone=false --org= 2>/dev/null || \
  gh repo fork JiangWay/openspec-schemas --clone=false
# creates github.com/AdrianTheopold/openspec-schemas
gh repo view AdrianTheopold/openspec-schemas --json name,parent,isFork
```
Expected: `isFork: true`, `parent.name: openspec-schemas`.

- [ ] **Step 2: Clone the fork to a working dir**

```bash
git clone https://github.com/AdrianTheopold/openspec-schemas.git \
  /develop/openspec-schemas-fork
export FORK=/develop/openspec-schemas-fork
```
Expected: clone succeeds; `ls $FORK/superpowers-bridge/schema.yaml` exists.

- [ ] **Step 3: Create the working branch**

```bash
git -C "$FORK" switch -c fix/correctness-pass-v1.1
```
Expected: `Switched to a new branch 'fix/correctness-pass-v1.1'`.

- [ ] **Step 4: Set the public-push identity in this clone** (Global Constraint)

```bash
git -C "$FORK" config user.email "83468052+AdrianTheopold@users.noreply.github.com"
git -C "$FORK" config user.name "Adrian Theopold"
git -C "$FORK" config --get user.email
```
Expected: prints the noreply email.

- [ ] **Step 5: Commit this plan into the fork**

```bash
mkdir -p "$FORK/docs/plans"
cp /tmp/claude-1000/-develop/c5e04289-cc7f-47dc-bfd7-bb9e4bc1cdde/scratchpad/2026-07-02-superpowers-bridge-fork-correctness-pass.md \
   "$FORK/docs/plans/2026-07-02-correctness-pass.md"
git -C "$FORK" add docs/plans/2026-07-02-correctness-pass.md
git -C "$FORK" commit -m "docs: add superpowers-bridge correctness-pass implementation plan"
```
Expected: one commit created (at the fork repo root `docs/plans/`, NOT inside `superpowers-bridge/`).

- [ ] **Step 6: Establish the validation seam for the fork copy**

The `openspec schema validate` CLI resolves schemas under a project's `openspec/schemas/`. To validate the fork copy during editing, point a scratch project at it:

```bash
# Reuse anomaly-detection's project but validate by temporarily copying the fork's
# schema over the vendored path is risky; instead validate structurally with a dry parse:
cd /develop/anomaly-detection && openspec schema validate superpowers-bridge
```
Expected: `✓ valid` (baseline — confirms the tool works before edits). During Tasks 2-7 you edit the FORK copy; the authoritative `openspec schema validate` re-runs after re-sync in Task 8. For per-task structural safety, parse the YAML: `python3 -c "import yaml,sys; yaml.safe_load(open('$FORK/superpowers-bridge/schema.yaml'))" && echo OK`.

---

### Task 2: Fix H2 — stop SDD from finishing the branch before the bridge's verify/retro/archive (HIGH)

**Files:**
- Modify: `$FORK/superpowers-bridge/schema.yaml` (apply step 2 "Tell the executor" block, currently lines ~502-505 + the surrounding step-2 prose ~496-518)

**Interfaces:**
- Consumes: nothing.
- Produces: an apply instruction where the SDD executor implements-and-reviews only, then returns control; the bridge alone runs finishing-a-development-branch at apply step 6.

**Context:** The bug: apply step 2 tells the executor to invoke `superpowers:subagent-driven-development` to "execute the plan.md micro-tasks," but that skill's OWN flow terminates by invoking `superpowers:finishing-a-development-branch` + worktree cleanup (SDD `SKILL.md:66,81,412`). Run literally, the executor opens the PR and destroys the worktree before the bridge's steps 3-6 (verify/retro/archive, `schema.yaml:527-567`). Fix: explicitly scope the executor to implementation+review and forbid the finish/cleanup, because the bridge owns finish at step 6. **Confirmed by the v5→v6 diff (research-D):** this conflict is PRE-EXISTING — SDD terminated with `finishing-a-development-branch` identically at the bridge's own v5.1.0 baseline (`SKILL.md:66` node, `:85` edge) — and v6 exposes NO native flag/mode to suppress that finish node, so the fix MUST be prose (this task), not a toggle.

- [ ] **Step 1: Read the current step-2 block** at `$FORK/superpowers-bridge/schema.yaml` (the `2. **Executor — subagent-driven-development**:` block and its `Tell the executor:` list).

- [ ] **Step 2: Add an explicit stop-boundary to the `Tell the executor:` list.** After the existing bullets (`Read plan.md…`, `Update tasks.md checkboxes…`, `Work within the created worktree`), append:

```yaml
       - STOP after the final whole-branch review passes. Do NOT invoke
         superpowers:finishing-a-development-branch and do NOT clean up
         or remove the worktree — this bridge runs the finish sequence
         itself at apply step 6 (retrospective + archive must land in the
         SAME PR, and the worktree + SDD ledger must survive for steps
         3-5). Return control to the apply controller after the final
         review; report the commit range and the ledger path.
```

- [ ] **Step 3: Add a guard note to the transitive-skill block.** In the `IMPORTANT — transitive skill activation:` paragraph (which lists TDD + requesting-code-review), add a final line:

```yaml
       NOTE: subagent-driven-development's own flow ends by invoking
       finishing-a-development-branch; under this bridge that terminal
       step is SUPPRESSED (see the executor instruction above) because
       the bridge sequences finish/verify/retrospective/archive itself.
```

- [ ] **Step 4: Validate structurally**

```bash
python3 -c "import yaml; yaml.safe_load(open('$FORK/superpowers-bridge/schema.yaml')); print('OK')"
```
Expected: `OK`.

- [ ] **Step 5: Grep-verify the guard is present**

```bash
grep -n "STOP after the final whole-branch review" "$FORK/superpowers-bridge/schema.yaml"
grep -n "terminal\s*step is SUPPRESSED\|is SUPPRESSED" "$FORK/superpowers-bridge/schema.yaml"
```
Expected: both match.

- [ ] **Step 6: Commit**

```bash
git -C "$FORK" add superpowers-bridge/schema.yaml
git -C "$FORK" commit -m "fix(bridge): suppress SDD self-finish so bridge owns verify/retro/archive (H2)"
```

---

### Task 3: Fix H1 — tie the tasks.md tick to the SDD ledger step (HIGH)

**Files:**
- Modify: `$FORK/superpowers-bridge/schema.yaml` (the `Update tasks.md checkboxes as coarse tasks complete` bullet in apply step 2, and the verify PRECHECK note at the `grep -c '^- \[x\]'` line)

**Interfaces:**
- Consumes: the `Tell the executor:` list edited in Task 2.
- Produces: an instruction where the executor ticks `tasks.md` in the same bookkeeping message it appends the SDD ledger line, so the verify PRECHECK (`grep -c '^- [x]' > 0`) reflects real progress.

**Context:** The known gap: SDD tracks progress in its ledger + todos and never touches `tasks.md` (it's OpenSpec-agnostic — zero `tasks.md` awareness). The bridge's one soft bullet asking for the tick gets dropped, so `tasks.md` stays all-unchecked and verify's PRECHECK `grep -c '^- [x]' openspec/changes/<change-name>/tasks.md` (which must return `> 0`) FALSELY STOPS a completed apply. `tasks.md` is the right source of truth because it is committed and travels in the PR diff; the SDD ledger is git-ignored per-worktree scratch.

This is a symptom of the **"task fragmentation" the README itself names** (`README.md:126, ~520`): one plan is represented THREE ways — coarse `tasks.md` checkboxes (what verify/archive count), fine `plan.md` TDD micro-steps (what the SDD executor works from), and the `.superpowers/sdd/progress.md` ledger (what SDD actually updates). Progress lands in the ledger + `plan.md` micro-steps but is never surfaced back to the coarse `tasks.md` the gates read. **Scope note:** this task fixes the SYMPTOM (surface the tick back to `tasks.md`); it deliberately does NOT collapse the three representations into one — resolving the fragmentation root (auto-derive / single source of truth) was weighed and rejected as over-engineering during brainstorm (option c). After this pass, the plan is still represented three ways; the coarse tracker just stops drifting.

- [ ] **Step 1: Replace the soft tick bullet.** Find in `$FORK/superpowers-bridge/schema.yaml` (apply step 2):

```yaml
       - Update tasks.md checkboxes as coarse tasks complete
```
Replace with:

```yaml
       - Tick tasks.md checkboxes IN THE SAME bookkeeping message where
         you append the SDD progress-ledger line for a cleared task:
         when a task's review comes back clean, flip its `- [ ]` to
         `- [x]` in openspec/changes/<name>/tasks.md AND append the
         ledger line together. tasks.md is the committed source of
         truth (it travels in the PR diff and gates verify); the ledger
         is throwaway per-worktree scratch. Never leave tasks.md
         all-unchecked — the verify PRECHECK below will falsely STOP.
```

- [ ] **Step 2: Add a cross-reference at the verify PRECHECK.** Find the verify PRECHECK block containing `grep -c '^- \[x\]' openspec/changes/<change-name>/tasks.md`. Immediately after that command's line, add a comment line inside the instruction prose:

```yaml
         (This returns 0 only if the apply executor failed to tick
         tasks.md as tasks cleared — see apply step 2's ticking rule;
         a 0 here on a genuinely-complete apply is a bookkeeping miss,
         not incomplete work. Tick the boxes, then re-run.)
```

- [ ] **Step 3: Validate structurally**

```bash
python3 -c "import yaml; yaml.safe_load(open('$FORK/superpowers-bridge/schema.yaml')); print('OK')"
```
Expected: `OK`.

- [ ] **Step 4: Grep-verify**

```bash
grep -n "IN THE SAME bookkeeping message" "$FORK/superpowers-bridge/schema.yaml"
grep -c "Update tasks.md checkboxes as coarse tasks complete" "$FORK/superpowers-bridge/schema.yaml"
```
Expected: first matches; second prints `0` (old bullet gone).

- [ ] **Step 5: Commit**

```bash
git -C "$FORK" add superpowers-bridge/schema.yaml
git -C "$FORK" commit -m "fix(bridge): bind tasks.md tick to SDD ledger step; note verify false-STOP (H1)"
```

---

### Task 4: Correctness MEDs batch — nonexistent command, wrong config path, fragile base-detection, live placeholders

**Files:**
- Modify: `$FORK/superpowers-bridge/schema.yaml` (M5 base-detection ~line 207; M6 placeholders ~210, ~314, ~320, ~335)
- Modify: `$FORK/superpowers-bridge/README.md` and `README.zh-TW.md` (M2 `/opsx:new` ~lines 156,172,223,336,352,419,425; M3 `openspec/config.yaml` ~line 354)
- Modify: `$FORK/superpowers-bridge/templates/adopters/CLAUDE.md.fragment.*.md` (M2 `/opsx:new` in the routing table)

**Interfaces:** none consumed/produced (independent doc + shell fixes).

- [ ] **Step 1: M2 — confirm the real command surface, then replace `/opsx:new`.**

```bash
ls /develop/anomaly-detection/.claude/commands/opsx/    # authoritative slash-command list
```
Expected: files for propose/ff/continue/apply/verify/archive/explore/onboard/sync — **no `new.md`**. `/opsx:new` is not a slash command (though `openspec new` is a CLI subcommand). Replace each `/opsx:new <name> --schema <schema>` usage:
- Interactive/step-by-step creation (was `/opsx:new … then /opsx:continue`): use the CLI `openspec new <name> --schema <schema>` then `/opsx:continue`, OR `/opsx:propose` for the one-shot. Pick per each occurrence's intent (the "New feature" table rows and the quickstart blocks → `/opsx:propose`; the "interactive" walkthrough at README:336-346 → `openspec new <name> --schema superpowers-bridge` then `/opsx:continue`).
- The `spec-driven` skip-brainstorm rows (README:352,425) → `openspec new <name> --schema spec-driven`.

Apply in BOTH READMEs + both CLAUDE fragments.

- [ ] **Step 2: M2 grep-verify no slash `/opsx:new` remains**

```bash
grep -rn "opsx:new" "$FORK/superpowers-bridge/"
```
Expected: no matches (CLI `openspec new` may remain — that's correct).

- [ ] **Step 3: M3 — fix the nonexistent config path.** At `README.md:354` (and the zh-TW mirror):

```
# Or change project default in openspec/config.yaml: schema: spec-driven
```
Replace with:

```
# Or pin the schema per change in the change's .openspec.yaml (schema: spec-driven),
# or pass --schema on the command. (OpenSpec 1.4.x/1.5.0 has no openspec/config.yaml.)
```

- [ ] **Step 4: M5 — make verify's base-detection robust for unpushed worktrees.** At `schema.yaml:207`, replace:

```bash
         git log --oneline $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master 2>/dev/null)..HEAD | wc -l
```
with a resolver that tries remote THEN local base refs and counts with `rev-list` (this repo's norm is unpushed local branches off local `master`):

```bash
         base=""; for ref in origin/main origin/master main master; do \
           git rev-parse -q --verify "$ref" >/dev/null 2>&1 && { base="$ref"; break; }; done; \
         [ -n "$base" ] && git rev-list --count "$(git merge-base HEAD "$base")..HEAD" || echo 0
```

- [ ] **Step 5: M6 — neutralize literal placeholders inside runnable shell.** The PRECHECK shells embed `<change-name>` / `<base>` (schema.yaml ~210, ~314, ~320, ~335) which error if pasted verbatim. Add ONE substitution note at the first PRECHECK that owns them and change the literals to shell vars, e.g. prefix the verify PRECHECK block with:

```yaml
      (Substitute the change name first: `chg=<change-name>` — replace
      <change-name> with this change's directory name, then the commands
      below use "$chg".)
```
and change `openspec/changes/<change-name>/tasks.md` → `openspec/changes/$chg/tasks.md`, `<base>` → `$base` (defined in Step 4), in the affected commands.

- [ ] **Step 6: Validate + grep**

```bash
python3 -c "import yaml; yaml.safe_load(open('$FORK/superpowers-bridge/schema.yaml')); print('OK')"
grep -rn "openspec/config.yaml" "$FORK/superpowers-bridge/" ; echo "--- expect no matches above ---"
```
Expected: `OK`; no `openspec/config.yaml` matches.

- [ ] **Step 7: Commit**

```bash
git -C "$FORK" add superpowers-bridge/schema.yaml superpowers-bridge/README.md superpowers-bridge/README.zh-TW.md superpowers-bridge/templates/adopters/
git -C "$FORK" commit -m "fix(bridge): real command surface, .openspec.yaml path, robust base-detect, placeholder subst (M2/M3/M5/M6)"
```

---

### Task 5: Adapt the bridge to Superpowers 6.1.0 (v5→v6 diff fold-in) + re-attest baselines

**Files:**
- Modify: `$FORK/superpowers-bridge/schema.yaml` (finish sequence apply step 6 ~557-567; transitive-review note ~513-518; executing-plans citation; a `# v6 notes` comment near apply)
- Modify: `$FORK/superpowers-bridge/README.md` + `README.zh-TW.md` (finish "opens the PR" ~408-410; per-task-vs-final review ~304-306,384; plan.md description; baseline badges 8-9; Compatibility ~487; executing-plans URL)
- Modify: `$FORK/superpowers-bridge/VERSION` (1.0.0 → 1.1.0)

**Interfaces:** none.

**Context:** research-D (`scratchpad/research-D-superpowers-v5-v6-diff.md`) diffed every invoked skill v5.1.0→6.1.0. Only H2 was BREAKING (fixed in Task 2, and pre-existing — not a v6 regression). This task folds the RELEVANT non-breaking alignments, records two OPT-IN v6 capabilities, and re-attests the baseline honestly. Deltas to fold:
- **(a)** v6 `finishing-a-development-branch` REMOVED `gh pr create` — Option 2 "Create PR" is now push-only (v6 `finishing-a-development-branch/SKILL.md:121-126`). The bridge's "finish opens the PR" is stale; fixing it also aligns with this workspace's no-auto-PR + GitLab/`glab` (not `gh`) rules.
- **(b)** v6 merged the two SDD reviewer prompts into one `task-reviewer-prompt.md` — per-task review is SDD's own; `requesting-code-review` is the FINAL whole-branch pass only.
- **(c)** writing-plans v6 adds `## Global Constraints` + per-task `Interfaces` blocks (richer plan.md) — this very plan uses them.
- **(d)** SDD v6 gained explicit per-dispatch model selection + a durable `.superpowers/sdd/` ledger — opt-in, already benefits apply, no bridge change needed.
- executing-plans still activates neither TDD nor code-review → the bridge's rejection rationale HOLDS (only a moving-URL nit).

- [ ] **Step 1: Confirm invoked-skill surface at 6.1.0**

```bash
ls /home/appuser/.claude/plugins/cache/claude-plugins-official/superpowers/6.1.0/skills/
grep -oE "superpowers:[a-z-]+" "$FORK/superpowers-bridge/schema.yaml" | sort -u
```
Expected: brainstorming, writing-plans, using-git-worktrees, subagent-driven-development, finishing-a-development-branch (+ transitively test-driven-development, requesting-code-review) all present; no renames.

- [ ] **Step 2: (delta a) finish is push-only — de-couple from `gh pr create`.** At `schema.yaml` apply step 6 (~557-567) and `README.md:408-410` (+ zh-TW), reword so the bridge does NOT claim finish "opens the PR". Replace the step-6 body with:

```yaml
    6. **Completion (finish + push is the LAST automated step)**:

       After retrospective + archive are both done, use the Skill
       tool to invoke **superpowers:finishing-a-development-branch**.
       In v6 this pushes the branch; it does NOT open a PR/MR for you
       (upstream removed the `gh pr create` step). Opening the MR/PR is
       a separate human step — on GitLab use `glab`; do NOT auto-open
       or auto-merge.

       The pushed branch MUST contain the complete archived cycle
       (all 8 artifacts, specs synced, change under archive/). If it
       does not, STOP and complete retrospective/archive first.
```
Mirror the "opens the PR" → "pushes the branch" wording in both READMEs.

- [ ] **Step 3: (delta b) clarify per-task vs final review.** At `schema.yaml:513-518` and `README.md:304-306,384` (+ zh-TW), reword the `requesting-code-review` note:

```yaml
       - **superpowers:requesting-code-review** — invoked only for the
         FINAL whole-branch review before apply concludes. Per-task
         review is handled INSIDE subagent-driven-development by its own
         merged task-reviewer prompt (spec-compliance + quality), not by
         a separate skill invocation.
```

- [ ] **Step 4: (delta c) note the richer plan.md format.** Where the bridge's `plan` artifact instruction describes plan.md (~schema.yaml:184-192), add one sentence: `writing-plans v6 emits a "## Global Constraints" block and per-task "Interfaces" blocks; implementers MUST honor both.` No structural change.

- [ ] **Step 5: (delta d) record opt-in v6 capabilities as a comment.** Add a short `# v6 notes:` comment just above the `apply:` key in `schema.yaml`:

```yaml
# v6 notes: subagent-driven-development (6.x) applies explicit per-dispatch
# model selection (Sonnet for mechanical steps, Opus for reasoning) and keeps
# a durable .superpowers/sdd/ progress ledger for long runs. Both are handled
# by the executor automatically — no instruction here duplicates them.
```

- [ ] **Step 6: pin the moving executing-plans citation.** Find the bridge's `executing-plans` reference (rejection rationale, ~schema.yaml:520-525 / README). If it links a moving `.../main/...` URL, replace with a versioned permalink or cite the skill by name only. Rationale unchanged (research-D: v6 executing-plans still activates neither TDD nor code-review).

- [ ] **Step 7: baseline badges + Compatibility.** Update badges (`README.md:8-9` + zh-TW):

```
[![OpenSpec baseline](https://img.shields.io/badge/OpenSpec_baseline-1.5.0-0277bd)](#compatibility)
[![Superpowers baseline](https://img.shields.io/badge/Superpowers_baseline-6.1.0-0277bd)](#compatibility)
```
In the Compatibility section set pinned baselines to OpenSpec 1.5.0 / Superpowers 6.1.0 and add: `Re-attested against Superpowers 6.1.0 (2026-07-02) via a full v5.1.0→6.1.0 skill diff: only finishing-a-development-branch (now push-only) and the merged SDD task-reviewer needed prose alignment; the SDD self-finish conflict (H2) predates v6 and is suppressed by the apply instruction.` Add: `OpenSpec 1.5.0 "Stores" is opt-in beta and does not affect this bridge; re-check the changes/+specs/ paths only if a future release makes Stores the default layout.`

- [ ] **Step 8: Bump VERSION** — `$FORK/superpowers-bridge/VERSION`: `1.0.0` → `1.1.0`.

- [ ] **Step 9: Validate + grep**

```bash
python3 -c "import yaml; yaml.safe_load(open('$FORK/superpowers-bridge/schema.yaml')); print('OK')"
grep -rn "gh pr create" "$FORK/superpowers-bridge/" ; echo "--- expect NONE in the bridge (the fork PR in this plan's Task 8 is separate) ---"
grep -n "5.1.0" "$FORK/superpowers-bridge/README.md" ; echo "--- expect only historical/changelog mentions, not the baseline ---"
cat "$FORK/superpowers-bridge/VERSION"
```
Expected: `OK`; no `gh pr create` in the bridge; baseline shows 6.1.0/1.5.0; VERSION `1.1.0`.

- [ ] **Step 10: Commit**

```bash
git -C "$FORK" add superpowers-bridge/
git -C "$FORK" commit -m "feat(bridge): adapt to Superpowers 6.1.0 (push-only finish, merged reviewer, plan.md format) + re-attest baselines 6.1.0/1.5.0 (M4 + v6 diff)"
```

---

### Task 6: Cosmetics batch — step-number/label drift, grep-anchor mismatch, artifact-count typos

**Files:**
- Modify: `$FORK/superpowers-bridge/schema.yaml` (L1 grep anchor ~line 210; L5 `design` missing from the chain at line 15)
- Modify: `$FORK/superpowers-bridge/README.md` + `README.zh-TW.md` (M7 finishing "step 4"→step 6 ~line 306; stale "2a"/"2b" labels ~line 445 / zh-TW ~310,449; L4 "7 artifacts" shows 6 ~line 225)
- Modify: `$FORK/superpowers-bridge/templates/retrospective.md` (L1 anchor `^\s*- \[x\]` vs gates' `^- \[x\]`)

**Interfaces:** none.

- [ ] **Step 1: L5** — the description chain at `schema.yaml:15` reads `brainstorm → proposal → specs → tasks → plan → verify → retrospective` but omits `design`. Insert `design` after `proposal`: `brainstorm → proposal → design → specs → tasks → plan → verify → retrospective`.

- [ ] **Step 2: L1** — align grep anchors. Decide on ONE anchor form and use it everywhere the completeness of `tasks.md` is counted. Use `^\s*- \[x\]` (tolerant of indentation) in the verify PRECHECK (`schema.yaml:210`) and confirm the retrospective template (`templates/retrospective.md:19`) matches. Update whichever differs so both read `^\s*- \[x\]`.

- [ ] **Step 3: M7** — fix step-number drift: README's touchpoints table says finishing-a-development-branch is "step 4" (~README:306) but the apply instruction sequences it at step 6. Change to "step 6". Fix stale "2a"/"2b" apply-step labels (~README:445; zh-TW ~310,449) to match the current numbered apply steps (1-6).

- [ ] **Step 4: L4** — the "PLANNING — 7 artifacts" heading (~README:225) lists 6. Recount and correct to match the actual planning artifacts.

- [ ] **Step 5: Validate + grep**

```bash
python3 -c "import yaml; yaml.safe_load(open('$FORK/superpowers-bridge/schema.yaml')); print('OK')"
grep -n "brainstorm → proposal → design → specs" "$FORK/superpowers-bridge/schema.yaml"
```
Expected: `OK`; chain now includes `design`.

- [ ] **Step 6: Commit**

```bash
git -C "$FORK" add superpowers-bridge/
git -C "$FORK" commit -m "docs(bridge): fix step-number/label drift, grep-anchor mismatch, artifact-count + chain typos (M7/L1/L4/L5)"
```

---

### Task 7: Re-point to the fork + retire the drift-vs-JiangWay apparatus (topology)

**Files:**
- Modify: `$FORK/superpowers-bridge/README.md` + `README.zh-TW.md` (4 clone-URLs in install/upgrade prose ~lines 26,40,67,86; CI badge line 5; Upstream Drift badge line 6 + its Compatibility-section duplicate ~496-497)
- Delete/neutralize (repo root, if present): `$FORK/.github/workflows/version-check.yml`

**Interfaces:** none.

**Context:** Adrian's chosen shape: GitHub fork = SSOT, re-point vendored copy to it, RETIRE the weekly drift-vs-JiangWay bot (upstream is dead), keep the fork publishable for PR-back. C found the touch-points: 4 clone-URL occurrences, the CI badge, the Upstream Drift badge (×2), and the workflow files.

- [ ] **Step 1: Re-point the 4 clone-URLs** from `https://github.com/JiangWay/openspec-schemas` to `https://github.com/AdrianTheopold/openspec-schemas` in both READMEs' Method 1/2 install + upgrade blocks.

- [ ] **Step 2: Add a "forked from" attribution** near the top of `README.md` (and zh-TW): `> Fork of [JiangWay/openspec-schemas](https://github.com/JiangWay/openspec-schemas) (upstream commit f5d4040), maintained independently since 2026-07-02. Upstream-PR-back welcome.`

- [ ] **Step 3: Retire the Upstream Drift badge + bot.** Remove the `Upstream Drift` badge (README line 6) and its duplicate link in the Compatibility section (~496-497). Delete `$FORK/.github/workflows/version-check.yml` if it exists (`git rm`); replace the drift row in the Compatibility "how updates flow" table with a manual note: `Baselines are updated by hand when this fork is maintained; there is no automated drift bot (upstream JiangWay is inactive).`

- [ ] **Step 4: Handle the CI badge** — either re-point the `validate-schemas.yml` badge to `AdrianTheopold/openspec-schemas` (keep only if that workflow exists in the fork) or remove the badge. Verify whether `$FORK/.github/workflows/validate-schemas.yml` exists; keep+repoint if yes, remove the badge if no.

- [ ] **Step 5: Grep-verify no stray JiangWay URLs remain except the attribution**

```bash
grep -rn "JiangWay" "$FORK/superpowers-bridge/"
```
Expected: only the single "Fork of … (upstream commit f5d4040)" attribution line (Step 2).

- [ ] **Step 6: Commit**

```bash
git -C "$FORK" add -A
git -C "$FORK" commit -m "chore(bridge): re-point to fork, retire drift-vs-JiangWay bot, add upstream attribution"
```

---

### Task 8: Re-sync the vendored copy, validate end-to-end, push, open PR

**Files:**
- Modify: `/develop/anomaly-detection/openspec/schemas/superpowers-bridge/**` (overwrite from the fork — the re-vendor)
- Modify: `/develop/CLAUDE.md` and `/develop/anomaly-detection/CLAUDE.md` (CLI pin note `@fission-ai/openspec@1.4.1` → `1.5.0`, and the "upstream commit f5d4040 / JiangWay" pointer → the fork) — **Adrian owns these files; propose the diff and get his ok before writing.**

**Interfaces:**
- Consumes: the finished fork branch from Tasks 2-7.
- Produces: a vendored copy byte-identical to `$FORK/superpowers-bridge/`, validating `✓ valid`, and an open PR on the fork.

- [ ] **Step 1: Re-vendor (whole-dir overwrite, per the bridge's own contract)**

```bash
rm -rf /develop/anomaly-detection/openspec/schemas/superpowers-bridge
cp -R "$FORK/superpowers-bridge" /develop/anomaly-detection/openspec/schemas/superpowers-bridge
```

- [ ] **Step 2: Authoritative structural validation**

```bash
cd /develop/anomaly-detection && openspec schema validate superpowers-bridge
```
Expected: `✓ valid`.

- [ ] **Step 3: Confirm vendored == fork**

```bash
diff -ruN "$FORK/superpowers-bridge" /develop/anomaly-detection/openspec/schemas/superpowers-bridge
```
Expected: no output (identical). The plan lives at the fork repo root (`docs/plans/`), NOT under `superpowers-bridge/`, so it does not appear in this diff.

- [ ] **Step 4: (OPTIONAL, gold-standard) dry apply behavioral check.** On a throwaway change, run one `/opsx:apply` cycle and confirm: (a) SDD does NOT open a PR / delete the worktree at the end (H2), (b) `tasks.md` boxes get ticked as tasks clear (H1), (c) verify's PRECHECK passes. Heavy (real worktree + subagents) — run only if Adrian wants full behavioral proof before merge.

- [ ] **Step 5: Bump the CLI pin references** (Adrian-owned files — propose diff first): `@fission-ai/openspec@1.4.1` → `@fission-ai/openspec@1.5.0` in `/develop/CLAUDE.md` (and any anomaly-detection mention); update the "vendored … upstream commit f5d4040 (JiangWay)" note to point at the fork.

- [ ] **Step 6: Push the fork branch + open the PR**

```bash
git -C "$FORK" push -u origin fix/correctness-pass-v1.1
gh pr create --repo AdrianTheopold/openspec-schemas --base main --head fix/correctness-pass-v1.1 \
  --title "Correctness pass v1.1: fix H1/H2 apply bugs, re-attest 6.1.0/1.5.0, re-point fork" \
  --body "See superpowers-bridge/docs/plans/2026-07-02-correctness-pass.md. Fixes 2 HIGH (tasks.md verify false-STOP; SDD self-finish before verify/retro/archive) + correctness MEDs + baseline re-attestation + fork re-pointing."
```
Expected: PR URL printed.

- [ ] **Step 7: Commit the vendored re-sync in anomaly-detection** (separate repo; on a branch, per commit-on-owned-branch discipline — do NOT push without Adrian's ok)

```bash
cd /develop/anomaly-detection && git switch -c chore/revendor-bridge-fork-v1.1
git add openspec/schemas/superpowers-bridge CLAUDE.md
git commit -m "chore: re-vendor superpowers-bridge from fork v1.1 (H1/H2 + baselines + re-point)"
```

---

## Self-Review notes (author)

- **Spec coverage:** every audit finding maps to a task — H2→T2, H1→T3, M2/M3/M5/M6→T4, M4+1.5.0→T5, M7/L1/L4/L5→T6, topology→T7, re-sync+pin+PR→T8. L3 (post_apply) is Global-Constraints OUT-of-scope (upstream-gated). Comprehensive-scope items (docs rewrite, test harness) intentionally deferred per the chosen "correctness pass."
- **No pytest by design:** verification is `openspec schema validate` + grep + (optional) one real apply cycle; stated in the Verification model up top so it isn't read as a placeholder.
- **Outward-facing gates flagged:** fork creation (T1.1), any public push (Global Constraint + T8.6), and Adrian-owned CLAUDE.md edits (T8.5) all require his ok — consistent with "confirm outward-facing actions."
- **Open item for Adrian:** whether the eventual PR is fork-internal (merge to his fork's main) or also raised BACK to JiangWay. Default here: fork-internal; PR-back is a later, separate action.
