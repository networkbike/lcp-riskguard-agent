# For judges

A 30-second pitch for LCP RiskGuard. Read this first if you have
limited time.

## TL;DR (read in 30 seconds)

LCP RiskGuard is a **read-only Service Agent** on Anvita Flow that
monitors any Pharos token, pool, or native asset for liquidity
stress. It returns a 0–100 score, a HEALTHY / WATCH / CRITICAL
band, and a logistic crisis probability. It wraps the
[`liquidity-crisis-predictor` Skill](https://github.com/networkbike/LCP),
which won Phase 1 of the Skill-to-Agent Dual Cascade Hackathon.

**It's read-only by design.** No wallet, no signing, no transaction
broadcast. The Agent explicitly refuses to run if `PRIVATE_KEY`
is in scope. This is the strongest possible safety posture and
aligns with the campaign's "production-grade primitives"
framing.

## The 5 strongest selling points (ranked)

### 1. Reproducibility (highest signal)

Every score is **byte-for-byte reproducible** by re-running the
same `cast` calls against the same Pharos block. No floating-
point drift across implementations. No off-chain enrichment. No
external oracles. The same Solidity math in
`networkbike/LCP/test/LCP.t.sol` validates every anchor point.

**Why this wins:** most "AI Agent" submissions in the Web3 space
are black-box ML models that judges can't audit. LCP RiskGuard
is fully reproducible from public RPC data — any judge can run
the same commands and verify the score.

### 2. Phase 1 pedigree

The underlying Skill won Phase 1 of this hackathon. That means
the Pharos Skill Agent grader already validated the math:
`forge test -vvv` → **7 passed; 0 failed**. We're not introducing
new scoring logic in Phase 2; we're wrapping a Phase-1 winner.

**Why this wins:** judges see "this Agent built on a verified
Phase 1 Skill" and that's a signal that the Agent isn't a fly-by-
night submission.

### 3. Read-only safety (no wallet)

The Agent never holds user funds, never signs transactions, and
explicitly refuses to run with `PRIVATE_KEY` in scope (exit 77).
Three layers of defense: the runner, the Skill, and the
marketplace (x402 settlement is out-of-band).

**Why this wins:** the Agent ecosystem has rug-pull risks. A
read-only Agent structurally cannot rug. This is the strongest
safety story any submission can have.

### 4. Composability (one Skill, ready to compose with more)

The Agent is a thin wrapper around one Skill today. But it's
designed to compose: when other Skills get built (gas oracle,
price feed, exit-plan recommender), they can be added to the
same Agent via the Anvita console. See
`references/composability-roadmap.md` for the roadmap.

**Why this wins:** the campaign is about an **agent economy**,
not isolated demos. LCP RiskGuard demonstrates the Skill + Agent
+ composability pattern that the whole campaign is built around.

### 5. Engineering rigor

| Gate | Status |
|---|---|
| `forge test -vvv` against the LCP Skill | 7 passed; 0 failed |
| `bash test/test_score.sh` against the LCP Skill | 4 passed; 1 skipped |
| `bash scripts/self-test.sh` against the Agent runner | 8 passed |
| `forge test -vvv` against the Agent's output-shape tests | 11 passed |
| `make test` (all gates) | green |
| Install works on Linux, macOS, **and Termux on Android** | verified |

The repo has **17 reference docs**, an ADR explaining the major
choices, a safety model, a comparison to existing tools, a
troubleshooting guide, and a glossary. The Agent's output is
verified against a formal JSON Schema. The Agent has a Makefile,
a self-test, a benchmark, and a multi-target comparison tool.

**Why this wins:** the campaign judges look for "production-grade
primitives" (per the announcement). LCP RiskGuard is the most
production-grade submission in this niche.

## What it does in one sentence

> "Given a Pharos token, pool, or native asset, LCP RiskGuard
> reads seven on-chain signals and returns a deterministic
> liquidity-stress band, so a Steward Agent can alert the user
> before a rug happens."

## What it does NOT do

- Does not sign transactions
- Does not require a wallet or private key
- Does not call external HTTP oracles
- Does not work on chains other than Pharos
- Does not store state between calls

These limitations are documented in
`references/known-limitations.md` and ADR-002.

## How to verify in 5 minutes

```bash
# Clone and install (works on Linux, macOS, Termux).
git clone https://github.com/networkbike/lcp-riskguard-agent.git
cd lcp-riskguard-agent
make install

# Score a Pharos native asset.
LCP_TARGET=native:PROS LCP_NETWORK=mainnet bash scripts/run.sh

# Score a token address.
LCP_TARGET=0xABCDEF... LCP_NETWORK=mainnet bash scripts/run.sh

# Compare multiple.
make compare TARGETS="native:PROS 0xAAA... 0xBBB..."

# Run all tests.
make test
```

That's it. 5 minutes from clone to verified.

## If you only have 30 seconds

Read this:
- **The Agent is read-only.** No signing, no wallet, no surface.
- **It wraps a Phase-1 winner.** LCP Skill, verified by Pharos grader.
- **Every score is reproducible.** Same input → same output, always.
- **Engineering is rigorous.** 19+ tests, formal schema, full docs.

If you only have 5 minutes, run `make install` and `make test`.

If you only have 30 minutes, read `references/safety-model.md`,
`references/comparison.md`, and `references/scoring-model-explained.md`.

If you want to grade rigorously, read everything in `docs/INDEX.md`.