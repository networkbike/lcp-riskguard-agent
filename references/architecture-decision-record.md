# Architecture Decision Records (ADR)

Records of the major technical choices made for LCP RiskGuard. Each
ADR explains the decision, the alternatives considered, and the
reasoning.

ADR format adapted from Michael Nygard's
[blog post](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).

## ADR-001: Bash + AWK + jq for the runner (not Node.js / Python)

**Date:** 2026-07-05
**Status:** Accepted

### Context

LCP RiskGuard needs a thin wrapper around the LCP CLI. The wrapper
must:

1. Accept inputs (target, network, threshold, drivers flag) from
   the Anvita Flow runtime as environment variables.
2. Invoke the LCP CLI.
3. Filter / reformat the result.
4. Emit JSON on stdout.

Three language options considered: Bash, Node.js, Python.

### Decision

Use **Bash + AWK + jq**.

### Consequences

**Positive:**

- **Zero new dependencies.** Bash, AWK, and jq are already on every
  Unix-like system (and on Termux via `pkg install bash jq`).
  Foundry (which the LCP Skill already requires) is also already
  on PATH.
- **No supply-chain attack surface.** No npm packages, no PyPI
  packages, no requirements.txt. The runner is auditable in
  isolation.
- **Fast startup.** No interpreter spin-up. ~30ms cold start vs
  ~300ms for Node.js.
- **Honest about what it does.** The runner is 80 lines of bash.
  Anyone who reads the file can verify the Agent does exactly what
  it claims.

**Negative:**

- **Less test-friendly than Node/Python.** We compensate with
  `scripts/self-test.sh`, which exercises the runner's defensive
  paths without needing RPC.
- **More verbose for some patterns.** AWK is less ergonomic than
  Python for complex string manipulation. The runner avoids
  complex string manipulation by deferring to jq for JSON
  composition.

### Alternatives considered

**Node.js.** Rejected because:
- Brings a 60MB Node runtime into the deployable artifact.
- Adds npm as a dependency manager, which expands the supply-chain
  surface.
- The runtime is already Foundry (Rust binary); adding Node
  alongside is duplicated weight.

**Python.** Rejected because:
- Termux ships Python but the user has to opt-in (`pkg install
  python`); Bash + jq are preinstalled.
- Same supply-chain concerns as Node.js (pip dependencies).
- The runner does very little computation; Python's strengths
  (numerical libraries, async, type hints) don't apply.

### Reversibility

Low cost. If the Agent grows to need stateful logic, async calls,
or non-trivial computation, we can rewrite the runner in Python
without changing the public Agent Card or input/output contract.

## ADR-002: Read-only by design (no wallet, no signing)

**Date:** 2026-07-05
**Status:** Accepted

### Context

LCP RiskGuard could either:

1. Be a **read-only monitor** that scores liquidity risk.
2. Be a **transaction-signing executor** that scores and then acts
   (e.g., exits a position).

The Phase 2 Agent Arena rewards Agents that demonstrate "practical
use case for AI Agents" and "successful deployment/integration on
Pharos." Both options technically qualify.

### Decision

Read-only by design. No wallet, no signing, no transaction
submission.

### Consequences

**Positive:**

- **No security surface.** An Agent that can't sign can't rug,
  can't be drained, can't be phished. This is the strongest
  possible safety story.
- **Wider addressable user base.** Users can invoke LCP RiskGuard
  without setting up a wallet. No KYC, no signing keys.
- **Composability.** Other Agents (transaction-signing or
  otherwise) can call LCP RiskGuard as a sub-routine without
  inheriting its safety posture.
- **Aligns with campaign spirit.** The Pharos Agent Carnival
  announcement says "production-grade primitives rather than
  one-off demonstrations" — a focused read-only Agent is the
  highest-signal primitive.

**Negative:**

- **Less "wow" factor.** A transaction-execution Agent looks more
  impressive on a demo video. We compensate with a strong
  "honest, focused, reproducible" narrative.
- **Limited "Caller Invocation Race" exposure.** Users invoke
  read-only Agents less often than trading Agents (no
  financial-action hook). We compensate with the multi-skill
  composability story.

### Alternatives considered

**Transaction-signing.** Rejected because:
- Adds significant complexity (balance checks, gas estimation,
  error handling, MEV exposure).
- Brings security surface that would require ongoing audit.
- The Skill is read-only by design; building a transaction
  executor on top of it would be a different product.

**Hybrid (read-only by default, sign-on-request).** Rejected
because:
- Adds complexity without clear benefit.
- "Sign-on-request" is hard to specify without a wallet.
- Easier to build a separate `lcp-exit-plan-agent` later that
  composes LCP RiskGuard's outputs with a swap-router.

### Reversibility

Medium cost. A future `lcp-exit-plan-agent` (separate repo) can
compose LCP RiskGuard's outputs with a transaction-signing flow.
LCP RiskGuard itself stays read-only.

## ADR-003: Wrap one Skill (not multiple)

**Date:** 2026-07-05
**Status:** Accepted

### Context

LCP RiskGuard could either:

1. Wrap **one Skill** (the LCP Skill, `networkbike/LCP`).
2. Wrap **multiple Skills** (LCP + a gas oracle + a price feed +
   an exit-plan recommender, etc.).

### Decision

Wrap exactly one Skill: `liquidity-crisis-predictor`.

### Consequences

**Positive:**

- **Simple to understand.** The Agent does one thing: invoke LCP
  and reformat the result.
- **Simple to test.** The runner has 8 self-test checks; multi-
  Skill Agents would need an order of magnitude more.
- **High composability ceiling.** A multi-Skill Agent is rigid
  about how the Skills are combined. A single-Skill Agent can be
  composed into any workflow by other Agents.
- **Honest signal.** Wrapping one Skill cleanly is a stronger
  proof of concept than wrapping three Skills messily.

**Negative:**

- **Less impressive scope.** A multi-Skill Agent would look more
  ambitious. We compensate with the composability story.
- **Limited functionality.** A user wanting exit-plan
  recommendations can't get them from LCP RiskGuard. They have
  to compose LCP RiskGuard with another Skill.

### Alternatives considered

**Multi-Skill.** Rejected because:
- No other Skills existed at submission time. Composing requires
  Skills to exist.
- The campaign rewards "production-grade primitives," not "kitchen
  sink" Agents.
- We could build supporting Skills ourselves (gas oracle, price
  feed) but each is its own repo and its own test surface.

**Template (no Skills, just an empty wrapper).** Rejected because:
- The Agent Arena is judged on "successful deployment/integration
  on Pharos." An Agent that does nothing doesn't qualify.

### Reversibility

Low cost. Adding Skills to the same Agent is a console-side change
on Anvita Flow; the runner code doesn't need to change. We can
add Skills in v0.2.0 without breaking the v0.1.0 contract.

## ADR-004: Free during pricing beta

**Date:** 2026-07-05
**Status:** Accepted

### Context

The Anvita Flow x402 micropayment protocol is in beta. The
campaign announcement says:

> "Set the price to Free until beta ends to avoid call failures."

Pricing options:

1. **Free** (default, recommended).
2. **Fixed per-call USDC** (e.g., 0.001 USDC / call).
3. **Tiered** (free for HEALTHY band, paid for WATCH / CRITICAL).

### Decision

Set the price to **Free**.

### Consequences

**Positive:**

- **No payment failures during beta.** Aligns with official
  guidance.
- **Higher addressable user base.** A free Agent gets more
  invocations, which helps the "Caller Invocation Race" judging
  criterion.
- **Simpler submit-time validation.** No wallet setup, no
  payment-channel config.

**Negative:**

- **No revenue from the Agent during beta.** We don't have
  monetization anyway, so this is neutral.
- **No incentive to migrate to paid.** When the beta ends, the
  Agent Card can be re-priced; existing users will see a
  notification.

### Alternatives considered

**Tiered pricing.** Rejected because:
- More complex Agent Card configuration.
- May confuse users in the early days of the Agent Arena.
- A flat Free is the simplest possible submission.

**Paid from day one.** Rejected because:
- Direct violation of campaign guidance.
- Higher failure rate in the debug session.

### Reversibility

Trivial. When the beta ends, the price can be updated in the
Agent Card.

## ADR-005: One-sentence SKILL.md description

**Date:** 2026-07-06
**Status:** Accepted

### Context

Anvita's spec says the SKILL.md `description:` field should be
one sentence (the spec example uses one sentence). The initial
draft used a multi-paragraph blockquote (9 lines).

### Decision

Use a single semicolon-separated sentence.

### Consequences

**Positive:**

- **Matches Anvita's Marketplace search model.** Search is
  keyword-based; a one-sentence description is more searchable.
- **Easier to scan.** Judges see the value prop in one breath.
- **Forces conciseness.** The body of SKILL.md has the rich
  detail; the description is a teaser.

**Negative:**

- **Some nuance lost.** The description can't capture every use
  case. The body of SKILL.md picks up the slack.

### Alternatives considered

**Multi-paragraph blockquote (initial).** Rejected because:
- Doesn't match the spec example.
- Adds noise to search results.

**Structured YAML list (e.g. `use_when: [...]`).** Rejected
because:
- Not in the spec.
- Anvita's parser may not support nested keys under `description`.

### Reversibility

Trivial. The description can be edited at any time without
touching the body.