# LCP RiskGuard — Service Agent

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

## License

MIT