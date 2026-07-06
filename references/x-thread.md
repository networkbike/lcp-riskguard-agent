# X / Twitter announcement thread

A 7-tweet thread for announcing LCP RiskGuard on launch day
(Jul 10 or whenever you're ready). Each tweet is under 280
characters and stands alone (in case the thread is broken up
or quoted).

## The thread

### Tweet 1 (hook)

```
🚨 New: LCP RiskGuard — read-only liquidity-stress monitor for
Pharos tokens, pools, and native assets. Free during Anvita
pricing beta.

→ HEALTHY / WATCH / CRITICAL band, score, and crisis probability

github.com/networkbike/lcp-riskguard-agent

#Pharos #Anvita #AIAgentCarnival
```

### Tweet 2 (problem)

```
Liquidity crises on DeFi happen fast. By the time you see the
"rug pull" tweet, the liquidity is already gone.

The question "is this token's liquidity draining right now?"
shouldn't need a wallet or a private key to answer.
```

### Tweet 3 (solution)

```
LCP RiskGuard reads 7 on-chain signals in real time:

→ pair reserves
→ liquidity depth
→ holder concentration
→ outflow velocity
→ gas stress
→ pair imbalance
→ supply growth

Every score is byte-for-byte reproducible from public RPC data.
```

### Tweet 4 (safety)

```
Read-only by design:

❌ No wallet
❌ No signing
❌ No external oracles
❌ No transaction broadcast

The Agent explicitly refuses to run if PRIVATE_KEY is set.
Three layers of defense: runner, Skill, marketplace.
```

### Tweet 5 (pedigree)

```
Built on top of @networkbike/LCP — the Skill that won Phase 1 of
the Skill-to-Agent Dual Cascade Hackathon.

Phase 1 grader already verified the math:
→ forge test: 7 passed, 0 failed
→ shell test: 4 passed, 1 skipped
```

### Tweet 6 (engineering)

```
The Agent itself passes:
→ 11 forge tests (runner output shape)
→ 8 offline self-test checks
→ 17 reference docs
→ formal JSON Schema for output

`make test` is the canonical grading entry point.
```

### Tweet 7 (call to action)

```
Try it now (free during beta):

$ LCP_TARGET=native:PROS LCP_NETWORK=mainnet \
  bash scripts/run.sh

📺 Demo: <demo video URL>
📖 Docs: github.com/networkbike/lcp-riskguard-agent
🛡️ Read-only by design — try without a wallet

#Pharos #Anvita #AIAgentCarnival
```

## Optional reply-tweet (after the thread)

```
If you find a real WATCH or CRITICAL band on a token you're
watching, send the JSON to your Steward Agent — it can route
alerts via webhook, Telegram, or Discord.

LCP RiskGuard is the monitor. The exit-plan Agent is a separate
project. Composable by design.
```

## Tips for posting

1. **Best time to post:** Tue-Thu, 9-11am in your target timezone.
   B2B/crypto audience is most active then.
2. **Pin the thread** to your X profile for the first week.
3. **Quote-tweet the thread** with a one-line "we shipped this"
   message from your main account.
4. **Tag relevant accounts:** `@Pharos_Network`, `@AnvitaFlow`
   (if exists), `@DoraHacks`, judges if you know their handles.
5. **Cross-post to Discord:** `#pharos`, `#skill-submission`.
6. **Post on Pharos' forum** if there's a project showcase
   thread pinned there.

## What NOT to do

- Don't claim it won the Agent Arena before the judges have
  announced winners (Jul 22-ish).
- Don't promote it as a "trading bot" — it's a monitor.
- Don't link to the LCP repo as the primary submission; LCP is
  Phase 1. The Agent is Phase 2.

## Variations

### 1-line version (if thread isn't an option)

```
LCP RiskGuard is a read-only liquidity-stress monitor for
Pharos tokens. Wraps the LCP Skill that won Phase 1. Free during
Anvita pricing beta. github.com/networkbike/lcp-riskguard-agent
```

### Long-form version (if you want a blog post)

See `references/marketing-1-pager.md` — it's structured as a
blog post you can paste directly into a Medium / Mirror / Notion
post.