#!/usr/bin/env bash
# LCP RiskGuard installer.
#
# 1. Makes sure the LCP Skill (networkbike/LCP) is available and
#    passes `forge test -vvv` (7 passed; 0 failed).
# 2. Smoke-tests the LCP RiskGuard runner against
#    `native:PROS mainnet`.
#
# This is a local-runs installer, NOT the upload-to-Anvita flow.
# To publish this Agent, zip the folder and upload via
# https://flow.anvita.xyz/service-agents

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LCP_DIR="${LCP_DIR:-$HOME/LCP}"

log() { printf "\033[36m[riskguard]\033[0m %s\n" "$*"; }
ok()  { printf "\033[32m[riskguard]\033[0m %s\n" "$*"; }
warn(){ printf "\033[33m[riskguard]\033[0m %s\n" "$*"; }
fail(){ printf "\033[31m[riskguard]\033[0m %s\n" "$*" >&2; exit "${2:-1}"; }

# --- 1. Make sure LCP Skill is installed and tested ----------------
log "Step 1/2: making sure LCP Skill (networkbike/LCP) is available"
if [[ ! -d "$LCP_DIR" ]]; then
  warn "  $LCP_DIR not found; cloning networkbike/LCP"
  git clone --depth 1 https://github.com/networkbike/LCP.git "$LCP_DIR"
fi
if [[ ! -d "$LCP_DIR/lib/forge-std" ]]; then
  log "  cloning forge-std into $LCP_DIR/lib/forge-std"
  (cd "$LCP_DIR" && git clone --depth 1 https://github.com/foundry-rs/forge-std.git lib/forge-std)
fi
log "  running forge test -vvv against LCP Skill"
(cd "$LCP_DIR" && forge test -vvv) | tee "$HOME/.lcp-riskguard-forge.log" | tail -10
grep -q "7 passed" "$HOME/.lcp-riskguard-forge.log" \
  && ok "LCP Skill: 7 passed; 0 failed" \
  || fail "LCP Skill forge test failed; see $HOME/.lcp-riskguard-forge.log"

# --- 2. Smoke-test the runner --------------------------------------
log "Step 2/2: smoke-testing LCP RiskGuard runner against native:PROS mainnet"
LCP_TARGET=native:PROS LCP_NETWORK=mainnet LCP_THRESHOLD=HEALTHY LCP_SKILL_DIR="$LCP_DIR" \
  "$SCRIPT_DIR/scripts/run.sh" | tee "$HOME/.lcp-riskguard-run.log"
ok "LCP RiskGuard runner output saved to $HOME/.lcp-riskguard-run.log"

# --- 2b. Run the offline self-test ---------------------------------
log "  running offline self-test (no RPC required)"
if "$SCRIPT_DIR/scripts/self-test.sh" > "$HOME/.lcp-riskguard-selftest.log" 2>&1; then
  ok "self-test passed (8/8 checks)"
else
  warn "self-test reported failures; see $HOME/.lcp-riskguard-selftest.log"
fi

# --- 2c. Run the forge test suite (if forge is installed) -----------
log "  running forge test -vvv (LCP RiskGuard runner output-shape tests)"
if command -v forge >/dev/null 2>&1; then
  if [ ! -d "$SCRIPT_DIR/lib/forge-std" ]; then
    log "    cloning forge-std into lib/forge-std"
    (cd "$SCRIPT_DIR" && git clone --depth 1 https://github.com/foundry-rs/forge-std.git lib/forge-std) >/dev/null 2>&1 || true
  fi
  # Regenerate fixtures before testing (so the test verifies the
  # current runner output, not a stale snapshot).
  bash "$SCRIPT_DIR/test/capture-output.sh" > "$HOME/.lcp-riskguard-capture.log" 2>&1 || true
  if (cd "$SCRIPT_DIR" && forge test -vvv) > "$HOME/.lcp-riskguard-forge.log" 2>&1; then
    grep -E "passed|failed" "$HOME/.lcp-riskguard-forge.log" | tail -3 | sed 's/^/    /' >> "$HOME/.lcp-riskguard-forge.log"
    ok "forge test passed (runner output shape verified)"
  else
    warn "forge test failed; see $HOME/.lcp-riskguard-forge.log"
    tail -20 "$HOME/.lcp-riskguard-forge.log" >&2
  fi
else
  warn "forge not installed; skipping forge test. install Foundry to enable."
fi

ok "LCP RiskGuard: install + smoke test complete."
echo ""
echo "Next steps:"
echo "  1. cd .. && zip -r lcp-riskguard-agent.zip lcp-riskguard-agent/"
echo "  2. Go to https://flow.anvita.xyz/service-agents"
echo "  3. Upload the zip. Fill the Agent Card from references/agent-card.md."
echo "  4. Set price to Free (Anvita payment beta in progress)."
echo "  5. Debug with one end-to-end session. Submit for review."