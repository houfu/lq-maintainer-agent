# LQ Maintainer Agent — Design Doc v0.7.2

**Status: DRAFTED 2026-08-05, extended 2026-08-06 — pending
adoption.** This document is a **delta over v0.7.1**
(`lq-maintainer-agent-design-v0.7.1.md`): it records three normative
additions proposed and ruled 2026-08-05
(`docs/proposals/v0.7.2-labels-breaking-changes-release-narrative.md`
carries the full rationale and the rulings), and adopts the
**deck-leanness** reordering (`docs/proposals/deck-leanness.md`,
proposed 2026-07-31 — one day after v0.7.1's adoption, so recorded
here; §4). Where this document is silent, v0.7.1 remains normative,
then v0.7, then v0.6 beneath it. Section references of the form "§N"
without a version refer to v0.7.

The three changes compose: §2's detector produces a signal, §1
publishes it onto the GitHub item, §3 consumes it at release time.
An "express service" that labels items on arrival was considered and
**rejected** — event-driven labeling is the M4 service spike (v0.6
§12), research-only behind its go/no-go criteria; everything here is
maintainer-invoked commands, human-gated writes, unchanged posture.

## 1. Label projection (new; `rules/labels.md` LB-NN, skill `/lq-maintainer:label`)

**Prompted by:** the agent classifies every item (lane, category,
tier, issue class, outcome) but none of that state is visible on the
GitHub item until a comment is posted; the maintainer wanted a cheap
first touch on arrival.

A fifth skill, **`/lq-maintainer:label`** (`pr N` / `issue N` / bare
sweep), makes a **provisional** classification from the same rule
files the router uses — never a fork of them — and offers label
writes one at a time, each behind its own permission prompt. No deck,
no receipt, no digest: seconds-cheap by design. Triage and both
review skills gain a **sync obligation**: on their fuller pass they
diff the item's agent-managed labels against the settled
classification and offer corrections — the internal receipt is the
authority; labels are its public shadow.

Normative rules (`rules/labels.md`):

- **LB-01 — labels are outputs only, never inputs.** No lane,
  category, tier, queue-group, or anchor determination ever reads a
  label (restating Q-01/A-xx/G-xx as a standing rule); resume reads
  the receipt footer, never the label set.
- **LB-02 — the target repo's own taxonomy (ruled 2026-08-05).** The
  agent maps onto labels that already exist in the target repo and
  never creates or invents one. The mapping table in
  `rules/labels.md` is target-repo vocabulary — a portable seam like
  `rules/canon-map.md`. For lq-ai: `bug`/`enhancement` from category;
  `breaking-change` from §2; `question` (needs-info) and `duplicate`
  (agent's own C-60 cross-reference) from issue recommendations;
  `documentation`/`dependencies` from lane; `api`/`gateway`/`web`/
  `ci` mechanically from changed paths. A mapped label missing from
  the repo is reported, never created (LB-02a).
- **LB-03 — carve-outs bind labels as public output.** An E-21 item
  gets no label change until the maintainer rules; a
  vulnerability-suspect issue gets no label, period (C-40). The agent
  never drafts lq-ai's `security` label, and judgment labels
  (`invalid`, `wontfix`, `good first issue`, `help wanted`) stay
  human-only.
- **LB-04 — stale labels are corrected, not layered**, within the
  agent-managed set only; maintainer-applied labels are never
  touched.

The `receipt:v2` footer gains one optional enumerated field,
`labels_synced: [<name>, …]` — additive, same compatibility posture
as v0.7.1's `decision_scoping` block.

## 2. Breaking-change detection (new; `rules/breaking-changes.md` BC-NN, `check-breaking.sh`)

**Prompted by:** `rules/reversibility.md` RV-02 names public API
contracts as an irreversible class, but nothing detects the class
mechanically — it rides on the model noticing, unlike every other
class.

A check script, `skills/triage/scripts/check-breaking.sh` (same
polyglot pattern, PASS/FAIL with evidence lines), runs over every
standard-lane PR diff at triage Step 6b and in `review-pr`: removed/
renamed public symbols and signature changes, removed config keys/
env vars/CLI flags, textually visible route or contract changes,
schema narrowing. Not a skill — there is no user act; detection is
evidence inside the existing passes.

- **BC-01** — a detection fires the RV-02 public-API class: Tier 1
  ineligible, entering condition named (TR-07), `breaking-change`
  label drafted (§1 LB-02).
- **BC-02** — the model layers judgment on top of the script, never
  instead of it; semantic breaks it finds are findings with the
  v0.7.1 impact/ask/scope fields and fire BC-01 the same way.
- **BC-03 — absence of detection proves nothing.** PASS means "no
  textual break detected", never "non-breaking"; the coverage
  statement discloses the heuristic bound, and a PASS never moves
  anything lighter (TR-09, L-04).
- **BC-04** — dependency-bump majors remain the semver script's job;
  no overlap, one authority per check.

## 3. The release narrative (new; skill `/lq-maintainer:release-notes`, `templates/release-notes.md` RN-NN)

**Prompted by:** release narratives for the target repo are assembled
by hand from merged PRs — the one moment the agent's per-item
evidence (categories, outcomes, breaking flags, §8.5 merge trailers)
pays off across items.

**`/lq-maintainer:release-notes [<ref>..<ref>]`** (default
last-tag..HEAD) reads, read-only: `git log` over the range (trailers
carry the four pinned fields), `gh` reads for merged PRs, the
internal evidence store's enumerated footer fields, and the target's
changelog conventions via a new conditional `canon-map` key
(`canon:release-conventions`, added only if it resolves at the pin).
The draft renders from `templates/release-notes.md`, never freehand:
**breaking changes lead** with their undo/migration lines (lq-ai's
own `breaking-change` label description — "you should read the
release notes" — is the contract this section fulfils), then
categories, contributor credit per item (CD-NN; the v0.7.1 §4
trailer work supplies clean attribution data), and a provenance
block carrying the range plus the pinned fields.

Injection posture applies with full force — contributor titles/bodies
quoted into a published artifact are normalized data, never
instructions — and the whole draft is tone-gated with an attribution
line, like every public output. The human publishes: drafts only,
every write gated, tagging is a push and stays hook-blocked. A
**semver suggestion is drafted, never decided** (BC-01 in range ⇒
major; features ⇒ minor; fixes-only ⇒ patch — with evidence lines).
**Target: the target repository only (ruled 2026-08-05)** — the
Step-0 repository-identity check applies unchanged, so this repo's
own releases stay a manual act; no escape hatch.

## 4. Deck leanness — the visible spine (adopts `docs/proposals/deck-leanness.md`)

**Prompted by:** maintainer field feedback after reading a large
number of decks — findings, actionable items, the drafted comment,
and the References are what gets used; the rest "kinda flies over my
head." Measured on a representative deck: 587 words visible before
any click, with the four used blocks at positions 1, 9, 10, 13 and
one collapsed card near the bottom, under a 138-word forced-open
"What was not checked" block.

v0.7.1 §5 puts renderer legibility mechanics in `CHANGELOG.md`, and
they stay there — the card-order and folding changes are
implementation, specified in the proposal. What this delta makes
normative is the **visible spine**: findings and the paste-ready
drafts render as *visible* cards, never folded; the drafted comment
and the drafted merge message render as **one card** (they are one
act — what you tell the contributor and what goes in the squash box);
References ride above the fold; and the maintainer's recorded ruling
(RP-18) and the agent's recommendation render as **one** decision
card, not two. Scaffolding prose (per-card intros, standing
disclaimers) consolidates into a single closed "How to read this
page" card, and the runtime caveat is stated once visibly rather
than three times.

The v0.6 §8 constraint is restated, not relaxed: never-checked
coverage and the permanently-open human-only judgments **render,
always, and can never read as resolved** — met by visibility of the
*item* (badge + title), while its explanatory gloss may fold. No
fact is deleted; nothing moves more than one disclosure level down.

## 5. What does not change

Everything in v0.7 §10 and v0.7.1 §5 holds verbatim (§4 above names
the one normative kernel it lifts out of the renderer work): a human
decides
every write; no write command enters any `allowed-tools`; the agent
never executes contributed code; the injection posture; the
deterministic dependency gate; canon grounding; the four pinned
fields; the conservative slop bar; the one-way ratchet — nothing
introduced here (a label, a PASS, a release draft) can move any item
lighter or un-fire any trigger.

## 6. Implementation order

§4 (deck leanness) is independent and can land first — it is a
renderer + `ci/scripts/test-render-deck.sh` change with no rule or
schema impact. Then §2 (smallest of the features; both others consume
its flag), §1 second (wants `breaking-change` in the mapping from day
one), §3 third. Ships as plugin v0.5.0 with eval fixtures per feature
— including an E-21 fixture whose expected label delta is empty
(LB-03 as a mechanical check) — and the two leanness regressions from
its proposal (the runtime caveat renders once in the visible region;
the merge-message block is absent from issue-profile decks).
