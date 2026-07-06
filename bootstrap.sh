#!/usr/bin/env bash
# LCP RiskGuard bootstrap helper.
#
# Idempotent: if you already have a clean clone, this is a no-op.
# If you have a broken or partial clone, this wipes it and re-clones.
#
# Why: Termux/Android often leaves a half-cloned repo after a network
# blip during `git clone`. The next attempt fails with
#   "destination path 'lcp-riskguard-agent' already exists and is not
#    an empty directory."
# This script handles that case.

set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/lcp-riskguard-agent}"
REPO_URL="https://github.com/networkbike/lcp-riskguard-agent.git"

log() { printf "\033[36m[bootstrap]\033[0m %s\n" "$*"; }
ok()  { printf "\033[32m[bootstrap]\033[0m %s\n" "$*"; }
warn(){ printf "\033[33m[bootstrap]\033[0m %s\n" "$*"; }

if [[ ! -d "$REPO_DIR" ]]; then
  log "$REPO_DIR does not exist; cloning fresh"
  git clone --depth 1 "$REPO_URL" "$REPO_DIR"
  ok "cloned to $REPO_DIR"
elif [[ ! -f "$REPO_DIR/scripts/run.sh" ]] || [[ ! -f "$REPO_DIR/foundry.toml" ]]; then
  warn "$REPO_DIR exists but appears incomplete; wiping and re-cloning"
  rm -rf "$REPO_DIR"
  git clone --depth 1 "$REPO_URL" "$REPO_DIR"
  ok "re-cloned to $REPO_DIR"
elif [[ ! -d "$REPO_DIR/.git" ]]; then
  warn "$REPO_DIR exists but is not a git repo; wiping and re-cloning"
  rm -rf "$REPO_DIR"
  git clone --depth 1 "$REPO_URL" "$REPO_DIR"
  ok "re-cloned to $REPO_DIR"
else
  ok "$REPO_DIR is a clean clone; nothing to do"
fi

echo ""
echo "Next: cd $REPO_DIR && ./install.sh"