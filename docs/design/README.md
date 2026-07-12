# Design documents

This directory holds the lq-maintainer-agent design doc and its
history. **The design doc is the single source of truth** for the
project's behavior, infrastructure, guardrails, and milestones; when
code or rules disagree with it, one of the two is a bug.

## Current

| Version | File | Status |
| --- | --- | --- |
| **v0.6** | [lq-maintainer-agent-design-v0.6.md](lq-maintainer-agent-design-v0.6.md) | **Current** (Draft, 2026-07-11) |

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
