# Design documents

This directory holds the lq-maintainer-agent design doc and its
history. **The design doc is the single source of truth** for the
project's behavior, infrastructure, guardrails, and milestones; when
code or rules disagree with it, one of the two is a bug.

## Current

| Version | File | Status |
| --- | --- | --- |
| **v0.5.1** | [lq-maintainer-agent-design-v0.5.1.md](lq-maintainer-agent-design-v0.5.1.md) | **Current** (Draft, 2026-07-10) |

Headline of v0.5.1: GitHub becomes the shared review state — the Triage
Receipt comment is canonical, carries a machine-readable footer, and is
updated in place; the local workspace demotes to a rebuildable cache;
partial receipts are legitimate and explicit; and a merge-commit audit
trailer gives every merged change an immutable, `git log`-queryable
triage record (§3.5, §8.4, §8.5).

## History

- **v0.4** — superseded. Carried the full behavioral derivation for
  anchoring, lanes, salvage, and receipts; v0.5.1 restates that
  behavior in condensed, normative form (§5–§9) and specifies
  infrastructure in full (§3–§4, §12). The v0.4 file has not yet been
  imported into this directory — add it here (as
  `lq-maintainer-agent-design-v0.4.md`) when recovered from the
  maintainers' archive, so the derivation trail stays public.

## Conventions

- One file per version, named
  `lq-maintainer-agent-design-v<major>.<minor>[.<patch>].md`; old
  versions are never edited or deleted.
- A new version is a PR that adds the new file and updates the table
  above; like everything judgment-bearing in this repo it takes two
  maintainer reviews (see [CONTRIBUTING.md](../../CONTRIBUTING.md)).
- Section references throughout the repo (`§4.2`, `§15 q.6`, ...) point
  into the **current** version unless a version is named explicitly.
