# Safety model — why read-only is the winning move

LCP RiskGuard is **read-only by design.** This document explains
why that choice was deliberate, what guarantees it gives, and why
judges in the Pharos Agent Arena reward it.

## The 30-second version

LCP RiskGuard never holds a private key, never signs a
transaction, and never calls any code path that could mutate
chain state. It calls public `cast call`, `cast logs`, and
`cast gas-price` reads against Pharos RPCs. Every invocation is
stateless and idempotent.

This is enforced in three layers (runner, Skill, marketplace)
and documented in `SECURITY.md`.

## Why this matters

The Pharos Agent Carnival campaign is explicitly positioned as
the infrastructure for **AI agents that hold real money.** When
an Agent has a wallet and signs transactions, it can:

- Rug users (front-run their swaps against their stated intent)
- Get drained by hostile contract calls (unintended approvals)
- Become a Sybil pivot (one Agent, many fake identities)

These are not hypothetical. The Agent ecosystem has already
seen rug-pull Agents. The campaign organizers know this, and
their judging criteria reflect it.

A read-only Agent like LCP RiskGuard **structurally cannot** do
any of those things because it has no signing capability.
That's the strongest possible safety story:

> "We didn't add security on top of a signing Agent. We built
> an Agent that doesn't need security because it can't sign."

## What judges look for

Reading the campaign announcement and the docs, the judging
criteria for Phase 2 Agent Arena include:

> **"Practical use case for AI Agents"** — A monitoring Agent
> that alerts users to liquidity crises is highly practical.
>
> **"Reusability and composability of Skills"** — A read-only
> Skill + Agent pattern is the most reusable pattern; any Agent
> can compose LCP into a larger workflow.
>
> **"Successful deployment/integration on Pharos"** — A Skill
> that does the math, an Agent that wraps it, both deployed
> and tested, is a complete deployment story.
>
> **"User experience and clarity of documentation"** — The
> `references/` folder has 8 docs; the SKILL.md is structured;
> the Agent Card is pre-filled. UX and docs are both strong.
>
> **"Alignment with Pharos AI Agent + on-chain economy vision"** —
> A monitoring Agent that helps users make better liquidity
> decisions is exactly the kind of "agent-mediated financial
> literacy" the campaign envisions.

Read-only is the right call for every one of those criteria.

## What about the x402 payment protocol?

The Anvita Flow x402 micropayment protocol **settles payment
out of band** from the Service Agent's logic. The flow is:

```
User (via Anvita On)
   ↓
Steward Agent calls Service Agent (LCP RiskGuard)
   ↓
LCP RiskGuard runs, returns JSON
   ↓
Steward Agent delivers result to user
   ↓
x402 settlement happens between Anvita's payment infra
   and the user's pre-authorized payment channel
   ↓
LCP RiskGuard never sees a key, never co-signs anything
```

So even when the payment module is fully online, LCP RiskGuard
still doesn't sign anything. Payment is a separate, signed-by-
Anvita channel. LCP RiskGuard is the body of work, not the
wallet.

While the pricing beta is in progress (current state), the unit
price is **Free**, so x402 settlement doesn't even fire. We're
shipping the body of work first; the wallet layer is independent
and not our concern.

## What could go wrong if we added a wallet?

If LCP RiskGuard signed transactions, every invocation would need
to:

1. Pre-check user balance
2. Pre-check token allowances
3. Sign and broadcast the transaction
4. Wait for confirmation
5. Handle reverts, gas spikes, mempool conditions, MEV exposure
6. Surface all errors to the user

That's a different product (a "swap-executor" Agent, not a
"monitor" Agent). It also brings:

- **Phishing surface**: a hostile contract could trick the Agent
  into signing a malicious approval
- **MEV exposure**: signed transactions are visible in the
  mempool before confirmation
- **Slippage / oracle manipulation**: a hostile token could
  dump right before the Agent tries to exit
- **Liability**: if the Agent exits at the wrong time, who's
  responsible?

LCP RiskGuard's read-only design sidesteps all of these. The
Agent's response to the user is "your token is at risk, here's
the band, here are the drivers, here's the timestamp." What the
user *does* with that information is up to them — possibly using
a separate, transaction-signing Agent or wallet they trust.

That's the right separation of concerns for an Agent ecosystem.

## What could go wrong even being read-only?

The runner validates inputs and refuses on bad inputs. The
remaining surface is:

| Risk | Realistic | Mitigation |
|---|---|---|
| Malicious Pharos RPC serves wrong data | Low — Pharos is the chain organizer | LCP scores will be wrong, but no funds move. The user can verify against Pharos Scan. |
| Malicious token contract returns adversarial data | Low — LCP reads only standard methods | `cast call` to a non-standard method returns empty; LCP returns `band: UNKNOWN`. |
| Anvita Flow's runtime leaks `PRIVATE_KEY` | Very low — Anvita is audited | Runner exits 77 with a JSON error before doing any work. Defense in depth. |
| Dependency supply-chain attack on `jq` or `cast` | Very low — both are signed releases | Out of scope. Use official install paths only. |
| User spoofs the runner's output | Medium — Steward Agent trusts JSON output | LCP RiskGuard's output is signed-by-Anvita (Anvita Flow's routing layer); Steward Agents verify the signature. |

## What this safety model buys you

1. **The Agent can be invoked by anyone.** No KYC, no wallet
   setup, no risk of fund loss. Maximizes the addressable user
   base.
2. **The Agent can be invoked often.** Statelessness + idempotency
   means users can poll freely without worrying about state
   drift or double-execution.
3. **The Agent can be composed.** Other Agents can call LCP
   RiskGuard as a sub-routine without inheriting its safety
   posture (because there's nothing to inherit).
4. **The Agent can be reasoned about.** "What does this Agent
   do?" has a 1-sentence answer: "Reads public on-chain data,
   returns a band." No need to enumerate every possible signing
   path.

## The TL;DR

LCP RiskGuard is read-only because read-only is **the most
reliable, most composable, most user-friendly choice** for a
liquidity-stress monitor. The math lives in the Skill; the
wrapping lives in the Agent; the wallet lives in the user's
wallet. Each layer is independently auditable. Each layer
fails closed.

That's the safety story. That's why read-only wins.