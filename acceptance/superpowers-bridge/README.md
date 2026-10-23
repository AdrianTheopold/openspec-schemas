# Mechanical acceptance for superpowers-bridge

Shell-driven checks that run the OpenSpec CLI against small fixture repositories
and assert on its JSON output.

```bash
acceptance/superpowers-bridge/run.sh check
acceptance/superpowers-bridge/run.sh stage <fixture> <dir> [--config <file>]
```

`check` prints one `PASS <fixture>: <assertion>` or `FAIL <fixture>: <assertion> — <detail>`
line per assertion and exits 0 only if none failed. `stage` builds a throwaway git
repository for a fixture and prints its path.

Set `OPENSPEC` to run the same assertions against another CLI version: a binary path, or
a command of several words such as `OPENSPEC="npx -y @fission-ai/openspec@1.13.0"`. The
value is split on whitespace, so a path that contains a space does not work. The runner
copies the bundle itself, so it needs no install beyond the CLI.

## Fixtures

| Fixture | What it holds | What `check` proves | What an agent run must report (`expected.md`) |
|---|---|---|---|
| `clean` | A change that breaks no rule | Strict validation passes with no archive refusal; the proposal parses; every scenario has steps; the instructions and templates still carry checks 8 to 10, the retrospective's dismissal tally, and the plan and apply rules (staged with `config.safety.yaml` and `config.apply.yaml`) | `No findings.` for checks 8 and 10; `No governing sources configured` for check 9 |
| `seeded` | A change with fourteen seeded defects, one per rule, and a sibling change on the same requirement | The CLI still reports each seed a command finds: strict failure, archive refusal, a scenario without steps, a non-scenario header, the placeholder Purpose, one code label, the sibling collision | Each of the fourteen seeds once, and nothing else |
| `seeded-proposal` | A change whose `proposal.md` does not parse | The CLI reports the parse error and returns no deltas while the proposal is unparsed | (mechanical only) |
| `no-deltas` | A change with code but no delta specs | The change has no deltas, and the code-label search still runs on its code | (mechanical only) |
| `deviation` | A change that moves away from a governing source kept in a second repository, with a branch amending that source checked out | The configured context and verify rules reach the verify instruction; the source repository has the amending branch checked out | Two deviations, read at `main`; with `config.unreadable.yaml`, FAIL naming the missing source |
| `security` | A branch adding a client with a hard-coded credential and certificate verification turned off | Both defects are in the diff against the trunk | Both defects found, each fixed or dismissed with a reason |

## Fixture layout

`fixtures/<name>/` holds `trunk` (the trunk branch name), `base/` (committed on the trunk),
`branch/` (committed on branch `change`), `expected.md` (the outcomes an agent review should
report), and optionally `config.yaml`.

A fixture with a `kb/` directory also gets a source repository, staged at `<dir>.kb`, that
stands in for an adopter's governing documents: `kb/trunk/` is committed on `main`, then
`kb/amend/` on a branch `amend`, which is left checked out. `@KB@` in the config becomes
that repository's path. Stage with `--config` to swap in another config, for example
`fixtures/deviation/config.unreadable.yaml`.

A fixture with an `sdd/` directory gets it copied, untracked, to `.superpowers/sdd/` in the
staged repository: the executor's ledger, whose `Ruling:` lines verify reads as the executor's
"Rulings I made" list.

## Agent acceptance

`check` proves that the CLI behaves as the checks expect; whether an agent applies the
checks correctly is tested by hand, one check per run:

1. Stage the fixture: `run.sh stage <fixture> <dir>` (with `--config <file>` for a variant).
   The staged repository holds its own copy of the bundle under `openspec/schemas/`,
   which OpenSpec resolves before a user-tier install, so the run reads this checkout.
2. Dispatch a fresh-context agent with its working directory inside `<dir>` and only the
   inputs the check passes in `schema.yaml`'s verify instruction — for check 8, the change
   name, the working directory and the rule file's path; for check 9, also the context,
   the verify rules and the check's text; for check 10, the change name (`security` has
   none), the working directory, the base and the reading list. Give it no history and no hint of what the fixture seeds.
3. Compare its report with the fixture's `expected.md`: every expected outcome present
   once, nothing else reported. A miss in the bundle is fixed in the bundle and the run
   repeated; an expectation found wrong is corrected in `expected.md`.
