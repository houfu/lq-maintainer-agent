# Salvage Protocol

Normative rules for decomposing overreaching contributions so their
valuable parts survive. Applies to **both PRs and issues**. Loaded by
`skills/triage/SKILL.md` and `skills/review-pr/SKILL.md`; do not
paraphrase these rules elsewhere — cite them by ID.

The failure mode this protocol exists to prevent is binary
merge-the-blob / reject-the-enthusiast. Contributors — often working
with AI assistants — tend to overdeliver; the agent's job is to make
sure the good parts have a path forward and the contributor hears that
first.

Salvage on **issues** is the cheapest, highest-value application: a
decomposed *idea* means the 400-line PR never gets written. Never skip
salvage on an issue because "it's only text."

## Triggers

Apply this protocol when any of the following holds:

- **S-01 — Scope-legibility failure.** The item cannot be stated as a
  single change in one sentence ("this PR does X"). If describing it
  honestly requires "and", it triggers.
- **S-02 — Multi-concern diff.** (PRs) The diff mixes separable
  concerns — e.g. a bug fix plus a refactor, a feature plus new
  dependencies, docs plus code, formatting churn plus substance —
  regardless of how the PR body describes itself. Judge from the
  hunks, not the narrative (see `rules/injection-posture.md` I-03).
- **S-03 — Sprawling request.** (Issues) The issue bundles multiple
  asks, mixes a bug report with feature proposals, or describes a
  program of work rather than one actionable item.

Salvage is additive to lane assignment, not a substitute for it: parts
that independently hit an escalation trigger in
`rules/escalation-triggers.md` still escalate, and salvage never moves
any part toward the fast lane.

## The four steps

Run all four, in order. The output of each step appears in the triage
card and the Triage Receipt.

- **S-10 — Decompose.** Split the item into separable parts and state
  each part in **one sentence**. Parts must be independently
  actionable: each could be its own PR or its own issue. Name the
  files/hunks (PRs) or the paragraphs/asks (issues) that belong to
  each part.
- **S-11 — Disposition per part.** Assign every part exactly one
  disposition from this **closed set** (no other values). Each
  disposition carries its own stable ID; cards, receipts, and the
  machine-readable footer cite the part's disposition by that ID:
  1. **S-ACCEPT — accept as-is** — the part stands on its own and
     anchors cleanly (per `rules/anchoring.md`); recommend it proceed
     as a follow-up PR / split issue.
  2. **S-DOCS — redirect to docs** — the docs-first default: when an
     operator recipe or documentation change would serve the goal as
     well as shipped code, prefer the docs path and say so.
  3. **S-DE — preserve as drafted DE-XXX / mini-PRD stub** — the idea
     is worth keeping but not now: draft the DE entry or mini-PRD stub
     **crediting the contributor by name/handle**, so the idea enters
     the canon instead of dying with the PR.
  4. **S-DUP — duplicate** — an existing issue, DE entry, or open PR
     already covers it; cross-reference both directions (the part's
     write-up names the existing item, and the drafted comment on the
     existing item notes the new interest).
  5. **S-DECLINE — decline** — with a **canon-cited reason** (path +
     anchor per `rules/canon-map.md`). "We don't want this" is never
     sufficient; "contradicts ADR-NNN / out of PRD scope §X /
     HONEST-STATE says we don't claim this" is the required form. If
     no canon speaks to it, that is an unanchored decision — escalate
     rather than decline.
- **S-12 — Draft the contributor response.** One reply, **leading with
  what is kept**: "we want two of your three ideas — here's the path
  for each." Then, per part: its disposition, the reason (cited for
  declines), and the concrete next step. Tone: warm to the person,
  precise about the work; calibrated for a possibly non-engineer
  contributor. Use the matching pattern in
  `templates/contributor-responses/` as the base.
- **S-13 — Propose the mechanical split.**
  - For **PRs**: map hunks to follow-up PRs — which files/hunks belong
    to which proposed PR, with a suggested title and one-line scope
    per follow-up.
  - For **issues**: drafted **titles + bodies** for each split issue,
    ready to file, each crediting the original issue and contributor.

## Boundaries

- **S-20 — Humans post and file everything.** The agent drafts the
  response, the DE/mini-PRD stubs, the split-issue titles and bodies,
  and the hunk map. A human maintainer posts every comment, files
  every issue and DE entry, and closes or relabels the original item.
  The agent never posts, files, closes, or labels (per §2.1 / §10 of
  the design doc).
- **S-21 — Decomposition appears in the receipt.** The part list with
  dispositions is a mandatory section of the Triage Receipt
  (`templates/receipt-pr.md` / `templates/receipt-issue.md`) whenever
  salvage was applied, and is recorded in the machine-readable footer.
- **S-22 — Credit is not optional.** Any part preserved via
  disposition 3 names the contributor in the drafted stub. Ideas enter
  the canon with their origin attached.
