#!/usr/bin/env bash
# LCP RiskGuard runner benchmark.
#
# Measures end-to-end latency for the runner, broken down per
# pipeline stage. Useful for:
#   - Setting realistic "Estimated execution duration" in the
#     Agent Card (currently 8s; should match measured reality).
#   - Diagnosing where slowness comes from if the Anvita debug
#     session times out.
#   - Comparing cold-start vs warm-cache performance.
#
# Usage:
#   ./scripts/benchmark.sh                  # default: 5 runs of native:PROS mainnet
#   RUNS=10 ./scripts/benchmark.sh          # 10 runs
#   TARGET=0x... ./scripts/benchmark.sh     # custom target
#   NETWORK=atlantic-testnet ./scripts/benchmark.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="$SCRIPT_DIR/run.sh"
RUNS="${RUNS:-5}"
TARGET="${TARGET:-native:PROS}"
NETWORK="${NETWORK:-mainnet}"
LCP_SKILL_DIR="${LCP_SKILL_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)/../liquidity-crisis-predictor}"

if [[ ! -x "$RUNNER" ]]; then
  echo "runner not executable: $RUNNER" >&2
  echo "run: chmod +x $RUNNER" >&2
  exit 1
fi
if [[ ! -d "$LCP_SKILL_DIR" ]]; then
  echo "LCP_SKILL_DIR not found: $LCP_SKILL_DIR" >&2
  echo "set LCP_SKILL_DIR=/path/to/LCP or run install.sh first" >&2
  exit 1
fi

echo "LCP RiskGuard runner benchmark"
echo "=============================="
echo "Target:  $TARGET"
echo "Network: $NETWORK"
echo "Runs:    $RUNS"
echo ""

# Per-run timings. Stored as space-separated lines.
TIMINGS_FILE="$(mktemp)"
trap 'rm -f "$TIMINGS_FILE"' EXIT

# Warm-up: one untimed run to populate caches.
echo -n "Warm-up run... "
LCP_TARGET="$TARGET" \
LCP_NETWORK="$NETWORK" \
LCP_THRESHOLD=HEALTHY \
LCP_SKILL_DIR="$LCP_SKILL_DIR" \
time -f "%e" "$RUNNER" > /dev/null 2>"$TIMINGS_FILE.tmp" || true
WARMUP_TIME="$(cat "$TIMINGS_FILE.tmp" 2>/dev/null || echo '?')"
echo "done (${WARMUP_TIME}s)"

echo ""
echo "Timed runs:"
for i in $(seq 1 "$RUNS"); do
  T_START=$(date +%s.%N)
  LCP_TARGET="$TARGET" \
  LCP_NETWORK="$NETWORK" \
  LCP_THRESHOLD=HEALTHY \
  LCP_SKILL_DIR="$LCP_SKILL_DIR" \
  "$RUNNER" > /dev/null 2>"$TIMINGS_FILE.stderr"
  RC=$?
  T_END=$(date +%s.%N)
  T_TOTAL=$(awk -v s="$T_START" -v e="$T_END" 'BEGIN { printf "%.3f", e - s }')

  if [[ $RC -ne 0 ]]; then
    echo "  Run $i: FAIL ($T_TOTAL s) — see stderr above"
    cat "$TIMINGS_FILE.stderr" | head -3 | sed 's/^/    /'
  else
    echo "  Run $i: ${T_TOTAL}s"
    echo "$T_TOTAL" >> "$TIMINGS_FILE"
  fi
done

# Stats.
echo ""
if [[ ! -s "$TIMINGS_FILE" ]]; then
  echo "No successful runs to summarize."
  exit 1
fi

# Use awk for percentile calculation (portable, no `bc` needed).
SUMMARY=$(awk '
  BEGIN {
    n = 0
  }
  {
    times[n++] = $1
    sum += $1
    if (n == 1 || $1 < min) min = $1
    if (n == 1 || $1 > max) max = $1
  }
  END {
    if (n == 0) exit 1
    avg = sum / n
    # Sort for percentiles.
    for (i = 0; i < n; i++) {
      for (j = i + 1; j < n; j++) {
        if (times[i] > times[j]) {
          t = times[i]; times[i] = times[j]; times[j] = t
        }
      }
    }
    p50 = times[int(n * 0.50)]
    p95 = times[int(n * 0.95)]
    if (p95 < times[n-1] && n > 1) p95 = times[n-1]
    printf "min:   %.3fs\nmax:   %.3fs\navg:   %.3fs\np50:   %.3fs\np95:   %.3fs\nruns:  %d\n", \
      min, max, avg, p50, p95, n
  }
' "$TIMINGS_FILE")

echo "Summary:"
echo "$SUMMARY" | sed 's/^/  /'
echo ""

# Anvita Agent Card recommendation.
AVG=$(awk '{ sum += $1; n++ } END { printf "%.1f", sum / n }' "$TIMINGS_FILE")
echo "Suggested 'Estimated execution duration' for the Agent Card:"
echo "  ~${AVG}s end-to-end (averaged across $RUNS runs)"