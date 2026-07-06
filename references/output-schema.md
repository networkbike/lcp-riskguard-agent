# Output schema (formal)

The full JSON Schema for LCP RiskGuard's output, in
[JSON Schema Draft 2020-12](https://json-schema.org/draft/2020-12).

Two variants: the **full output** (default) and the **filtered
output** (when the band is below the user's threshold).

## Full output

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://github.com/networkbike/lcp-riskguard-agent/schemas/full-output.json",
  "title": "LCP RiskGuard full output",
  "type": "object",
  "required": ["target", "network", "score", "band", "p_crisis", "timestamp", "skill", "skill_version"],
  "additionalProperties": false,
  "properties": {
    "target": {
      "description": "The address (0x...) or native asset (native:PROS, native:PHRS) that was scored",
      "type": "string",
      "pattern": "^(0x[0-9a-fA-F]{40}$|^native:(PROS|PHRS)$)"
    },
    "network": {
      "description": "Which Pharos network was queried",
      "type": "string",
      "enum": ["mainnet", "atlantic-testnet"]
    },
    "score": {
      "description": "0-100 liquidity-stress score (higher = more stressed)",
      "type": "integer",
      "minimum": 0,
      "maximum": 100
    },
    "band": {
      "description": "Categorical classification of the score",
      "type": "string",
      "enum": ["HEALTHY", "WATCH", "CRITICAL", "UNKNOWN"]
    },
    "p_crisis": {
      "description": "Logistic probability of imminent liquidity crisis, [0, 1]",
      "type": "number",
      "minimum": 0,
      "maximum": 1
    },
    "drivers": {
      "description": "Top N (default 3) signals by absolute contribution to the score. Present unless include_drivers=false.",
      "type": "array",
      "items": {
        "type": "object",
        "required": ["signal", "contribution"],
        "additionalProperties": false,
        "properties": {
          "signal": {
            "description": "Name of the LCP signal",
            "type": "string",
            "enum": [
              "pair_reserves",
              "liquidity_depth",
              "holder_concentration",
              "outflow_velocity",
              "gas_stress",
              "pair_imbalance",
              "supply_growth"
            ]
          },
          "contribution": {
            "description": "Absolute contribution of this signal to the score (0-1 scale after normalization)",
            "type": "number",
            "minimum": 0,
            "maximum": 1
          }
        }
      }
    },
    "timestamp": {
      "description": "UTC ISO-8601 timestamp of when the call ran",
      "type": "string",
      "format": "date-time"
    },
    "block": {
      "description": "Block number the signals were read against. Null if RPC was unreachable for the block lookup.",
      "type": ["integer", "null"],
      "minimum": 0
    },
    "skill": {
      "description": "Skill identifier (always 'liquidity-crisis-predictor' for v0.1.0)",
      "type": "string",
      "const": "liquidity-crisis-predictor"
    },
    "skill_version": {
      "description": "Skill semver (v0.2.0 for the current Phase-1 submission)",
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$"
    }
  }
}
```

## Filtered output (when band is below threshold)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://github.com/networkbike/lcp-riskguard-agent/schemas/filtered-output.json",
  "title": "LCP RiskGuard filtered output",
  "type": "object",
  "required": ["target", "network", "band", "filtered", "reason"],
  "additionalProperties": false,
  "properties": {
    "target": {
      "type": "string",
      "pattern": "^(0x[0-9a-fA-F]{40}$|^native:(PROS|PHRS)$)"
    },
    "network": {
      "type": "string",
      "enum": ["mainnet", "atlantic-testnet"]
    },
    "band": {
      "type": "string",
      "enum": ["HEALTHY", "WATCH", "CRITICAL", "UNKNOWN"]
    },
    "filtered": {
      "type": "boolean",
      "const": true
    },
    "reason": {
      "type": "string",
      "examples": ["band below threshold WATCH"]
    }
  }
}
```

## Error output (any failure)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://github.com/networkbike/lcp-riskguard-agent/schemas/error-output.json",
  "title": "LCP RiskGuard error output",
  "type": "object",
  "required": ["error"],
  "additionalProperties": true,
  "properties": {
    "error": {
      "type": "string"
    }
  }
}
```

Error JSON is emitted on stderr; exit code is non-zero.

## Validation examples

Validate the runner's output against the schema with `jq`:

```bash
SCHEMA='https://raw.githubusercontent.com/networkbike/lcp-riskguard-agent/main/references/output-schema.md'

LCP_TARGET=native:PROS LCP_NETWORK=mainnet \
  bash scripts/run.sh | jq '
    # Strip the $schema comment lines from the markdown before parsing.
    select(type == "object")
  '
```

Or with `ajv` (if you have it):

```bash
ajv validate -s references/output-schema.json -d output.json
```

## Why a formal schema?

Three reasons:

1. **Steward Agents can validate the output** before forwarding
   it to the user. A Steward Agent that knows the schema can
   reject malformed responses and surface the error to the user.
2. **Phase 2 grader can verify the contract.** The grader (or
   human judges) can run a smoke test that asserts the Agent's
   output conforms to the documented schema.
3. **Future Skills can extend safely.** A Skill that wants to
   add a new field can do so via `additionalProperties: true`
   in the error schema (errors are free-form). The full output
   schema is locked to the v0.1.0 contract; new versions of
   the Skill can ship a v0.2 schema.

## Compatibility notes

- **`band` can be `UNKNOWN`.** This happens when the target
  doesn't expose standard ERC-20 methods (e.g., it's a non-ERC20
  contract). The score and p_crisis will be `null` in that case.
- **`block` can be `null`.** This happens when the runner
  couldn't reach Pharos RPC for the block lookup. The score
  is still valid; only the metadata is missing.
- **`drivers` can be absent.** This happens when the user sets
  `LCP_INCLUDE_DRIVERS=false`. The rest of the output is
  unchanged.
- **`filtered` outputs omit score, p_crisis, drivers, etc.**
  When the runner filters out a result, it returns a slim
  payload with just the relevant filter metadata. Steward
  Agents that receive this can drop the notification cleanly.