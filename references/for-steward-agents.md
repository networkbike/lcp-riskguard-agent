# For Steward Agents — calling LCP RiskGuard

If you're a Steward Agent on Pharos and you want to call LCP
RiskGuard, this is the API doc. It documents the input/output
contract from the caller's perspective.

## The call

LCP RiskGuard is invoked by Anvita Flow's routing layer when a
Steward Agent matches it to a user request. The inputs come in
as env vars to the runner (`scripts/run.sh`):

| Env var | Required | Type | Example |
|---|---|---|---|
| `LCP_TARGET` | yes | string | `0xABCDEF...` or `native:PROS` or `native:PHRS` |
| `LCP_NETWORK` | yes | enum | `mainnet` (default) or `atlantic-testnet` |
| `LCP_THRESHOLD` | no | enum | `HEALTHY` (default, no filter), `WATCH`, or `CRITICAL` |
| `LCP_INCLUDE_DRIVERS` | no | bool | `true` (default) or `false` |

Anvita Flow automatically sets these env vars before invoking
the runner, based on the user's request and your Steward Agent's
intent extraction.

## The output

The runner emits a JSON document on stdout. Errors go to stderr.
The exit code is 0 on success, non-zero on failure.

### Full output (default)

```json
{
  "target": "0xABCDEF...",
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

### Filtered output (when band is below threshold)

If you set `LCP_THRESHOLD=WATCH` and the band is `HEALTHY`, the
runner suppresses the full payload:

```json
{
  "target": "0xABCDEF...",
  "network": "mainnet",
  "band": "HEALTHY",
  "filtered": true,
  "reason": "band below threshold WATCH"
}
```

This is for noise reduction: if the user said "alert me only
on WATCH or worse", a HEALTHY result is filtered out so the
Steward Agent doesn't have to do its own threshold check.

### Slim output (when `LCP_INCLUDE_DRIVERS=false`)

If you don't need the diagnostic `drivers` array (e.g., the
Steward Agent only needs the band + score for routing):

```json
{
  "target": "0xABCDEF...",
  "network": "mainnet",
  "score": 73,
  "band": "WATCH",
  "p_crisis": 0.62,
  "timestamp": "2026-07-05T22:10:18Z",
  "block": 9953438,
  "skill": "liquidity-crisis-predictor",
  "skill_version": "0.2.0"
}
```

### Error output (any failure)

Errors come on stderr as JSON. Examples:

```json
{"error":"PRIVATE_KEY is set; LCP RiskGuard is read-only ..."}
{"error":"required binary cast not found on PATH ..."}
{"error":"LCP Skill not found at /path/to/LCP ..."}
```

Exit codes:

- `64` — EX_USAGE (bad input, missing binary, missing Skill dir)
- `70` — EX_SOFTWARE (LCP Skill invocation failed)
- `77` — EX_NOPERM (PRIVATE_KEY was set; we refuse to run)

## Validation

The output conforms to the JSON Schema in
`references/output-schema.md`. Validate before forwarding to
the user:

```python
import json, jsonschema
schema = json.load(open("references/output-schema.json"))  # JSON Schema
result = json.loads(runner.stdout)
jsonschema.validate(result, schema)
```

Or use `ajv` in Node.js, or any other JSON Schema validator.

## Example: a Steward Agent flow

```
User (via Anvita On): "Watch 0xABCDEF... on Pharos mainnet, alert
                        me if it goes WATCH or worse."
        ↓
Steward Agent: extracts target=0xABCDEF..., network=mainnet,
               threshold=WATCH
        ↓
Steward Agent: invokes LCP RiskGuard via Anvita Flow routing
        ↓
Anvita Flow: sets LCP_TARGET=0xABCDEF..., LCP_NETWORK=mainnet,
             LCP_THRESHOLD=WATCH, then runs scripts/run.sh
        ↓
Runner: returns JSON on stdout
        ↓
Steward Agent: parses JSON, formats for user
        ↓
User: sees "WATCH — outflow velocity is the dominant signal"
```

## Example: a Steward Agent that runs on a schedule

A common pattern: the Steward Agent invokes LCP RiskGuard every
N blocks for each token the user is watching, and stores the
results in a time-series database. When a band crosses the
user's threshold, the Steward Agent sends an alert.

```python
# Pseudocode
for token in user.watched_tokens:
    result = invoke_lcp_riskguard(token, network="mainnet", threshold="HEALTHY")
    if result.band == "CRITICAL":
        send_alert(user, token, result)
    store_ts(token, result.timestamp, result.score, result.band, result.p_crisis)
```

LCP RiskGuard is **stateless** — it doesn't remember earlier
scores. The Steward Agent is responsible for tracking state
across invocations.

## Performance expectations

- **Cold start:** ~30ms (bash spin-up).
- **Per-call RPC:** ~7 seconds on Pharos mainnet public RPCs
  (cast round trips for 7 signals).
- **Total per invocation:** ~8 seconds end-to-end.

If you need faster, run a local Anvil node and point the runner
at it via `LCP_RPC_URL` (or modify `assets/networks.json` to
include a local entry).

## When to call

LCP RiskGuard is best called:

- **On demand** when the user asks about a specific token.
- **Periodically** (e.g., every 100 blocks) for tokens the user
  is watching.
- **Before a transaction** when the user is about to enter or
  exit a position.

It is NOT a good fit for:

- High-frequency trading (too slow at ~8 seconds per call).
- Cross-chain comparison (Pharos-only).
- Historical analysis (no time-series built in; you store it).

## What if the call fails?

The runner's exit code tells you what went wrong:

| Exit code | Meaning | Steward Agent should... |
|---|---|---|
| 0 | Success | Parse the JSON output. |
| 64 | Bad input | Tell the user the input is malformed. |
| 70 | RPC failure | Retry once, then tell the user the RPC is down. |
| 77 | PRIVATE_KEY set | This should never happen; tell the user to unset PRIVATE_KEY. |

## Versioning

The output JSON includes `skill_version`. If the Skill ships a
new version, the field changes. Steward Agents should log this
field and surface version changes to the user.

LCP RiskGuard itself follows [Semantic Versioning](https://semver.org/).
A major version bump (e.g., 1.0 → 2.0) means the output shape
changed and Steward Agents may need to update their parsing.

## See also

- `references/output-schema.md` — formal JSON Schema
- `references/example-outputs.md` — 5 canonical output shapes
- `references/scoring-model-explained.md` — how the math works
- `README.md` — quick-start for direct usage