# Marketing one-pager

A short, ready-to-publish essay that explains LCP RiskGuard
without jargon. Use it for:

- Medium / Mirror / Notion blog posts
- Project showcase threads on Discord
- One-page PDF for stakeholders / partners
- Email blast to your network

Length: ~400 words. Read time: 2 minutes.

---

# LCP RiskGuard: a read-only liquidity-stress monitor for Pharos

DeFi liquidity crises happen fast. By the time you see a "rug
pull" tweet, the liquidity is already gone. By the time you see
a Telegram panic post, the pair is empty. By the time you check
the explorer, the deployer has moved the funds.

The question "is this token's liquidity draining right now?"
shouldn't need a wallet or a private key to answer. It shouldn't
require you to trust a third-party oracle. And it certainly
shouldn't ask you to sign anything.

LCP RiskGuard is a Service Agent that answers exactly that
question — and only that question — for any token, pool, or
native asset on the Pharos Network.

## What it does

You give LCP RiskGuard a Pharos address. It reads seven on-chain
signals in real time — pair reserves, ERC-20 liquidity depth,
holder concentration, recent outflow velocity, gas-stress proxy,
DEX pool imbalance, and supply growth — and returns a band:
**HEALTHY**, **WATCH**, or **CRITICAL**, plus a 0–100 score and a
logistic crisis probability.

The math is fully reproducible. Run the same `cast` calls
against the same block on any machine and you get the same
result. There's no ML model, no off-chain data, no third-party
oracle. The score is determined entirely by what's on chain
right now.

## What it doesn't do

LCP RiskGuard never signs a transaction. It never holds user
funds. It never calls any external HTTP oracle. It explicitly
refuses to run if `PRIVATE_KEY` is set in the environment.

That's the safety story: we didn't add security on top of a
signing Agent. We built an Agent that doesn't need security
because it can't sign.

## How to use it

The Agent is published on Anvita Flow's Marketplace during the
Pharos Agent Carnival (Round 2, Jul 10). Any Steward Agent on
Pharos can find it and invoke it. End users can call it directly
via Anvita On.

Or, if you want to call it directly from a terminal:

```bash
LCP_TARGET=native:PROS LCP_NETWORK=mainnet bash scripts/run.sh
```

Output:

```json
{
  "target": "native:PROS",
  "network": "mainnet",
  "score": 18,
  "band": "HEALTHY",
  "p_crisis": 0.04,
  "drivers": [...]
}
```

## How it's built

LCP RiskGuard wraps the `liquidity-crisis-predictor` (LCP)
Skill, which won Phase 1 of the Skill-to-Agent Dual Cascade
Hackathon. The Skill does the math; the Agent does the
formatting.

- **Foundry 1.7.1** for `cast` / `forge` / `anvil`
- **Solidity 0.8.31** for the math (validated by 7 forge tests)
- **Bash + AWK + jq** for the runner
- **No JS/TS, no npm, no Python, no external HTTP**
- **MIT licensed**, runs on Linux, macOS, and Termux on Android

The runner has 8 offline self-test checks. The Agent has 11
forge tests for the output shape. The repo has 17 reference
docs, an architecture decision record, a safety model, and a
formal JSON Schema for the output. The install is one command:
`make install`.

## Why this matters

The Pharos Agent Carnival is building an economy of agents that
hold real money on behalf of users. Most of those agents will
eventually have wallets, sign transactions, and execute trades.
That's where the value accrues, but it's also where the risk
lives.

LCP RiskGuard sits at the other end of that economy: a read-
only monitor that tells users when an agent *shouldn't* trade.
It's the early-warning system. The "should I be worried?"
component that every portfolio-monitor, every Steward Agent, and
every risk-aware user needs.

It's free during the Anvita pricing beta. It's reproducible.
It's auditable. It's the most boring Agent in the Marketplace
— and that's the highest compliment we can give it.

## Get started

- **Agent:** https://github.com/networkbike/lcp-riskguard-agent
- **Skill:** https://github.com/networkbike/LCP
- **Anvita Flow:** https://flow.anvita.xyz
- **Pharos Network:** https://pharos.xyz

Built by `networkbike` for the Pharos Skill-to-Agent Dual
Cascade Hackathon, Agent Arena (Phase 2). License: MIT.