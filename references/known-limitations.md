# Known limitations

A transparent list of things LCP RiskGuard does NOT do. The
goal isn't to apologize — it's to set accurate expectations for
users, judges, and future contributors.

## What this document is

This is the **honest** version of the docs. If `README.md` says
"the runner handles everything you need," this doc says
"everything EXCEPT these things."

We want users to know the limits before they invoke the Agent,
not after.

## Functional limitations

### 1. Pharos-only

LCP RiskGuard works on **Pharos Mainnet (chain 1672)** and
**Pharos Atlantic Testnet (chain 688689)**. It does NOT work on:

- Ethereum mainnet / testnets
- Base, Optimism, Arbitrum, Polygon, BSC, Avalanche
- Solana, Sui, Aptos, Move chains
- Any L1 or L2 that's not Pharos

If you invoke the Agent with a non-Pharos chain name, it fails
with `band: UNKNOWN` (the LCP CLI doesn't know the network).

**Why:** the LCP Skill is Pharos-specific. Building multi-chain
support would require porting LCP's seven signals to each new
chain, which is a separate project per chain.

**Workaround:** invoke LCP RiskGuard separately for each chain,
or build a separate `lcp-riskguard-<chain>-agent` for each.

### 2. ERC-20 + UniswapV2-style AMMs only

The LCP math assumes the target is an ERC-20 token with a
standard UniswapV2-style pair contract. It does NOT support:

- ERC-721 (NFTs) — LCP needs fungible liquidity, which NFTs don't have.
- ERC-1155 (mixed) — same reason.
- Curve / Balancer / UniswapV3 — different pair contracts.
- Native liquidity pools that aren't smart contracts.

For these targets, LCP returns `band: UNKNOWN`.

**Why:** the seven signals assume the standard ERC-20 + pair
contract interface. Curve's `get_balances` and UniswapV3's
`slot0` are different shapes.

**Workaround:** for these targets, build a separate Skill that
handles the contract shape, then a separate Agent that wraps it.

### 3. No transaction signing

LCP RiskGuard never signs transactions. It reads public on-chain
data and returns a band. If a user wants to **act** on the band
(e.g., exit a position), they need to do that separately.

**Why:** see `SECURITY.md` and `references/safety-model.md`. Read-
only is the design choice.

**Workaround:** a future `lcp-exit-plan-agent` could compose
LCP RiskGuard with a swap-router. That's a separate Agent, not
a v0.2 of this one.

### 4. Stateless across calls

Each invocation is independent. If a user wants to track a token
over time, they need to invoke the Agent multiple times and
compare the scores themselves.

**Why:** Anvita Flow's Service Agent runtime doesn't provide
cross-call state. Adding state would require either a database
backend (added complexity) or a separate cache service.

**Workaround:** a Steward Agent that invokes LCP RiskGuard can
keep its own state. The runner's stateless design is fine for
that.

### 5. No historical data

LCP RiskGuard scores the current block. It doesn't show "this
token was at HEALTHY for the past 30 days."

**Why:** computing historical scores requires scanning past
blocks, which is a separate Skill (similar to the
`pharos-token-history` Skill mentioned in
`references/composability-roadmap.md`).

**Workaround:** invoke LCP RiskGuard periodically and store the
results in your own time-series database.

### 6. No cross-token correlation

LCP RiskGuard scores one token at a time. If two tokens are
correlated (e.g., they're both pegged to the same off-chain
asset), the Agent doesn't know that.

**Why:** correlation would require comparing pairs of tokens,
which is a quadratic computation. Better as a separate Skill.

**Workaround:** the `scripts/compare.sh` wrapper runs LCP
RiskGuard against N tokens and sorts by p_crisis. That gives
you a side-by-side comparison, just not a correlation score.

## Operational limitations

### 7. Pricing is Free (during beta)

LCP RiskGuard's Agent Card is set to **Free** during the Anvita
Flow pricing beta. After the beta ends, the price can be
updated to a fixed per-call USDC amount.

**Why:** the Anvita pricing beta is still in development. Setting
a price during beta can cause call failures.

**Workaround:** once the beta ends, update the price via the
Anvita console.

### 8. Termux requires `.deb` install

On Termux on Android, the install pulls the Termux-packaged
Foundry and solc `.deb` files. If you're not on Termux, you can
use the standard foundryup install.

**Why:** Foundry's static linux-arm64 binary has an 8-byte TLS
segment that Bionic Termux rejects. The Termux-built Foundry is
PIE and works natively.

**Workaround:** if you're on a non-Termux Linux distribution
(e.g., Ubuntu on arm64), use the standard foundryup install.

### 9. No built-in wallet

LCP RiskGuard does not include any wallet tooling. To use the
Agent alongside a wallet, the wallet must be in a separate
process.

**Why:** see `SECURITY.md`. No wallet, no signing, no surface.

**Workaround:** the user manages their wallet in a separate
process (e.g., a hardware wallet, MetaMask, etc.).

## Limits on accuracy

### 10. Score is calibrated, not calibrated-precise

The score thresholds and weights are calibrated on historical
Pharos mainnet data. They are NOT precise enough to be used as
the sole input to a trading decision. Use them as one input
among many.

**Why:** see `references/scoring-model-explained.md`. The math
is piecewise-linear, not a learned model. It's a starting point
for human judgment, not a replacement.

### 11. `p_crisis` is a probability, not a guarantee

`p_crisis: 0.94` does NOT mean "94% chance the token will rug
tomorrow." It means "based on the seven signals, the current
state has a 94% probability of being in a state that historically
preceded a liquidity crisis." Use it as a signal, not a forecast.

**Why:** the LCP math captures the *current state*. It doesn't
predict future behavior. A token can be HEALTHY today and rug
tomorrow; nothing in the math can prevent that.

## Documentation limitations

### 12. The docs are written in English

All docs are in English. Translations would be welcome but aren't
on the v0.1.0 roadmap.

### 13. The demo video is in English

Same. The video script (`references/demo-video-script.md`) is in
English; translate before recording if you need a non-English
version.

## What we WON'T add (deliberate design choices)

These are documented in `references/architecture-decision-record.md`
but worth surfacing here:

- **Wallet integration.** See ADR-002. Will never be added.
- **Multi-Skill composition at v0.1.0.** See ADR-003. The Agent
  wraps exactly one Skill. Composition is a v0.3+ feature.
- **Paid pricing during the beta.** See ADR-004. Free until
  Anvita Flow's payment module is fully rolled out.

## Reporting new limitations

If you discover a limitation that isn't listed here, please open
an issue on `networkbike/lcp-riskguard-agent`. We'll either fix
it or add it to this doc.

## When the limitations will change

| Limitation | Status | Target |
|---|---|---|
| Multi-chain support | Planned | v0.3.0 (Q4 2026) |
| Cross-token correlation | Planned | v0.4.0 (Q4 2026) |
| Historical time series | Roadmap | depends on `pharos-token-history` Skill |
| Stateful monitoring | Roadmap | depends on Anvita Flow state support |
| Translations | Roadmap | post-Agent Arena |