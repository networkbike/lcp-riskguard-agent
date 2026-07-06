# Security policy

## Read-only by design

LCP RiskGuard is a **read-only** Service Agent. It does not sign
transactions, does not hold user funds, does not require a wallet
or private key, and does not call any external HTTP oracle. Every
invocation is stateless and idempotent.

This is enforced at three layers:

### Layer 1 — Runner (defense in depth)

`scripts/run.sh` has the following checks at startup, before doing
any on-chain work:

```bash
# Refuses to run if a private key is in scope.
if [[ -n "${PRIVATE_KEY:-}" ]]; then
  echo '{"error":"PRIVATE_KEY is set; ..."}' >&2
  exit 77
fi

# Refuses to run without required binaries.
for bin in cast jq; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo '{"error":"required binary '"$bin"' not found ..."}' >&2
    exit 64
  fi
done
```

`PRIVATE_KEY` is the standard convention across the Foundry /
cast ecosystem for "I have a wallet ready to sign." LCP RiskGuard
refuses this explicitly — even if the user sets it by mistake.

### Layer 2 — Skill (no on-chain writes)

The underlying Skill (`networkbike/LCP`) is also read-only by
design. `examples/score.sh` performs only `cast call`, `cast logs`,
and `cast gas-price` reads. There is no `cast send` and no
transaction-signing code in the entire Skill codebase.

The Skill also refuses `PRIVATE_KEY`:

```bash
# from examples/score.sh (line 60)
if [[ -n "$PRIVATE_KEY" ]]; then
  echo "Refusing to run: \$PRIVATE_KEY is set. LCP is read-only." >&2
  exit 77
fi
```

### Layer 3 — Marketplace (no signing in x402)

The Anvita Flow x402 micropayment protocol is **out of band** with
respect to the Service Agent's actual logic. When a Steward Agent
calls LCP RiskGuard, the x402 settlement happens between Anvita's
infrastructure and the user's pre-authorized payment channel. LCP
RiskGuard's runner never sees a key, never co-signs anything.

While the Anvita Flow pricing beta is in progress, the unit price
is **Free** — no payment channel is opened at all.

## What LCP RiskGuard will NOT do

- Will not call `cast send` (no transaction signing)
- Will not import or hold a private key
- Will not call any HTTP oracle or external API (no `curl` from
  the runner)
- Will not write to disk beyond temp files in `$HOME/.lcp-*`
- Will not execute arbitrary user-supplied code
- Will not chain to another Agent that *does* sign (no Agent-to-
  Agent signing in this design)

## What LCP RiskGuard DOES read

- `cast block-number`, `cast chain-id`, `cast gas-price`
- `cast call <contract> "method()(type)"` — read-only contract
  queries (e.g. `getReserves`, `totalSupply`, `balanceOf`,
  `symbol`, `decimals`)
- `cast logs Transfer <filter>` — public Transfer event scan
- `assets/networks.json` — local config file with RPC URLs

Every RPC call is a public, read-only method. There is no path by
which a `cast call` or `cast logs` invocation can mutate chain
state.

## Threat model

| Threat | Mitigation |
|---|---|
| User supplies a malicious contract address | LCP reads only standard ERC-20 + UniswapV2-pair methods. A malicious token cannot exfiltrate data or sign on the user's behalf through read-only calls. |
| Pharos RPC serves wrong data | LCP's `p_crisis` logistic and band thresholds are calibrated against historical Pharos mainnet behavior. Erroneous RPC output would produce wrong scores but cannot sign or move funds. |
| Anvita Flow routing leak | The runner only accepts the documented env-var inputs (`LCP_TARGET`, `LCP_NETWORK`, `LCP_THRESHOLD`, `LCP_INCLUDE_DRIVERS`). Anything else is passed through to the LCP CLI, which validates the address format and rejects malformed input. |
| Steward Agent supplies hostile `LCP_TARGET` | The runner forwards the address verbatim to the LCP CLI. LCP's `cast call` to a non-contract address returns empty data; LCP returns `band: UNKNOWN` for tokens that don't expose standard methods. Worst case: a useless result, never a security issue. |
| `PRIVATE_KEY` accidentally in environment | Runner exits 77 with a JSON error before doing any work. |
| Dependency compromise (a malicious jq, cast, or forge) | Out of scope. LCP RiskGuard trusts the binaries on PATH. Mitigation: use the official Foundry install (`curl -L https://foundry.paradigm.xyz \| bash`) and the Termux-packaged `foundry` and `solidity` packages from `packages.termux.dev`, both of which are GPG-signed by their respective publishers. |

## Audit posture

LCP RiskGuard is built on top of:

- **`networkbike/LCP` Skill** — verified by the Pharos Skill Agent
  grader (forge test 7 passed; shell test 4 passed) and the
  manual DoraHacks review.
- **Foundry** (`cast`, `forge`) — the canonical EVM toolchain;
  widely audited, MIT-licensed, used by every major Solidity shop.
- **jq** — a single static binary, MIT-licensed, ubiquitous.

The total attack surface is small:

```
LCP RiskGuard runner (Bash, ~80 lines)
  └─ examples/score.sh (Bash, ~250 lines)
       └─ cast (Rust binary, Foundry)
       └─ jq (C binary, stedolan)
```

No npm dependencies. No Python. No JS runtime. No HTTP fetches.

## Reporting a vulnerability

If you find a security issue with LCP RiskGuard, please email the
maintainer (networkbike) rather than opening a public issue. We
will acknowledge within 48 hours and aim to ship a fix within 7
days for critical issues.

## Versioning

LCP RiskGuard follows [Semantic Versioning](https://semver.org/).
The current version is **0.1.0** (initial release for Phase 2 of
the Skill-to-Agent Dual Cascade Hackathon).

Pre-1.0 versions may have breaking changes between minor releases.
After 1.0, the API will be stable.

## License

MIT. See `LICENSE`.