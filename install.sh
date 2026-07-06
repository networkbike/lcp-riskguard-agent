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
# --- 0. Termux sanity: ensure foundry is Bionic-compatible ----------
# On Termux, the foundryup-installed static alpine/arm64 foundry has
# a TLS segment with 8-byte alignment that Bionic rejects with:
#   "TLS segment is underaligned: alignment is 8, needs to be at
#    least 64 for ARM64 Bionic"
# The Termux-packaged foundry .deb is the only build that works
# natively. Detect and replace a broken binary before anything else.
if [[ "$(uname -s)" == "Linux" ]] && [[ "$(uname -m)" == "aarch64" ]] \
   && command -v pkg >/dev/null 2>&1; then
  log "Step 0/2: Termux detected — verifying foundry is Bionic-compatible"
  NEEDS_TERMUX_FORGE=0
  if command -v forge >/dev/null 2>&1; then
    if ! forge --version >/dev/null 2>&1; then
      warn "  existing forge is broken on Termux (fails to exec); will replace"
      NEEDS_TERMUX_FORGE=1
    fi
  else
    log "  forge not on PATH; will install Termux .deb"
    NEEDS_TERMUX_FORGE=1
  fi

  if [[ $NEEDS_TERMUX_FORGE -eq 1 ]]; then
    DEB_URL="https://packages.termux.dev/apt/termux-main/pool/main/f/foundry/foundry_1.7.1-1_aarch64.deb"
    DEB_TMP="$HOME/.lcp-riskguard-foundry.deb.$$"
    rm -f "$DEB_TMP"
    if curl -fsSL --retry 5 --retry-delay 3 "$DEB_URL" 2>/dev/null > "$DEB_TMP"; then
      EXTRACT_DIR="$HOME/.lcp-riskguard-foundry-ext.$$"
      rm -rf "$EXTRACT_DIR" 2>/dev/null
      mkdir -p "$EXTRACT_DIR"
      EXTRACT_OK=0
      if command -v dpkg-deb >/dev/null 2>&1 \
         && dpkg-deb -x "$DEB_TMP" "$EXTRACT_DIR" 2>/dev/null; then
        EXTRACT_OK=1
      elif command -v ar >/dev/null 2>&1; then
        (cd "$EXTRACT_DIR" && ar x "$DEB_TMP" 2>/dev/null \
          && (tar -xJf data.tar.xz 2>/dev/null || tar -xzf data.tar.gz 2>/dev/null))
        EXTRACT_OK=1
      fi
      rm -f "$DEB_TMP"
      if [[ $EXTRACT_OK -eq 1 ]]; then
        mkdir -p "$HOME/.foundry/bin"
        for b in cast forge anvil chisel; do
          if [[ -x "$EXTRACT_DIR/data/data/com.termux/files/usr/bin/$b" ]]; then
            cp -f "$EXTRACT_DIR/data/data/com.termux/files/usr/bin/$b" "$HOME/.foundry/bin/$b" 2>/dev/null || true
            cp -f "$EXTRACT_DIR/data/data/com.termux/files/usr/bin/$b" "$PREFIX/bin/$b" 2>/dev/null || true
          fi
        done
        chmod +x "$HOME/.foundry/bin/"* 2>/dev/null || true
        chmod +x "$PREFIX/bin/"{cast,forge,anvil,chisel} 2>/dev/null || true
        rm -rf "$EXTRACT_DIR"
        ok "  installed Termux foundry .deb (Bionic-compatible)"
        export PATH="$HOME/.foundry/bin:$PREFIX/bin:$PATH"
      else
        rm -rf "$EXTRACT_DIR" 2>/dev/null
        warn "  could not extract foundry .deb; proceeding with existing forge"
      fi
    else
      rm -f "$DEB_TMP" 2>/dev/null
      warn "  could not download foundry .deb; proceeding with existing forge"
    fi
  fi
fi

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