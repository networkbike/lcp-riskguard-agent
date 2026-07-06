# Glossary

Pharos / Web3 / Anvita-specific terms used in this repo. Newcomers
should be able to read the rest of the docs after reading this.

## Pharos ecosystem

### Pharos Network

A modular, full-stack parallel L1 blockchain. Three layers:
L1-Base (data availability), L1-Core (high-throughput consensus),
L1-Extension (special processing networks + restaking). LCP
RiskGuard reads on-chain data from Pharos L1 chains.

### Pharos Mainnet

The primary Pharos L1 chain.

- Chain ID: `1672` (0x688)
- RPC: `https://rpc.pharos.xyz`
- Explorer: `https://pharosscan.xyz`
- Native token: **PROS** (18 decimals)

### Pharos Atlantic Testnet

The Pharos L1 testnet.

- Chain ID: `688689` (0xa8331)
- RPC: `https://atlantic.dplabs-internal.com`
- Explorer: `https://atlantic.pharosscan.xyz`
- Native token: **PHRS** (18 decimals)

### Anvita Flow

The Agent infrastructure layer built by the Pharos Network team.
Hosts Service Agents, routes requests from Steward Agents,
settles payment via the x402 protocol.

- Web app: `https://flow.anvita.xyz/`
- Developer Console: `https://flow.anvita.xyz/service-agents`

### Skill-to-Agent Dual Cascade Hackathon

The 6-week builder event that this repo is submitted to. Two
phases:

- **Phase 1 (Skill Hackathon)** — build a Skill. Submitted Jun 15.
- **Phase 2 (Agent Arena)** — build a Service Agent that wraps
  one or more Skills. Submitted Jul 10.

### Skill (Pharos sense)

A packaged set of on-chain capabilities, defined by a `SKILL.md`
file with YAML frontmatter. The unit of composition in the Agent
Arena. LCP RiskGuard wraps the `liquidity-crisis-predictor` Skill.

### Service Agent

A hosted runtime that wraps a Skill, gives it an identity, and
exposes it as a callable service on Anvita Flow. The unit of
deployment in the Agent Arena. **LCP RiskGuard is a Service
Agent.**

### Steward Agent

A user's personal AI assistant that finds and calls Service
Agents on their behalf. The user-facing layer.

### Agent Card

The public profile of a Service Agent. Includes name,
introduction, capabilities, example tasks, pricing, and runtime
config. Shown in the Anvita Marketplace.

### x402 Protocol

The micropayment protocol that handles per-call billing between
a Steward Agent and a Service Agent. HTTP 402 ("Payment
Required") is the spec the protocol uses; the actual settlement
is out of band.

### Anvita On

The user-facing chat interface at `https://flow.anvita.xyz/agent/chat`.
Users talk to their Steward Agent here.

### Marketplace

The registry of all published Service Agents on Anvita Flow.
Steward Agents search it to find Agents that match a user's
request.

## On-chain concepts

### ERC-20

The fungible token standard on EVM chains. LCP RiskGuard reads
ERC-20 `symbol`, `decimals`, `totalSupply`, and `balanceOf`.

### DEX Pair

A UniswapV2-style liquidity pool contract. Has `getReserves()`
returning `(reserve0, reserve1, blockTimestampLast)`. LCP RiskGuard
reads pair reserves for liquidity depth + imbalance signals.

### `Transfer` event

The ERC-20 event emitted on every token transfer. Topics:
`Transfer(address indexed from, address indexed to, uint256 value)`.
LCP RiskGuard scans recent Transfer events to compute outflow
velocity.

### Block Number

The current height of the Pharos chain. LCP RiskGuard returns
the block number the signals were read against, so users can
reproduce the score by re-running against the same block.

### Native asset

The chain's first-class token (PROS on Pharos mainnet, PHRS on
Atlantic testnet). Distinguished from ERC-20 by the `native:`
prefix in LCP's input: `native:PROS`, `native:PHRS`.

## LCP-specific terms

### Score

A 0–100 integer representing the liquidity-stress level of an
asset. Higher is more stressed. `cast … | jq .score`.

### Band

A categorical classification of the score:

- `HEALTHY` — score 0–40, low stress.
- `WATCH` — score 40–70, moderate stress, watch closely.
- `CRITICAL` — score 70–100, imminent liquidity drain, exit
  recommended.

### `p_crisis`

A logistic probability of imminent liquidity crisis, in `[0, 1]`.
Computed from the score via a piecewise-linear approximation of
a logistic curve. `cast … | jq .p_crisis`.

### Driver

One of the seven on-chain signals that contributes to the score.
The LCP runner returns the top 3 drivers, ranked by absolute
contribution to the score.

### The seven signals (LCP v0.2.0)

| # | Signal | What it reads |
|---|---|---|
| 1 | `pair_reserves` | DEX pair reserve depth |
| 2 | `liquidity_depth` | Total supply of the ERC-20 |
| 3 | `holder_concentration` | Top-10 holder balance / total supply |
| 4 | `outflow_velocity` | Recent Transfer events (large outflows vs inflows) |
| 5 | `gas_stress` | Recent `cast gas-price` history |
| 6 | `pair_imbalance` | Reserve ratio (one-sided drain signal) |
| 7 | `supply_growth` | Total supply change over a lookback window |

Each signal is normalized to `[0, 1]` via `assets/lcp-thresholds.json`,
weighted, summed to the score, then mapped to the band and `p_crisis`.

## Foundational tools

### Foundry

A Solidity development toolchain (`forge`, `cast`, `anvil`,
`chisel`). MIT-licensed, written in Rust. Required runtime for
LCP Skill + LCP RiskGuard.

Install: `curl -L https://foundry.paradigm.xyz | bash && foundryup`

### `cast`

Foundry's read-only / write-capable RPC client. LCP RiskGuard uses
`cast` for `cast call`, `cast logs`, `cast gas-price`, `cast block-number`,
`cast chain-id`.

### `forge`

Foundry's test/build runner. `forge test -vvv` is the canonical
Pharos grading command for Skills.

### `anvil`

Foundry's local testnet node. Useful for offline testing of
LCP-style skills.

### jq

A JSON processor. LCP RiskGuard uses `jq` for JSON composition
(merging LCP output with metadata). Install via your package
manager.

### Termux

A terminal emulator + Linux environment for Android. LCP RiskGuard
runs natively on Termux. The Termux-built Foundry + solc packages
from `packages.termux.dev` are the recommended install path on
Android (they're PIE binaries that Bionic accepts).

## Conventions

### Kebab-case file names

`scripts/run.sh`, `references/agent-card.md`, etc. Folder names
also use kebab-case. Anvita Flow's spec requires the folder name
to match the SKILL.md `name:` field exactly.

### One-sentence description

Anvita's spec says SKILL.md descriptions should be one sentence.
LCP RiskGuard's is one semicolon-separated sentence; rich detail
lives in the SKILL.md body.

### Free during pricing beta

The x402 payment protocol is in beta. LCP RiskGuard's price is
set to Free until the beta ends. After that, the Agent Card can
be re-priced to a fixed per-call USDC amount.

### Read-only by design

LCP RiskGuard never signs a transaction, never holds user funds,
never calls an external HTTP oracle. Documented in SECURITY.md.