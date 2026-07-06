# Releasing

How to cut a release of LCP RiskGuard.

## Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **Patch** (0.0.x) — bug fixes, no API changes.
- **Minor** (0.x.0) — new features, backwards-compatible.
- **Major** (x.0.0) — breaking changes.

Pre-1.0 versions may have breaking changes between minor
releases. After 1.0, the public contract is stable.

## Cutting a release

### 1. Pick the version number

Look at the commits since the last tag:

```bash
git log --oneline v0.1.0..HEAD
```

Decide: bug fixes only (patch), new backwards-compatible feature
(minor), or breaking change (major).

### 2. Update version references

Update the version in:

- `SKILL.md` frontmatter (`version: 0.X.Y`)
- `CHANGELOG.md` (move `[Unreleased]` to `[0.X.Y]`)
- `README.md` (the version line if you have one)

If the new release uses a different Skill version (e.g., LCP
Skill bumped from 0.2.0 to 0.3.0):

- Update `runner.sh` `skill_version` constant
- Update `references/output-schema.md` skill_version constraint
- Update the docs that reference the Skill version

### 3. Tag the commit

```bash
git tag -a v0.X.Y -m "v0.X.Y: short description"
git push origin v0.X.Y
```

### 4. Create a GitHub release

The tag push doesn't auto-create a release. Go to
`https://github.com/networkbike/lcp-riskguard-agent/releases/new`
and:

- Choose the new tag
- Title: `v0.X.Y — short description`
- Body: copy the relevant `[0.X.Y]` section from CHANGELOG.md
- Attach the upload zip (`lcp-riskguard-agent.zip`) as a release asset

### 5. Announce

Tweet / Discord / X with:

- The release tag
- A 1-sentence description
- The demo video URL
- A link to the GitHub release

## Hotfix releases

For a critical bug fix that can't wait for the regular release
cadence:

1. Branch from the latest released tag (`v0.X.Y`), not from main.
2. Fix the bug + add a regression test.
3. Tag as `v0.X.Y+1` (patch bump).
4. Cherry-pick the fix into main so it doesn't get lost.

## Pre-release versions

For work that needs to be installed by the Anvita Flow console
but isn't ready for general use:

- Use a `-alpha.N` or `-beta.N` suffix: `v0.2.0-beta.1`.
- Tag with a pre-release flag in GitHub.
- Document the pre-release status in the CHANGELOG.

## Release cadence

There is no fixed release cadence. The maintainer releases
when:

- A new feature is ready.
- A bug fix is needed.
- A Skill dependency (LCP) releases and the Agent needs to
  update to match.

## What NOT to do

- **Don't** release without updating the CHANGELOG.
- **Don't** release without bumping the version in SKILL.md.
- **Don't** release without running `make test` locally first.
- **Don't** release a major version without an `UPGRADING.md`
  guide describing how to migrate from the previous version.
- **Don't** tag a commit that hasn't been merged to main.

## What to do after the Agent Arena

If LCP RiskGuard wins at the Agent Arena (Jul 10) and gets
adopted by other developers:

- Set up CI on the repo (the workflow content is in
  `.github/CI.md`; needs a workflow-scoped PAT to enable).
- Consider cutting a 1.0 release once the API has been stable
  for a month.
- Add a "Powered by LCP RiskGuard" section to the README.

If it doesn't win:

- The repo is still useful as a reference implementation of an
  Anvita Flow Service Agent. Keep it maintained for the next
  hackathon cycle.

Either way, the maintainer commits to keeping the repo working
through Jul 24 (end of Agent Carnival).