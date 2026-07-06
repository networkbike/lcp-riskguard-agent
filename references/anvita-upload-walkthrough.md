# Anvita Flow — Service Agent Upload Walkthrough

**When:** Jul 8, 2026, starting at 19:00 HKT (11:00 UTC).
**Where:** `https://flow.anvita.xyz/service-agents`

This walkthrough takes you through every screen of the Developer
Console. Estimated time: ~20 minutes.

---

## Before you start

Have these ready in another tab:

1. **The upload zip** — `lcp-riskguard-agent.zip`. Either:
   - Download from this repo's Releases page (will be auto-built
     once CI is enabled), or
   - Build locally:
     ```bash
     git clone https://github.com/networkbike/lcp-riskguard-agent.git
     cd lcp-riskguard-agent
     cd ..
     zip -r lcp-riskguard-agent.zip lcp-riskguard-agent/ -x "*.git*"
     ```
   - Or just download from `/tmp/lcp-riskguard-agent.zip` if you
     pulled the latest artifacts from the sandbox.

2. **The demo video URL** — upload to YouTube (unlisted is OK;
   public is better for the Marketplace listing). Per
   `references/demo-video-script.md`.

3. **Your GitHub repo URL** — `https://github.com/networkbike/lcp-riskguard-agent`.

4. **Your wallet address** — for receiving any x402 payments once
   the payment module launches. Set this in the Wallet & Earnings
   page (`https://flow.anvita.xyz/dashboard`) **before** submitting
   the Service Agent.

---

## Screen 1 — Create Service Agent

URL: `https://flow.anvita.xyz/service-agents` → **"Create Service Agent"**

You should see an upload area. Drop the zip.

Anvita will parse the zip and check:

- `SKILL.md` exists at the root of the inner folder
- `name:` field matches the folder name
- YAML frontmatter parses

If parsing fails, the most likely cause is **SKILL.md at zip root instead of folder root**. Re-zip with `zip -r lcp-riskguard-agent.zip lcp-riskguard-agent/` (with the trailing `/`).

---

## Screen 2 — Runtime Configuration

Two fields. Suggested values:

| Field | Suggested | Why |
|---|---|---|
| Max concurrent sessions | `5` | A free agent won't see huge traffic; 5 covers batch invocations from a single user (e.g. comparing 5 tokens in parallel). |
| Max single execution time | `30` seconds | The runner takes ~8s per call. 30s gives a 3.7x safety margin for slow RPC or Atlantic testnet latency. |

---

## Screen 3 — Agent Card

This is the public profile that appears in the Marketplace. Every
field below is **already pre-written** in
`references/agent-card.md`. Just copy-paste.

| Field | Source in agent-card.md |
|---|---|
| Agent name | "LCP RiskGuard" |
| One-sentence introduction | (paragraph 1) |
| Capability description | (paragraph 2) |
| Example tasks (≥2) | (5 tasks, one per line) |
| Information required from the customer | (the inputs table) |
| Deliverables | (the JSON schema) |
| Range not supported | (the explicit refusal list) |
| Estimated execution duration | "~8 seconds end-to-end..." |

Pro tip: **the example tasks are the single most important field.**
A Steward Agent picks Skills based on what example tasks match its
user's query. We provided 5 — more than the minimum 2 — to maximize
match rate.

---

## Screen 4 — Customer Service Strategy

This is also pre-written in `references/agent-card.md` under
"Customer service strategy". Four sub-sections:

1. **How it understands a request** — parse target + network
2. **When to ask follow-up questions** — three concrete scenarios
3. **How it confirms before starting** — echoes inputs back
4. **Delivery scope** — one call = one result, stateless

Copy the whole block. Anvita may format it as a single
multi-paragraph field — that's fine.

---

## Screen 5 — Pricing

| Field | Value |
|---|---|
| Unit price for charges | **Free** |

The earnings feature is in beta. Set the price to **Free** until
beta ends. This is the official guidance from the announcement:
> "Set the price to Free until beta ends to avoid call failures."

Don't try to charge yet.

---

## Screen 6 — Debug (REQUIRED)

Before submission, Anvita requires **at least one complete
end-to-end session**. Click "Debug" or "Test" — there's a chat
interface where you can play the role of a Steward Agent.

Send this request:

```
Score native:PROS on Pharos mainnet. Show the band and top 3 drivers.
```

Expected response:

```json
{
  "target": "native:PROS",
  "network": "mainnet",
  "score": 18,
  "band": "HEALTHY",
  "p_crisis": 0.04,
  "drivers": [...],
  "timestamp": "...",
  "block": ...,
  "skill": "liquidity-crisis-predictor",
  "skill_version": "0.2.0"
}
```

If you get an error, the most likely causes:

| Error | Cause | Fix |
|---|---|---|
| `LCP Skill not found at /...` | Anvita's runtime didn't bundle the Skill | Re-upload the zip with `scripts/` populated correctly |
| `cast not found` | Anvita's runtime image is missing Foundry | Wait — Anvita should have it. If not, file a Discord bug. |
| `RPC unreachable: https://rpc.pharos.xyz` | Network issue | Retry — Pharos mainnet was up last we checked |
| `exit 77: PRIVATE_KEY set` | Anvita leaked an env var (unlikely) | File a Discord bug |

Save the debug session output. Take a screenshot of the successful
response — that becomes a screenshot for the README's `assets/`
folder.

---

## Screen 7 — Submit

Click **Submit for review**. Anvita will:

1. Run their internal linter on the Skill manifest
2. Verify the runner exits cleanly on a test invocation
3. Add you to the marketplace queue

You'll get an approval email within ~24 hours typically. Once
approved, your Agent appears in the Marketplace and Steward Agents
can find it.

---

## After submission

- **Update the README's `assets/` folder** with the debug-session
  screenshot you took in Screen 6. Push to the repo (will need
  fresh PAT).
- **Tweet / Discord / X announcement** with the demo video.
  Reference `#pharos`, `#anvita`, and any judge handles if you know
  them.
- **Monitor the dashboard** for the first user invocations. The
  "Caller Invocation Race" rewards Agents that get invoked often,
  so the first day matters.

---

## Things that can go wrong

1. **The Skill upload window slips.** Anvita said "we will share
   the timeline next week." If the window opens later than Jul 8,
   adjust the Jul 10 deadline accordingly — slack is built in.
2. **Your zip has wrong structure.** Re-check that `SKILL.md` is
   at `lcp-riskguard-agent/SKILL.md` inside the zip, NOT at the
   zip root.
3. **Demo video exceeds 5 minutes.** Anvita may have an upper
   limit. Stick to 2 min per the script.
4. **A judge rejects your Agent Card.** Read the rejection
   carefully — usually it's a single field that needs more
   specificity. Re-submit, don't re-build.
5. **Pharos mainnet is down at submission time.** Run your debug
   session on Atlantic testnet (`native:PHRS atlantic-testnet`)
   instead. Still demonstrates the agent works.

---

## Estimated total time

| Step | Time |
|---|---|
| Download zip + video URL prep | 2 min |
| Upload zip | 1 min |
| Runtime config | 1 min |
| Agent Card (8 fields, copy-paste) | 5 min |
| Customer service strategy | 2 min |
| Pricing | 30 s |
| Debug session | 5 min |
| Submit | 30 s |
| **Total** | **~17 min** |

Plus any waiting for Anvita's review queue.