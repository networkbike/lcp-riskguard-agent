#!/usr/bin/env bash
# Capture a sample runner output and write it to test/fixtures/.
#
# This generates the JSON fixture that forge test uses to verify the
# runner's output shape. Run this after any change to scripts/run.sh
# to keep the fixture in sync.
#
# Usage:
#   bash test/capture-output.sh
#
# Output:
#   test/fixtures/sample-output.json   (full HEALTHY-band output)
#   test/fixtures/sample-filtered.json (filtered output, band below threshold)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RUNNER="$REPO_ROOT/scripts/run.sh"

# Set up a sandbox with a fake cast that returns deterministic output,
# plus the real jq (already in /usr/bin/jq).
FAKE_BIN="$(mktemp -d)"
trap 'rm -rf "$FAKE_BIN"' EXIT

if command -v jq >/dev/null 2>&1; then
  ln -sf "$(command -v jq)" "$FAKE_BIN/jq"
else
  echo "jq is required" >&2
  exit 1
fi

# Fake cast: --version works, block-number returns 12345.
cat > "$FAKE_BIN/cast" << 'EOF'
#!/usr/bin/env bash
case "$*" in
  --version|"-V") echo "cast 1.7.1" ;;
  "block-number"*) echo "12345" ;;
  *) echo "0x0" ;;
esac
EOF
chmod +x "$FAKE_BIN/cast"

# Mock LCP Skill dir.
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$FAKE_BIN" "$TMPDIR"' EXIT
mkdir -p "$TMPDIR/examples" "$TMPDIR/assets"

cat > "$TMPDIR/examples/score.sh" << 'EOF'
#!/usr/bin/env bash
echo '{"score":18,"band":"HEALTHY","p_crisis":0.04,"drivers":[{"signal":"outflow_velocity","contribution":0.06},{"signal":"holder_concentration","contribution":0.04}]}'
EOF
chmod +x "$TMPDIR/examples/score.sh"

cat > "$TMPDIR/assets/networks.json" << 'EOF'
{"networks": [{"name":"mainnet","rpcUrl":"https://rpc.pharos.xyz","chainId":1672}]}
EOF

# Generate the HEALTHY-band fixture.
echo "Generating sample-output.json (HEALTHY band)..."
PATH="$FAKE_BIN:$PATH" \
LCP_TARGET=native:PROS \
LCP_NETWORK=mainnet \
LCP_THRESHOLD=HEALTHY \
LCP_SKILL_DIR="$TMPDIR" \
bash "$RUNNER" \
  | jq '
    # Scale p_crisis to 1e18 for fixed-point arithmetic in the test.
    # The Solidity test reads ".p_crisis_e18" instead of ".p_crisis".
    if .p_crisis != null then
      .p_crisis_e18 = (.p_crisis * 1000000000000000000 | round)
    else
      .p_crisis_e18 = 0
    end
    # block null → 0
    | if .block == null then .block = 0 else . end
  ' > "$REPO_ROOT/test/fixtures/sample-output.json"

echo "  wrote $REPO_ROOT/test/fixtures/sample-output.json"

# Generate the filtered fixture.
echo "Generating sample-filtered.json (filtered output)..."
cat > "$TMPDIR/examples/score.sh" << 'EOF'
#!/usr/bin/env bash
echo '{"score":10,"band":"HEALTHY","p_crisis":0.02,"drivers":[]}'
EOF
chmod +x "$TMPDIR/examples/score.sh"

PATH="$FAKE_BIN:$PATH" \
LCP_TARGET=0xABCDEF0123456789ABCDEF0123456789ABCDEF01 \
LCP_NETWORK=mainnet \
LCP_THRESHOLD=WATCH \
LCP_SKILL_DIR="$TMPDIR" \
bash "$RUNNER" \
  | jq '
    .p_crisis_e18 = 0
  ' > "$REPO_ROOT/test/fixtures/sample-filtered.json"

echo "  wrote $REPO_ROOT/test/fixtures/sample-filtered.json"
echo ""
echo "Done. Now run:"
echo "  forge test"
echo "to verify the runner output shape against these fixtures."