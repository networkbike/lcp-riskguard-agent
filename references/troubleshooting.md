# Troubleshooting

Common errors and fixes when running LCP RiskGuard.

## Runner errors

### `PRIVATE_KEY is set; ...`

```
{"error":"PRIVATE_KEY is set; LCP RiskGuard is read-only and will refuse to run with a key in scope. unset PRIVATE_KEY and retry."}
```

**Cause:** You exported `PRIVATE_KEY=0x...` in your shell.
LCP RiskGuard is read-only by design and refuses to run with a
key in scope.

**Fix:** `unset PRIVATE_KEY` and re-run.

### `required binary cast not found on PATH. ...`

```
{"error":"required binary cast not found on PATH. Install Foundry (cast) and jq before invoking LCP RiskGuard."}
```

**Cause:** Foundry isn't installed or isn't on `PATH`.

**Fix:**

- Linux/macOS: `curl -L https://foundry.paradigm.xyz | bash && source ~/.bashrc && foundryup`
- Termux: see `references/anvita-upload-walkthrough.md` —
  install the Termux-packaged `foundry_1.7.1-1_aarch64.deb`.

### `LCP Skill not found at ...`

```
{"error":"LCP Skill not found at /some/path. Run install.sh first."}
```

**Cause:** The runner couldn't find the underlying `liquidity-crisis-predictor`
Skill. The runner looks for it as a sibling directory by default,
or at `$LCP_SKILL_DIR` if set.

**Fix:**

- Run `./install.sh` first — it clones the Skill into `~/LCP`.
- Or set `LCP_SKILL_DIR=/path/to/LCP` and re-run.

### `LCP Skill execution failed`

```
{"error":"LCP Skill execution failed","target":"0x...","network":"mainnet"}
```

**Cause:** The runner invoked the LCP CLI but it returned non-zero.
Most likely the RPC is unreachable or the target address is
malformed.

**Fix:**

- Test the RPC manually: `cast block-number --rpc-url https://rpc.pharos.xyz`
- Verify the address format: `cast call 0x... "symbol()(string)"` should not error.
- Run `bash ~/LCP/test/test_score.sh` to confirm the underlying
  Skill is healthy.

## Install errors

### `./install.sh: Permission denied`

**Cause:** The script isn't executable.

**Fix:** `chmod +x install.sh` then `./install.sh`.

### `pkg: command not found`

**Cause:** You're on Termux but `pkg` isn't available (rare —
Termux ships `pkg` by default).

**Fix:** `apt update && apt install -y termux-tools` (some Termux
images require this).

### `dpkg-deb: command not found` during solc install

**Cause:** On Termux, the install falls back from `dpkg-deb` to
`ar + tar` if `dpkg-deb` isn't found. If `ar` also isn't found,
the install fails.

**Fix:** `pkg install -y binutils xz-utils tar` to get `ar` and
modern `tar` with xz support.

### `libboost_filesystem.so: cannot open shared object file`

**Cause:** The Termux-packaged solc is dynamically linked and
needs `boost` and `libc++` from Termux's `pkg` repo.

**Fix:** `pkg install -y boost libc++` then re-run.

### `e_type: 2 ... unexpected` when running solc on Termux

**Cause:** The static linux-arm64 solc from `binaries.soliditylang.org`
is e_type=2 (non-PIE). Bionic rejects it. The install should
have installed the Termux-built PIE solc instead.

**Fix:** Make sure the install completed. If the static solc is
on `$PREFIX/bin/solc` from a previous failed install, remove it:

```bash
rm -f $PREFIX/bin/solc
cd ~/LCP && ./install.sh
```

### `forge test` hangs forever on Termux

**Cause:** forge is trying to download forge-std and the network
is slow / blocked.

**Fix:** Pre-clone forge-std manually:

```bash
mkdir -p ~/LCP/lib
cd ~/LCP/lib
git clone --depth 1 https://github.com/foundry-rs/forge-std.git
```

Then re-run the install.

## Runtime errors

### `band: HEALTHY` but the user expected CRITICAL

**Cause:** Either the LCP math genuinely scored the asset as
healthy (the band is honest), or the threshold filter suppressed
a CRITICAL result.

**Fix:** Check the runner's `LCP_THRESHOLD` setting. If you set
`LCP_THRESHOLD=WATCH` and the band is HEALTHY, the runner will
return `filtered:true`. Use `LCP_THRESHOLD=HEALTHY` to disable
filtering.

### `p_crisis: 0.95` but `band: HEALTHY`

**Cause:** This shouldn't happen — `p_crisis` and `band` are
derived from the same score and should be consistent. If you see
this, it's a bug in the underlying LCP Skill.

**Fix:** Open an issue on `networkbike/LCP` with the input
(`target`, `network`, block number).

### Output has `block: null`

**Cause:** The runner couldn't reach Pharos RPC to fetch the
current block number. The score and band are still valid — only
the `block` metadata field is null.

**Fix:** Retry. If the RPC is down for an extended period, try
the alternative RPC:

```bash
LCP_TARGET=0x... LCP_NETWORK=atlantic-testnet bash scripts/run.sh
```

### `jq: error: ... at top-level`

**Cause:** The runner's `jq` command line got malformed input.
Usually this means a system `jq` is older than 1.6 and doesn't
support `--argjson`.

**Fix:** Update `jq`: `brew install jq` or `apt install jq` or
`pkg upgrade jq`.

## Debugging tips

### Run the offline self-test

`bash scripts/self-test.sh` runs 8 checks against the runner
without needing any RPC. Use this first when something is wrong.

### Run the LCP Skill directly

To verify the underlying Skill is healthy:

```bash
cd ~/LCP
forge test -vvv              # should report 7 passed; 0 failed
bash test/test_score.sh      # should report 4 passed; 0 failed; 1 skipped
./examples/score.sh native:PROS mainnet  # should return JSON
```

If any of these fail, the issue is in the Skill, not the Agent.

### Check Pharos RPC health

```bash
cast block-number --rpc-url https://rpc.pharos.xyz
cast chain-id --rpc-url https://rpc.pharos.xyz
cast gas-price --rpc-url https://rpc.pharos.xyz
```

If any of these fail, the issue is the RPC, not your install.

### Run the runner with `bash -x`

For verbose tracing:

```bash
bash -x scripts/run.sh 2>&1 | head -50
```

This shows every command the runner executes. Useful for
identifying where a failure happens.

### Capture the full output

```bash
LCP_TARGET=0x... LCP_NETWORK=mainnet bash scripts/run.sh > out.json 2> err.log
echo "stdout:"; cat out.json
echo "stderr:"; cat err.log
```

If a judge asks "why did your agent return X", this is the
fastest way to capture the exact execution context.

## When all else fails

Open an issue on `networkbike/lcp-riskguard-agent` with:

1. The exact command you ran.
2. The exact output (stdout + stderr).
3. The output of `bash scripts/self-test.sh`.
4. The output of `cast --version`.
5. The output of `solc --version` (if installed).
6. Your OS (Linux/macOS/Termux, version).
7. Your architecture (x86_64/arm64).

That's usually enough to diagnose.