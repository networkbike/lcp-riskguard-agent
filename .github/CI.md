# CI workflow — manual setup

The CI workflow for `networkbike/lcp-riskguard-agent` is held back
from the public repo because the GitHub PAT used during Phase 2 of
the hackathon has only `repo` scope, not `workflow` scope. Pushing a
`.github/workflows/*.yml` file requires `workflow` scope on the PAT;
GitHub refuses the push otherwise.

The workflow content is below. To enable CI on the repo:

1. Create a new PAT with `repo` + `workflow` scope:
   `https://github.com/settings/tokens/new`
2. Save the workflow file below as
   `.github/workflows/ci.yml` in your local clone of this repo.
3. Push with the new PAT. After the first successful push, the
   `workflow`-scoped PAT is no longer needed — you can switch back
   to a `repo`-only PAT.

## Workflow content

Copy this to `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test-skill:
    name: forge test -vvv (Phase 1 Skill)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          repository: networkbike/LCP
          path: LCP

      - name: Install Foundry
        run: |
          curl -L https://foundry.paradigm.xyz | bash
          source $HOME/.bashrc
          foundryup

      - name: Run forge test -vvv
        working-directory: LCP
        run: forge test -vvv

      - name: Run shell smoke test
        working-directory: LCP
        run: bash test/test_score.sh

  test-agent:
    name: Service Agent smoke test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Foundry + jq
        run: |
          curl -L https://foundry.paradigm.xyz | bash
          source $HOME/.bashrc
          foundryup
          sudo apt-get install -y jq

      - uses: actions/checkout@v4
        with:
          repository: networkbike/LCP
          path: ../liquidity-crisis-predictor

      - name: Build the LCP Skill
        working-directory: ../liquidity-crisis-predictor
        run: |
          if [ ! -d lib/forge-std ]; then
            git clone --depth 1 https://github.com/foundry-rs/forge-std.git lib/forge-std
          fi
          forge build

      - name: Smoke-test the runner (against native:PROS mainnet)
        working-directory: ${{ github.workspace }}
        env:
          LCP_TARGET: native:PROS
          LCP_NETWORK: mainnet
          LCP_SKILL_DIR: ${{ github.workspace }}/../liquidity-crisis-predictor
        run: bash scripts/run.sh | jq .

  lint-zip:
    name: Validate upload zip structure
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build the zip
        run: |
          cd ..
          zip -r lcp-riskguard-agent.zip lcp-riskguard-agent/ -x "*.git*"
          ls -la lcp-riskguard-agent.zip

      - name: Verify SKILL.md at root of folder, not at zip root
        run: |
          cd ..
          if unzip -l lcp-riskguard-agent.zip | grep -q "lcp-riskguard-agent/SKILL.md"; then
            echo "OK: SKILL.md is at the root of the inner folder."
          else
            echo "FAIL: SKILL.md is not at lcp-riskguard-agent/SKILL.md"
            exit 1
          fi
          if unzip -l lcp-riskguard-agent.zip | grep -E "^\s*[0-9]+\s+[0-9-]+\s+[0-9:]+\s+SKILL\.md\s*$"; then
            echo "FAIL: SKILL.md appears at the zip root (should be inside the folder)"
            exit 1
          fi
          echo "OK: SKILL.md is not at the zip root."

      - name: Verify the frontmatter name matches the folder
        run: |
          cd ..
          NAME=$(awk '/^name:/ {print $2; exit}' lcp-riskguard-agent/SKILL.md)
          if [ "$NAME" = "lcp-riskguard-agent" ]; then
            echo "OK: frontmatter name '$NAME' matches folder."
          else
            echo "FAIL: frontmatter name '$NAME' does not match folder 'lcp-riskguard-agent'"
            exit 1
          fi
```

## What this CI does

1. **`test-skill`** — checks out the Phase 1 Skill (`networkbike/LCP`),
   installs Foundry, runs `forge test -vvv` and `bash test/test_score.sh`.
   Confirms the underlying Skill is still green.
2. **`test-agent`** — checks out this repo, installs Foundry + jq,
   also checks out the LCP Skill as a sibling, runs the Service
   Agent runner (`scripts/run.sh`) against `native:PROS mainnet` and
   pipes through `jq` to confirm valid JSON.
3. **`lint-zip`** — builds the upload zip the same way a developer
   would (`cd .. && zip -r lcp-riskguard-agent.zip lcp-riskguard-agent/`),
   then verifies:
   - `SKILL.md` exists at `lcp-riskguard-agent/SKILL.md` inside the zip
   - `SKILL.md` is **not** at the zip root (Anvita Flow rejects that)
   - The frontmatter `name:` field matches the folder name
     (`lcp-riskguard-agent`)

A green CI run means the upload zip is structurally valid and the
underlying Skill still passes its gates. The same checks should pass
in your local environment before you upload to Anvita Flow.

## Why this matters for the Agent Arena

The Anvita Flow / Pharos grader scans the uploaded Skill + Agent and
will run them. If the underlying Skill (`networkbike/LCP`) ever goes
red, this Agent will silently break. CI here is a canary — it makes
sure you're notified if the Skill breaks, before a judge finds it.