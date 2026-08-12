# LQ Maintainer Agent — Design Doc v0.7.3

**Status: adopted 2026-08-12** (drafted and implemented the same
cycle, shipping as plugin v0.5.1). This document is a **delta over
v0.7.2** (`lq-maintainer-agent-design-v0.7.2.md`): it records two
normative additions drawn from maintainer field feedback on v0.5.0
decks (`docs/proposals/deck-findings-and-work-log.md` carries the
measurement and the implementation spec). Where this document is
silent, v0.7.2 remains normative, then v0.7.1, then v0.7, then v0.6
beneath it. Section references of the form "§N" without a version
refer to v0.7.

Both changes answer the same defect from opposite ends: **the deck
rendered what the run concluded and dropped how it got there.** §1
gives the run's acts a place in the record; §2 makes the deck render
the structure the record already had.

## 1. The work log (new; `templates/receipt-pr.md` RP-21, `templates/receipt-issue.md` RI-15)

**Prompted by:** "It hardly shows what you actually do when you run
the skill so that i can track what you checked." The record carried
coverage as a per-item verdict (`covered` / `not-covered`) and nothing
behind it; a maintainer could not tell a full-subsystem walk from a
skimmed diff, or a canon doc read this run from one recalled.

Every triaged item's internal evidence record now carries a **work
log**: one row per act the run actually performed, in the order it
happened — what was read, which check scripts ran, which named review
passes ran, and which did not.

Normative:

- **Written as the work happens, never reconstructed.** A log rebuilt
  at the end from the finished record is a summary of the record, and
  the maintainer already has one. `B-00a` applies at row granularity:
  every row is an act performed this run against the diff at the
  pinned head SHA and the clone at the pinned canon SHA.
- **`Act` and `Result` are enumerated** (`read` / `canon` / `script` /
  `query` / `review` / `draft`; `done` / `pass` / `fail` / `not-run` /
  `partial` / `n-a`). `What` and `Evidence` are short factual free
  text and therefore **visible-body only** — the `receipt:v2` footer
  schema is unchanged, and free text never enters it (§8.4). The
  addition is additive: a record written before this delta renders
  exactly as it did.
- **A skipped pass gets a `not-run` row, not a silence** — carrying
  its reason and, where there is one, the check that would close it
  (`RV-06`). This is the v0.6 §8 honesty rail at act granularity, and
  it binds the same way: on an in-place update or a resumed session a
  `not-run` row is **updated when the pass actually runs, never
  deleted** to make the record look complete.
- **The log is the checkable half of the coverage statement.** The
  coverage statement (RP-07) states what was covered; the work log is
  the evidence that it was. A coverage claim with no work-log row
  behind it is a defect in the record.

Unchanged: nothing routes on the work log. It is evidence, not a
signal — no lane, tier, category, burden axis, or resume decision may
read it, and it can never move an item lighter.

## 2. The deck renders the finding structure and the run's evidence

**Prompted by:** "Findings are one of the most important deliverables
in the deck, but they appear as a glob of text… if for example there's
an easy approve change thing i can't tell what the finding wants me to
change and where."

v0.7.2 §4 made the visible *spine* normative — which cards, in what
order. It said nothing about what a card renders, and the findings
card rendered eleven distinct L-33 fields as one paragraph. What this
delta makes normative is the **inside** of two cards:

- **A finding renders as its structure, not as prose.** The L-33
  fields the record separates — the location, the ask, the impact —
  render as separate, labelled slots; the L-33a drafted replacement
  renders **verbatim and paste-ready**, never reflowed and never
  reformatted into prose; the apply path renders with it. Severity,
  scope and disposition render as one-word chips whose glosses live
  once in the "How to read this page" card (the TG-03.5 gloss
  obligation is met by the gloss being in reach, not by restating it
  on every finding). The finding's own location is a **click-through
  link** on the same terms as every other citation
  (`rules/canon-map.md`'s link rule — agent-constructed from validated
  parts only, pinned to the reviewed head SHA).
- **The run's evidence renders visibly.** The work log (§1), the
  anchor determination (RP-02), the checks that actually ran, the
  vetting checklist (RP-04) and the self-attestation cross-check with
  its evidence column (RP-04a) render as one visible "What I checked"
  card, positioned **directly above "what was not checked"** — the two
  halves of coverage are one question and render adjacently.
- **The deterministic gate renders only where it applied.** The
  seven-point gate is the *dependency* fast-lane gate (RP-03). Its
  tile, meter and explainer render only on items it judged; a code
  change no longer displays a "safety gate — all passed" figure for
  checks that never ran. The checks that did run still render, with
  their results, as evidence.
- **The decision ledger renders its decisions.** `rules/decision-scoping.md`
  D-13 already requires the "Decisions to make" panel to render "from the
  footer counts over the body ledger"; it rendered the counts only. The
  panel now carries each residual as the sentence the record states it in,
  each settled entry with its click-through citation, and each
  reserved-human row under the permanently-open badge (v0.6 §8 — a
  reserved row is never a decision this page can close). The footer's
  counts stay the headline, and a residual the footer counts but the body
  does not state renders as a row marked unstated: a missing sentence
  reads as a missing sentence, never as one fewer decision. The drafted
  artifacts themselves stay in the committee packet (D-06/D-07) — whether
  a watermarked draft belongs on a public deck is **left open**, and the
  panel names where the draft lives instead.
- **A never-checked item is not a next step.** Never-by-design
  coverage entries render in the alert and in the "what was not
  checked" card, and no longer seed the Next-steps list: a step is
  something a person can do and cross off.

The v0.6 §8 constraint is restated once more, unrelaxed: never-checked
coverage and the permanently-open human-only judgments **render,
always, and can never read as resolved**. Nothing here deletes a fact;
the work log adds facts, and the finding slots re-present facts the
page already carried.

## 3. What does not change

Everything in v0.7.2 §5 holds verbatim: a human decides every write;
no write command enters any `allowed-tools`; the agent never executes
contributed code; the injection posture (every new surface — work-log
rows, finding slots, paste blocks — is sanitised as data, and a URL
that reached the record from contributor text is never emitted as an
href); the deterministic dependency gate; canon grounding; the four
pinned fields; the one-way ratchet.

The `receipt:v2` footer schema is **unchanged** — no field added, no
version bump. Every deck rendered from a pre-v0.7.3 record renders as
before, minus the dependency-gate figures on items that never had a
dependency gate.

## 4. Implementation order

§2 is a renderer + `ci/scripts/test-render-deck.sh` change and lands
first — it needs no record change and improves every existing receipt
on re-render. §1 follows in the same cycle: template field rules
(RP-21 / RI-15) plus the emission steps in `skills/review-pr`,
`skills/review-issue` and `skills/triage`. Ships as plugin v0.5.1.

Eval impact: none of the golden files assert on the deck or on the
work log; the fixtures gain work-log rows opportunistically as they
are next revised, not as a blocking migration.
