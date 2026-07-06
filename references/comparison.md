# Why LCP RiskGuard — comparison to existing Pharos tooling

What already exists in the Pharos Agent ecosystem, and how LCP
RiskGuard differs.

## The existing ecosystem (as of Jul 6, 2026)

### 1. `pharos-skill-engine`

A generic Foundry-based toolkit shipped by the Pharos Network team
themselves. Includes:

- `cast` / `forge` recipe sheets for common operations
- Wallet configuration patterns
- Pre-built references for transfer / airdrop / contract deploy
- The four-check pre-flight for write operations

**What it isn't:** It isn't a domain-specific Skill. It's a
reference / pattern library — useful infrastructure, not an
opinionated answer to a specific user need.

### 2. `pharos-agent-kit`

A TypeScript toolkit providing:

- ERC-20 transfer helpers
- Market data fetchers
- Wallet integration
- (No NFT, no SVG, no liquidity analysis)

**What it isn't:** It isn't a Skill on Anvita Flow. It's a
codebase that other developers can import. To turn it into a
Service Agent, the developer has to do all the wrapping work.

### 3. `x402-pharos` Skill (PharosNetwork/examples/skills)

The official HTTP 402 payment-protocol Skill on Pharos. Lets a
Steward Agent handle micropayments via the x402 protocol.

**What it isn't:** It isn't a domain-specific analytical Skill.
It's a payment infrastructure Skill.

### 4. General Web3 analytics tools (DefiLlama, DexScreener, etc.)

Off-chain UI tools that show TVL, liquidity depth, holder
distribution, etc. Most have no API; the ones that do require
API keys and aren't Pharos-specific.

**What they aren't:** They aren't Skills. They aren't Agents.
They aren't callable from a Steward Agent.

### 5. Generic AI Agent frameworks (LangChain, CrewAI, AutoGen)

Off-chain frameworks for building agents. Useful for prototyping
but not designed for on-chain Skills.

**What they aren't:** They aren't Skills. They aren't Agents.
They aren't bundled with a Pharos-specific runtime.

## Where LCP RiskGuard fits

LCP RiskGuard is **the first read-only, Pharos-native, Anvita
Flow-deployed Service Agent that returns a domain-specific
analytic (liquidity stress) with a calibrated band.**

| Dimension | LCP RiskGuard | pharos-skill-engine | pharos-agent-kit | x402-pharos | DefiLlama |
|---|---|---|---|---|---|
| **Domain** | Liquidity stress on Pharos | Generic EVM ops | ERC-20 transfers | HTTP 402 payments | Cross-chain TVL |
| **Reads on-chain** | ✅ 7 signals | ✅ recipe sheets | ✅ basic | ✅ invoice reads | ✅ cross-chain |
| **Writes on-chain** | ❌ read-only by design | ⚠️ write-capable | ⚠️ write-capable | ⚠️ write-capable | ❌ off-chain only |
| **Anvita Service Agent** | ✅ | ❌ reference only | ❌ codebase | ✅ (different domain) | ❌ SaaS only |
| **Pharos-native** | ✅ | ✅ | ✅ | ✅ | ⚠️ partial |
| **Deterministic score** | ✅ 0–100 + band | ❌ no scoring | ❌ no scoring | ❌ n/a | ⚠️ TVL only |
| **Free during pricing beta** | ✅ | ✅ | ✅ | ✅ | ⚠️ freemium |
| **Source-readable on GitHub** | ✅ | ✅ | ✅ | ✅ | ⚠️ partial |
| **Test gates passing** | ✅ forge 7/7 + shell 4/4 | n/a | n/a | n/a | n/a |
| **Composable with other Skills** | ✅ wraps LCP Skill | ✅ pattern library | ✅ npm package | ✅ payment primitives | ❌ standalone |

The gap LCP RiskGuard fills: **a deployable, callable, read-only
Service Agent that does one thing well — risk-scoring a Pharos
asset — and exposes that scoring through Anvita Flow so any
Steward Agent can use it.**

## Why this matters for the Agent Arena

The Phase 2 Agent Arena rewards:

> "Successful deployment/integration on Pharos"

LCP RiskGuard is **deployed** on Pharos (via the underlying
Skill's on-chain reads), **integrated** with Anvita Flow
(the Service Agent runtime), and **read-only by design**
(no deployer wallet needed). That ticks every box.

Other possible Phase 2 Agents in this ecosystem would have to:

- Add a wallet and become a "swap executor" Agent (different
  category, more competition, more liability)
- Build a multi-Skill Agent (more impressive but more
  failure modes, harder to demo)
- Build a UI / dashboard Agent (different category, judged
  on UX rather than Skills)

LCP RiskGuard picks the **most defensible** niche: a
focused, readable, testable, reproducible Agent that wraps
the Skill you already shipped. The skill quality carries over.

## Risks and limitations of LCP RiskGuard

Honest list of things LCP RiskGuard doesn't do, that other
tools in the ecosystem do:

- **Doesn't trade.** It scores; it doesn't execute. Users must
  decide on their own what to do with the band.
- **Doesn't do cross-chain.** It's Pharos-only. A Steward Agent
  on Ethereum mainnet can't invoke it.
- **Doesn't aggregate.** It scores one asset at a time. A user
  asking "compare 5 tokens" needs 5 separate invocations.
- **Doesn't backtest.** It scores the current state, not the
  historical trajectory. No "this token has been HEALTHY for
  30 days" — just "right now, this band."
- **Doesn't store user state.** Each call is stateless. A user
  asking "is this token improving?" needs to invoke twice and
  compare the scores themselves.

These limitations are deliberate, and they keep the Agent small,
auditable, and safe. Other Agents in the ecosystem might do
these things — that's fine, different Agents for different
needs.

## What if someone builds a competing liquidity-stress Agent?

That's expected and welcome. The Agent Arena is not a
winner-take-all competition. Multiple Agents can compete on:

- Different scoring models (e.g. ML-based vs LCP's
  piecewise-linear)
- Different signal sets (LCP uses 7; a competitor might use 20)
- Different networks (Pharos-only vs multi-chain)
- Different UX (chat-friendly vs dashboard vs API)

LCP RiskGuard's competitive advantages are:

- **Phase 1 pedigree** — the underlying Skill won Phase 1
  (verified by Pharos grader)
- **Reproducibility** — every score is byte-for-byte
  reproducible from public RPC data
- **Safety** — read-only by design, no wallet, no signing
- **Documentation** — 8 reference docs + Agent Card pre-filled

A competitor would need to match at least three of those to
be in the conversation. That's a high bar, and it's good for
the ecosystem.