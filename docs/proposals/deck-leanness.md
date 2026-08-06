# Deck leanness — reordering and demoting, not deleting (PROPOSED 2026-07-31; INCORPORATED into design delta v0.7.2, 2026-08-06)

> **2026-08-06:** adopted into the v0.7.2 delta
> (`docs/design/lq-maintainer-agent-design-v0.7.2.md` §4), which makes
> the *visible spine* normative and leaves the mechanics below as the
> implementation spec, recorded in `CHANGELOG.md` per v0.7.1 §5.
> Ships in the v0.5.0 implementation cycle, independent of the three
> v0.7.2 features and able to land first.

Field feedback from the maintainer after reading a large number of decks:

> the findings are very important, especially major and blocking. the
> actionable items are also very useful. I use the drafted comment to compare
> what I understand from the report with what I want to tell the contributor.
> the links to the docs and adjacent issues are very important but feel kinda
> buried. the headline action is useful for orientating me. Everything else
> kinda flies over my head.

Scoped as **deck legibility** — an implementation change to
`skills/triage/scripts/render-deck.sh`, not a design decision (design v0.7.1
§5, which puts renderer legibility work in `CHANGELOG.md` rather than a design
delta). No rule, template, or footer schema changes.

## The measurement

Rendered a representative deck — standard lane, `merge-after`, one major and
two low findings, References, both drafts, a recorded ruling — and counted
every block in reading order. **587 words visible before any click; 870 more
folded.**

| # | Block | Words | Cumulative | Field verdict |
| --- | --- | --- | --- | --- |
| 1 | Hero: headline + outcome + undo | 82 | 82 | **used** |
| 2 | "Not checked" alert | 25 | 107 | — |
| 3–6 | Tiles + gate meter | 26 | 133 | — |
| 7 | The decision | 74 | 207 | — |
| 8 | What the maintainer decided | 33 | 240 | — |
| 9 | Next steps to check | 80 | 320 | **used** |
| 10 | References | 22 | 342 | **used, buried** |
| 12 | What was *not* checked (`<details open>`) | 138 | 484 | — |
| 13 | Findings | 57 | 541 | **most important** |
| 14 | Provenance footer | 46 | 587 | — |
| — | Drafted comment (*collapsed*, 3 cards below findings) | 97 | — | **used** |

The four things the maintainer uses sit at positions 1, 9, 10, 13, and one
collapsed card near the bottom. The largest visible block on the page is
"What was not checked" at 138 words, forced open, **above** the findings.

The severity split is not the problem: `render-deck.sh:1216` already
auto-opens the findings card when anything above minor/nit is present, and
folds minors into a nested sub-card. Position is the problem.

### What is eating the page

**Duplication.** One glossary key, `coverage:runtime-behavior`, renders
**three times, all visible** — the alert (`:1036`), the first bullet of Next
steps (`:1129`), and the not-checked card (`:1202`). So the card the
maintainer finds actionable opens with a sentence already read twice. "A
human decides, every time" renders twice; `3 / 3` renders twice (tile and
meter); the decision card at #7 restates the hero lede at #1 almost verbatim.

**Scaffolding prose.** Every card opens with an `.intro` explaining what the
card is, plus standing disclaimers and footer boilerplate — about **140
visible words, 24% of the page**. Essential on a first read, invisible by the
third deck.

### The constraint this must not break

Design v0.6 §8: never-checked coverage and the permanently-open human-only
judgments "all render and can never read as resolved." The wording is
*render*, not *expand* — folding the per-item detail behind a disclosure is
compatible; removing the item, or letting it read as done, is not.

## The changes

### 1. Reorder the visible spine

Findings and the drafts move out of `<details>` into visible cards;
References moves above the decision card, matching what the issue profile
already does (`render-deck.sh:1582` vs `:1155` — same content, two depths,
for no stated reason).

Decisions ride near the top: the deck is becoming a **reference document**,
consulted after the fact, and the ruling is what a reference reader looks up
first.

```
1.  Hero — headline action + undo path
2.  "Not checked" alert  (the one place the runtime caveat is stated)
3.  The decision — the maintainer's recorded ruling (RP-18) where present,
    the agent's recommendation-shaped line otherwise; ONE card, not two
4.  Findings — visible; blocking/major inline, minor/nit in the nested sub-card
5.  What you'd tell the contributor — the drafted comment AND the drafted
    merge message in one card (see 2 below)
6.  References
7.  Next steps
8.  Tiles + gate meter
9.  "How to read this page" — closed (see 4 below)
10. Folded detail: what was checked · what was not checked (shortened) ·
    how this was reviewed · below threshold · the full technical record
11. Provenance footer
```

Pure reordering of `A(...)` calls plus three `<details>` → `<section>`
conversions. No content change.

### 2. The drafted comment card carries the merge message too

Today they are two separate collapsed cards (`render-deck.sh:1305` and
`:1310`), and the merge message sits *below* the comment, several cards down
from the findings. They are one act — what you say to the contributor and
what goes in the squash box — and the maintainer reads them together, against
the findings. Render them as one visible card with two paste-ready blocks;
the merge-message block is PR-profile-only and absent when the receipt
carries no `### Drafted merge message` (issue decks are unchanged).

Both blocks keep `user-select:all` and their verbatim-escaped rendering —
paste fidelity is unchanged. The posting-is-a-separate-human-action line
moves into the "How to read this page" card (change 4); it currently costs 47
words of preamble above a 50-word draft.

### 3. Say the runtime caveat once

Keep the alert — 25 words, safety-critical, top of page. Suppress
`never-by-design` coverage entries from the Next-steps builder when the alert
has already rendered them, so Next steps opens on a real action instead of a
repeat. The not-checked card keeps its own copy (that card *is* the
non-resolvable rendering the §8 constraint requires).

### 4. One closed "How to read this page" card

The deck is JS-free by contract, so a stateful "I have seen this" toggle is
out — but `<details>` is native and needs none. A single closed card near the
top absorbs the per-card intros, the standing disclaimers, and the footer
boilerplate. A first-time reader clicks once and gets *more* context than
today's scattered prose gives them; a repeat reader never opens it.

This is the change that serves both readers instead of trading one against
the other.

### 5. Shorten "What was not checked" to badge + title

Per-item explanation moves into the nested sub-disclosure; the badge
(`Never checked` / `Not yet — resumable` / `Human-only`) and the item title
stay visible. 138 words → ~45. Still rendered, still never resolvable —
the §8 constraint is met by visibility of the *item*, not of its gloss.

## Expected effect

Visible words ~587 → ~390, entirely from repetition and explanation; no fact
is deleted and nothing moves more than one disclosure level down. The four
things the maintainer actually uses become the first five blocks.

## Test impact

`ci/scripts/test-render-deck.sh` — the assertions that pin card ordering and
the collapsed/expanded state of Findings, the drafts, and the not-checked
card. Add a regression asserting `coverage:runtime-behavior` renders **once**
in the visible region, and one asserting the merge-message block is absent
from the issue-profile deck.
