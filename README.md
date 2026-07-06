# LCP RiskGuard — Service Agent

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](CHANGELOG.md)
[![Skill Engine: Foundry](https://img.shields.io/badge/runtime-Foundry%201.7.1-blueviolet.svg)](https://book.getfoundry.sh)
[![Framework: Anvita Flow](https://img.shields.io/badge/framework-Anvita%20Flow-orange.svg)](https://flow.anvita.xyz)
[![Network: Pharos](https://img.shields.io/badge/network-Pharos-success.svg)](https://pharos.xyz)
[![Read-only](https://img.shields.io/badge/security-read--only-brightgreen.svg)](SECURITY.md)
[![Hackathon: Agent Arena](https://img.shields.io/badge/Agent%20Arena-Phase%202-red.svg)](https://dorahacks.io/hackathon/pharos-phase1/detail)

LCP RiskGuard is a **read-only Service Agent** for the
[Anvita Flow](https://flow.anvita.xyz) Agent Marketplace. It wraps
the [`liquidity-crisis-predictor`](https://github.com/networkbike/LCP)
(LCP) Skill and answers one question for a Pharos token, pool, or
native asset:

> **"Should I be worried about this position's liquidity right now?"**

The Agent calls LCP on every invocation, gets back a band
(`HEALTHY` / `WATCH` / `CRITICAL`), a 0–100 liquidity-stress score,
and a logistic crisis probability, then formats the result as a
chat-friendly JSON document.

LCP RiskGuard never signs a transaction, never holds user funds,
and never calls an external HTTP oracle. It's free during the
Anvita Flow pricing beta.

**If you're a judge:** start with [`references/for-judges.md`](references/for-judges.md)
for a 30-second pitch and the 5 strongest selling points.
**If you're a user:** start with [`USER-GUIDE.md`](USER-GUIDE.md)
for a 60-second orientation.
**If you want everything:** see [`docs/INDEX.md`](docs/INDEX.md).

> 📺 **Live demo:** [https://networkbike.github.io/lcp-riskguard-agent/](https://networkbike.github.io/lcp-riskguard-agent/)
> — try the form, see the band, see the drivers. (Numbers are
> approximations; the real LCP math runs in the Anvita runtime.)

## What it solves

Liquidity crises on DeFi happen fast. By the time a holder sees a
"rug pull" tweet, the liquidity is already gone. LCP RiskGuard gives
a Steward Agent (or a user via Anvita On) a deterministic way to ask
"is this token's liquidity draining right now?" — repeatedly,
automatically, with no wallet or private key.

## How it works

```
User (via Anvita On):
  "Watch 0xABCDEF… on Pharos mainnet, alert me if it goes WATCH or worse"
        ↓
Steward Agent finds LCP RiskGuard in the Anvita Marketplace
        ↓
Anvita Flow routes the request → LCP RiskGuard Service Agent
        ↓
LCP RiskGuard runs the LCP Skill (networkbike/LCP):
   - reads 7 on-chain signals
   - normalizes → score, band, p_crisis
   - picks top 3 drivers
        ↓
LCP RiskGuard formats the result into a JSON document
        ↓
Steward Agent delivers the document to the user
```

## Skill used

This Service Agent is a thin wrapper around one Phase-1 Skill:

- **`liquidity-crisis-predictor`** (LCP), `networkbike/LCP` v0.2.0
  — the on-chain liquidity-stress scorer

LCP RiskGuard is read-only and reuses LCP's scoring math verbatim.
No re-implementation. No forked math.

## Quick start (local smoke test)

```bash
git clone https://github.com/networkbike/lcp-riskguard-agent.git
cd lcp-riskguard-agent
chmod +x install.sh
./install.sh
```

The installer:
1. Installs the LCP Skill from `networkbike/LCP` (or uses an
   existing clone at `$HOME/LCP`).
2. Runs `forge test -vvv` against the LCP Skill to confirm the
   underlying math passes.
3. Runs the LCP RiskGuard runner against `native:PROS mainnet`
   to confirm the wrapper round-trips correctly.

Expected output:
```
[install] LCP Skill: forge test 7 passed; 0 failed
[install] LCP RiskGuard runner output:
{"target":"native:PROS","network":"mainnet","score":18,"band":"HEALTHY","p_crisis":0.04,...}
[install] LCP RiskGuard: complete.
```

## Inputs

| Input | Required | Example |
|---|---|---|
| `LCP_TARGET` | yes | `0xABCDEF…` or `native:PROS` |
| `LCP_NETWORK` | yes | `mainnet` (default) or `atlantic-testnet` |
| `LCP_THRESHOLD` | no | `WATCH` (default) or `CRITICAL` |
| `LCP_INCLUDE_DRIVERS` | no | `true` (default) or `false` |

On Anvita Flow these are passed by the Steward Agent as env vars.
For local smoke tests you can also call the runner directly:

```bash
LCP_TARGET=0xABCDEF0123456789ABCDEF0123456789ABCDEF01 \
LCP_NETWORK=mainnet \
./scripts/run.sh
```

## Output

```json
{
  "target": "0xABCDEF…",
  "network": "mainnet",
  "score": 73,
  "band": "WATCH",
  "p_crisis": 0.62,
  "drivers": [
    {"signal": "outflow_velocity", "contribution": 0.31},
    {"signal": "holder_concentration", "contribution": 0.22},
    {"signal": "pair_imbalance", "contribution": 0.18}
  ],
  "timestamp": "2026-07-05T22:10:18Z",
  "block": 9953438,
  "skill": "liquidity-crisis-predictor",
  "skill_version": "0.2.0"
}
```

## What it does NOT do

- Does not sign or send any transaction
- Does not require a wallet or private key
- Does not call any external HTTP oracle
- Does not store user data between invocations (each call is stateless)
- Does not hold funds on behalf of the user
- Does not execute trades or trigger swaps
- Does not work with chains other than Pharos

## Pricing

**Free during the Anvita Flow pricing beta.** Once payment
collection launches, LCP RiskGuard will charge a fixed per-call
USDC price via the x402 protocol. The Agent Card price field
should be set to `Free` until the payment module is out of beta.

## Publishing to Anvita Flow

```bash
# 1. Zip the folder (the folder name must match `name:` in SKILL.md)
cd ..
zip -r lcp-riskguard-agent.zip lcp-riskguard-agent/

# 2. Go to https://flow.anvita.xyz/service-agents and create a new
#    Service Agent. Upload the zip. Fill the Agent Card from
#    references/agent-card.md.

# 3. Set price to "Free" until the Anvita payment beta ends.

# 4. Debug with at least one end-to-end session. Submit for review.
```

## Repository

- This Agent: `https://github.com/networkbike/lcp-riskguard-agent`
- Skill used: `https://github.com/networkbike/LCP` (Phase 1 winner)

## Submission materials (Phase 2 Agent Arena)

- **Demo video script:** `references/demo-video-script.md` (5 scenes, ~2 min)
- **Agent Card fields:** `references/agent-card.md` (all 8 fields pre-filled)
- **Submission prep:** `references/phase2-submission-prep.md` (copy-paste ready)
- **Anvita upload walkthrough:** `references/anvita-upload-walkthrough.md` (step-by-step for Jul 8)
- **Example outputs:** `references/example-outputs.md` (5 canonical JSON shapes to paste in Deliverables)
- **Installation flow:** `references/installation-flow.md` (visual architecture diagram for judges)
- **Safety model:** `references/safety-model.md` (why read-only is the winning move)
- **Comparison:** `references/comparison.md` (vs pharos-skill-engine, pharos-agent-kit, etc.)

## Repository extras

- `SECURITY.md` — read-only guarantees, threat model, audit posture
- `CHANGELOG.md` — version history (Keep a Changelog format)
- `FAQ.md` — anticipated questions from judges, Anvita reviewers, users
- `CODE_OF_CONDUCT.md` — Contributor Covenant 2.1 + finance-norms
- `CONTRIBUTING.md` — how to report issues, PR conventions, scope
- `LICENSE` (MIT)
- `docs/INDEX.md` — every doc, organized by audience
- `scripts/self-test.sh` — offline runner validation (8 checks, no RPC)
- `scripts/benchmark.sh` — latency benchmark
- `scripts/compare.sh` — multi-target comparison (N tokens)
- `test/LCPRiskGuard.t.sol` — 11 forge tests for the runner output shape
- `test/capture-output.sh` — regenerate the JSON fixtures
- `foundry.toml` + `Makefile` — `make test` is the canonical grading entry
- `references/glossary.md` — Pharos / Web3 / LCP terminology
- `references/troubleshooting.md` — common errors + fixes
- `references/architecture-decision-record.md` — 5 ADRs
- `references/composability-roadmap.md` — future Skills and Agents
- `references/scoring-model-explained.md` — deep dive on the LCP math
- `references/output-schema.md` — formal JSON Schema for the output

## Quick start with Make

The fastest way to install + verify everything:

```bash
git clone https://github.com/networkbike/lcp-riskguard-agent.git
cd lcp-riskguard-agent
make install         # clones LCP Skill, installs Foundry, runs all tests
make test            # re-run tests anytime (forge + bash self-test)
```

If `make` isn't available, use the underlying scripts directly:

```bash
./install.sh                                          # full install
bash scripts/self-test.sh                             # offline runner checks (8)
forge test -vvv                                       # runner output-shape tests (11)
LCP_TARGET=native:PROS bash scripts/run.sh           # one-shot invocation
LCP_TARGET=native:PROS LCP_NETWORK=mainnet bash scripts/run.sh
bash scripts/compare.sh native:PROS 0xABCDEF...      # multi-target comparison
bash scripts/benchmark.sh                              # latency benchmark
bash test/capture-output.sh                           # regenerate test fixtures
```

## Make targets

```bash
make install      # one-shot install (Foundry + jq + LCP Skill)
make test         # forge test + bash self-test (all gates)
make test-foundry # forge test -vvv (runner output shape, 11 tests)
make self-test    # bash scripts/self-test.sh (8 offline checks)
make compare TARGETS="native:PROS 0xABC..."   # multi-target comparison
make benchmark    # latency benchmark
make fixtures     # regenerate test/fixtures/*.json
make clean        # remove build artifacts
```

## License

MIT