# Contributing

LCP RiskGuard is open-source under MIT. Contributions are welcome.

## Scope

LCP RiskGuard wraps the [`networkbike/LCP`](https://github.com/networkbike/LCP)
Skill. The Skill does the math; the Agent does the formatting. If you
want to add new functionality:

- **New on-chain signals, new scoring math, new chains** → contribute
  to `networkbike/LCP`, not to this repo. The Agent inherits whatever
  the Skill does.
- **New output formats, new threshold logic, new input validation** →
  contribute to this repo. That's the Agent's job.
- **New Skills that compose with LCP** → build a new Service Agent
  that wraps multiple Skills. This repo can be a starting template.

## Reporting issues

Use GitHub Issues on `networkbike/lcp-riskguard-agent` for:

- Bugs in the runner
- Bugs in the install.sh / self-test.sh
- Documentation errors
- Feature requests for new output formats or input validation

For security issues, see `SECURITY.md` — email rather than opening
a public issue.

## Pull requests

Before opening a PR:

1. **Run the self-test.** `bash scripts/self-test.sh` should report
   `8 passed; 0 failed`. New runner features must include new
   self-test checks.
2. **Run install.sh locally** if you changed anything that touches
   the LCP Skill integration. The install must still pass on a
   fresh Termux install.
3. **Update the relevant docs.** If you change the input/output
   contract, update:
   - `references/agent-card.md`
   - `references/example-outputs.md`
   - `SKILL.md` body (input/output section)
4. **Add a CHANGELOG entry** under `[Unreleased]` in `CHANGELOG.md`.
5. **Keep the runner small.** The runner should stay under 150
   lines. If you're adding more than that, the logic probably
   belongs in the Skill, not the Agent.

## Coding style

- **Bash:** prefer `set -euo pipefail` and explicit error paths.
  Use `[[ ]]` not `[ ]`. Use `printf` for output, not `echo` (except
  for one-line log messages).
- **Naming:** env vars use `LCP_` prefix. Files use kebab-case.
- **Comments:** explain the why, not the what. The what is visible
  in the code; the why is what reviewers actually need.
- **JSON output:** every public function emits valid JSON on stdout.
  Errors on stderr. Use `jq` for composition.

## Testing policy

- New runner features require new self-test checks.
- New self-test checks must pass on a fresh Termux install (no
  Foundry pre-installed).
- New tests must run in under 5 seconds total.

## Release process

This project follows [Semantic Versioning](https://semver.org/):

- **Patch** (0.0.x) — bug fixes, no API changes.
- **Minor** (0.x.0) — new features, backwards-compatible.
- **Major** (x.0.0) — breaking changes.

To cut a release:

1. Update `CHANGELOG.md` from `[Unreleased]` to a dated version.
2. Update `SKILL.md` `version:` field.
3. Tag the commit: `git tag v0.x.0`.
4. Push the tag: `git push origin v0.x.0`.

## What NOT to contribute

- Wallet integration / transaction signing. The Agent is read-only
  by design; this is documented in `SECURITY.md`. If you want a
  transaction-signing Agent, build a separate one that calls LCP
  RiskGuard as a sub-routine.
- Hardcoded RPC URLs or chain IDs. Use `assets/networks.json`
  (inherited from the LCP Skill).
- Cross-chain support. LCP RiskGuard is Pharos-only. A multi-chain
  variant should be a separate Agent.

## Code of conduct

By participating, you agree to abide by `CODE_OF_CONDUCT.md`. Be
constructive, be honest, and assume good faith. We're all building
something new here.