# LQ Maintainer Agent — Design Doc v0.7.1

**Status: adopted 2026-07-30.** This document is a **delta over v0.7**
(`lq-maintainer-agent-design-v0.7.md`, "Momentum"): it records four
normative changes drawn from real maintainer field sessions on
`legalquants/lq-ai` in July 2026 (PRs 316, 398, 399, 441; a dependabot
queue sweep; the mkorpela squash). Where this document is silent, v0.7
remains normative, and where v0.7 is silent, v0.6 remains normative
beneath it. Section references of the form "§N" without a version
refer to v0.7.

## 1. The finding contract (amends §7, `rules/lanes.md` L-33)

**Prompted by:** findings like "does not touch a test" and "empty JWT
secret skips the guard" reached the maintainer with no statement of
what actually breaks and no concrete next step — scope (is this the
PR's problem?) then got litigated by hand, PR by PR.

Every finding now carries three fields beyond severity and citation:
**impact** (what goes wrong, for whom, if left unaddressed), **ask**
(who does what next, phrased as a request), and **scope** — exactly
one of *in-scope*, *follow-up* (drafted as an issue stub the human
files), or *pre-existing*. A new binding test, **L-33b**, applies at
every tier including Tier 1: a finding that leaves the reader asking
"so what do I do?" is incomplete, however accurate its diagnosis;
`rules/tone-gate.md` TG-01 defers to L-33b rather than restating it.
The filter stage (§7 Tier-2 finding filter) now rejects any finding
missing impact or ask, and out-of-diff observations land as scoped
*pre-existing*/*follow-up* findings instead of vanishing into a bare
coverage note. Mirrored into the rendered finding block, the receipt
footer tuple, `templates/triage-card.md`, `templates/receipt-issue.md`,
and `skills/review-pr/references/member-constraints.md`.

## 2. Batch queue intelligence (new; `rules/queue.md`, Q-NN)

**Prompted by:** running a full dependabot sweep, a maintainer asked
for a table showing which open PRs collide on merge order, which
should be prioritized (fastapi/starlette/cryptography, named because
they carried advisories), and said babysitting each PR's rebase by
hand "seems a bit painful."

Batch mode (`/lq-maintainer:triage`) now computes **merge-order
groups** from the fetched `files` field alone (never a label or title)
— two or more open PRs touching the same dependency manifest/lockfile.
Within a group, the recommended order puts advisory-backed/
security-relevant members first (read off signals the deterministic
gate already computed — the F-05 OSV lookup and the anchor — never off
a PR body's own urgency framing), then an order minimizing the rebase
cascade for what remains; the digest states, per remaining PR, exactly
what merging the first one invalidates. The triage fetch gains
`mergeable`, `mergeStateStatus`, and `baseRefName` to support this —
these feed the queue computation only and never move a lane, category,
or tier call. The digest itself reorders security-first (escalations
lead) and gains a mergeability table and a merge-order-groups section,
each digest line naming its item's deck path (the digest is now the
deck index). **Report-only, absolute (Q-03):** the agent never merges,
rebases, or re-triggers CI for any group member — one human click per
write stands exactly as everywhere else.

## 3. GitHub-state-wins ruling sync (amends §8 amendment, RP-18)

**Prompted by:** a maintainer who had already ruled on a PR through
normal GitHub review asked the agent to read the PR itself for the
decision rather than trusting what the chat session remembered.

At finalize, and again on any resumed session, the skill now reads
live GitHub state (`gh pr view --json state,mergedAt,mergeCommit`)
before recording or re-displaying the `### Maintainer decision`
section. **GitHub state wins over a previously recorded ruling** —
if the PR was merged or closed by a route the session didn't observe,
that fact overrides a stale in-session guess. Any discrepancy between
recorded and observed state surfaces as a dated note, never a silent
rewrite; §8's rule that an absent block reads as "not yet decided",
never as agreement, is unchanged and still holds where GitHub itself
shows no resolution. Mirrored into RI-13 and into the finalize/resume
steps of all three review skills (`triage`, `review-pr`,
`review-issue`).

## 4. Squash attribution (new; `templates/merge-message.md`, MM-05a)

**Prompted by:** a contributor squash-merge (the mkorpela PR) where
maintainers had to work out by hand what two `Signed-off-by` trailers
meant and how to keep every squashed author's credit in a single
commit.

The drafted squash-merge message now preserves each contributor's
`Signed-off-by` trailer, adds a `Co-authored-by` line per distinct
squashed author, fixes the trailer order, and carries a plain-language
explainer of what the two certifications (the contributor's DCO
sign-off on the contribution's origin vs. the maintainer's sign-off on
the separate act of merging it) mean. The agent still never signs anything
itself — it drafts the trailer block; the maintainer's own sign-off
happens at their own merge click, unchanged from §8.5. The stale
`receipt at <receipt-comment-url>` placeholder in the same template is
also fixed to point at the evidence store, matching §8's "receipt
becomes internal evidence" (receipts stopped being PR comments in v0.7).

## 5. What does not change

Everything in v0.7 §10 ("What does not change") holds verbatim: a
human decides every write; the agent never executes contributed code;
the injection posture; the deterministic dependency gate; canon
grounding; the four pinned fields; the conservative slop bar. The
renderer's deck-legibility work this same cycle (severity-split
findings, glossed dispositions/scope, the "Why this escalated" card,
the renderer's own version stamp in the provenance footer) is an
implementation change to `skills/triage/scripts/render-deck.sh`, not a
design decision — it renders what §1–§4 above already made normative,
and is recorded in `CHANGELOG.md` rather than here.
