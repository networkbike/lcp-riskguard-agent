#!/usr/bin/env bash
# LCP RiskGuard runner self-test.
#
# This script exercises the runner's defensive checks WITHOUT
# making any RPC calls. Use it as a quick smoke test in CI or
# before submitting the Agent to Anvita Flow.
#
# What it verifies:
#   1. PRIVATE_KEY is rejected (exit 77)
#   2. Missing binary is rejected (exit 64, when PATH is sanitized)
#   3. Missing LCP_SKILL_DIR is rejected (exit 64)
#   4. JSON output is well-formed (when run against a mock Skill)
#
# This is intentionally separate from the install.sh smoke test,
# which DOES make real RPC calls. self-test.sh is the offline
# version you can run anywhere.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="$SCRIPT_DIR/run.sh"

# Build a private PATH that has cast and jq available, so the runner's
# binary check passes. We use the system's real binaries if they exist,
# otherwise we synthesize fakes that print version info and exit 0.
FAKE_BIN="$(mktemp -d)"
trap 'rm -rf "$FAKE_BIN" "${TMPDIR:-}"' EXIT

if command -v cast >/dev/null 2>&1; then
  ln -sf "$(command -v cast)" "$FAKE_BIN/cast"
else
  cat > "$FAKE_BIN/cast" << 'EOF'
#!/usr/bin/env bash
# Fake cast for self-test: only handles --version and block-number.
case "$*" in
  --version|"-V") echo "cast 1.7.1 (fake)" ;;
  "block-number"*) echo "1" ;;
  "chain-id"*) echo "1672" ;;
  *) echo "0x0" ;;
esac
EOF
  chmod +x "$FAKE_BIN/cast"
fi

if command -v jq >/dev/null 2>&1; then
  ln -sf "$(command -v jq)" "$FAKE_BIN/jq"
else
  cat > "$FAKE_BIN/jq" << 'EOF'
#!/usr/bin/env bash
# Minimal jq stub for self-test. Pass-through for non-trivial input.
exec cat
EOF
  chmod +x "$FAKE_BIN/jq"
fi

export PATH="$FAKE_BIN:$PATH"

PASS=0
FAIL=0

ok()  { printf "  \033[32mPASS\033[0m %s\n" "$*"; PASS=$((PASS+1)); }
bad() { printf "  \033[31mFAIL\033[0m %s\n" "$*"; FAIL=$((FAIL+1)); }

echo "LCP RiskGuard runner self-test"
echo "=============================="

# --- 1. PRIVATE_KEY rejected ---------------------------------------
echo ""
echo "[1] PRIVATE_KEY must be rejected (exit 77)"
unset LCP_TARGET LCP_NETWORK LCP_THRESHOLD LCP_INCLUDE_DRIVERS LCP_SKILL_DIR
unset PRIVATE_KEY
# Mock the LCP Skill so the runner gets past the directory check.
TMPDIR="$(mktemp -d)"
mkdir -p "$TMPDIR/examples" "$TMPDIR/assets"
cat > "$TMPDIR/examples/score.sh" << 'EOF'
#!/usr/bin/env bash
echo '{"score":1,"band":"HEALTHY","p_crisis":0.01,"drivers":[]}'
EOF
chmod +x "$TMPDIR/examples/score.sh"
# Stub networks.json so the runner's block lookup doesn't blow up.
cat > "$TMPDIR/assets/networks.json" << 'EOF'
{
  "networks": [
    {"name": "mainnet", "rpcUrl": "https://rpc.pharos.xyz", "chainId": 1672},
    {"name": "atlantic-testnet", "rpcUrl": "https://atlantic.dplabs-internal.com", "chainId": 688689}
  ],
  "defaultNetwork": "mainnet"
}
EOF
export LCP_SKILL_DIR="$TMPDIR"

PRIVATE_KEY=0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef \
LCP_TARGET=native:PROS \
LCP_NETWORK=mainnet \
LCP_SKILL_DIR="$TMPDIR" \
bash "$RUNNER" > /dev/null 2>&1
RC=$?
if [[ $RC -eq 77 ]]; then
  ok "exits 77 when PRIVATE_KEY is set"
else
  bad "expected exit 77, got $RC"
fi
unset PRIVATE_KEY

# --- 2. Missing cast is rejected (exit 64) -------------------------
echo ""
echo "[2] Missing required binary must be rejected (exit 64)"
# Build a sanitized PATH that excludes cast/jq/forge.
SANITIZED_PATH="/tmp:/usr/bin:/bin"
OUTPUT=$(PATH="$SANITIZED_PATH" \
  LCP_TARGET=native:PROS \
  LCP_NETWORK=mainnet \
  LCP_SKILL_DIR="$TMPDIR" \
  bash "$RUNNER" 2>&1 > /dev/null)
RC=$?
if [[ $RC -eq 64 ]]; then
  if echo "$OUTPUT" | grep -q "cast.*not found"; then
    ok "exits 64 with clear error when cast is missing"
  else
    bad "exits 64 but error message unclear: $OUTPUT"
  fi
else
  bad "expected exit 64, got $RC"
fi

# --- 3. Missing LCP_SKILL_DIR is rejected (exit 64) ----------------
echo ""
echo "[3] Missing LCP Skill directory must be rejected (exit 64)"
# Use real PATH (so cast/jq are found) but point at a non-existent
# LCP Skill directory.
OUTPUT=$(unset LCP_SKILL_DIR; \
  LCP_TARGET=native:PROS \
  LCP_NETWORK=mainnet \
  LCP_SKILL_DIR=/tmp/this-directory-does-not-exist-12345 \
  bash "$RUNNER" 2>&1 > /dev/null)
RC=$?
if [[ $RC -eq 64 ]]; then
  if echo "$OUTPUT" | grep -q "LCP Skill not found"; then
    ok "exits 64 with clear error when LCP Skill directory is missing"
  else
    bad "exits 64 but error message unclear: $OUTPUT"
  fi
else
  bad "expected exit 64, got $RC"
fi

# --- 4. JSON output is well-formed ---------------------------------
echo ""
echo "[4] Output is well-formed JSON when Skill returns valid JSON"
# Mock the Skill to return a known-valid LCP result.
cat > "$TMPDIR/examples/score.sh" << 'EOF'
#!/usr/bin/env bash
echo '{"score":42,"band":"HEALTHY","p_crisis":0.10,"drivers":[{"signal":"x","contribution":0.1}]}'
EOF
chmod +x "$TMPDIR/examples/score.sh"

OUTPUT=$(unset LCP_SKILL_DIR; \
  LCP_TARGET=native:PROS \
  LCP_NETWORK=mainnet \
  LCP_THRESHOLD=HEALTHY \
  LCP_SKILL_DIR="$TMPDIR" \
  bash "$RUNNER" 2>&1)
RC=$?

if [[ $RC -eq 0 ]]; then
  if echo "$OUTPUT" | jq -e . > /dev/null 2>&1; then
    ok "exit 0 with valid JSON output"

    # Check that the runner merged its metadata correctly.
    SKILL=$(echo "$OUTPUT" | jq -r '.skill')
    SKILL_VER=$(echo "$OUTPUT" | jq -r '.skill_version')
    if [[ "$SKILL" == "liquidity-crisis-predictor" ]]; then
      ok "skill field is 'liquidity-crisis-predictor'"
    else
      bad "skill field is '$SKILL', expected 'liquidity-crisis-predictor'"
    fi
    if [[ "$SKILL_VER" == "0.2.0" ]]; then
      ok "skill_version field is '0.2.0'"
    else
      bad "skill_version field is '$SKILL_VER', expected '0.2.0'"
    fi
  else
    bad "output is not valid JSON: $OUTPUT"
  fi
else
  bad "expected exit 0, got $RC: $OUTPUT"
fi

# --- 5. include_drivers=false strips drivers -----------------------
echo ""
echo "[5] include_drivers=false strips the drivers array"
OUTPUT=$(unset LCP_SKILL_DIR; \
  LCP_TARGET=native:PROS \
  LCP_NETWORK=mainnet \
  LCP_THRESHOLD=HEALTHY \
  LCP_INCLUDE_DRIVERS=false \
  LCP_SKILL_DIR="$TMPDIR" \
  bash "$RUNNER" 2>&1)
RC=$?

if [[ $RC -eq 0 ]] && ! echo "$OUTPUT" | jq -e '.drivers' > /dev/null 2>&1; then
  ok "drivers field is absent when include_drivers=false"
else
  bad "drivers field present when include_drivers=false (or exit was $RC)"
fi

# --- 6. Threshold filter returns filtered:true ---------------------
echo ""
echo "[6] Threshold filter returns filtered:true when band is below threshold"
# Mock the Skill to return HEALTHY band, but ask for WATCH threshold.
# HEALTHY is below WATCH in severity, so the runner should filter.
cat > "$TMPDIR/examples/score.sh" << 'EOF'
#!/usr/bin/env bash
echo '{"score":10,"band":"HEALTHY","p_crisis":0.02,"drivers":[]}'
EOF
chmod +x "$TMPDIR/examples/score.sh"

OUTPUT=$(unset LCP_SKILL_DIR; \
  LCP_TARGET=native:PROS \
  LCP_NETWORK=mainnet \
  LCP_THRESHOLD=WATCH \
  LCP_SKILL_DIR="$TMPDIR" \
  bash "$RUNNER" 2>&1)
RC=$?

if [[ $RC -eq 0 ]] && echo "$OUTPUT" | jq -e '.filtered == true' > /dev/null 2>&1; then
  ok "filtered:true when band (HEALTHY) is below threshold (WATCH)"
else
  bad "expected filtered:true, got: $OUTPUT"
fi

# --- Cleanup --------------------------------------------------------
rm -rf "$TMPDIR"

# --- Summary --------------------------------------------------------
echo ""
echo "=============================="
echo "Results: $PASS passed; $FAIL failed"
echo "=============================="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1