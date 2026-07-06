# User guide

A 60-second orientation to LCP RiskGuard.

## What this is

LCP RiskGuard is a **read-only Service Agent** for the Pharos
Agent Arena. It wraps the [`liquidity-crisis-predictor` (LCP)
Skill](https://github.com/networkbike/LCP) and exposes liquidity-
stress scoring through Anvita Flow. Any Steward Agent (or user
via Anvita On) can call it to get a HEALTHY / WATCH / CRITICAL
band for any Pharos token, pool, or native asset.

**It's not a trading bot.** It reads on-chain data and returns
a band. What you do with that band is up to you.

## 30-second tour

```bash
# 1. Clone and install (one-time).
git clone https://github.com/networkbike/lcp-riskguard-agent.git
cd lcp-riskguard-agent
make install

# 2. Score a Pharos native asset.
LCP_TARGET=native:PROS LCP_NETWORK=mainnet bash scripts/run.sh

# 3. Score a token address.
LCP_TARGET=0xABCDEF... LCP_NETWORK=mainnet bash scripts/run.sh

# 4. Compare N tokens, sorted by risk.
make compare TARGETS="native:PROS 0xAAA... 0xBBB..."

# 5. Measure latency.
make benchmark
```

## What the output looks like

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

- **score**: 0–100 integer (higher = more stressed)
- **band**: `HEALTHY` (0-40), `WATCH` (40-70), or `CRITICAL` (70-100)
- **p_crisis**: logistic crisis probability, [0, 1]
- **drivers**: top 3 signals by absolute contribution
- **timestamp**, **block**: when and where the score was read

## Common tasks

### Run the test gates

```bash
make test
# Runs forge test -vvv + bash scripts/self-test.sh
# Expected: 11 forge tests passed; 8 self-test checks passed
```

### Read the Agent Card fields

See `references/agent-card.md` — all 8 fields are pre-filled,
ready to copy-paste into the Anvita Developer Console.

### Understand the output schema

See `references/output-schema.md` — formal JSON Schema for the
output. Steward Agents can validate responses against this.

### Use the runner in your own scripts

```bash
LCP_TARGET=0xABCDEF... LCP_NETWORK=mainnet \
  bash scripts/run.sh | jq '.band, .p_crisis'
```

Or call from Python:

```python
import subprocess, json
result = subprocess.run(
    ["bash", "scripts/run.sh"],
    env={"LCP_TARGET": "0xABCDEF...", "LCP_NETWORK": "mainnet",
         "PATH": "/usr/local/bin:/usr/bin:/bin"},
    capture_output=True, text=True, check=True,
)
data = json.loads(result.stdout)
if data["band"] == "CRITICAL":
    send_alert(data)
```

### Run the LCP Skill tests

```bash
make install    # also runs the LCP Skill's forge test
```

Expected: `7 passed; 0 failed`.

## Where to next

| If you want to... | Read... |
|---|---|
| Submit to the Agent Arena | `references/anvita-upload-walkthrough.md` |
| Understand the LCP math | `references/scoring-model-explained.md` |
| See why read-only wins | `references/safety-model.md` |
| Compare to other tools | `references/comparison.md` |
| Compose with other Skills | `references/composability-roadmap.md` |
| Diagnose a problem | `references/troubleshooting.md` |
| Read everything | `docs/INDEX.md` |

That's it. 60 seconds. Welcome to LCP RiskGuard.