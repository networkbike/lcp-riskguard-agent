#!/usr/bin/env bash
# LCP RiskGuard runner.
#
# Thin wrapper around the LCP Skill (networkbike/LCP).
# Invoked by the Anvita Flow Service Agent runtime when a Steward
# Agent calls this Service.
#
# Inputs (from the Steward Agent's request, exposed as env vars by
# Anvita Flow):
#   LCP_TARGET  — token, pool, or `native:PROS` / `native:PHRS`
#   LCP_NETWORK — `mainnet` (default) or `atlantic-testnet`
#   LCP_THRESHOLD — `WATCH` (default) or `CRITICAL`
#   LCP_INCLUDE_DRIVERS — `true` (default) or `false`
#
# Output: JSON document on stdout, exit 0 on success.
#         Error JSON on stderr, exit non-zero on failure.
#
# The actual scoring lives in the LCP Skill:
#   https://github.com/networkbike/LCP
# We invoke its CLI directly. No re-implementation.

set -euo pipefail

# Refuse to run if a private key is in scope. LCP RiskGuard is
# read-only by design; if PRIVATE_KEY is set, refuse loudly.
if [[ -n "${PRIVATE_KEY:-}" ]]; then
  echo '{"error":"PRIVATE_KEY is set; LCP RiskGuard is read-only and will refuse to run with a key in scope. unset PRIVATE_KEY and retry."}' >&2
  exit 77
fi

# Make sure required binaries are present. Anvita Flow's runtime
# image is expected to have these; this check catches local dev
# mistakes early.
for bin in cast jq; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo '{"error":"required binary '"$bin"' not found on PATH. Install Foundry (cast) and jq before invoking LCP RiskGuard."}' >&2
    exit 64
  fi
done

# Locate the LCP Skill. On Anvita Flow this will be the bundled
# version of the Skill that was uploaded alongside this Agent.
# In dev / local-runs we use the cloned repo next to this one.
LCP_SKILL_DIR="${LCP_SKILL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/../liquidity-crisis-predictor}"
if [[ ! -d "$LCP_SKILL_DIR" ]]; then
  echo '{"error":"LCP Skill not found at '"$LCP_SKILL_DIR"'. Run install.sh first."}' >&2
  exit 64
fi

# Inputs.
TARGET="${LCP_TARGET:?LCP_TARGET is required (e.g. 0xABCDEF... or native:PROS)}"
NETWORK="${LCP_NETWORK:-mainnet}"
THRESHOLD="${LCP_THRESHOLD:-WATCH}"
INCLUDE_DRIVERS="${LCP_INCLUDE_DRIVERS:-true}"

# Run the LCP CLI.
# `score.sh` returns a JSON document with score, band, p_crisis, drivers.
RAW="$("$LCP_SKILL_DIR/examples/score.sh" "$TARGET" "$NETWORK")" || {
  echo '{"error":"LCP Skill execution failed","target":"'"$TARGET"'","network":"'"$NETWORK"'"}' >&2
  exit 70
}

# Compose the RiskGuard output. Merge the LCP result with the
# Steward-Agent-facing metadata (timestamp, skill version, threshold).
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
# Look up the RPC URL for the requested network in one jq call.
RPC_URL="$(jq -r --arg n "$NETWORK" '.networks[] | select(.name == $n) | .rpcUrl' "$LCP_SKILL_DIR/assets/networks.json" 2>/dev/null)"
# If we found an RPC URL, fetch the current block number. Otherwise
# leave BLOCK unset so it ends up as null in the JSON.
if [[ -n "$RPC_URL" ]]; then
  BLOCK="$(cast block-number --rpc-url "$RPC_URL" 2>/dev/null || echo null)"
else
  BLOCK=null
fi

# Filter: the threshold is the MINIMUM band to return. Bands are
# ordered HEALTHY < WATCH < CRITICAL in severity. If the actual
# band is less severe than the threshold, filter it out.
#
#   THRESHOLD=WATCH    → return WATCH or CRITICAL
#   THRESHOLD=CRITICAL → return CRITICAL only
#   THRESHOLD=HEALTHY  → return all (default; no filter)
BAND="$(echo "$RAW" | jq -r '.band')"
FILTER_OUT=0
case "$THRESHOLD" in
  CRITICAL)
    [[ "$BAND" == "CRITICAL" ]] || FILTER_OUT=1
    ;;
  WATCH)
    [[ "$BAND" == "HEALTHY" ]] && FILTER_OUT=1
    ;;
  HEALTHY | "")
    FILTER_OUT=0
    ;;
  *)
    # Unknown threshold: be conservative and don't filter.
    FILTER_OUT=0
    ;;
esac

if [[ $FILTER_OUT -eq 1 ]]; then
  printf '{"target":"%s","network":"%s","band":"%s","filtered":true,"reason":"band below threshold %s"}\n' \
    "$TARGET" "$NETWORK" "$BAND" "$THRESHOLD"
  exit 0
fi

# Build final output.
if [[ "$INCLUDE_DRIVERS" == "true" ]]; then
  echo "$RAW" | jq \
    --arg target "$TARGET" \
    --arg network "$NETWORK" \
    --arg ts "$TS" \
    --argjson block "${BLOCK:-null}" \
    --arg skill "liquidity-crisis-predictor" \
    --arg skill_version "0.2.0" \
    '. + {
      target: $target,
      network: $network,
      timestamp: $ts,
      block: $block,
      skill: $skill,
      skill_version: $skill_version
    }'
else
  echo "$RAW" | jq \
    --arg target "$TARGET" \
    --arg network "$NETWORK" \
    --arg ts "$TS" \
    --argjson block "${BLOCK:-null}" \
    --arg skill "liquidity-crisis-predictor" \
    --arg skill_version "0.2.0" \
    'del(.drivers) + {
      target: $target,
      network: $network,
      timestamp: $ts,
      block: $block,
      skill: $skill,
      skill_version: $skill_version
    }'
fi