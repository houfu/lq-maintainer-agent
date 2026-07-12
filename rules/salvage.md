# Salvage Protocol

Normative rules for decomposing overreaching contributions so their
valuable parts survive (design doc §6, §6.1). Applies to **both PRs
and issues**. Loaded by `skills/triage/SKILL.md` and
`skills/review-pr/SKILL.md`; do not paraphrase these rules elsewhere —
cite them by ID.

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
     anchor resolved via `rules/canon-map.md`). "We don't want this"
     is never sufficient; "contradicts a recorded architecture
     decision / outside product scope / overclaims against the
     honest-state doc" — each cited to path + anchor — is the
     required form. If no canon speaks to it, that is an unanchored
     decision — escalate rather than decline.
  6. **S-SLOP — decline as spam/slop** — only under the obvious-slop
     criteria of S-30 below; drafts the close-with-pointer response
     per S-31. Applied conservatively: anything arguable is NOT this
     disposition (S-30).
- **S-12 — Draft the contributor response.** One reply, **leading with
  what is kept**: "we want two of your three ideas — here's the path
  for each." Then, per part: its disposition, the reason (cited for
  declines), and the concrete next step. Tone: warm to the person,
  precise about the work; calibrated for a possibly non-engineer
  contributor. Use the matching pattern in
  `templates/contributor-responses/` as the base.
  **The default offer for any split is maintainer-performed**
  *(research 2026-07)*: handing a novice contributor unverified rework
  is a documented way contributions die. The drafted response offers
  the maintainer-performed split first and invites the contributor to
  take it over only as an option, never as a precondition.
- **S-13 — Propose the mechanical split — as an explicitly-unverified
  advisory.** *(research 2026-07: concern detection is strong; hunk
  assignment tops out near 70% and degrades with size, and nothing
  verifies a proposed split compiles or passes tests.)*
  - For **PRs**: map hunks to follow-up PRs — which files/hunks belong
    to which proposed PR, with a suggested title and one-line scope
    per follow-up. This map is advisory, governed by S-14 through
    S-16.
  - For **issues**: drafted **titles + bodies** for each split issue,
    ready to file as GitHub **sub-issues** of the original, each
    crediting the original issue and contributor.

## Step-4 advisory rules (PR hunk maps)

- **S-14 — The advisory disclaimer is mandatory.** Every card and
  receipt that carries a hunk map includes, verbatim, the line:
  "proposed split not verified to compile or pass tests." The hunk
  map never renders without it, and no output may claim or imply a
  proposed split builds, passes tests, or preserves behavior.
- **S-15 — Two mechanical sanity checks DO block.** Unlike compile
  verification (which the agent never performs — it never executes
  contributed code, `rules/injection-posture.md` I-05), these two
  checks are cheap, mechanical, and blocking — a hunk map that fails
  either is not rendered; the step degrades to file-level per S-16:
  1. **Complete partition.** Every hunk in the diff is assigned to
     exactly one proposed follow-up — nothing dropped, nothing
     double-assigned.
  2. **No symbol split across parts.** A grep-based
     defined-here/used-there cross-reference over the diff finds no
     symbol that is defined in one proposed part and used in another.
- **S-16 — File-level degradation above the size threshold.** Above
  the size threshold, hunk-level assignment is unreliable; propose the
  split at **file granularity** (which files belong to which
  follow-up), state that the degradation happened and why, and keep
  the S-14 disclaimer. Default threshold: **more than 400 changed
  lines or more than 10 files** in the diff. (The design doc fixes no
  number; this default is data, tunable by a rules PR against this
  file, with the eval harness showing what it flips.)

## Boundaries

- **S-20 — Humans post and file everything.** The agent drafts the
  response, the DE/mini-PRD stubs, the split-issue titles and bodies
  (including sub-issue filing instructions), and the hunk map. A human
  maintainer posts every comment, files every issue and DE entry, and
  closes or relabels the original item. The agent never posts, files,
  closes, or labels (per §2.1 / §10 of the design doc).
- **S-21 — Decomposition appears in the receipt.** The part list with
  dispositions is a mandatory section of the Triage Receipt
  (`templates/receipt-pr.md` / `templates/receipt-issue.md`) whenever
  salvage was applied, and is recorded in the machine-readable footer
  (disposition IDs only — the footer carries enumerated fields, never
  free text, per design doc §8.4).
- **S-22 — Credit is not optional.** Any part preserved via
  disposition S-DE names the contributor in the drafted stub. Ideas
  enter the canon with their origin attached.

## The slop disposition (design doc §6.1)

The crisis that motivated peer projects — flooded bug bounties,
low-effort AI-generated PRs and reports — needs a disposition of its
own, applied conservatively. A false slop accusation costs more
community goodwill than ten slow reviews.

- **S-30 — Only obvious slop is flagged.** S-SLOP (and the
  spam-suspect classification, `rules/issues.md` C-05) applies only
  when at least one of these criteria is met, with the evidence quoted
  in the card/receipt:
  1. **Fabricated APIs or citations** — the contribution invokes
     functions, modules, options, docs, or references that do not
     exist on `main` or anywhere findable;
  2. **Tests that assert nothing** — test code whose assertions are
     vacuous, tautological, or absent;
  3. **Wrong-repo content** — text that answers a different project's
     question or patches code this repository does not contain;
  4. **Boilerplate detached from the diff** — a description,
     changelog, or analysis that does not correspond to what the
     change actually does.
  Anything arguable — low quality but plausibly sincere, AI-assisted
  but on-topic, wrong but about *this* repo — routes standard-lane
  like every other item and is never called slop.
- **S-31 — Close-with-pointer, never an insult.** The S-SLOP drafted
  response is a close-with-pointer: it cites the contribution
  guidelines and the PR template (paths resolved via
  `rules/canon-map.md`), states plainly which S-30 criterion was met,
  and points to a legitimate way back in. No mockery, no
  "AI-generated" accusation as a pejorative, no speculation about the
  contributor's tools or motives beyond the quoted evidence. The
  human posts it or doesn't.
- **S-32 — Slop is a disposition, not a shortcut.** An item flagged
  S-SLOP still gets its lane, its classification (issues), and its
  escalation-trigger evaluation — a slop-shaped contribution touching
  a sensitive path escalates like any other. S-SLOP never suppresses
  a check.

## Non-human authors (design doc §6.1)

- **S-33 — "External contributor" and "autonomous AI agent" are
  different author classes.** Author class is determined via the
  GitHub API (App identity, org membership) or the contribution's own
  verifiable self-identification — never inferred from display names,
  branch names, or writing style.
- **S-34 — Agent-authored is not auto-declined.** A contribution that
  self-identifies as agent-authored (or is verifiable as such) is
  triaged on its merits; what lq-ai wants to say to autonomous-agent
  contributions beyond this file is an open governance call (design
  doc §15 q.6). Two rules hold regardless:
  1. agent-authored items **never fast-lane**, whatever the diff
     looks like; and
  2. their anchor requirements (`rules/anchoring.md`) are **never
     waived** — no "the agent's reasoning is in the PR body"
     substitute for a canon anchor.
- **S-35 — Non-human authorship is not slop.** S-30's criteria are
  about content, not authorship. An agent-authored contribution that
  meets no S-30 criterion is not S-SLOP; a human-authored one that
  meets them is.
