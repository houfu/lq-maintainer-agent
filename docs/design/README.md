# Design documents

This directory holds the lq-maintainer-agent design doc and its
history. **The design doc is the single source of truth** for the
project's behavior, infrastructure, guardrails, and milestones; when
code or rules disagree with it, one of the two is a bug.

## Current

| Version | File | Status |
| --- | --- | --- |
| **v0.7.2** | [lq-maintainer-agent-design-v0.7.2.md](lq-maintainer-agent-design-v0.7.2.md) | **Current** (Adopted 2026-08-06; delta over v0.7.1 — proposal and rulings in [../proposals/v0.7.2-labels-breaking-changes-release-narrative.md](../proposals/v0.7.2-labels-breaking-changes-release-narrative.md) and [../proposals/deck-leanness.md](../proposals/deck-leanness.md)) |
| v0.7.1 | [lq-maintainer-agent-design-v0.7.1.md](lq-maintainer-agent-design-v0.7.1.md) | Base document — normative where v0.7.2 is silent (Adopted 2026-07-30; delta over v0.7) |
| v0.7 | [lq-maintainer-agent-design-v0.7.md](lq-maintainer-agent-design-v0.7.md) | Base document — normative where v0.7.1 is silent |
| v0.6 | [lq-maintainer-agent-design-v0.6.md](lq-maintainer-agent-design-v0.6.md) | Base document — normative where v0.7 is silent |

Headline of v0.7.2 — three features that compose, plus a leaner deck:
the agent's classification now **projects onto the target repo's own
labels** (a new express skill for the first touch on arrival; labels
are outputs only, nothing ever routes on them, and the security
carve-outs bind them as public output); **breaking changes are
detected mechanically** from the diff (a new deterministic check
script feeding the RV-02 public-API irreversible class — a detection
blocks the quick pass, a PASS proves nothing); a new skill drafts the
target repo's **release narrative** from merge trailers and receipt
evidence, breaking changes leading, semver suggested but never
decided; and the deck's **visible spine** is now normative — findings
and the paste-ready drafts lead, the ruling rides one decision card,
and the scaffolding folds away. An always-on labeling service was
considered and rejected as M4 territory.

Headline of v0.7.1 — four normative changes drawn from real maintainer
field sessions on `legalquants/lq-ai` in July 2026: every finding now
carries an **impact**, an **ask**, and a **scope** (in-scope /
follow-up / pre-existing), bound at every tier by the new
maintainer-actionability test (L-33b); batch triage gains **merge-order
groups**, a **mergeability table**, and a security-first digest for
queues where multiple open PRs collide on a shared manifest/lockfile,
report-only throughout; the maintainer's recorded ruling now **syncs
from live GitHub state** at finalize and resume, so GitHub's own record
of what happened always wins over a stale in-session guess; and a
squash-merge message now preserves every contributor's `Signed-off-by`
and adds a `Co-authored-by` per squashed author, with a plain-language
explainer of what the two trailers certify.

Headline of v0.7 ("Momentum") — the maintainer decisions from the
first 2–3 weeks of live operation: every contribution is treated as
sincere and with respect (probing/challenging language is banned and
tone-gated); reviewers defer to authors; the canon is amenable to
change; PRs classify into four change categories with categories 2–3
(behavioral changes, bug fixes) as the review target and category 1
(greenfield / the DE series) routed to a design path that drafts the
plan, ADRs, and atomic decomposition; review is tiered with a
quick-pass default (≤400 lines) that must end in a concrete action
with its undo path; conservatism attaches to irreversibility instead
of uncertainty; escalation softens where it was decision-shaped (E-04
retired for categories 2/3, the agent now recommends on escalated
items) while every security trigger stays absolute; and the
deliverables split public/internal — the deck becomes the public
primary artifact (bound for a community repo), the PR comment shrinks
to a short warm note, and the receipt becomes internal evidence.

Headline of v0.6 — the decisions taken in the 2026-07-11 maintainer
review, grounded in the research report below: the fast lane becomes
deterministic-first (scripted semver/OSV/release-age checks decide
merge-candidacy; the LLM anchors and flags anomalies, §5.1); every
receipt carries an attribution line and a fourth pinned field, the
served model ID (§8, §3.4); the receipt footer is versioned and
restricted to structured fields (§8.4); contributors get a published
bot-behavior page and a contest/hold path (§7.1); salvage gains an
AI-slop disposition (§6.1) and its mechanical split ships as an
explicitly-unverified advisory (§6); injection posture is hardened
with Unicode normalization and the agent-instruction-files trigger
(§10.2); the stale sweep gets guardrails (§7); the deep dive gets a
finding-filter stage and severity cap (§9); and hook limits are
documented honestly rather than overclaimed (§10.1).

## Evidence base

The v0.6 decisions draw on
[../research/prd-research-report.md](../research/prd-research-report.md)
(2026-07, twelve research dimensions, sources inline). Statements
marked *(research 2026-07)* in the design doc were adopted from that
review and are revisitable on evidence.

## History

- **v0.5.1** —
  [lq-maintainer-agent-design-v0.5.1.md](lq-maintainer-agent-design-v0.5.1.md),
  superseded by v0.6. Headline: GitHub becomes the shared review state
  — the Triage Receipt comment is canonical, carries a
  machine-readable footer, and is updated in place; the local
  workspace demotes to a rebuildable cache; partial receipts are
  legitimate and explicit; and a merge-commit audit trailer gives
  every merged change an immutable, `git log`-queryable triage record.
- **v0.4** — superseded. Carried the full behavioral derivation for
  anchoring, lanes, salvage, and receipts; v0.5.1 and v0.6 restate
  that behavior in condensed, normative form. The v0.4 file has not
  yet been imported into this directory — add it here (as
  `lq-maintainer-agent-design-v0.4.md`) when recovered from the
  maintainers' archive, so the derivation trail stays public.

## Conventions

- One file per version, named
  `lq-maintainer-agent-design-v<major>.<minor>[.<patch>].md`; old
  versions are never edited or deleted.
- A new version is a PR that adds the new file and updates the table
  above; like everything judgment-bearing in this repo it takes two
  maintainer reviews (see [CONTRIBUTING.md](../../CONTRIBUTING.md)).
- Section references throughout the repo (`§5.1`, `§15 q.2`, ...)
  point into the **current** version unless a version is named
  explicitly.
