## What does this PR do?

One-paragraph description of the change.

## Type of change

- [ ] Bug fix (no API change)
- [ ] New feature (backwards-compatible)
- [ ] Breaking change (requires major version bump)
- [ ] Documentation update
- [ ] Repo hygiene (CI, templates, .gitignore, etc.)

## Checklist

- [ ] `bash scripts/self-test.sh` reports `8 passed; 0 failed`
- [ ] Updated `references/agent-card.md` if input/output changed
- [ ] Updated `references/example-outputs.md` if output shape changed
- [ ] Added a CHANGELOG entry under `[Unreleased]`
- [ ] Did NOT add a wallet or transaction signing (read-only by design)
- [ ] Did NOT add a new dependency (no npm, no pip, no curl beyond Foundry)
- [ ] Did NOT exceed 150 lines in `scripts/run.sh` (split out if needed)

## How was this tested?

```bash
$ bash scripts/self-test.sh
```

Paste the full output.

## Related issues

Closes #... / Fixes #... / Related to #...
