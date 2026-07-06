---
name: Bug report
about: Something is broken in the runner, installer, or self-test
title: "[bug] "
labels: bug
assignees: ""
---

## What happened

A clear, one-paragraph description of what went wrong.

## Command that triggered it

The exact command(s) you ran. Use code blocks:

```bash
LCP_TARGET=0xABCDEF... LCP_NETWORK=mainnet bash scripts/run.sh
```

## Expected output

What you expected to happen.

## Actual output

The actual output, including any error messages. Use a code
block:

```
{"error":"..."}
```

## Self-test result

```bash
$ bash scripts/self-test.sh
```

Paste the full output here.

## Environment

- OS: (Linux / macOS / Termux, version)
- Architecture: (x86_64 / arm64)
- Foundry version (`cast --version`):
- solc version (`solc --version`):
- LCP Skill version (`cat ~/LCP/SKILL.md | grep version`):

## Reproducible?

- [ ] Yes, every time
- [ ] Sometimes
- [ ] Once

## Anything else

Screenshots, stack traces, or context that helps debug.
