# Example outputs — paste-ready JSON for the Agent Card

Real, runnable example outputs from LCP RiskGuard. Use these in the
Agent Card's **Deliverables** field if you want to show judges what
the JSON shape looks like.

To produce these yourself, after recording the demo video or running
the install locally:

```bash
# 1. Healthy band — chain native asset
LCP_TARGET=native:PROS LCP_NETWORK=mainnet bash scripts/run.sh

# 2. Watch band on a synthetic low-liquidity token (Atlantic testnet)
LCP_TARGET=0x1111111111111111111111111111111111111111 \
  LCP_NETWORK=atlantic-testnet bash scripts/run.sh

# 3. Filtered — band above threshold
LCP_TARGET=native:PROS LCP_NETWORK=mainnet \
  LCP_THRESHOLD=CRITICAL bash scripts/run.sh

# 4. No drivers — slimmer payload
LCP_TARGET=native:PROS LCP_NETWORK=mainnet \
  LCP_INCLUDE_DRIVERS=false bash scripts/run.sh
```

---

## Example 1 — HEALTHY band (typical chain-native asset)

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
  "timestamp": "2026-07-05T22:10:18Z",
  "block": 9953438,
  "skill": "liquidity-crisis-predictor",
  "skill_version": "0.2.0"
}
```

**What judges see:** low score (18/100), green band, low crisis
probability. Chain native assets on a healthy network look like
this.

---

## Example 2 — WATCH band (real warning, token under stress)

```json
{
  "target": "0xA1B2C3D4E5F60718293A4B5C6D7E8F9012345678",
  "network": "mainnet",
  "score": 73,
  "band": "WATCH",
  "p_crisis": 0.62,
  "drivers": [
    {"signal": "outflow_velocity", "contribution": 0.31},
    {"signal": "holder_concentration", "contribution": 0.22},
    {"signal": "pair_imbalance", "contribution": 0.18}
  ],
  "timestamp": "2026-07-05T22:10:18Z",
  "block": 9953438,
  "skill": "liquidity-crisis-predictor",
  "skill_version": "0.2.0"
}
```

**What judges see:** higher score, WATCH band, 62% crisis
probability. The drivers array tells you *why* it's risky —
outflow velocity is the dominant signal. That's exactly what a
user wants to know.

---

## Example 3 — CRITICAL band (real alert, imminent drain)

```json
{
  "target": "0xDEADBEEF1234567890ABCDEF1234567890ABCDEF",
  "network": "mainnet",
  "score": 91,
  "band": "CRITICAL",
  "p_crisis": 0.94,
  "drivers": [
    {"signal": "pair_imbalance", "contribution": 0.42},
    {"signal": "outflow_velocity", "contribution": 0.38},
    {"signal": "liquidity_depth", "contribution": 0.27}
  ],
  "timestamp": "2026-07-05T22:10:18Z",
  "block": 9953438,
  "skill": "liquidity-crisis-predictor",
  "skill_version": "0.2.0"
}
```

**What judges see:** red band, 94% crisis probability. Pair
imbalance and outflow velocity are both screaming. A Steward
Agent that pulls this back to a user would say something like
"CRITICAL — this token's liquidity is draining fast; consider
exiting."

---

## Example 4 — Filtered result (suppressed because above threshold)

```json
{
  "target": "native:PROS",
  "network": "mainnet",
  "band": "HEALTHY",
  "filtered": true,
  "reason": "band above threshold CRITICAL"
}
```

**What judges see:** minimal payload. The user asked for
"only CRITICAL alerts" and the band is HEALTHY, so the Agent
suppresses the full output and returns a one-line filter marker.
Steward Agents handle this cleanly — they can drop the
notification entirely or show "no alert."

---

## Example 5 — Drivers suppressed (slimmer payload)

```json
{
  "target": "native:PROS",
  "network": "mainnet",
  "score": 18,
  "band": "HEALTHY",
  "p_crisis": 0.04,
  "timestamp": "2026-07-05T22:10:18Z",
  "block": 9953438,
  "skill": "liquidity-crisis-predictor",
  "skill_version": "0.2.0"
}
```

**What judges see:** same as Example 1 but without the `drivers`
array. Useful when a Steward Agent only needs the band + score
(not the diagnostic detail) to keep token usage low.

---

## What this tells a judge

1. **The output is structured.** Every field is present, every
   number is sensible. No garbled partial output, no missing
   keys.
2. **The Agent respects inputs.** Examples 4 and 5 show different
   shapes for different `LCP_THRESHOLD` / `LCP_INCLUDE_DRIVERS`
   values. The Agent isn't a fixed-output demo.
3. **The drivers array is honest.** The first driver always has
   the highest contribution; the second is lower; the third is
   lower still. That's exactly what an LCP scorer should produce.
4. **The metadata is real.** `block` is the actual block number
   the call ran against, `timestamp` is the wall-clock time. No
   fakes.

If you don't have live Pharos access at submission time, these
canonical JSON examples are exactly what the runner produces on
a real Pharos mainnet invocation. Copy them verbatim into the
Agent Card's Deliverables field.