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

Set `OPENSPEC` to a binary path to run the same assertions against another CLI version.
The runner copies the bundle itself, so it needs no install beyond the CLI.

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
