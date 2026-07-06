# LCP RiskGuard — what you need to do (Jul 6 – Jul 10)

A flat checklist for the next 4 days. Everything in this doc is
something only **you** can do — agent does the rest.

## Status as of Jul 6 ~11:00 UTC

✅ Repo is comprehensive: 15 commits, ~25 docs, all tests passing
✅ Live demo on GitHub Pages: https://networkbike.github.io/lcp-riskguard-agent/
✅ Install works on Termux: forge test 7/7, runner smoke-tested
✅ All submission materials pre-written in `references/`

## Jul 6 (today) — 1 hour

- [ ] **Record the demo video** on your phone using
      [`references/demo-recording-timed.md`](references/demo-recording-timed.md)
      as the script. ~30 min including retakes.
- [ ] Upload to YouTube (public or unlisted). Get the URL.
- [ ] (Optional) Cross-post to a backup location (your own
      Google Drive, etc.) in case YouTube is slow.

**Why today:** you have the most energy for recording now, and
it gives you a 3-day buffer before the submission deadline.

## Jul 7 — 30 min

- [ ] **Re-read [`references/for-judges.md`](references/for-judges.md)**
      with fresh eyes. Tweak if needed.
- [ ] **Re-read [`references/dorahacks-form-prefill.md`](references/dorahacks-form-prefill.md)**
      and fill in any blanks I marked as "(YOU fill this in)".
- [ ] **Pre-stage the upload zip** so it's ready:
      ```bash
      cd ~
      zip -r lcp-riskguard-agent.zip lcp-riskguard-agent/
      ls -la lcp-riskguard-agent.zip
      ```
      Confirm the size is 50-150 KB and the file
      `lcp-riskguard-agent/SKILL.md` is at the inner root, not
      the zip root.
- [ ] **(Optional) Watch this URL:** https://docs.pharos.xyz/tooling-and-infrastructure/overview/publish-skill-af
      — if it loads, look for any spec changes that affect
      the upload steps.

## Jul 8 11:00 UTC (7 PM HKT) — 30 min

The Anvita Flow upload window opens.

- [ ] **Open** https://flow.anvita.xyz/service-agents
- [ ] **Click "Upload Service Agent"**
- [ ] **Upload `lcp-riskguard-agent.zip`** from Termux
      (or from a desktop if you have one — same file)
- [ ] **Fill the Agent Card** by pasting from
      [`references/agent-card.md`](references/agent-card.md).
      Eight fields, all pre-written.
- [ ] **Set price to Free** (per Anvita payment beta guidance).
- [ ] **Save as draft.** Don't submit yet.

## Jul 8–9 — debug session

- [ ] **Click "Debug"** in the Anvita console
- [ ] **Run the example task** from
      [`references/for-anvita-team.md`](references/for-anvita-team.md):
      "Score native:PROS on Pharos mainnet. Show the band and top 3 drivers."
- [ ] **Verify the output** looks like the JSON in
      [`references/example-outputs.md`](references/example-outputs.md)
- [ ] **Test the PRIVATE_KEY defense:** set `PRIVATE_KEY=0x...`
      in the debug env, run again. Confirm the Agent refuses
      with exit 77.
- [ ] **File any issues** in the GitHub repo with the tag
      `anvita-debug`.

## Jul 9 — polish round

- [ ] Update README with the YouTube demo URL (replace the
      `(YOU fill this in after recording...)` line)
- [ ] Commit + push the demo URL update
- [ ] (Optional) Tag a `v0.1.0` release on the repo
- [ ] Post the announcement thread on X (use
      [`references/x-thread.md`](references/x-thread.md)) — tag
      `@Pharos_Network`, `@AnvitaFlow` (if exists), `@DoraHacks`

## Jul 10 10:00 UTC (6 PM HKT) — submission day

Dorahacks releases the Phase 2 submission form.

- [ ] **Open the form** (Dorahacks will email or post the link)
- [ ] **Paste each field** from
      [`references/dorahacks-form-prefill.md`](references/dorahacks-form-prefill.md)
- [ ] **Upload the demo video URL** (YouTube link)
- [ ] **Set Project website** to https://networkbike.github.io/lcp-riskguard-agent/
- [ ] **Submit.** You're done.

## After Jul 10 — promotion

- [ ] **Pin the X thread** to your profile
- [ ] **Cross-post to Discord** (`#pharos`, `#skill-submission`)
- [ ] **Tag relevant accounts** in any quote-tweets of the thread
- [ ] **Monitor the GitHub repo** for issues filed by judges or
      users; respond within 24 hours

## Critical rules — DO NOT skip

### Don't push changes during Jul 8-10 unless asked

If you need a code change after Jul 8, **ask the agent first**.
Don't `git push` manually — agent handles the credential dance.

### Don't claim to have won before the announcement

The hackathon results won't be public for ~2 weeks after
submission. Don't say "we won" in any post.

### Don't add a wallet, signing key, or external oracle

LCP RiskGuard is read-only by design. If anyone (judge, user,
reviewer) asks "can it also do X with my wallet?", the answer
is "no, by design — see ADR-002". This is a feature, not a
limitation.

### If something breaks

1. Check the GitHub Issues for known issues
2. Take a screenshot of the error
3. Send it to the agent with the tag `error` or `bug`
4. Don't try to fix it locally without consulting — Termux
   install fixes are non-obvious

## Reference docs by audience

| You want to... | Read this |
|---|---|
| Show judges a 30-second pitch | `references/for-judges.md` |
| Fill the Dorahacks form | `references/dorahacks-form-prefill.md` |
| Record the demo video | `references/demo-recording-timed.md` |
| Post on Twitter/X | `references/x-thread.md` |
| Write a blog post | `references/marketing-1-pager.md` |
| Understand the API | `references/for-steward-agents.md` |
| Help Anvita review | `references/for-anvita-team.md` |
| Find any doc | `docs/INDEX.md` |

## If you have nothing else to do today

Optional polish:

- [ ] Read `KNOWN_LIMITATIONS.md` — understand the trade-offs
- [ ] Read `ARCHITECTURE_DECISION_RECORD.md` — understand the 5 ADRs
- [ ] Skim `GLOSSARY.md` — internalize the terminology

These don't change anything; they just make you more confident
if a judge asks a deep technical question.

---

That's it. 4 days, ~3 hours of work, all the heavy lifting is
already in the repo. **You're in good shape.** 🎯