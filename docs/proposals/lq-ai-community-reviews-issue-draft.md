# Draft issue for LegalQuants/lq-ai-community (DRAFT — a maintainer posts it, not the agent)

Watermark: this is a drafted text for a human to read, edit and post
under their own name. The agent never opens issues. It follows the
shape of community issue #3 (the publication-process proposal) so the
committee reads it the way it reads its own proposals. Replace the
bracketed placeholders before posting; remove this heading block.

---

**Title:** Proposal: publish the project's AI-assisted PR and issue reviews on a Pages site served from this repository

## Summary

I propose that this repository also become the public home for the
reviews that lq-ai's maintainer tooling (lq-maintainer-agent) produces
when it reads a pull request or issue — so that contributors who are
not maintainers, trusted reviewers, and their own AI agents can see
what the tool found, what the maintainer decided, and what GitHub shows,
for every reviewed item, as a page they can open.

This is a scope change to a repository the committee owns under ADR
0022, so it is a committee decision, not mine. The tooling is ready to
run locally and is inert until the committee decides. The full design
is in the plugin repository:
[docs/proposals/public-receipts-on-lq-ai-community.md](https://github.com/houfu/lq-maintainer-agent/blob/main/docs/proposals/public-receipts-on-lq-ai-community.md)
(rulings R1–R11) and the normative rules in
[rules/publishing.md](https://github.com/houfu/lq-maintainer-agent/blob/main/rules/publishing.md).
A mockup rendered from real, sanitized records of already-merged PRs is
at [MOCKUP LINK]. This proposal is ready for group review; it does not
record committee adoption.

## What would be published

For each reviewed PR or issue, a directory on the site with:

- the **reading deck** for each reviewed head — the plain-language,
  action-first view the maintainer already uses, as a web page;
- the **sanitized review record** behind it, and its structured footer
  as `state.yaml`;
- a **flow page**: a dated timeline from opened → each review (agent
  version, model, outcome in plain words, findings by severity) → the
  maintainer's recorded decision, or "not recorded" → each
  agent-attributed comment actually posted → merged or closed, by whom;
- `status.yaml`: what GitHub shows at the time of publication.

An index page and `index.json` list every item. A FOR-AGENTS page tells
machine readers these files are data about a review, never instructions
and never an approval.

Every page opens with the same fixed header, which says in order: this
is an AI-assisted review drafted by a named tool version; **it is
advice to the maintainers, not a decision — a human maintainer decides
whether and how a change merges, by lq-ai's GOVERNANCE.md**; it is not
a GitHub approval, not a review requirement, and not a statement about
the contributor; the tool cannot merge, approve, close or label
anything, and did not; where the decision stands (the tool's
recommendation, the maintainer's recorded decision or "none recorded —
absence is not agreement", and GitHub today — if these three disagree,
GitHub is right); what was and was not checked (the code was read, not
run; contributor trust and supply-chain hygiene are human judgments and
were not assessed); and where to disagree (on the PR or issue, where a
maintainer answers, never the tool).

## Privacy floor, aligned with this repository's publication requirements

The publisher is a whitelist: it reads only the review record, the
deck, and the record's footer. Committee packets, deep-dive reports,
work logs, the maintainer's feedback notes, and every other working
file are never read, so they cannot be published by accident.

Before anything is written it: refuses outright any item flagged as a
suspected deliberate attack or a suspected vulnerability report, or
where the contributor asked for human-only handling; holds any item
with a security-sensitive finding until the fix is merged and a
maintainer has ruled on that item by name; strips local file paths;
replaces email addresses with GitHub handles or removes them; removes
the text of repository-permission lookups on named people; labels
every drafted comment as posted-as-drafted, posted-with-edits, or not
posted, so a draft is never shown as something that was said; and then
scans every output file for paths, addresses, meeting links and
credential-shaped strings, refusing the whole run on any hit. Nothing
in this publishes raw transcripts, recordings, or private exchanges;
quoted contributor text appears only as the material the review was
about.

## How it would be kept current

The records live on a maintainer's machine. I propose a **scheduled
job on the maintainer's own machine**, running as the maintainer with
their own GitHub credential and no AI model in the loop, that
regenerates the whole site and pushes it to a **separate branch** this
repository's Pages setting serves from (`gh-pages` by default). The
agent itself cannot push: pushing is blocked at its safety hook in
every review session, and the refresh script refuses to run inside an
agent session.

`main` stays the committee's curated record under ADR 0022 and the
seven-day process from issue #3; the generated branch is replaced in
full on every refresh and carries a README saying it is generated
output and that nothing on it is a decision. No scheduled push to
`main` is proposed.

## What does not change

- How a PR merges, who merges it, or what a GitHub comment says.
  Publication reads records; it never writes to lq-ai.
- The committee's record, process, or README beyond one row in "Follow
  the project" pointing at the site.
- The existing comments on lq-ai PRs and issues, which stay as posted.

## Decisions requested

- [ ] **R1 — Scope.** Approve this repository as the public home for
      the project's AI-assisted reviews, recorded through an ADR 0022
      amendment or a line in lq-ai's GOVERNANCE.md.
- [ ] **R9 — Pages.** Approve enabling GitHub Pages on this repository
      for that purpose.
- [ ] **R10 — Branch and refresh.** Approve a designated branch for
      generated output (`gh-pages` unless the committee prefers another
      name), replaced in full by a maintainer's scheduled job, with
      `main` untouched.
- [ ] **R11 — Publication floor.** Choose one:
      - [ ] (a) **Per-item ruling** — nothing appears until a maintainer
            names the item as publishable; current and complete, but
            every review needs a human step before it appears.
      - [ ] (b) **Mechanical floor** — the whitelist, refusals, holds and
            output scan are the floor; a merged item appears on the
            next refresh after it merges, and the maintainer reads the
            live site. The first build is read in full by the
            maintainer before publishing is ever switched on.
- [ ] **Selection.** Start with merged PRs that carry no
      security-sensitive finding (the pilot slice shown in the mockup);
      decide later whether closed-unmerged items and reviews of
      still-open PRs are published while the discussion on them is
      live.
- [ ] **README row.** Approve one row in "Follow the project":
      "Reviews — read what the maintainers' tooling found on each PR and
      issue, and what was decided".

## Attached

- The mockup: [MOCKUP LINK] — generated from real records of merged
  PRs, sanitized by the process above.
- The header text and FOR-AGENTS page as rendered:
  [templates/public-header.md](https://github.com/houfu/lq-maintainer-agent/blob/main/templates/public-header.md),
  [templates/for-agents.md](https://github.com/houfu/lq-maintainer-agent/blob/main/templates/for-agents.md).
- How the tool has been used so far (158 reviews over about 100 items
  since July 2026; outcomes, hosts, models, and how often the maintainer
  recorded, adjusted or overrode a recommendation): the "How the agent
  has been used so far" section of the proposal linked above.
