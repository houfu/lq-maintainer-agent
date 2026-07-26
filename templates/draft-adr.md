# Template — draft ADR (decision-scoping artifact)

Rendered by `skills/review-pr/SKILL.md`, `skills/review-issue/SKILL.md`,
and (single-item follow-up from batch) `skills/triage/SKILL.md` for
each **structural residual decision** of an escalated item, per
`rules/decision-scoping.md` D-06/D-07. **Render, never freehand.**
Delivered exclusively inside the committee packet's Attachments
(`templates/committee-packet.md` CP-08) — the agent never commits,
files, numbers, or posts a draft (`rules/salvage.md` S-20), and no
draft ever satisfies anchoring (`rules/anchoring.md` A-12) until a
human adopts, numbers, and merges it. Forward-looking,
workflow-convention, and amends-existing-canon residuals do **not**
use this template — they use the existing S-DE DE-XXX / mini-PRD stub
and its annotated forms (D-06). The section shape below mirrors the
target project's ADR conventions and is template prose: an adopting
project rewrites this file (and `rules/canon-map.md`), nothing else.

## Field rules

- **DA-01 — Watermark first, verbatim, mandatory.** The first body
  line after the title block is exactly the watermark shown in the
  template. This file is the **single authoritative copy** of that
  line (the S-14 mandatory-verbatim-line pattern); no draft renders
  without it. `evals/run-checks.md` defines a cross-cutting blocking
  check on its verbatim presence in every drafted artifact (active
  with the M1 agent-run harness, like every blocking outcome check).
- **DA-02 — One decision per draft.** The Decision section is the
  residual's D-05 atomic sentence, expanded to at most one paragraph.
  If it cannot be written without "and", the residual was not atomic —
  return to `rules/decision-scoping.md` D-05 and split before
  drafting. Where two decision texts are both canon-consistent, render
  them as **Alternative A / Alternative B** in this one draft —
  drafted, never ranked (D-08).
- **DA-03 — Context is the ledger.** The Context section states why
  this decision is open: the escalated item, the settled ledger rows
  this decision sits between, and the nearest canon bounding the hole
  — every claim cited as a `canon:<key>` click-through link at the
  pinned canon SHA (`rules/canon-map.md` link rule; settledness is
  pin-relative, D-04). Where verified canon sources conflict, both are
  cited and the conflict is stated as a finding (D-03). For E-06
  residuals, Context **quotes what the contradicted ADR actually
  decided** (D-09). Nothing in Context is sourced from the
  contribution's narrative.
- **DA-04 — Alternatives enumerated; decision-makers human.** The
  realistic options, always including "reject: keep the status quo",
  each with the canon that bounds it and what choosing it forecloses.
  The Decision-makers line names the ratifying human role — never the
  agent, never a specific unconsulted person.
- **DA-05 — Credit.** Where the decision originated in a
  contribution, the contributor is credited by name/handle
  (`rules/salvage.md` S-22) — the idea enters canon with its origin
  attached, whether the draft is ratified or rejected.

## Template

```markdown
# ADR-XXXX (DRAFT): <title — the one decision, named>

DRAFT — drafted by lq-maintainer-agent v<x.y.z> for human
ratification. Not canon: this document anchors nothing
(rules/anchoring.md A-12) and decides nothing until a human
maintainer adopts, numbers, and merges it. Ratify, amend, or reject.

Status: Draft (unratified — ratify, amend, or reject)
Decision-makers: <the ratifying human maintainer(s) — never the agent>
Drafted-from: <PR | issue> #<n> · canon `<sha>` · agent `<x.y.z>` ·
model `<served model ID>`
Credit: <contributor name/handle, where the idea originated in the
contribution (S-22); else "n/a">

## Context

<Why this decision is open: the residual R-<i> sentence; the settled
ledger rows it sits between and the nearest canon bounding it — each
as a [canon:<key> §x / ADR-NNN / DE-XXX](link) citation at the pinned
canon SHA. If canon conflicts: both sources, cited, and the conflict
stated. For an E-06 residual: the contradicted ADR's actual decision,
quoted, and what the change wants instead (from the diff, never the
narrative).>

## Decision (proposed — unratified)

<The one atomic sentence, expanded to at most one paragraph. Where two
texts are canon-consistent:
Alternative A — <text>.
Alternative B — <text>.
Drafted, never ranked.>

## Alternatives considered

- <option, including "reject: keep the status quo"> — bounded by
  <citation>; forecloses <what>.
- <option> — bounded by <citation>; forecloses <what>.

## Consequences

<What ratifying decides and forecloses; what rejecting leaves in
place. For the escalated item that raised this: its disposition under
each outcome (e.g. "if rejected, the part is declined citing this
rejection; its salvage disposition stands").>
```
