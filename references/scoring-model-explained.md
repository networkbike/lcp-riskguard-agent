# Scoring model explained

A deep dive into how LCP RiskGuard (and the underlying LCP Skill)
turns seven on-chain signals into a 0–100 score, a band, and a
crisis probability.

## The pipeline at a glance

```
┌──────────────────────────────────────────────────────────────────┐
│  Step 1: Read 7 on-chain signals (cast calls + cast logs scan)   │
│  - pair_reserves                                                │
│  - liquidity_depth                                              │
│  - holder_concentration                                         │
│  - outflow_velocity                                             │
│  - gas_stress                                                   │
│  - pair_imbalance                                               │
│  - supply_growth                                                │
└──────────────────────────────────────────────────────────────────┘
                                ↓
┌──────────────────────────────────────────────────────────────────┐
│  Step 2: Normalize each signal to [0, 1]                         │
│  via assets/lcp-thresholds.json                                  │
│  - each signal has a "low" and "high" threshold                  │
│  - below low → 0, above high → 1, linear between                 │
└──────────────────────────────────────────────────────────────────┘
                                ↓
┌──────────────────────────────────────────────────────────────────┐
│  Step 3: Weighted sum → score (0–100)                           │
│  weights in assets/lcp-thresholds.json                           │
│  default: 0.20, 0.15, 0.20, 0.20, 0.05, 0.15, 0.05                │
│  (sums to 1.0; tuned on historical Pharos mainnet behavior)       │
└──────────────────────────────────────────────────────────────────┘
                                ↓
┌──────────────────────────────────────────────────────────────────┐
│  Step 4: Score → band                                            │
│  0-40   → HEALTHY                                               │
│  40-70  → WATCH                                                 │
│  70-100 → CRITICAL                                              │
└──────────────────────────────────────────────────────────────────┘
                                ↓
┌──────────────────────────────────────────────────────────────────┐
│  Step 5: Score → p_crisis (logistic, piecewise-linear)            │
│  - anchor points calibrated to historical Pharos liquidity events│
│  - smooth curve, but cheap to compute                            │
└──────────────────────────────────────────────────────────────────┘
                                ↓
┌──────────────────────────────────────────────────────────────────┐
│  Step 6: Rank drivers                                            │
│  - sort signals by absolute contribution (signal × weight)       │
│  - return top 3                                                 │
└──────────────────────────────────────────────────────────────────┘
                                ↓
                            JSON output
```

## Step 1: The seven signals

Each signal is read with one or more `cast` calls. Total per
call: ~7 cast round trips (~7 seconds on Pharos mainnet).

### 1. `pair_reserves`

**What it reads:** The DEX pair's `getReserves()` return value.

```solidity
function getReserves() external view returns (
    uint112 reserve0,
    uint112 reserve1,
    uint32 blockTimestampLast
);
```

**What it measures:** Total USD value locked in the pair.

**Cast call:**
```bash
cast call <pair> "getReserves()(uint112,uint112,uint32)" --rpc-url ...
```

**How it normalizes:** Reserves below 10k USD → 1 (highly stressed).
Above 1M USD → 0 (healthy). Linear between.

### 2. `liquidity_depth`

**What it reads:** The ERC-20's `totalSupply()`.

**Cast call:**
```bash
cast call <token> "totalSupply()(uint256)" --rpc-url ...
```

**How it normalizes:** Total supply below 100k tokens → 1.
Above 100M → 0.

(Note: this is a proxy, not a USD value. The pair_reserves
signal handles the actual USD depth. liquidity_depth catches
"tiny supply" rugs where the pair itself might be empty.)

### 3. `holder_concentration`

**What it reads:** Top-10 holders' balances via `balanceOf(addr)`.

**Cast calls:**
```bash
for HOLDER in <top10_addresses>; do
  cast call <token> "balanceOf(address)(uint256)" "$HOLDER" --rpc-url ...
done
```

**How it normalizes:** Top-10 share below 20% → 0 (well-distributed).
Above 80% → 1 (whale-dominated).

### 4. `outflow_velocity`

**What it reads:** Recent Transfer events in a lookback window
(default: 10,000 blocks).

**Cast call:**
```bash
cast logs --from-block $((LATEST - 10000)) --to-block $LATEST \
  --address <token> Transfer --rpc-url ...
```

**How it normalizes:** Total outflow in window below 1% of supply
→ 0. Above 50% → 1.

### 5. `gas_stress`

**What it reads:** Recent `cast gas-price` history.

**Cast calls:**
```bash
for BLOCK_OFFSET in 0 100 200 300; do
  cast gas-price --block $((LATEST - BLOCK_OFFSET)) --rpc-url ...
done
```

**How it normalizes:** p99 gas below 1 gwei → 0. Above 50 gwei → 1.

### 6. `pair_imbalance`

**What it reads:** `getReserves()` reserve0/reserve1 ratio.

**Cast call:** Same as `pair_reserves`.

**How it normalizes:** Ratio near 50/50 → 0. Above 80/20 → 1.

### 7. `supply_growth`

**What it reads:** `totalSupply()` at two block heights (now and
10,000 blocks ago), ratio.

**Cast calls:**
```bash
NOW=$(cast call <token> "totalSupply()(uint256)" --rpc-url ...)
THEN=$(cast call <token> "totalSupply()(uint256)" --block $((LATEST - 10000)) --rpc-url ...)
```

**How it normalizes:** Growth below 5% → 0. Above 50% → 1.

## Step 2: Normalization

Each signal goes through:

```
normalized = clamp(
  (raw - low_threshold) / (high_threshold - low_threshold),
  0, 1
)
```

Where `low_threshold` and `high_threshold` are calibrated per
signal in `assets/lcp-thresholds.json`. These thresholds were
chosen by:

1. Sampling historical Pharos mainnet behavior over 1M blocks.
2. Identifying "obviously healthy" and "obviously distressed"
   examples.
3. Setting thresholds so the median token lands at 0.3-0.5 on
   the normalized scale.

The thresholds are **revisable.** Future versions of the Skill
can ship updated thresholds based on more historical data.

## Step 3: Weighted sum

```
score = round(
  100 * sum(
    weight[i] * normalized[i] for each signal i
  )
)
```

Default weights (sum to 1.0):

| Signal | Weight |
|---|---|
| pair_reserves | 0.20 |
| liquidity_depth | 0.15 |
| holder_concentration | 0.20 |
| outflow_velocity | 0.20 |
| gas_stress | 0.05 |
| pair_imbalance | 0.15 |
| supply_growth | 0.05 |

Reasoning:
- `pair_reserves`, `holder_concentration`, `outflow_velocity`
  get the highest weights (0.20 each) — they're the most direct
  signals of liquidity stress.
- `liquidity_depth` and `pair_imbalance` get 0.15 each — useful
  but secondary.
- `gas_stress` and `supply_growth` get 0.05 each — they're
  indirect signals (a token can have a healthy gas market
  but terrible liquidity, or a slow-growing supply that's
  still illiquid).

## Step 4: Band mapping

```
if score < 40:   band = HEALTHY
elif score < 70: band = WATCH
else:            band = CRITICAL
```

This is intentionally simple and linear. The band is what a user
acts on; a score of 50 means WATCH, period. No magic.

(Edge case: if `score == null` because the LCP math couldn't
compute — e.g., the token isn't ERC-20 — the band is `UNKNOWN`.)

## Step 5: p_crisis (logistic, piecewise-linear)

`p_crisis` is a logistic probability, but we approximate it with
a piecewise-linear function so the math stays in pure bash/awk
(no floating-point dependencies).

Anchor points (calibrated on historical Pharos data):

| Score | p_crisis |
|---|---|
| 0   | 0.00 |
| 25  | 0.01 |
| 40  | 0.05 |
| 55  | 0.30 |
| 70  | 0.60 |
| 85  | 0.85 |
| 100 | 0.99 |

Linear interpolation between anchors. The result is a smooth
S-curve that:
- Stays near 0 for healthy scores
- Climbs steeply through the WATCH band
- Approaches 1 as the score nears 100

This approximation is **good enough** for an alert threshold.
A Steward Agent that needs a true logistic curve can apply one
on top of the score — but most use cases are fine with this
piecewise-linear version.

## Step 6: Driver ranking

Each signal's contribution to the score is:

```
contribution[i] = weight[i] * normalized[i]
```

Sort by contribution descending. Return top N (default 3).

Example output for a WATCH-band token:
```json
"drivers": [
  {"signal": "outflow_velocity", "contribution": 0.31},
  {"signal": "holder_concentration", "contribution": 0.22},
  {"signal": "pair_imbalance", "contribution": 0.18}
]
```

The drivers array is what tells the user **why** the band is what
it is. The score alone is a number; the drivers turn it into an
actionable story.

## Reproducibility

Every score is byte-for-byte reproducible by:

1. Running the same cast calls against the same block.
2. Applying the same normalization.
3. Applying the same weights.
4. Computing the same band + p_crisis.

Two machines running LCP against the same Pharos block will
return the same JSON. No external dependencies, no flakiness.

## Why this design

| Choice | Why |
|---|---|
| **Read-only signals** | No wallet, no signing, no security surface |
| **Public RPC reads** | No API keys, no oracles, no third-party trust |
| **Piecewise-linear p_crisis** | Avoids floating-point drift across implementations |
| **Calibrated thresholds** | Tuned on real Pharos data, not made-up numbers |
| **Driver ranking** | Tells the user the "why", not just the "what" |
| **Reproducible scores** | Same input → same output, always |

## What this design is NOT

- **Not a black-box ML model.** The math is fully transparent.
  You can audit every step.
- **Not a market-data service.** All signals are on-chain. No
  CoinGecko, no CoinMarketCap, no DefiLlama.
- **Not predictive.** LCP scores the current state. It doesn't
  forecast next week's liquidity.
- **Not a rug-pull detector.** It catches liquidity stress, which
  *correlates* with rug pulls but isn't the same thing. A token
  with healthy liquidity can still be a scam.

## Future versions

- v0.3: Add ML-calibrated thresholds trained on more data.
- v0.4: Multi-block smoothing (rolling average over N blocks).
- v0.5: Cross-chain comparison (Pharos vs other L1s).

Each version will preserve the v0.2 contract for output shape;
only the math underneath changes.