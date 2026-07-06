# Demo recording — frame-by-frame

A 2-minute, 5-scene screencast with exact timings, on-screen text,
and pause points. Designed to be recordable in **one take** with
no editing.

## Setup (before recording)

1. **Phone:** Termux, font size 14-16pt
   (Settings → Termux → Appearance → Font size).
2. **Screen recorder:** `screenrecord /sdcard/demo.mp4 &` then
   `kill %1` after the last scene. Records at native res.
3. **Recording mode:** 1080p horizontal (landscape). YouTube
   auto-embed looks best in 16:9.
4. **Audio:** None. The on-screen captions do the storytelling.
   If you want voiceover, mute the system audio.
5. **Total target time:** 2:00 (under 2:30 if you can).

## Scene 1 — Cold open (0:00–0:08)

**Visual:** Black screen, white monospaced text fades in:

```
$ ▍

LCP RiskGuard
```

**Timing:** Text fades in over 1 second, holds for 4 seconds,
fades to next scene. Total: 5 seconds.

**Caption:** A read-only liquidity-stress monitor for any Pharos
token, pool, or native asset.

---

## Scene 2 — Install (0:08–0:45)

**Visual:** Termux prompt. Run:

```bash
cd ~
rm -rf lcp-riskguard-agent
git clone https://github.com/networkbike/lcp-riskguard-agent.git
cd lcp-riskguard-agent
chmod +x install.sh
./install.sh
```

**On-screen caption (overlay at top of screen):**

```
0:08 — git clone lcp-riskguard-agent
0:18 — install.sh runs
0:30 — Termux foundry .deb auto-installs
0:35 — forge test: 7 passed
0:40 — shell test: 4 passed
```

**What judges see:**
- The clone completes.
- The install fires Step 0 (Termux detected), downloads and
  installs the foundry `.deb`.
- forge test runs and reports 7 passed.
- bash test/test_score.sh runs and reports 4 passed.
- The "LCP RiskGuard: install + smoke test complete" message.

**Hold for 3 seconds** on the "ALL TESTS PASSED" banner.

**Why this scene wins:** the "this just works on a phone"
moment is the strongest visual signal in the whole demo. It's
also the moment that proves the Termux-specific install is
real, not vaporware.

---

## Scene 3 — Score a native asset (0:45–1:05)

**Visual:** Termux prompt. Run:

```bash
LCP_TARGET=native:PROS LCP_NETWORK=mainnet \
LCP_THRESHOLD=HEALTHY \
bash scripts/run.sh | jq
```

**On-screen caption:**

```
0:45 — one-shot invocation
0:55 — JSON output, HEALTHY band
1:00 — score 18, p_crisis 0.04
```

**What judges see:**

```json
{
  "target": "native:PROS",
  "network": "mainnet",
  "score": 18,
  "band": "HEALTHY",
  "p_crisis": 0.04,
  "drivers": [
    {"signal": "outflow_velocity", "contribution": 0.06},
    {"signal": "holder_concentration", "contribution": 0.04},
    {"signal": "pair_imbalance", "contribution": 0.03}
  ],
  ...
}
```

**Hold for 3 seconds** on the JSON output. Then cut to next
scene.

**Why this scene wins:** the JSON output is structured, complete,
and uses real-looking data. It demonstrates the Agent's
contract in one screen.

---

## Scene 4 — Compare multiple tokens (1:05–1:35)

**Visual:** Termux prompt. Run:

```bash
make compare TARGETS="native:PROS 0x1234abcd5678ef901234abcd5678ef901234abcd 0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
```

(Substitute real addresses if you have them; otherwise these
fictional-but-valid 40-char hex strings will return `band: UNKNOWN`
which is fine — the demo is about the *comparison* mechanic.)

**On-screen caption:**

```
1:05 — multi-target comparison
1:15 — sorted by p_crisis, worst first
1:25 — summary stats (by_band, worst, best)
```

**What judges see:**

```json
{
  "summary": {
    "total": 3,
    "by_band": {"HEALTHY": 1, "WATCH": 1, "CRITICAL": 1},
    "worst": {...},
    "best": {...},
    "elapsed_seconds": 23,
    "failed": 0
  },
  "results": [...]
}
```

**Hold for 4 seconds** on the summary.

**Why this scene wins:** shows the Agent is composable (one
call, multiple tokens). Demonstrates the summary feature, which
most users will use day-to-day.

---

## Scene 5 — Make test (1:35–1:50)

**Visual:** Termux prompt. Run:

```bash
make test
```

**On-screen caption:**

```
1:35 — make test
1:45 — forge test: 11 passed
1:48 — bash self-test: 8 passed
```

**What judges see:**

```
Ran 11 tests for test/LCPRiskGuard.t.sol:LCPRiskGuardTest
[PASS] test_runnerOutput_bandAndScoreConsistent()
[PASS] test_runnerOutput_bandIsValid()
...
Suite result: ok. 11 passed; 0 failed; 0 skipped
==============================
Results: 8 passed; 0 failed
==============================
```

**Hold for 2 seconds** on the "ALL TESTS PASSED" banner.

**Why this scene wins:** shows the Agent has its own test suite
on top of the Skill's. 11 forge tests + 8 self-test checks.
This is engineering rigor the judges can grade.

---

## Scene 6 — Closing (1:50–2:00)

**Visual:** Black screen, fade in:

```
LCP RiskGuard
github.com/networkbike/lcp-riskguard-agent

Built on the LCP Skill that won Phase 1.

Read-only by design. Free during Anvita pricing beta.
```

**Hold for 8 seconds**, then fade to black.

**Why this scene wins:** the closing card has everything a
viewer needs to take action. GitHub link, the Phase-1 pedigree
in one line, and the safety story.

---

## Post-production

If you want to edit (optional):

1. **Trim silence** at the start and end. Most screen recorders
   leave 1-2 seconds of black at the edges.
2. **Add chapter markers** in the YouTube description:
   ```
   0:00 — Cold open
   0:08 — Install on Termux
   0:45 — Score a native asset
   1:05 — Compare multiple tokens
   1:35 — make test
   1:50 — Closing
   ```
3. **Title:** "LCP RiskGuard — Pharos liquidity-stress monitor
   (Agent Arena Phase 2)"
4. **Description:** Paste the contents of
   `references/marketing-1-pager.md` here.
5. **Tags:** `pharos`, `anvita`, `ai-agent-carnival`,
   `foundry`, `solidity`, `defi`, `liquidity-risk`.

## Hosting

- **YouTube:** upload as public or unlisted.
- **Mirror:** also host on your own site if you have one.
- **Anvita:** the demo video URL goes in the Agent Card
  (when the form opens).

## Why these specific scenes

I picked these 5 scenes because they maximize **signal density**:

- **Scene 2 (install):** "this works on a phone" → 10x more
  memorable than "this works on a server."
- **Scene 3 (single invocation):** shows the core contract.
- **Scene 4 (multi-target):** shows the composability story.
- **Scene 5 (tests):** shows engineering rigor.
- **Scene 6 (closing):** leaves a clear CTA.

Each scene has **one job**. A judge watching this 2 minutes
walks away knowing: it works on a phone, the JSON is structured,
it scales to N tokens, it has tests, and the GitHub link is
right there.

## What NOT to do

- Don't add background music. It distracts from the JSON.
- Don't add voiceover unless you're confident in your delivery.
  Captions are safer and more inclusive.
- Don't cut to a separate "explainer" screen in the middle of
  the demo. The whole point is to show it running.
- Don't add fancy transitions. A hard cut between scenes is
  fine and feels professional.