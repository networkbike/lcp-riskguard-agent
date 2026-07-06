# Composability roadmap

LCP RiskGuard wraps one Skill today. Future versions (or sibling
Agents) can compose it with other Skills. This document maps the
near-term composable future.

## The pattern

Every Agent in this roadmap is **read-only by design** and
**wraps one or more Skills from the `networkbike/` namespace**.
Agents don't compete; they compose.

```
networkbike/LCP              (liquidity-crisis-predictor Skill)
networkbike/SkillX           (hypothetical, see below)
networkbike/SkillY           (hypothetical, see below)
networkbike/lcp-riskguard    (this Agent; wraps LCP)
networkbike/lcp-exit-plan    (hypothetical Agent; wraps LCP + Skills X+Y)
```

When a Steward Agent needs "exit plan for token X," it routes to
`lcp-exit-plan` which internally invokes `lcp-riskguard` plus
`SkillX` and `SkillY`, returning a single combined recommendation.

## Composable Skills (priority order)

### High priority — these unlock the obvious next moves

#### `pharos-gas-oracle`

Read-only Skill that returns recent gas-price history on Pharos
mainnet and Atlantic testnet, with percentile statistics
(p50, p95, p99 over the last N blocks).

**Why it composes:** exit-plan recommendations need to know
"is gas currently expensive?" A high p99 means the user should
wait or use a low-priority transaction.

**Composability story:** `lcp-exit-plan` calls
`lcp-riskguard` (for liquidity) and `pharos-gas-oracle` (for
gas), combines the answers.

**Effort estimate:** ~2 days. Single cast calls + AWK math.

#### `pharos-token-history`

Read-only Skill that returns a token's recent Transfer events
already-parsed (sender, receiver, amount, timestamp, block),
suitable for time-series analysis.

**Why it composes:** "is this token's outflow velocity getting
worse?" is what LCP scores right now, but a richer Skill could
return the time series directly. Steward Agents could plot it.

**Composability story:** `lcp-riskguard`'s `outflow_velocity`
signal could be replaced with a richer call to
`pharos-token-history` for users who want the raw time series.

**Effort estimate:** ~3 days. cast logs scan + jq parsing.

### Medium priority — composable but not strictly needed for v0.1.0

#### `pharos-pool-comparator`

Read-only Skill that scores N pools side-by-side and returns
a sortable list. Reuses LCP's math under the hood, just changes
the input shape from "one target" to "many targets."

**Why it composes:** "compare these 5 tokens" is a common user
intent. LCP RiskGuard handles one target; this Skill handles N.

**Composability story:** A Steward Agent can route to either
LCP RiskGuard (one target) or `pharos-pool-comparator` (N
targets) based on the user's question.

**Effort estimate:** ~2 days. Bash loop + LCP Skill invocation.

#### `pharos-holder-distribution`

Read-only Skill that returns the holder-concentration curve
for an ERC-20 (Gini coefficient, top-10 percentage, top-50
percentage). LCP uses holder concentration as one of seven
signals; this Skill could expose the raw distribution.

**Why it composes:** Advanced users want to see the curve, not
just one number. LCP RiskGuard's `drivers` array shows
"holder_concentration contributed 0.22" but not the underlying
shape.

**Composability story:** A Steward Agent that wants "show me the
concentration curve" routes to `pharos-holder-distribution`. One
that wants "is this safe?" routes to LCP RiskGuard.

**Effort estimate:** ~2 days. cast calls + percentile math.

### Lower priority — useful but niche

#### `pharos-rpc-health`

Read-only Skill that probes a Pharos RPC endpoint for
availability, latency, and consistency with Pharos Scan.

**Why it composes:** LCP RiskGuard sometimes hits timeouts on
stressed RPCs. A Skill that picks the healthiest RPC out of a
list of public ones would improve robustness.

**Composability story:** Used internally by every other
read-only Skill. Not user-facing.

**Effort estimate:** ~1 day. cast call + awk latency stats.

#### `pharos-tx-decoder`

Read-only Skill that, given a transaction hash, returns a
human-readable summary ("Alice sent 100 PHRS to Bob via the
UniswapV2 router, paying 0.001 PHRS in gas"). Useful for
post-hoc analysis, not for risk-scoring.

**Why it composes:** An exit-plan Agent could show "here's the
transaction you'd execute" without signing it.

**Composability story:** Optional add-on to `lcp-exit-plan`.

**Effort estimate:** ~1 day. cast tx + cast receipt + jq.

## Composable Agents (the same idea, applied to Agents)

### `lcp-exit-plan-agent`

Wraps `lcp-riskguard` + `pharos-gas-oracle` + `pharos-tx-decoder`.
Returns "if you exit token X now, here's the recommended tx,
the gas you'd pay, and the risk level you'd be exiting from."

**When:** v0.3.0 (after Skills 1 and 2 are built).

### `pharos-portfolio-monitor`

Wraps `lcp-riskguard` per token in a user's portfolio list.
Returns the worst band across all watched tokens.

**When:** v0.4.0 (after LCP RiskGuard is stable).

### `pharos-alert-dispatcher`

Wraps `lcp-riskguard` + a webhook / Telegram / Discord notifier.
Sends a notification when a watched token crosses WATCH or
CRITICAL.

**When:** v0.5.0 (after the payment module is fully online —
this is a paid Agent).

## What stays as one Agent

Some capabilities don't need to compose:

- **LCP RiskGuard itself** — wraps exactly one Skill. The
  composability story is about what *can* be added later, not
  what *must* be there at v0.1.0.
- **The Steward Agent** — owned by Anvita / user-facing.
  LCP RiskGuard is a primitive the Steward Agent calls; not
  the other way around.

## Why ship one Skill at a time

Each Skill is its own repo, its own test suite, its own grader
run. Building multiple Skills in parallel before the Agent
Arena deadline is risky:

- Each Skill needs its own forge test suite.
- Each Skill needs its own SKILL.md and Agent Card.
- Each Skill needs its own round of judge review.

Better to ship one Skill well (LCP + LCP RiskGuard) and
extend the family later, when there's bandwidth to do each
Skill justice.

## How a Skill joins the family

The criteria for a Skill to compose with LCP RiskGuard:

1. **Read-only by design.** No signing. No wallet. Same safety
   story as LCP RiskGuard.
2. **MIT licensed.** Same as the rest of the family.
3. **`forge test -vvv` passes.** Same test-gate bar as LCP.
4. **SKILL.md frontmatter has `name:` matching the folder.**
   Same packaging convention.
5. **`assets/networks.json` schema is compatible.** New chains
   can be added; existing entries shouldn't break.

When a Skill meets all five criteria, it can be wrapped into a
new Agent (or added to LCP RiskGuard in a future version).

## Open questions for the future

- **Multi-Agent collaboration.** Should a Steward Agent be able
  to invoke LCP RiskGuard + SkillX in one round-trip? Or should
  the orchestrating Agent call them sequentially? Anvita Flow's
  x402 settlement handles this naturally — each call is its own
  settlement, so there's no batching incentive.
- **Skill versioning.** LCP RiskGuard pins Skill version
  0.2.0 in its output. When the Skill ships 0.3.0, the Agent
  needs to opt in. We could add a `LCP_SKILL_VERSION` env var
  for that.
- **Backward compatibility.** If the Skill contract changes
  (new input field, new output field), does the Agent break?
  Today: yes, any breaking Skill change requires an Agent
  update. That's the right tradeoff for a small, focused
  Agent.

## The TL;DR

LCP RiskGuard ships alone. The roadmap is full of composable
extensions, but each one is its own repo, its own tests, its
own Agent Card. The point isn't to ship everything — it's to
ship the smallest thing that wins, and then extend.