# For the Anvita Flow review team

This document is for whoever reviews LCP RiskGuard on the Anvita
Flow side — the person who runs the debug session, validates the
Agent Card, and decides whether to publish it to the Marketplace.

It's structured as a checklist. Walk through it top-to-bottom
during your review.

## Quick facts

- **Agent name:** LCP RiskGuard
- **Skill used:** liquidity-crisis-predictor (`networkbike/LCP` v0.2.0)
- **Runtime:** Foundry 1.7.1, solc 0.8.31, jq, bash
- **Networks:** Pharos Mainnet (1672), Pharos Atlantic Testnet (688689)
- **Pricing:** Free (during Anvita Flow payment beta)
- **Read-only:** yes (explicitly refuses PRIVATE_KEY)
- **Test gates:**
  - `forge test -vvv` against the LCP Skill: 7 passed
  - `bash test/test_score.sh`: 4 passed, 1 skipped
  - `bash scripts/self-test.sh` against the runner: 8 passed
  - `forge test -vvv` against the Agent's output shape: 11 passed

## Review checklist

### 1. Upload zip structure

```bash
unzip -l lcp-riskguard-agent.zip
```

Verify:

- [ ] `SKILL.md` exists at `lcp-riskguard-agent/SKILL.md` (NOT at the zip root)
- [ ] `scripts/`, `references/`, `assets/` folders are present
- [ ] No `lib/forge-std/` cruft (we use Anvita's runtime, not vendored deps)

### 2. SKILL.md frontmatter

```bash
unzip -p lcp-riskguard-agent.zip lcp-riskguard-agent/SKILL.md | head -15
```

Verify:

- [ ] `name: lcp-riskguard-agent` (matches folder name)
- [ ] `description:` is a single sentence (not multi-paragraph)
- [ ] `metadata.framework: Anvita Flow` is present
- [ ] `metadata.skills_used:` references `liquidity-crisis-predictor`

### 3. Runtime configuration

Recommended values (the agent defaults):

- **Max concurrent sessions:** 5 (free tier, low traffic expected)
- **Max single execution time:** 30 seconds (runner takes ~8s; 30s
  gives a 3.7x safety margin)

### 4. Agent Card

All 8 fields are pre-filled in `references/agent-card.md`. They
should paste cleanly into the Developer Console.

Pay particular attention to:

- **Example tasks (≥2 required):** we provide **5**. More than
  the minimum helps Steward Agents match this Agent to a wider
  variety of user queries.
- **Pricing:** set to **Free** (per the campaign's explicit
  guidance during the Anvita payment beta).
- **Customer service strategy:** explicit four-step plan
  (parse → ask → confirm → deliver) is in
  `references/agent-card.md` under that heading.

### 5. Debug session

Click "Debug" in the Developer Console and run this request:

```
Score native:PROS on Pharos mainnet. Show the band and top 3 drivers.
```

Expected:

- **Response time:** ~8 seconds.
- **Exit code:** 0.
- **Output:** JSON on stdout, with `band: HEALTHY`, `score: 18-ish`,
  `p_crisis: 0.04-ish`, drivers array, timestamp, block, skill,
  skill_version. Exact numbers vary because the underlying
  RPC state changes block-to-block.

If you get an error, the most likely causes:

| Error | Cause | Fix |
|---|---|---|
| `LCP Skill not found` | The Anvita runtime didn't bundle the Skill | Re-upload the zip; ensure `scripts/` contains `run.sh` |
| `cast not found` | Anvita's runtime is missing Foundry | File a Discord bug; this is an Anvita-side issue |
| `RPC unreachable` | Pharos mainnet is down | Retry; or test against `atlantic-testnet` instead |

### 6. Safety audit

Verify the Agent's read-only guarantees:

- [ ] Set `PRIVATE_KEY=0x...` in the debug environment. The Agent
      should refuse with exit 77 and a JSON error.
- [ ] Run the Agent without a private key. It should succeed.
- [ ] Run `bash scripts/self-test.sh` in the debug environment.
      All 8 checks should pass.

The runner source is in `scripts/run.sh` — review the first 30
lines for the defensive checks:

```bash
if [[ -n "${PRIVATE_KEY:-}" ]]; then
  echo '{"error":"PRIVATE_KEY is set; ..."}' >&2
  exit 77
fi

for bin in cast jq; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo '{"error":"required binary '"$bin"' not found ..."}' >&2
    exit 64
  fi
done
```

### 7. Output schema verification

The output conforms to the JSON Schema in
`references/output-schema.md`. Quick visual check:

- `target` is a 0x... or `native:...` string
- `network` is `mainnet` or `atlantic-testnet`
- `band` is `HEALTHY` / `WATCH` / `CRITICAL` / `UNKNOWN`
- `score` is 0-100 integer
- `p_crisis` is 0-1 float
- `drivers` is an array of `{signal, contribution}` objects
- `timestamp` is ISO-8601 with `Z` suffix
- `block` is a positive integer (or absent if RPC failed)
- `skill` is `liquidity-crisis-predictor`
- `skill_version` is `0.2.0` (semver)

### 8. Acceptance

If all of the above checks pass, the Agent is ready to publish
to the Marketplace. Approve it.

## Common review questions (anticipated)

**Q: Why does the Agent wrap only one Skill?**
A: Phase 2 prioritizes "production-grade primitives" over
multi-Skill complexity. LCP RiskGuard demonstrates the
Skill + Agent + composability pattern. Other Skills (gas oracle,
price feed, exit-plan recommender) can be added to the same
Agent later. See `references/composability-roadmap.md`.

**Q: Why is the price Free?**
A: Per the campaign's explicit guidance during the Anvita Flow
payment beta: "Set the price to Free until beta ends to avoid
call failures."

**Q: Is this Agent a trading bot?**
A: No. It's read-only by design. It returns a band; what the
user does with the band is up to them. The Agent cannot sign
transactions, hold user funds, or call external oracles.

**Q: Can the Agent work on other chains?**
A: No, Pharos-only. The underlying Skill is Pharos-specific.
Cross-chain support is roadmap but not in v0.1.0.

**Q: How do I verify the Skill's math?**
A: The Skill ships its own test suite: `forge test -vvv` reports
7 passed; `bash test/test_score.sh` reports 4 passed; the math
is documented in `references/scoring-model-explained.md`.

## Contact

For questions during the review, see the GitHub repo:
https://github.com/networkbike/lcp-riskguard-agent

If something is unclear or broken, open an issue. The
maintainer is responsive within 24 hours.