# Documentation index

Every document in this repo, organized by audience and purpose.

## For judges / Anvita Flow reviewers

| Doc | Why read it |
|---|---|
| `README.md` | First impression, quick start, what's inside |
| `SKILL.md` | The Agent Card metadata; one-sentence description for Marketplace search |
| `references/agent-card.md` | All 8 Agent Card fields pre-filled, copy-paste ready |
| `references/example-outputs.md` | What the Agent returns: 5 canonical JSON shapes |
| `references/installation-flow.md` | Architecture diagram, end-to-end flow |
| `references/safety-model.md` | Why read-only wins |
| `references/comparison.md` | vs pharos-skill-engine, pharos-agent-kit, x402-pharos, etc. |
| `references/scoring-model-explained.md` | How the LCP math works (deep dive) |
| `references/output-schema.md` | Formal JSON Schema for the output |

## For submitters (you, Jul 8)

| Doc | Why read it |
|---|---|
| `references/anvita-upload-walkthrough.md` | 7-screen walkthrough for the Developer Console |
| `references/phase2-submission-prep.md` | Every form field pre-written |
| `references/demo-video-script.md` | 5-scene screencast script |
| `references/example-outputs.md` | JSON shapes for the Deliverables field |

## For users / operators

| Doc | Why read it |
|---|---|
| `README.md` | Quick start (`git clone && ./install.sh`) |
| `FAQ.md` | Anticipated questions |
| `references/troubleshooting.md` | Common errors + fixes |
| `references/glossary.md` | Pharos / Web3 / LCP terms |
| `references/composability-roadmap.md` | Future Skills + Agents |

## For engineers / contributors

| Doc | Why read it |
|---|---|
| `SECURITY.md` | Read-only guarantees, threat model, audit posture |
| `references/architecture-decision-record.md` | 5 ADRs explaining the major choices |
| `CONTRIBUTING.md` | How to contribute |
| `CODE_OF_CONDUCT.md` | Contributor Covenant + finance norms |
| `CHANGELOG.md` | Version history (Keep a Changelog format) |
| `references/output-schema.md` | The output contract (machine-readable) |
| `references/known-limitations.md` | Transparent list of things the Agent does NOT do |
| `.github/CI.md` | CI workflow content (held back; PAT is repo-only) |
| `.github/ISSUE_TEMPLATE/*.md` | Bug + feature request templates |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR checklist |

## Self-contained docs

| Doc | Description |
|---|---|
| `references/anvita-upload-walkthrough.md` | Step-by-step Jul 8 upload |
| `references/phase2-submission-prep.md` | Pre-written Dorahacks Phase 2 answers |
| `references/demo-video-script.md` | 5-scene screencast script |
| `references/example-outputs.md` | Canonical JSON outputs |
| `references/installation-flow.md` | ASCII architecture diagram |
| `references/safety-model.md` | Why read-only wins |
| `references/comparison.md` | Head-to-head with other tools |
| `references/scoring-model-explained.md` | Deep dive on LCP math |
| `references/output-schema.md` | JSON Schema for output |
| `references/glossary.md` | Pharos / Web3 / LCP terms |
| `references/troubleshooting.md` | Common errors + fixes |
| `references/architecture-decision-record.md` | 5 ADRs |
| `references/composability-roadmap.md` | Future Skills + Agents |

## Top-level files

| File | Description |
|---|---|
| `README.md` | Project landing page |
| `LICENSE` (MIT) | Open-source license |
| `CHANGELOG.md` | Version history |
| `CONTRIBUTING.md` | Contribution guide |
| `CODE_OF_CONDUCT.md` | Community standards |
| `SECURITY.md` | Security model |
| `SKILL.md` | Anvita Flow upload manifest |
| `Makefile` | `make test`, `make install`, `make compare`, etc. |
| `foundry.toml` | Forge config for the runner output-shape tests |
| `RELEASING.md` | Release process, versioning, hotfixes |

## `scripts/`

| File | Purpose |
|---|---|
| `install.sh` | Local smoke-test installer |
| `run.sh` | The Service Agent runner |
| `self-test.sh` | 8 offline runner checks (no RPC required) |
| `benchmark.sh` | End-to-end latency benchmark |
| `compare.sh` | Multi-target comparison (N tokens, sorted by p_crisis) |
| `test/capture-output.sh` | Regenerate the test/fixtures/*.json from the runner |

## `references/`

See the "self-contained docs" table above.

## `test/`

| File | Purpose |
|---|---|
| `LCPRiskGuard.t.sol` | 11 forge tests verifying the runner output shape |
| `capture-output.sh` | Regenerate the JSON fixtures |
| `fixtures/sample-output.json` | HEALTHY-band fixture (committed) |
| `fixtures/sample-filtered.json` | Filtered-output fixture (committed) |
| `LCP.t.sol` | (optional, when including the underlying Skill's tests) |

## `.github/`

| File | Purpose |
|---|---|
| `CI.md` | CI workflow content (held back because PAT is repo-only) |
| `ISSUE_TEMPLATE/bug_report.md` | Bug report template |
| `ISSUE_TEMPLATE/feature_request.md` | Feature request template |
| `PULL_REQUEST_TEMPLATE.md` | PR template with checklist |

## What to read first

| If you are... | Read first... |
|---|---|
| A judge with 5 minutes | `README.md` + `references/example-outputs.md` |
| A judge with 30 minutes | `README.md` + `references/agent-card.md` + `references/installation-flow.md` + `references/safety-model.md` + `references/comparison.md` |
| A submitter | `references/anvita-upload-walkthrough.md` + `references/phase2-submission-prep.md` |
| An engineer | `SECURITY.md` + `references/architecture-decision-record.md` + `references/output-schema.md` |
| A contributor | `CONTRIBUTING.md` + `references/architecture-decision-record.md` |
| An operator | `README.md` + `FAQ.md` + `references/troubleshooting.md` |

Pick the path that matches your role. Each path is self-contained
— you don't need to read the rest.