# Phase 2 Submission — Pre-filled Answers

When the Phase 2 form opens (Dorahacks says "we'll share the form next
week" — that's roughly Mon-Tue Jul 7-8), this file has every answer
pre-written so you can copy-paste in one sitting.

---

## Project name

```
LCP RiskGuard
```

## One-line pitch

```
A read-only Service Agent that monitors any Pharos token, pool, or native
asset for liquidity-stress changes, with deterministic scoring and
chat-friendly output.
```

## Long description (Markdown, ~600 words)

A Liquidity Crisis Predictor (LCP) RiskGuard Service Agent for the
Pharos Agent Arena.

LCP RiskGuard is a read-only monitoring agent that wraps the
`liquidity-crisis-predictor` (LCP) Skill — `github.com/networkbike/LCP`,
Phase 1 winner of the Skill-to-Agent Dual Cascade Hackathon.

For a given Pharos address or native asset, LCP RiskGuard reads seven
on-chain signals in real time: pair reserves, ERC-20 liquidity depth,
holder concentration, recent outflow velocity, gas-stress proxy, DEX
pool imbalance, and supply growth. It normalizes each signal to
`[0, 1]`, weights them per `assets/lcp-thresholds.json`, sums them
into a 0–100 liquidity-stress score, maps the score to a `HEALTHY /
WATCH / CRITICAL` band, and computes a logistic crisis probability.

The Agent then formats the result as a chat-friendly JSON document
that a Steward Agent (or a user via Anvita On) can deliver back to
the requester.

### Why it wins

**It's reproducible.** Every score is byte-for-byte reproducible by
re-running the same cast / forge recipe against the same block. The
same Solidity math in the underlying Skill's test suite validates
every anchor point. No floating-point drift, no off-chain inputs,
no signed transactions.

**It's read-only.** No wallet. No private key. No oracle. The Agent
explicitly refuses to run if `PRIVATE_KEY` is in scope. Every call is
stateless and idempotent — safe to invoke as often as the caller
wants.

**It's composable.** LCP RiskGuard is a thin wrapper around one Phase-1
Skill. It demonstrates the "Skill + Agent = service" pattern that the
hackathon is built to surface. Other Skills could be added to the
same Agent later (gas oracle, price feed, exit-plan recommender).

**It composes for users.** A user can say "watch this token, alert me
when it crosses WATCH" and the Steward Agent routes to LCP RiskGuard,
which scores continuously. That's the kind of long-running,
stateful-adjacent, on-chain-data-monitoring behaviour that the
Pharos Agent Carnival's "Caller Invocation Race" rewards.

### Tech stack

- **Solidity 0.8.31** — re-implements the LCP scoring math in tests
- **Foundry 1.7.1** — `forge`, `cast` (mandatory runtime)
- **Bash + AWK + jq** — the runner in `scripts/run.sh`
- **No JS/TS, no Hardhat, no Truffle, no OpenZeppelin runtime**
- **MIT licensed**

### Networks

- Pharos Mainnet (chain 1672, default)
- Pharos Atlantic Testnet (chain 688689, additional)

Both wired in `assets/networks.json`.

### Test gates (already passing)

```bash
forge test -vvv            # → 7 passed; 0 failed
bash test/test_score.sh    # → 4 passed; 0 failed; 1 skipped
```

The Skill side passes both gates on a real arm64 Termux phone.

---

## Tech stack (form field — short)

```
Solidity 0.8.31 + Foundry 1.7.1 (forge, cast) + Bash + AWK + jq
No JS/TS runtime. No external oracles. Read-only by design.
```

## Chains (form field — short)

```
Pharos Mainnet (chain 1672) — default
Pharos Atlantic Testnet (chain 688689) — additional
```

## License

```
MIT
```

## Demo video URL

```
(YOU fill this in after recording per references/demo-video-script.md)
```

## GitHub repo URL

```
https://github.com/networkbike/lcp-riskguard-agent
```

## Phase 1 Skill repo URL

```
https://github.com/networkbike/LCP
```

## Categories (multi-select; pick the closest)

```
✓ On-chain analytics
✓ DeFi / liquidity
✓ Read-only monitoring / risk
```

## Team info (Solo developer)

```
Solo developer. Designed, implemented, tested, and documented LCP
RiskGuard end-to-end. Phase 1 Skill (networkbike/LCP) is the engine
that this Service Agent wraps. Background in smart-contract
analytics and on-chain data tooling.
```

## Contact email

```
(whatever you use — not stored in this repo)
```

---

## What to do when the form opens

1. Open the form.
2. For each field, copy-paste the answer above.
3. Upload the demo video URL (record it first per
   `references/demo-video-script.md`).
4. Submit.

Total time: ~15 minutes if you've already recorded the video.