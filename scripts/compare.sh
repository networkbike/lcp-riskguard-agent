#!/usr/bin/env bash
# LCP RiskGuard multi-target comparison.
#
# Runs the runner against N targets (sequential, not parallel —
# sequential preserves the deterministic order and avoids hammering
# the RPC). Returns a JSON array sorted by p_crisis descending.
#
# Usage:
#   ./scripts/compare.sh 0xAAA... 0xBBB... 0xCCC...
#   ./scripts/compare.sh native:PROS native:PHRS
#   ./scripts/compare.sh 0xAAA... 0xBBB... --network=atlantic-testnet
#   ./scripts/compare.sh 0xAAA... 0xBBB... --json     # raw array output
#
# Output: JSON object with results array and summary stats.
# Each entry has the same shape as a single runner invocation.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="$SCRIPT_DIR/run.sh"

# Parse args.
NETWORK="mainnet"
JSON_ONLY=0
TARGETS=()
for arg in "$@"; do
  case "$arg" in
    --network=*) NETWORK="${arg#--network=}" ;;
    --network) shift; NETWORK="${1:-mainnet}" ;;
    --json)     JSON_ONLY=1 ;;
    -h|--help)
      cat << 'EOF'
Usage: ./scripts/compare.sh [options] TARGET [TARGET ...]

Options:
  --network=NAME        mainnet (default) or atlantic-testnet
  --json                output raw JSON array only (no summary)
  -h, --help            show this help

Each TARGET is a 0x-prefixed 20-byte address or 'native:PROS' / 'native:PHRS'.

Example:
  ./scripts/compare.sh native:PROS 0xAAA... 0xBBB... --network=mainnet
EOF
      exit 0
      ;;
    *) TARGETS+=("$arg") ;;
  esac
done

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  echo "no targets provided. try --help" >&2
  exit 64
fi

# Sanity: refuse if PRIVATE_KEY is set.
if [[ -n "${PRIVATE_KEY:-}" ]]; then
  echo '{"error":"PRIVATE_KEY is set; refusing to run."}' >&2
  exit 77
fi

# Per-target collection.
RESULTS="[]"
FAILED=0
TOTAL=${#TARGETS[@]}
START_TS="$(date +%s)"

for i in "${!TARGETS[@]}"; do
  TARGET="${TARGETS[$i]}"
  printf "[%d/%d] %s ... " $((i + 1)) "$TOTAL" "$TARGET" >&2

  RAW="$(LCP_TARGET="$TARGET" LCP_NETWORK="$NETWORK" \
              LCP_THRESHOLD=HEALTHY \
              LCP_INCLUDE_DRIVERS=false \
              "$RUNNER" 2>/dev/null)"
  RC=$?

  if [[ $RC -ne 0 ]]; then
    echo "FAIL (exit $RC)" >&2
    FAILED=$((FAILED + 1))
    # Insert a placeholder so the array stays aligned.
    RESULTS=$(echo "$RESULTS" | jq --arg t "$TARGET" \
      '. + [{target: $t, error: "runner exit '"$RC"'"}]')
    continue
  fi

  # Validate JSON and pull out the key fields.
  if ! echo "$RAW" | jq -e . >/dev/null 2>&1; then
    echo "FAIL (bad JSON)" >&2
    FAILED=$((FAILED + 1))
    RESULTS=$(echo "$RESULTS" | jq --arg t "$TARGET" \
      '. + [{target: $t, error: "runner returned non-JSON"}]')
    continue
  fi

  SCORE=$(echo "$RAW" | jq -r '.score // "null"')
  BAND=$(echo "$RAW" | jq -r '.band // "UNKNOWN"')
  P_CRISIS=$(echo "$RAW" | jq -r '.p_crisis // "null"')
  echo "$BAND (score=$SCORE, p_crisis=$P_CRISIS)" >&2

  # Merge into the results array. Keep just the comparison-relevant fields.
  RESULTS=$(echo "$RESULTS" | jq --argjson raw "$(echo "$RAW" | jq '{score, band, p_crisis}')" \
    '. + [($raw + {target: "'"$TARGET"'"})]')
done

END_TS="$(date +%s)"
ELAPSED=$((END_TS - START_TS))

# Sort by p_crisis descending (worst first), nulls last.
SORTED=$(echo "$RESULTS" | jq '
  sort_by(
    if .p_crisis == null then 999
    elif (.p_crisis | type) == "number" then .p_crisis
    else 999
    end
  ) | reverse
')

# Build summary stats.
SUMMARY=$(echo "$SORTED" | jq '{
  total: length,
  by_band: (
    [group_by(.band)[] | {(.[0].band // "UNKNOWN"): length}]
    | add // {}
  ),
  worst: (.[0] // null),
  best:  (.[length - 1] // null),
  elapsed_seconds: '"$ELAPSED"',
  failed: '"$FAILED"'
}')

# Final output.
if [[ $JSON_ONLY -eq 1 ]]; then
  echo "$SORTED"
else
  jq -n --argjson results "$SORTED" --argjson summary "$SUMMARY" \
    '{summary: $summary, results: $results}'
fi
