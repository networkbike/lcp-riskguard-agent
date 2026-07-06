# LCP RiskGuard — Live Demo

A static, single-page demo of the LCP RiskGuard runner output.

## Live URL

The page is hosted on **GitHub Pages**:

```
https://networkbike.github.io/lcp-riskguard-agent/
```

Deployed from the `gh-pages` branch of this repo. The source
HTML is `demo/index.html` (also kept on `main` for discoverability).

This URL can be used in:

- The Dorahacks Phase 2 submission form (Project website field)
- The X / Twitter announcement thread (`references/x-thread.md`)
- The marketing one-pager (`references/marketing-1-pager.md`)
- README badges (under "Project Links")

## What the demo shows

The page has a form with three inputs:

1. **Target** — a Pharos address (`0x...`) or native asset
   (`native:PROS` / `native:PHRS`).
2. **Network** — `mainnet` or `atlantic-testnet`.
3. **Threshold** — minimum band to return (`HEALTHY` no filter,
   `WATCH` suppress HEALTHY, `CRITICAL` suppress HEALTHY+WATCH).

Click "Run LCP RiskGuard" to see a realistic-looking output:

- A band pill (HEALTHY / WATCH / CRITICAL).
- The 0-100 score.
- The p_crisis probability.
- Top 3 drivers, with bar charts.
- The raw JSON.

## What the demo does NOT do

The demo is a **static HTML page**, so it cannot make `cast` calls
against Pharos RPCs from the browser (CORS would block it). The
numbers shown are:

- For `native:PROS` and `native:PHRS`: pre-computed approximations
  based on actual LCP runs at the time of writing.
- For arbitrary addresses: a deterministic hash-based simulation
  that gives a realistic-looking band distribution.

**The real LCP math runs on the Anvita Flow runtime**, not in
the browser. To get the real numbers, run the Agent on Anvita:

```bash
# Local:
LCP_TARGET=native:PROS LCP_NETWORK=mainnet \
  bash ../lcp-riskguard-agent/scripts/run.sh
```

Or wait for the Agent to be published on Anvita Flow and invoke
it through Anvita On.

## Why we built it this way

Three reasons:

1. **Dorahacks "Project website" field is optional.** The page
   fills it for users who want to give judges a quick visual.
2. **No backend needed.** A static page can be hosted on any
   CDN. No server costs, no CORS issues.
3. **Honest about what it does.** The page clearly says the
   numbers are approximations. Real scores require the Anvita
   Agent.

## Files

- `index.html` — the demo page (self-contained, no external
  dependencies).

## Regenerating the deployment

The deployment lives on the `gh-pages` branch. To update it:

```bash
# Edit demo/index.html on main, then re-publish to gh-pages
git checkout gh-pages
cp ../demo/index.html .
git add index.html
git commit -m "docs(pages): update demo"
git push origin gh-pages
git checkout main
```

GitHub Pages rebuilds automatically (usually under 30 seconds).
The URL stays the same.

## Notes for judges

If you opened this URL during judging and got the cached version,
hard-refresh (Cmd-Shift-R / Ctrl-Shift-R) to get the latest
content.