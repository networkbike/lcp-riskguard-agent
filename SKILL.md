---
name: lcp-riskguard-agent
description: >
  A read-only Service Agent that monitors an ERC-20 token, DEX pool, or
  native asset on Pharos for liquidity-stress changes. Invoke whenever
  the user wants continuous monitoring, threshold-based alerts, or a
  chat-friendly summary of liquidity risk for a Pharos address.
  Built on top of the `liquidity-crisis-predictor` (LCP) Skill
  (networkbike/LCP); consumes seven on-chain signals and reports a
  HEALTHY / WATCH / CRITICAL band plus a logistic crisis probability.
  Free during Anvita Flow pricing beta; never touches a wallet, never
  signs a transaction.
version: 0.1.0
license: MIT
author: networkbike
metadata:
  framework: Anvita Flow
  category: on-chain-analytics
  networks:
    - Pharos Mainnet (chain 1672)
    - Pharos Atlantic Testnet (chain 688689)
  skills_used:
    - liquidity-crisis-predictor (networkbike/LCP, v0.2.0)
  runtime:
    host: Anvita Flow
    language: Solidity 0.8.31 (LCP math) + Bash + AWK + jq
    mandatory_binaries:
      - cast
      - forge
      - jq
  pricing:
    unit_price: Free
    billing_protocol: x402 (deferred; charging disabled during beta)
  read_only: true
  signs_transactions: false
  test_command: forge test -vvv
  test_expected: 7 passed
---

# LCP RiskGuard — Service Agent

LCP RiskGuard is a **read-only monitoring agent** that wraps the
[`liquidity-crisis-predictor`](https://github.com/networkbike/LCP) (LCP)
Skill and answers one question for a Pharos token, pool, or native
asset: **"Should I be worried about this position's liquidity right
now?"**

LCP RiskGuard calls LCP on every invocation, gets back a band
(`HEALTHY` / `WATCH` / `CRITICAL`), a 0–100 liquidity-stress score,
and a logistic crisis probability, then formats the result as a
chat-friendly summary the Steward Agent can deliver to the user.

## What it solves

Liquidity crises on DeFi happen fast. By the time a holder sees a
"rug pull" tweet, the liquidity is already gone. LCP RiskGuard gives
a Steward Agent (or a user via Anvita On) a deterministic way to
ask "is this token's liquidity draining right now?" — repeatedly,
automatically, with no wallet or private key.

## How it works

```
User: "Watch 0xABCDEF… on Pharos mainnet, alert me if it goes WATCH or worse"
        ↓
Steward Agent finds LCP RiskGuard in the Marketplace
        ↓
Anvita Flow routes the request → LCP RiskGuard Service Agent
        ↓
LCP RiskGuard runs the LCP Skill (networkbike/LCP):
   - reads 7 on-chain signals (reserves, liquidity depth, holder
     concentration, outflow velocity, gas stress, pool imbalance,
     supply growth)
   - normalizes each to [0, 1] via assets/lcp-thresholds.json
   - sums weighted → score, band, p_crisis
   - picks top 3 drivers
        ↓
LCP RiskGuard formats the result into a chat-friendly summary
        ↓
Steward Agent delivers the summary to the user
```

## Inputs

The Steward Agent (or the user) supplies:

| Input | Required | Example |
|---|---|---|
| `target` | yes | `0xABCDEF…` (ERC-20) or `native:PROS` or `native:PHRS` |
| `network` | yes | `mainnet` (default) or `atlantic-testnet` |
| `alert_threshold` | no | `WATCH` (default) or `CRITICAL` — only return a result if band ≤ threshold |
| `include_drivers` | no | `true` (default) or `false` |

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
- Does not work with chains other than Pharos (mainnet, Atlantic testnet)

## Pricing

**Free during the Anvita Flow pricing beta.** Once payment collection
launches, LCP RiskGuard will charge a fixed per-call USDC price via
the x402 protocol. Set the unit price to `Free` in the Agent Card
until then.

## Testing

The underlying LCP Skill is verified by Foundry:

```bash
cd /path/to/liquidity-crisis-predictor
forge test -vvv
# Expected: 7 passed; 0 failed
bash test/test_score.sh
# Expected: 4 passed; 0 failed; 1 skipped
```

## Repository

- LCP RiskGuard: `https://github.com/networkbike/lcp-riskguard-agent`
- Skill used: `https://github.com/networkbike/LCP` (Phase 1 submission)

## License

MIT