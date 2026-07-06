# Changelog

All notable changes to LCP RiskGuard are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0] — 2026-07-06

### Added

- **Initial release** for the Pharos Agent Arena Phase 2 of the
  Skill-to-Agent Dual Cascade Hackathon.
- `SKILL.md` — Anvita Flow upload manifest with full YAML frontmatter.
  `name: lcp-riskguard-agent` matches the upload folder name.
  Description is one sentence per Anvita's Marketplace search spec.
- `scripts/run.sh` — Service Agent runner. Reads `LCP_TARGET`,
  `LCP_NETWORK`, `LCP_THRESHOLD`, `LCP_INCLUDE_DRIVERS` from env,
  invokes the underlying LCP Skill, merges output with metadata
  (timestamp, block, skill, version), and supports threshold-based
  result filtering.
- `install.sh` — Local smoke-test installer. Confirms the LCP Skill
  is available and passes its test gates (`forge test -vvv` →
  7 passed), then runs the runner against `native:PROS mainnet`.
- `README.md` — Human-readable landing page.
- `LICENSE` (MIT) + `SECURITY.md`.
- `references/agent-card.md` — All 8 Agent Card fields pre-filled.
  Copy-paste ready for the Anvita Developer Console.
- `references/phase2-submission-prep.md` — Every field on the
  (upcoming) Dorahacks Phase 2 submission form pre-written.
- `references/demo-video-script.md` — 5-scene, ~2-minute screencast
  script. Designed for one-take recording with on-screen captions
  (no voiceover required).
- `references/anvita-upload-walkthrough.md` — 7-screen walkthrough
  of the Anvita Developer Console flow for Jul 8 upload.
- `references/example-outputs.md` — 5 canonical JSON output shapes
  (HEALTHY, WATCH, CRITICAL, filtered, drivers-suppressed) to paste
  into the Agent Card's Deliverables field.
- `references/installation-flow.md` — ASCII architecture diagram
  showing the on-chain data path end-to-end. Designed for judges
  who want to see the full request → score → response flow.
- `.github/CI.md` — CI workflow content documented (the workflow
  YAML itself is held back because the project PAT is `repo`-only,
  not `workflow`-scoped).
- `assets/README.md` — Placeholder for screenshots and diagrams
  to add before publishing.

### Security

- Runner explicitly refuses to run if `PRIVATE_KEY` is set (exit 77).
- Runner explicitly refuses if `cast` or `jq` are missing (exit 64).
- The runner performs no `cast send` and no transaction signing —
  all on-chain reads are `cast call`, `cast logs`, or `cast gas-price`.
- `SECURITY.md` documents the threat model and what the agent will
  and will not do.

### Dependencies

- Foundry 1.7.1 (`cast`, `forge`) — mandatory, installed via the
  official `curl -L https://foundry.paradigm.xyz | bash` flow on
  Linux/macOS, or the Termux-packaged `foundry_1.7.1-1_aarch64.deb`
  on Termux.
- Solidity compiler 0.8.31 (matches `foundry.toml` in the
  underlying Skill).
- `jq` — for JSON composition.
- The Skill itself: `networkbike/LCP` v0.2.0.

### Known limitations

- Pricing is **Free** during the Anvita Flow payment beta. Charging
  will be enabled when the Anvita payment module launches; the
  runner is already x402-ready (it accepts the same inputs
  regardless of price).
- The runner currently calls the underlying LCP Skill via a
  sibling directory. On Anvita Flow's hosted runtime, this
  resolves via the platform's bundle mechanism. If Anvita's
  bundle strategy changes, the runner's `LCP_SKILL_DIR` env var
  allows override.

### Acknowledgements

Built on top of [`networkbike/LCP`](https://github.com/networkbike/LCP)
(Phase 1 Skill Hackathon winner). The Skill does the math; the
Agent does the formatting.