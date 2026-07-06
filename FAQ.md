# Frequently Asked Questions

Anticipated questions from judges, Anvita Flow reviewers, and users.

## General

### What does LCP RiskGuard do?

LCP RiskGuard is a read-only Service Agent that monitors any
Pharos token, pool, or native asset for liquidity-stress changes.
It returns a 0–100 liquidity-stress score, a HEALTHY / WATCH /
CRITICAL band, and a logistic crisis probability. Built on top of
the `liquidity-crisis-predictor` (LCP) Skill — `networkbike/LCP`,
the Phase 1 winner of the Skill-to-Agent Dual Cascade Hackathon.

### How is this different from just running `score.sh` directly?

Three things:

1. **It's callable.** A Steward Agent (or a user via Anvita On)
   can invoke it without knowing about Foundry, cast, jq, or
   the LCP CLI. The Agent Card is the integration surface.
2. **It's standardized.** Inputs, outputs, error handling, and
   thresholds are documented and tested. A Steward Agent knows
   exactly what to expect from `LCP RiskGuard` and how to interpret
   the result.
3. **It's multi-Skill-ready.** When more Skills get built (gas
   oracle, price feed, exit-plan recommender), they can be added
   to the same Agent via the Anvita console without rewriting
   the integration.

### Why "RiskGuard" instead of just "Score"?

Two reasons:

1. **The output is a band, not a number.** Calling it "Score"
   suggests a single number is the answer; LCP RiskGuard returns
   a band (HEALTHY / WATCH / CRITICAL) plus a score plus a
   crisis probability plus drivers. "RiskGuard" emphasizes the
   band classification — that's what a Steward Agent or user
   actually acts on.
2. **It's continuous-monitoring-shaped.** "Guard" implies
   monitoring over time, which is the most common pattern
   ("watch this token, alert me when it crosses WATCH"). A pure
   "Score" name would imply one-shot invocations.

## Technical

### Why Bash + AWK + jq instead of Node.js / Python?

- **No npm/PyPI attack surface.** LCP RiskGuard has zero
  third-party code dependencies — only the binaries on PATH.
- **Foundry is already required** (it's the LCP Skill's runtime).
  Adding bash + jq + awk costs nothing on systems that already
  have them.
- **The math lives in the Skill, not the Agent.** The Agent is
  a thin wrapper that adds ~80 lines of bash. If the math ever
  moves to Python or Rust, the Agent doesn't have to change.

### Why not call the LCP Skill via HTTP / RPC?

- The LCP Skill is a CLI, not an HTTP service. There's no server
  to call.
- Anvita Flow's hosted runtime bundles the Skill code directly,
  so calling `examples/score.sh` from the runner is the
  lowest-latency path (no network hop in the Skill call).
- If the LCP Skill later exposes an HTTP endpoint, the runner
  can be swapped to a curl call without changing the Agent's
  public input/output contract.

### What happens if the Pharos RPC is down?

The runner calls into the LCP CLI, which calls into `cast`. If
Pharos RPC is unreachable, `cast` returns a network error and the
runner surfaces it as a JSON error on stderr with exit code 70
(`EX_SOFTWARE` per BSD sysexits). The Steward Agent should treat
this as "RPC down, retry later" and not as "skill broken."

### What happens if the LCP Skill version changes?

If `networkbike/LCP` is updated to a new version, the runner still
works as long as the CLI contract is unchanged (target on argv,
network on argv, JSON on stdout). If the contract changes, the
runner needs an update too. The runner pins `skill_version:
"0.2.0"` in its output JSON so the Agent Card can show users
which Skill version they're getting.

### What if a user passes an unsupported chain (e.g. Ethereum mainnet)?

The runner passes the network name to the LCP CLI. LCP looks up
the network in `assets/networks.json`. If the network is not
found, LCP returns a friendly error and the runner surfaces it.
The runner does not need to special-case non-Pharos chains.

### What if a user passes a malformed address (e.g. `0xZZZ…`)?

The LCP CLI validates the address format up front and returns
exit code 64 with a JSON error. The runner forwards this
verbatim. The Steward Agent should surface the error to the
user without retrying.

## Operational

### How do I run it locally?

```bash
git clone https://github.com/networkbike/lcp-riskguard-agent.git
cd lcp-riskguard-agent
chmod +x install.sh
./install.sh
```

This installs Foundry + jq, clones the LCP Skill, runs the
underlying Skill's tests, and runs the runner against
`native:PROS mainnet`.

### How do I invoke it once installed?

```bash
LCP_TARGET=0xABCDEF0123456789ABCDEF0123456789ABCDEF01 \
LCP_NETWORK=mainnet \
bash scripts/run.sh
```

The output is JSON on stdout.

### How do I publish to Anvita Flow?

See `references/anvita-upload-walkthrough.md` — 7-screen
walkthrough. The short version:

```bash
cd .. && zip -r lcp-riskguard-agent.zip lcp-riskguard-agent/
# upload to https://flow.anvita.xyz/service-agents
```

### What's the upload zip structure?

`SKILL.md` at `lcp-riskguard-agent/SKILL.md` inside the zip (NOT
at the zip root). Folder name must match the `name:` field in
the SKILL.md frontmatter. The full structure is documented in
the upload walkthrough doc.

### How do I enable CI on the repo?

Generate a fresh PAT with `repo + workflow` scope, copy the
content of `.github/CI.md` into `.github/workflows/ci.yml`, and
push. The CI covers forge test against the underlying Skill +
agent smoke test + zip structure lint.

### Why isn't CI on by default?

The Phase-1 PAT for this project has `repo` scope only, not
`workflow`. Pushing `.github/workflows/*.yml` requires the
`workflow` scope. The CI workflow content is preserved in
`.github/CI.md` so anyone with a workflow-scoped PAT can enable
it in one copy-paste.

## Hackathon-specific

### Which phase of the hackathon is this for?

**Phase 2: Agent Arena.** Submission deadline Jul 10, 6 PM HKT
(10:00 UTC).

### What's the prize pool?

The Phase 2 Agent Arena awards **25,000 PROS** to selected
winners. The Phase 1 Skill Hackathon (where the underlying LCP
Skill won) had a 20,000 PROS pool across 40 winners.

### Why didn't you just submit the Skill directly?

Phase 1 is the Skill. Phase 2 is the Agent. They are scored
separately by the Anvita Flow / Pharos grader. A Skill alone
isn't discoverable to end-users; an Agent is.

### Why not build a more sophisticated Agent (multi-skill, with
wallet, with transactions)?

Three reasons:

1. **Read-only is a deliberate choice.** Adding a wallet and
   transaction signing to LCP RiskGuard would make it a
   different product (a liquidity-drain trader, not a
   liquidity-drain monitor). The Skill is read-only by design;
   the Agent preserves that.
2. **Composition over complexity.** A Service Agent that wraps
   one Skill cleanly is more composable than one that wraps many
   Skills messily. Other Skills can be added later.
3. **Judge signal.** The Pharos / Anvita Flow campaign explicitly
   rewards "production-grade primitives rather than one-off
   demonstrations" (from the campaign announcement). A small,
   focused, reliable Agent is the highest-signal submission.

### Will you add transaction support in a future version?

Possibly, behind a separate Service Agent. LCP RiskGuard will
stay read-only. A future `lcp-exit-plan-agent` or similar could
chain LCP RiskGuard's outputs to a swap-router, but that's a
different Agent, not an upgrade to this one.

## Licensing

### What license is this under?

MIT. See `LICENSE`. You can fork, modify, and redistribute,
provided you keep the copyright notice and don't hold the
original authors liable.

### Can I run this commercially?

Yes, under the MIT license. There's no commercial restriction.
The Skill + Agent can power a paid product, an internal tool, or
a hosted marketplace service. Attribution is appreciated but not
required.

### Will there be a hosted version?

Not from me. The design is meant to be self-hosted: Anvita
Flow's Marketplace will host the public version for free
during the pricing beta. Anyone can fork the Agent and run
their own instance on Anvita or another agent runtime.