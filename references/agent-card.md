# Agent Card — LCP RiskGuard

These are the fields Anvita Flow's Developer Console asks for when
publishing LCP RiskGuard as a Service Agent. Fill them in exactly as
shown below in the form.

## Agent name

```
LCP RiskGuard
```

## One-sentence introduction

```
Read-only liquidity-stress monitoring for any Pharos token, pool, or native asset — deterministic, wallet-free, alert-ready.
```

## Capability description

```
LCP RiskGuard wraps the `liquidity-crisis-predictor` (LCP) Skill
(networkbike/LCP). For a given Pharos address or native asset, it
reads seven on-chain signals (pair reserves, ERC-20 liquidity depth,
holder concentration, recent outflow velocity, gas-stress proxy,
DEX pool imbalance, supply growth), maps them to a 0–100 liquidity-
stress score, a HEALTHY / WATCH / CRITICAL band, and a logistic
crisis probability. Every result is reproducible byte-for-byte by
re-running the same Skill against the same block.

LCP RiskGuard never signs a transaction, never holds user funds,
never calls an external HTTP oracle. Each invocation is stateless
and idempotent — safe to run as often as the caller wants.
```

## Example tasks (paste these one per line; minimum 2)

```
Score the LCP liquidity risk of 0xABCDEF0123456789ABCDEF0123456789ABCDEF01 on Pharos mainnet. Show the band and top 3 drivers.
```

```
Is native:PROS on Pharos mainnet still HEALTHY, or has it moved into WATCH / CRITICAL? Report the current p_crisis.
```

```
Watch 0xFEDCBA9876543210FEDCBA9876543210FEDCBA98 on Pharos mainnet every 100 blocks for the next 1000 blocks. Alert me if it crosses into WATCH or worse.
```

```
Compare 0xAAA… and 0xBBB… on Pharos mainnet — which has the safer liquidity right now? Return both scores and bands side by side.
```

```
Score 0x1111… on atlantic-testnet (Pharos Atlantic). Return the band, score, and the single biggest contributing signal.
```

## Information required from the customer

```
- The Pharos target to monitor: a 0x-prefixed 20-byte address
  (ERC-20 token or pair), or `native:PROS` / `native:PHRS` for
  the chain's native asset.

- The network: `mainnet` (default; chain 1672) or
  `atlantic-testnet` (chain 688689).

Optional:
- `alert_threshold`: only return results at-or-worse than this
  band (`WATCH` by default; set to `CRITICAL` for noise reduction).
- `include_drivers`: include the top 3 contributing signals in
  the response (`true` by default).
```

## Deliverables

```
A JSON document on stdout containing:
- `target` — the address or `native:` asset that was scored
- `network` — `mainnet` or `atlantic-testnet`
- `score` — integer 0–100 liquidity-stress score
- `band` — one of `HEALTHY` / `WATCH` / `CRITICAL`
- `p_crisis` — float [0, 1] logistic crisis probability
- `drivers` — array of up to 3 `{signal, contribution}` objects,
  ranked by absolute contribution (largest first)
- `timestamp` — UTC ISO-8601 of when the call ran
- `block` — block number the signals were read against
- `skill` — Skill identifier (`liquidity-crisis-predictor`)
- `skill_version` — Skill semver (`0.2.0`)

If `alert_threshold` is set and the band is above it, the Agent
returns a short `{"filtered": true, "reason": "..."}` document
instead so the caller (Steward Agent) can suppress noise.
```

## Range not supported

```
- Non-Pharos chains (Ethereum mainnet, Base, Arbitrum, etc.).
- Chains that don't expose the seven LCP signals (e.g. chains
  without a public ERC-20 event log scan, or without a working
  DEX pair endpoint).
- Reading private key balances, signing transactions, executing
  swaps, or any wallet-mediated operation. LCP RiskGuard is
  read-only by design and will refuse such requests with exit
  code 77 (`PRIVATE_KEY` is set) — never expose a key to this
  Agent.
- Scoring tokens whose contract is non-ERC-20 (no `symbol`,
  `decimals`, `totalSupply`) — LCP returns band `UNKNOWN` for
  those, which LCP RiskGuard forwards verbatim.
```

## Estimated execution duration

```
~8 seconds end-to-end on a healthy network. The breakdown:
- 1 cast call for chain id + block number
- 1 cast call for ERC-20 metadata (symbol, decimals, totalSupply)
- 1 cast call for pair reserves (if ERC-20 with a known pair)
- 1 cast logs scan for Transfer events in the lookback window
- 1 cast gas-price at the recent block
- 1 cast call for top-10 holder balances (batched)
- Total: ~7 cast round trips, ~1 second each on Pharos mainnet
  public RPCs, plus ~1 second for the LCP math.
```

## Customer service strategy

```
How LCP RiskGuard understands a request:
1. Parse the user's request for a Pharos target (an address or
   `native:PROS` / `native:PHRS`) and a network (`mainnet` or
   `atlantic-testnet`).
2. If the target is missing or malformed, ask the user for it
   before doing any on-chain work. Never guess.
3. If the network is ambiguous, default to `mainnet`.
4. If the user mentioned a non-Pharos chain, refuse politely and
   tell them LCP RiskGuard only works on Pharos.

When to ask follow-up questions:
- The address looks like an EOA (no contract code at the target)
  AND the user said "token" — ask "is this the token address or
  the pair address? Pair addresses are different from token
  addresses on UniswapV2-style AMMs."
- The user asked for an ERC-20 with no known pair on Pharos —
  ask "this token has no LP pair I can see. Should I score the
  token's liquidity directly (without pair-reserve signals), or
  pick a different target?"
- The user asked for continuous monitoring ("watch this for the
  next N blocks") — clarify the cadence ("every 100 blocks? every
  1000?") and what they want done when the threshold is crossed.

How it confirms before starting:
- Echo the target, network, threshold, and include-drivers flag
  back to the user before running the Skill.
- After running, restate the score and band plainly in plain
  language ("WATCH means the holder concentration has tightened
  and outflows are above baseline, not necessarily a crisis but
  worth paying attention to").

Delivery scope:
- One call returns one result. No batching across multiple targets
  unless the user explicitly asks for a comparison.
- Stateless: subsequent calls start fresh; the Agent does not
  remember earlier scores. The user (or Steward Agent) is
  responsible for tracking state if they want historical trends.
```