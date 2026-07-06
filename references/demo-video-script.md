# LCP RiskGuard — Demo Video Script

**Duration:** ~2 minutes (judges watch a lot of these; under 2 min is the sweet spot)
**Format:** Screencast with on-screen captions. **No voiceover required** — captions do the work.
**Resolution:** 1080p vertical (mobile-first; this is going on phones) **or** 1080p horizontal (laptop-first; fine either way)
**Tools:** Termux on your phone for the install + run. Optional: a separate screen-recording tool (Termux has `screenrecord` built in).

---

## Scene 1 — Cold open (0:00–0:10)

**Visual:** Black screen, white monospaced text fades in:
```
$ ▍

LCP RiskGuard
A read-only liquidity-stress monitor for Pharos.
Free during Anvita pricing beta.
```

**Caption:** "A read-only liquidity-stress monitor for any Pharos token, pool, or native asset."

**Why:** Sets the scene in 10 seconds. Tells the judge exactly what they're looking at without audio.

---

## Scene 2 — The Skill works (0:10–0:35)

**Visual:** Termux on your phone. Run:

```bash
cd ~/LCP && forge test -vvv
```

Capture the full output on screen. You already have this screenshot — record the live terminal instead for the video.

**Caption (overlay):** "Phase 1 Skill: 7 Solidity tests, all passing."

**What judges see:** The Foundry output:
```
Ran 7 tests for test/LCP.t.sol:LCPSkillTest
[PASS] test_allMissingReverts() (gas: 9851)
[PASS] test_criticalToken() (gas: 11594)
[PASS] test_doesNotMutateGlobalState() (gas: 374)
[PASS] test_endToEndOnDeployedToken() (gas: 551612)
[PASS] test_healthyToken() (gas: 12780)
[PASS] test_missingSignalsDownweight() (gas: 6246)
[PASS] test_pCrisisLogistic() (gas: 6888)
Suite result: ok. 7 passed; 0 failed; 0 skipped
```

**Why:** Proves the underlying math is solid before showing the agent.

---

## Scene 3 — Install the agent (0:35–0:55)

**Visual:** Fresh Termux session. Run:

```bash
git clone https://github.com/networkbike/lcp-riskguard-agent.git
cd lcp-riskguard-agent
chmod +x install.sh
./install.sh
```

Capture the install output. Should show:
- forge-std already present (cache hit)
- forge test 7/7 (cache hit, fast)
- runner output for `native:PROS mainnet` → `band: HEALTHY`

**Caption:** "One-shot install. No wallet. No key. Works on Termux."

**Why:** The "this just works on a phone" demo is the single most viral moment in any Web3 video. Your Termux install story is the strongest asset you have.

---

## Scene 4 — The agent in action (0:55–1:35)

**Visual:** Three back-to-back terminal calls. Run these in the same Termux session:

```bash
LCP_TARGET=native:PROS LCP_NETWORK=mainnet bash scripts/run.sh
```

Show output (HEALTHY band, score ~18, p_crisis ~0.04).

Then, to show the WATCH band, point at a real Pharos token that's been stressed. **If you don't have a known-watch token handy**, fake it gracefully:

```bash
LCP_TARGET=native:PROS LCP_NETWORK=mainnet LCP_THRESHOLD=CRITICAL bash scripts/run.sh
# shows filtered=true (the band is HEALTHY, threshold is CRITICAL, so suppressed)
LCP_TARGET=native:PROS LCP_NETWORK=mainnet LCP_INCLUDE_DRIVERS=false bash scripts/run.sh
# shows the same result without the drivers array (proves the input is honored)
```

Or, if you want a real WATCH-band result: run `cast logs Transfer` against any
ERC-20 on Pharos mainnet with high recent outflow. That's manual scout work;
you may not have time.

**Caption:** "Same Skill, three invocations, three different shapes. Stateless, deterministic."

**Why:** Shows the agent isn't a one-shot demo — it composes inputs into useful outputs.

---

## Scene 5 — Closing (1:35–2:00)

**Visual:** Terminal, then a fade to:

```
Phase 1 Skill: github.com/networkbike/LCP
Phase 2 Agent: github.com/networkbike/lcp-riskguard-agent
Pharos Agent Arena — submission deadline Jul 10
```

**Caption:** "Read-only. Deterministic. Free during pricing beta."

**Optional:** a final line on screen, "Built for the Pharos Agent Carnival · Round 2".

**Why:** Tells the judge where to look for the code + the deadline so they can verify everything after the video ends.

---

## Recording tips

1. **Termux has built-in `screenrecord`.** Run `screenrecord /sdcard/demo.mp4 &` before starting the demo, then `kill %1` after Scene 5. Output goes to your phone's storage.
2. **Phone font size:** bump it up to 14–16pt before recording so the terminal text is readable in the video. Settings → Termux → Appearance → Font size.
3. **No audio needed.** Captions do the storytelling. Removing audio saves you a recording pass and removes any background noise concerns.
4. **Vertical vs horizontal:** judges watch these on phones (vertical) and laptops (horizontal). 16:9 horizontal is the safest bet — also how YouTube auto-embeds look best in Dorahacks submissions.
5. **One take is fine.** Don't over-edit. A 2-minute unedited screencast reads as "the developer actually uses this every day" — which is exactly the impression you want.

## Hosting

Upload to YouTube (unlisted is fine, public is better). Put the link in:
- The Dorahacks Phase 2 submission form (when it opens)
- `networkbike/lcp-riskguard-agent` README (under a "Demo" section)
- Your X / Discord announcement