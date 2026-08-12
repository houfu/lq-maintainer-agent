# Findings you can act on, and a record of what the run did (PROPOSED 2026-08-12)

Field feedback from the maintainer after reading v0.5.0 decks — the
leanness pass landed, and two things it did not touch are now the
loudest:

> there's still a lot of fluff content. It hardly shows what you actually
> do when you run the skill so that i can track what you checked.
> However, i am irritated by another part. Findings are one of the most
> important deliverables in the deck, but they appear as a glob of text.
> if for example there's an easy approve change thing i can't tell what
> the finding wants me to change and where.

Two defects, one shared cause: **the deck renders the record's
conclusions and drops its structure.** `docs/proposals/deck-leanness.md`
moved cards around; it never looked inside one.

## The measurement

Rendered a representative deck through `render-deck.sh` — standard lane,
`merge-after`, one major and one minor finding, both carrying the full
`rules/lanes.md` L-33 structure, with the receipt's anchor, vetting and
self-attestation tables filled in.

### Defect 1 — the finding is a paragraph

L-33 fixes eleven distinct fields on every finding: file, line,
severity, canon citation, impact, ask, disposition, scope, suggested
comment, the L-33a `suggestion` block, and the apply path. The receipt
writes each one on its own labelled line. The deck rendered **all of
them into a single `<div class="txt">`**, so the page read:

> `src/fetcher/citation.py:118` — the retry loop has no ceiling… Impact:
> a single unreachable court site pins a worker… Ask: could you cap the
> loop… Disposition hint: relayable Scope: in-scope Suggested comment:
> Thanks for adding the retry… Suggested change — paste as a review
> comment on `src/fetcher/citation.py:118`: ``suggestion for attempt in
> range(MAX_RETRIES): ` Apply path: post the drafted comment…

Three specific failures in that one paragraph:

1. **The one-click block was destroyed.** `render_linked` (`:307`)
   rewrites backtick pairs into `<code>` spans. It ate the
   ` ```suggestion ` fence, leaving `` `suggestion `` and a stray
   backtick. The drafted replacement — the whole point of L-33a, the
   thing that makes a finding one click for the contributor — arrived
   unusable and unselectable. This is a bug, not a layout preference.
2. **Duplication.** Disposition and scope rendered twice: once as a
   glossed sentence in the header, once as the raw label inside the
   prose blob.
3. **No location affordance.** `file:line` was present as text. The
   `canon-map` link rule ("check it in one click" is literal) was
   applied to canon citations and to issues, but never to the finding's
   own location.

### Defect 2 — the deck never says what the run did

The deck's only check card is the **seven-point dependency gate**
(RP-03). On a code change four of its seven checks are `n-a`, so the
page rendered the survivors as a glance tile reading:

> **Safety gate — 3 / 3 — all passed**

…for a gate that never applied to the item. Meanwhile the record's own
evidence of work — the **anchor determination** (RP-02), the
**security-vetting checklist** (RP-04), and the **self-attestation
cross-check with its Evidence column** (RP-04a) — is not read by the
renderer at all. `grep` for anchor/vetting/attestation in
`render-deck.sh` hits only glossary strings. All three exist in the
record and reach the reader only inside the verbatim dump at the foot
of the page.

And nothing in the record — before this proposal — states what was
*read*: which hunks, which files at which SHA, which canon documents,
which passes ran and which were skipped. Coverage is recorded as
`covered` / `not-covered` per item: a conclusion, with no trace behind
it.

## The changes

### 1. Findings render as their L-33 structure

One card per finding, action-first:

- **chips** — severity, scope (only when it is not the unremarkable
  `in-scope`), disposition, and a `one-click apply` chip whenever a
  drafted replacement exists;
- **the diagnosis** as the finding's title line;
- **slots** — `where` (the location, as a click-through blob link
  pinned to the reviewed head SHA), `change` (the L-33 *ask*), `why`
  (the L-33 *impact*);
- **the drafted replacement**, verbatim, in a `user-select:all` block
  labelled with its target, and the **apply path** under it;
- the per-finding **drafted comment** and any **follow-up issue stub**,
  one disclosure down, still paste-ready.

Above the cards, a **scan strip**: one chip per finding — id, severity,
location, and ⚡ where a replacement is drafted — each linking to its
card. Every finding appears in the strip, *including* the minor ones
folded into the sub-card, so the strip is the complete picture without
opening anything.

The disposition and scope glosses move to the single closed "How to
read this page" card and to each chip's tooltip: said twice, in reach,
instead of a full sentence restated on every finding.

Nothing is dropped. A finding the parser does not recognise (a terse
one, or a record written before the labels existed) renders exactly as
it does today, and an unclaimed fenced block still renders as a
paste-ready block.

### 2. A work log — the run's own acts, in order

New receipt section, `### Work log` (RP-21 for PRs, RI-15 for issues):
one row per act the run performed, written **as it happens**.

| Act | What | Evidence | Result |
| --- | --- | --- | --- |
| `read` / `canon` / `script` / `query` / `review` / `draft` | the specific target | what came back, in one clause | `done` / `pass` / `fail` / `not-run` / `partial` / `n-a` |

`Act` and `Result` are enumerated; `What` and `Evidence` are short free
text and, like every free-text field, are **visible-body only** — the
footer schema is untouched, so this is additive and no `:v3` bump is
needed (design v0.6 §8.4).

The rule that gives it teeth: **a skipped pass gets a `not-run` row,
never a silence** — with its reason and the check that would close it
(RV-06) — and on a resume that row is *updated* when the pass runs, never
deleted to make the record look complete. This is the v0.6 §8 honesty
rail at act granularity.

### 3. "What I checked" becomes a visible card

The work log, the anchor determination, the checks that actually ran,
the vetting checklist, and the self-attestation cross-check (with its
evidence column) render as one visible card, positioned directly above
"What was **not** checked" — the two halves of coverage are one
question, and reading them apart is what let the gaps go unnoticed.

### 4. The dependency gate stops claiming a clearance it never ran

The gate tile, the dot meter, and the "safety gate" how-to paragraph
render **only where the gate applied** (any of manifest-only, semver,
OSV, release-age carrying a real result). On a code change the checks
that did run still render — as rows in the evidence card, with their
result — and their dependency-flavoured glosses ("alongside the bump",
"the lockfile") are suppressed, because they describe a review that did
not happen.

### 5. A standing caveat is not a next step

Never-by-design coverage items no longer seed the Next-steps list. They
name nothing a maintainer can do and cross off, and every one of them
already renders — unresolvable — in the "what was not checked" card
immediately above. v0.7.2 §4 suppressed the one the top alert had
already stated; this finishes the thought.

### 6. The decision ledger renders its decisions

Same defect, one card over. `rules/decision-scoping.md` D-13 says the deck
renders the "Decisions to make" panel "from the footer counts **over the
body ledger**" — but the renderer read only the footer's enumerated
block. Measured on an escalated record (PR #431, multi-tenancy, two
residual decisions):

| In the record | On the deck |
| --- | --- |
| **R-1** — "lq-ai stores data for more than one tenant in one deployment" | `R-1 — structural ·` + a 30-word explainer of what a draft ADR *is* |
| **R-2** — "tenant isolation is enforced at the query layer…" | the same 30-word explainer, verbatim, again |
| Settled: row-level security is available — cited to ADR-0014 §3 | the count "1 found settled" and a 60-word generic explainer |
| Reserved-human: whether the roadmap has room in M2 | nothing — counted in the footer, never rendered |

So the deck that most needs it named no decision to be made, and spent
its words explaining the machinery instead.

The panel now renders the body ledger: one row per residual carrying
**the decision in the sentence the record states it in**, with the
artifact as a short chip (`draft ADR` / `DE stub`) whose gloss is its
tooltip; the settled entries with their click-through citations; and the
reserved-human rows under the same permanently-open badge the human-only
judgments carry (v0.6 §8 — a reserved row is not a decision anyone on
this page can take). The `scoping:*` and `artifact:*` explainers move to
the "How to read this page" card, said once.

Two honesty rails: the footer's counts stay the headline, and a residual
the footer counts but the body never states **still renders as a row**,
marked as unstated — a missing sentence must read as a missing sentence,
never as one fewer decision.

Out of scope, deliberately: the drafted ADR / DE stub itself stays in the
committee packet (D-06/D-07) and does not become a deck block. The panel
now says where it is instead of leaving a reader hunting for a draft the
chip just told them exists. Putting watermarked drafts on a public
surface is a design call, not a rendering one; it is left open.

## Expected effect

The four things the maintainer uses stay where v0.7.2 put them. Inside
the findings card, "what do I change, where, and can I apply it in one
click" is answerable without reading a sentence. And the page gains the
one thing it never had: a checkable trace of what the run actually did,
with its gaps named as gaps.

Visible words go **up**, not down — from ~590 to ~740 on the measured
deck. All of the increase is the work log, and none of it is prose: the
leanness target was scaffolding and repetition, not evidence.

## Test impact

`ci/scripts/test-render-deck.sh` — 42 new checks: the L-33 slots and
their labels never rendering as prose; the head-SHA-pinned location
link; the `suggestion` fence surviving verbatim and click-to-select; the
scan strip (present at two findings, absent at one, listing the folded
minor finding, marking one-click findings); the evidence card and each
of its four tables; a `not-run` row rendering as not run; the gate
suppressed on code items and intact on dependency items; injection
holding on every new surface (an off-host link in a work-log row or a
finding never becomes an href); the v0.6 §8 rail unmoved; and the decision ledger (sentences, citations, the reserved-human row, the counted-but-unstated row, the gloss said once).
