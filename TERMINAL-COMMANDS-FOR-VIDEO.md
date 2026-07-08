# LCP RiskGuard — Termux command sequence (Phase 2 demo)

Copy-paste the entire block below into a fresh Termux session.
Each section is one scene of the demo video.

---

## SCENE 1 — Cold open (no commands; just the title)

```
$ ▍

LCP RiskGuard
```

On-screen caption: A read-only Service Agent for the Pharos Agent Arena.
Wraps the Phase 1 winning Skill. Free during Anvita pricing beta.

---

## SCENE 2 — Fresh install (the money shot)

```bash
cd ~
rm -rf lcp-riskguard-agent
git clone https://github.com/networkbike/lcp-riskguard-agent.git
cd lcp-riskguard-agent
./install.sh
```

What the audience will see, in order:

1. `rm -rf lcp-riskguard-agent` — wipes any prior clone
2. `git clone ...` — fresh copy from GitHub
3. `cd lcp-riskguard-agent` — enter the repo
4. `./install.sh` — runs the installer

The installer will:
- Detect Termux → install Foundry `.deb` (Bionic-compatible)
- Find or clone the LCP Skill at `~/LCP`
- Run `forge test -vvv` → 7 tests pass
- Smoke-test the runner against `native:PROS mainnet`
- Run the offline self-test → 8/8 checks
- Run the Agent's own `forge test -vvv` → 11 tests pass
- Print the green "ALL TESTS PASSED" banner

Expected: ~60-90 seconds total.

---

## SCENE 3 — Score a native asset (one-shot invocation)

```bash
cd ~/lcp-riskguard-agent
LCP_TARGET=native:PROS LCP_NETWORK=mainnet \
  bash scripts/run.sh | jq
```

Expected output (~8 seconds):

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
  "timestamp": "2026-07-08T...",
  "block": 9953438,
  "skill": "liquidity-crisis-predictor",
  "skill_version": "0.2.0"
}
```

Hold on this for 3-4 seconds. The JSON is the deliverable.

---

## SCENE 3b — Threshold filter demo (optional, ~10s extra)

```bash
LCP_TARGET=native:PROS LCP_NETWORK=mainnet LCP_THRESHOLD=WATCH \
  bash scripts/run.sh | jq
```

Expected: filtered response, just the band + a `filtered: true` flag.
This demonstrates the noise-reduction feature for Steward Agents.

---

## SCENE 4 — Compare multiple targets (the "summary" feature)

```bash
cd ~/lcp-riskguard-agent
make compare TARGETS="native:PROS 0x1234abcd5678ef901234abcd5678ef901234abcd 0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
```

Expected: a summary object with `total`, `by_band`, `worst`, `best`,
`elapsed_seconds`, plus an array of per-target results sorted by `p_crisis`
descending. (~25 seconds for 3 targets.)

Note: the placeholder addresses will return `band: UNKNOWN` since they're
not real Pharos tokens. That's fine — the demo is about the *comparison*
mechanic, not the addresses. If you have real Pharos addresses you want to
score, swap them in.

---

## SCENE 5 — `make test` (the engineering rigor shot)

```bash
cd ~/lcp-riskguard-agent
make test
```

Expected output:

```
=== Step 1: forge test -vvv against the LCP Skill ===
Ran 7 tests for test/LCP.t.sol:LCPSkillTest
[PASS] test_allMissingReverts() (gas: 9851)
[PASS] test_criticalToken() (gas: 11594)
[PASS] test_doesNotMutateGlobalState() (gas: 374)
[PASS] test_endToEndOnDeployedToken() (gas: 551612)
[PASS] test_healthyToken() (gas: 12780)
[PASS] test_missingSignalsDownweight() (gas: 6246)
[PASS] test_pCrisisLogistic() (gas: 6888)
Suite result: ok. 7 passed; 0 failed

=== Step 2: bash scripts/self-test.sh ===
Results: 8 passed; 0 failed

=== Step 3: forge test -vvv (Agent's own tests) ===
Ran 11 tests for test/LCPRiskGuard.t.sol:LCPRiskGuardTest
[PASS] test_runnerOutput_bandAndScoreConsistent()
[PASS] test_runnerOutput_bandIsValid()
[PASS] test_runnerOutput_blockIsPositiveInteger()
[PASS] test_runnerOutput_driversContainedInZeroOne()
[PASS] test_runnerOutput_hasExpectedFields()
[PASS] test_runnerOutput_pCrisisIsZeroOne()
[PASS] test_runnerOutput_scoreIsZeroHundred()
[PASS] test_runnerOutput_skillNameMatches()
[PASS] test_runnerOutput_skillVersionSemver()
[PASS] test_runnerOutput_thresholdFilter_bandBelowThresholdIsFiltered()
[PASS] test_runnerOutput_thresholdFilter_bandMeetsThresholdIsKept()
Suite result: ok. 11 passed; 0 failed

ALL TESTS PASSED
```

Hold on the green "ALL TESTS PASSED" banner for 2-3 seconds.

---

## SCENE 5b — Privacy defense: PRIVATE_KEY rejection (bonus, ~10s extra)

```bash
cd ~/lcp-riskguard-agent
PRIVATE_KEY=0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef \
  bash scripts/run.sh
```

Expected: a JSON error on stderr, exit code 77:

```json
{"error":"PRIVATE_KEY is set; LCP RiskGuard is read-only by design. Unset PRIVATE_KEY to use this Agent."}
```

This demonstrates the strongest possible safety posture: the Agent
refuses to run if a private key is in the environment. Even if you
accidentally export one, the Agent won't do anything dangerous.

---

## SCENE 6 — Closing card (no commands; just the title)

```
LCP RiskGuard
github.com/networkbike/lcp-riskguard-agent

Built on the LCP Skill that won Phase 1.

Service Agent for the Pharos Agent Arena. Free during Anvita pricing beta.
```

Hold for 5-8 seconds, fade to black.

---

## FULL ONE-PASTE SCRIPT (for the screencast)

If you want to run the whole thing in one continuous session, here's
the entire sequence as a single block. The recording should cover the
text output as it scrolls.

```bash
# === SCENE 2: install ===
cd ~
rm -rf lcp-riskguard-agent
git clone https://github.com/networkbike/lcp-riskguard-agent.git
cd lcp-riskguard-agent
./install.sh

# === SCENE 3: one-shot ===
LCP_TARGET=native:PROS LCP_NETWORK=mainnet \
  bash scripts/run.sh | jq

# === SCENE 3b: threshold filter ===
LCP_TARGET=native:PROS LCP_NETWORK=mainnet LCP_THRESHOLD=WATCH \
  bash scripts/run.sh | jq

# === SCENE 4: compare ===
make compare TARGETS="native:PROS 0x1234abcd5678ef901234abcd5678ef901234abcd 0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"

# === SCENE 5: make test ===
make test

# === SCENE 5b: PRIVATE_KEY defense ===
PRIVATE_KEY=0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef \
  bash scripts/run.sh
```

---

## RECORDING TIPS

### Start recording

```bash
screenrecord /sdcard/lcp-riskguard-demo.mp4 &
```

The `&` puts it in the background. The PID is in `%1`.

### Stop recording

When you're done with the last scene:

```bash
kill %1
```

The file is at `/sdcard/lcp-riskguard-demo.mp4`. Move it off the phone
via any file manager, Google Drive, or `termux-share` (if installed):

```bash
pkg install termux-api
termux-share /sdcard/lcp-riskguard-demo.mp4
```

### Settings that help readability

1. **Font size:** Settings → Termux → Appearance → Font size → 14-16pt
2. **Theme:** dark (works better on YouTube)
3. **Resolution:** landscape 16:9 (1080p)

### Common pitfalls

- **Tap the screen** between scenes to make sure focus is on the terminal, not the IME
- **Press the down-arrow on the IME** to dismiss the keyboard before each scene
- **Don't add voiceover** unless you're confident — captions (in the script) are safer
- **Total target time:** 2:00-2:30 (matches `references/demo-recording-timed.md`)
- **If the install hangs:** Ctrl-C, run `pkg install foundry`, then `./install.sh` again

---

## UPLOAD TO YOUTUBE

1. Pull the .mp4 off the phone (file manager or `termux-share`)
2. Upload to YouTube (public or unlisted)
3. Title: "LCP RiskGuard — Pharos liquidity-stress monitor (Agent Arena Phase 2)"
4. Description: paste from `references/marketing-1-pager.md`
5. Tags: pharos, anvita, ai-agent-carnival, foundry, solidity, defi, liquidity-risk
6. Get the URL, paste it into `references/dorahacks-form-prefill.md` and the
   agent repo's README
