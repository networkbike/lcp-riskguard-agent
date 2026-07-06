# LCP RiskGuard — installation flow

A visual narrative of how the Service Agent gets from "fresh
Termux on Android" to "scoring a Pharos token in 8 seconds flat."
Designed for judges who want to see the on-chain data path
end-to-end.

---

## The full picture

```
┌──────────────────────────────────────────────────────────────────┐
│                    Anvita Flow Marketplace                       │
│                                                                  │
│   User (Anvita On) ──► Steward Agent ──► routes to ──┐           │
│                                                       ▼           │
│                                              ┌──────────────┐     │
│                                              │  LCP          │     │
│                                              │  RiskGuard    │     │
│                                              │  (Service     │     │
│                                              │   Agent)      │     │
│                                              └──────┬───────┘     │
└─────────────────────────────────────────────────────┼─────────────┘
                                                      │
                                                      │ invokes
                                                      ▼
┌──────────────────────────────────────────────────────────────────┐
│              LCP RiskGuard runner (scripts/run.sh)               │
│                                                                  │
│   1. Refuse if PRIVATE_KEY is set (exit 77)                       │
│   2. Refuse if cast/jq missing (exit 64)                          │
│   3. Locate LCP Skill (sibling dir, or $LCP_SKILL_DIR)            │
│   4. Validate inputs: target is 0x… or native:PROS/PHRS            │
│                                                                  │
└─────────────────────────────┬────────────────────────────────────┘
                              │
                              │ invokes
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│     LCP Skill (networkbike/LCP, examples/score.sh)               │
│                                                                  │
│   Read 7 on-chain signals in parallel:                           │
│                                                                  │
│   ┌────────────┐  cast block-number        → height              │
│   │ chain id   │  cast chain-id            → 1672 or 688689      │
│   ├────────────┤  cast gas-price           → gas stress proxy    │
│   │ gas stress │                                                 │
│   ├────────────┤  cast call <pair>         → pair reserves       │
│   │ reserves   │     "getReserves()(...)"     (depth + imbalance)│
│   ├────────────┤  cast call <token>        → supply + decimals   │
│   │ erc20 meta │     "symbol/decimals/                            │
│   │            │      totalSupply()(...)"                         │
│   ├────────────┤  cast logs --from-block N → outflow velocity    │
│   │ outflow    │     Transfer events                               │
│   ├────────────┤  cast call <token>        → top-10 holder       │
│   │ holders    │     "balanceOf(addr)(uint)"   balances           │
│   └────────────┘  (batched)               → concentration       │
│                                                                  │
│   Compute in pure AWK + bash:                                    │
│     - normalize each signal to [0,1] via thresholds.json         │
│     - weighted sum → score (0–100)                               │
│     - piecewise-linear p_crisis (logistic)                       │
│     - rank drivers by absolute contribution                      │
│                                                                  │
└─────────────────────────────┬────────────────────────────────────┘
                              │
                              │ returns
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│           LCP Score JSON (raw, unformatted)                      │
│                                                                  │
│   { "target": "...",                                             │
│     "score": 73,                                                 │
│     "band": "WATCH",                                             │
│     "p_crisis": 0.62,                                            │
│     "drivers": [...] }                                           │
│                                                                  │
└─────────────────────────────┬────────────────────────────────────┘
                              │
                              │ RiskGuard post-processes
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│             LCP RiskGuard final JSON                             │
│                                                                  │
│   {                                                              │
│     "target": "0xABCDEF…",                                       │
│     "network": "mainnet",                                        │
│     "score": 73,                                                 │
│     "band": "WATCH",                                             │
│     "p_crisis": 0.62,                                            │
│     "drivers": [                                                 │
│       {"signal": "outflow_velocity", "contribution": 0.31},      │
│       {"signal": "holder_concentration", "contribution": 0.22},  │
│       {"signal": "pair_imbalance", "contribution": 0.18}         │
│     ],                                                           │
│     "timestamp": "2026-07-05T22:10:18Z",                         │
│     "block": 9953438,                                            │
│     "skill": "liquidity-crisis-predictor",                      │
│     "skill_version": "0.2.0"                                     │
│   }                                                              │
│                                                                  │
└─────────────────────────────┬────────────────────────────────────┘
                              │
                              │ Anvita Flow routes back
                              ▼
                          Steward Agent
                              │
                              │ formats for user
                              ▼
                       User (Anvita On)
```

---

## The 8-second budget

| Step | Time | Notes |
|---|---|---|
| Anvita routing in | ~50ms | Same-region hosting |
| RiskGuard runner cold start | ~30ms | bash spin-up |
| Locate LCP Skill (fs walk) | ~5ms | single directory |
| cast block-number + chain-id | ~200ms | single round-trip each, can be parallel |
| cast call ERC-20 metadata | ~300ms | symbol + decimals + totalSupply |
| cast call pair reserves | ~300ms | one call to getReserves |
| cast gas-price | ~150ms | one round-trip |
| cast logs Transfer scan | ~3000ms | last 10000 blocks filtered by topic0 |
| cast call 10 holders | ~3000ms | 10 round-trips, parallelizable in future |
| LCP math (AWK + jq) | ~10ms | sub-millisecond on a phone |
| RiskGuard merge + format | ~5ms | jq composition |
| Anvita routing out | ~50ms | |
| **Total end-to-end** | **~7.1s** | Within the 30s budget |

The big line items are the **Transfer log scan** and the **holder
balance batch**. Both are I/O-bound on the Pharos RPC, not CPU-bound
on the phone. Anvita Flow's regional hosting typically cuts these
to 1-2 seconds in practice.

---

## What makes this win

1. **The Skill does the math, the Agent does the formatting.**
   LCP RiskGuard never recomputes a score. It calls LCP, gets a
   JSON, decorates with metadata. Zero risk of math drift.

2. **No external state.** Every call is idempotent — same
   `(target, network, block)` always returns the same JSON.
   Steward Agents can cache safely.

3. **Refuses loudly when misused.** Setting `PRIVATE_KEY` in the
   environment exits 77 with a JSON error. Missing `cast` exits
   64 with a JSON error. The Agent never silently fails.

4. **Threshold-aware.** A user asking "alert me only on CRITICAL"
   doesn't get noise from WATCH-band tokens. The runner returns
   `{"filtered": true, "reason": "..."}` so the Steward Agent
   can drop the notification cleanly.

5. **Composable.** When other Skills get built (gas oracle,
   price feed, exit-plan recommender), they can be added to
   this same Agent via the Anvita console without touching
   the runner. That's the whole point of the Skill + Agent
   split.

---

## What's NOT in the picture

- **No wallet / signer.** RiskGuard never holds keys, never
  signs, never sends transactions. If `PRIVATE_KEY` is in scope,
  the runner refuses before doing anything.
- **No external HTTP calls.** All data comes from Pharos RPC
  via Foundry's `cast`. No third-party oracles.
- **No state between calls.** Each invocation starts fresh.
  Steward Agents track their own history if they want trends.

---

## Why this flow is honest

The diagram above shows **exactly** what runs in production. There
are no hidden services, no off-chain enrichment, no "the model
also considered X." If a judge asks "how does the score get from
RPC to JSON," the answer is the path above — and the path above
is fully reproducible from `networkbike/LCP` and the runner
source.