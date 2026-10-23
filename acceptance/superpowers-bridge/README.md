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
report), and optionally `config.yaml`. `@KB@` in a config is replaced with the fixture's
`kb/` source repository when it has one.
