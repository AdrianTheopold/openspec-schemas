## Why

The order store hands its internal dictionary to callers and keeps the one it was given, so an edit a caller makes after saving silently changes the stored order. The behavior the orders specification states is unchanged; only the module's internals are tidied.

## What Changes

- Store a copy of each saved order instead of the caller's own dictionary.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- Affected code: the order storage module.
- No specification changes.
