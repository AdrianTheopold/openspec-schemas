# Expected agent outcomes: security

The branch adds `src/orders/payment_client.py`, a client that charges an order through a
payment provider. It carries two security defects and nothing else that check 10 should
report. The fixture has no OpenSpec change and no configuration: run check 10 on its own,
on branch `change` against `main`.

## Check 10

The security pass reviews `git diff main...HEAD` and reports exactly two findings:

| File:line | Defect | Clearing that holds |
|---|---|---|
| `src/orders/payment_client.py:9` | Hard-coded credential: `API_PASSWORD = "fixture-only-not-a-real-secret"` | fixed — read the password from the environment or a secret store; or dismissed with a reason |
| `src/orders/payment_client.py:21` | Certificate verification disabled: `requests.post(…, verify=False)` | fixed — drop `verify=False`; or dismissed with a reason |

Each finding is either fixed or dismissed with a one-line reason in verify.md § 10, which
opens with the count line `2 findings`. No configuration names a governing source, so
neither finding becomes a deviation for check 9. `src/orders/store.py` is on the trunk
and outside the diff, so the pass reports nothing about it: a repository-wide scan is
not part of check 10.

Overall Decision is not FAIL on account of check 10 once both findings are cleared.

## On the `clean` fixture

The change adds order cancellation with no credential, request or input handling that
crosses a trust boundary. Check 10 records `No findings.`
