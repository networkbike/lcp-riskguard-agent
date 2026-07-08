# Dorahacks Phase 2 submission form — pre-filled answers

When the Phase 2 submission form opens (Dorahacks says "we'll
share the form next week"), this file has every field pre-filled
ready to paste.

## Project name

```
LCP RiskGuard
```

## One-line pitch

```
A read-only Service Agent that monitors any Pharos token, pool,
or native asset for liquidity-stress changes, with deterministic
scoring and chat-friendly output. Free during Anvita pricing beta.
```

## Project description (long)

LCP RiskGuard is a Service Agent for the Pharos Agent Arena
(Phase 2 of the Skill-to-Agent Dual Cascade Hackathon). It wraps
the `liquidity-crisis-predictor` (LCP) Skill — `github.com/networkbike/LCP`,
the Phase 1 winner.

For a given Pharos address or native asset, LCP RiskGuard reads
seven on-chain signals in real time: pair reserves, ERC-20
liquidity depth, holder concentration, recent outflow velocity,
gas-stress proxy, DEX pool imbalance, and supply growth. It
normalizes each signal to `[0, 1]`, weights them per
`assets/lcp-thresholds.json`, sums them into a 0–100 liquidity-
stress score, maps the score to a `HEALTHY / WATCH / CRITICAL`
band, and computes a logistic crisis probability. The Agent then
formats the result as a chat-friendly JSON document that a
Steward Agent (or a user via Anvita On) can deliver back to the
requester.

LCP RiskGuard is **read-only by design**. It never signs a
transaction, never holds user funds, never requires a wallet or
private key, and never calls any external HTTP oracle. The Agent
explicitly refuses to run if `PRIVATE_KEY` is in scope. Every
invocation is stateless and idempotent. This is the strongest
possible safety posture and aligns with the campaign's call for
"production-grade primitives."

### Tech stack

- **Solidity 0.8.31** — re-implements the LCP scoring math in
  tests (`test/LCP.t.sol`)
- **Foundry 1.7.1** — `forge`, `cast`, `anvil` (mandatory runtime)
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

### Why this wins

1. **Reproducibility.** Every score is byte-for-byte reproducible
   from public RPC data. The same Solidity math in tests
   validates every anchor point.
2. **Phase 1 pedigree.** Built on a verified Phase 1 Skill.
3. **Read-only safety.** No wallet, no signing, no surface.
4. **Composability.** Designed to compose with future Skills
   (gas oracle, price feed, exit-plan recommender).
5. **Engineering rigor.** 19+ tests, formal JSON Schema,
   17 reference docs, ADR explaining the major choices,
   offline self-test, latency benchmark, multi-target comparison.

## Categories (multi-select; pick the closest)

```
[x] On-chain analytics
[x] DeFi / liquidity
[x] Read-only monitoring / risk
```

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
https://youtube.com/shorts/PVxDwzwWiSE?si=HDGvRA7mK9NzaPDl
```

(Recorded on the user's phone via Termux `screenrecord`, 2026-07-08.
Format: YouTube Shorts, vertical. Title: "LCP RiskGuard — Pharos
liquidity-stress monitor (Agent Arena Phase 2)".)

## GitHub repo URL

```
https://github.com/networkbike/lcp-riskguard-agent
```

## Phase 1 Skill repo URL

```
https://github.com/networkbike/LCP
```

## Team info

```
Solo developer. Designed, implemented, tested, and documented LCP
RiskGuard end-to-end. Phase 1 Skill (networkbike/LCP) is the
engine that this Service Agent wraps. Background in smart-contract
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