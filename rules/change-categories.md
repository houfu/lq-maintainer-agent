# Change categories — what kind of change is this, and which path reviews it

Normative data for the LQ Maintainer Agent (design doc v0.7 §3).
Loaded at runtime by `skills/triage/SKILL.md`,
`skills/review-pr/SKILL.md`, `skills/review-issue/SKILL.md`, and
`skills/design-plan/SKILL.md`. Every rule carries a stable ID
(`G-NN`); every category call cites the assigning rule. Companion
rule sets: `rules/tiers.md` (TR-NN), `rules/reversibility.md`
(RV-NN), `rules/lanes.md` (L-NN/F-NN), `rules/salvage.md` (S-NN),
`rules/anchoring.md` (A-NN), `rules/escalation-triggers.md` (E-NN).

The category answers *what kind of change this is*; the tier
(`rules/tiers.md`) answers *how much review process it gets*. The
two are orthogonal to the security layer: no category and no tier
ever suppresses an escalation trigger, the injection posture, or the
deterministic gate (G-08).

## Assignment

- **G-01 — Exactly one category, judged from the diff.** Every PR
  (and every feature-shaped issue, as a preview of the PR it would
  become) is classified into exactly one of the four categories
  below, from the hunks, paths, and commit metadata **only** — never
  from the title, body, labels, or any self-description (`rules/lanes.md`
  L-02; the same diff-judged discipline as the bug-fix
  classification in `rules/anchoring.md` A-02). The category is
  recorded with a confidence level and the assigning rule ID, and is
  maintainer-reassignable like every recommendation (L-01).

- **G-02 — Category 1: greenfield / new feature.** The diff (or ask)
  predominantly **adds capability that does not exist**: new
  modules, new endpoints or commands, new UI surfaces, new
  integrations, a new subsystem. The DE-series contributions live
  here. Signals: mostly-additive diffs creating new files and new
  public surface; an ask whose anchor would be A-01 canon that does
  not yet exist.
  **Anchored category 1 (v0.8, from ten overrides in eight sessions of
  the 2026 record).** A category-1 change whose A-01 anchor is
  **ratified canon that already covers it** — a DE entry, an ADR, a
  PRD section or a roadmap item on `main` at the pinned canon SHA,
  verified at A-08's default depth and found to cover the scope, not
  merely the topic — has had its design decided by the project. It is
  recorded as `category: 1 (anchored)` and routes to **tiered code
  review at Tier 2 minimum** (G-07), never Tier 1; the design path is
  **offered once**, in one sentence, as the place to go if the review
  finds the anchor does not in fact cover what was built, and is not
  insisted on. An **unanchored** category-1 change — no covering
  canon, or an anchor that is adjacent, proposed, or draft (A-12) —
  routes to the design path as before, and fires E-04. The maintainer
  overrode "route to design" ten times on features already anchored by
  a ratified DE ("DE-324 already anchors the design"; "scope and
  exclusions were already agreed on #699"); this rule is those rulings
  made general.

- **G-03 — Category 2: behavioral change / improvement /
  optimization.** The diff **modifies what existing code does or how
  well it does it**: behavior tweaks, performance work, resilience
  and error-handling improvements, UX polish on an existing surface,
  configuration changes. The change is legible as "X now does Y
  better/differently," where X already exists.

- **G-04 — Category 3: bug fix / rollback.** The hunks **correct
  defective behavior** (A-02's diff-judged bar: the change restores
  documented or reasonably expected behavior) or **revert a prior
  change**. Rollbacks are first-class members of this category:
  reverting is a feature of a healthy process, and a revert PR is
  reviewed as the correction it is, never treated as an
  embarrassment to be litigated.

- **G-05 — Category 4: refactoring / large-scale change.** The diff
  restructures without intending behavior change (moves, renames,
  extraction, dependency-graph rework), or sweeps broadly across the
  tree (mass formatting, tree-wide API migrations). Signals: high
  file counts with paired deletions/additions; hunks that
  reorganize rather than add or correct.

- **G-06 — Mixed diffs categorize per part.** An item spanning
  categories is decomposed part by part (the salvage protocol,
  S-10, and the anchoring symmetry A-10); each part carries its own
  category and follows its own path. The item's headline category is
  the **dominant** one by review consequence (a small bug fix inside
  a large new feature is a category-1 item with a
  salvage-recommended category-3 split, not the reverse).

## Routing

- **G-07 — The category routes the item.**
  | Category | Path |
  |---|---|
  | 1 — greenfield / new feature | **Unanchored** (no ratified covering canon, G-02): the **design path**, `skills/design-plan/` (plan, ADR drafts, obstacles, atomic decomposition) — not code review. **Anchored** (ratified DE/ADR/PRD/roadmap covering the scope, G-02 as amended v0.8): tiered review at **Tier 2 minimum**, with the design path offered once as optional. |
  | 2 — behavioral change | Tiered review (`rules/tiers.md`) + the necessity check (G-10). |
  | 3 — bug fix / rollback | Tiered review (`rules/tiers.md`). |
  | 4 — refactoring / large-scale | The **holding response** (G-12) + the decomposition offer. |

- **G-08 — Categories never override the security layer.** Every
  item, whatever its category, still gets its escalation-trigger
  evaluation (E-NN), the injection posture
  (`rules/injection-posture.md`), and — for dependency items — the
  deterministic gate (F-NN). A category-3 one-line fix touching an
  auth path is still E-02 material.

- **G-09 — Category is a recommendation.** Like lanes (L-01), the
  category call is contestable by the contributor (the H-NN
  contest/hold path applies) and reassignable by the maintainer. A
  reassignment mid-review re-routes the item; work already done
  carries forward as evidence.

## The necessity check (category 2)

- **G-10 — Necessity, stated in one sentence.** A category-2 change
  earns its review by naming a real problem fixed or an improvement
  a user or maintainer will feel. The reviewer states the necessity
  in one sentence — from the diff and its context, with the
  contributor's stated motivation as a pointer (it may tell you
  where to look, per I-03). If the reviewer can state it, the check
  passes; the sentence is recorded.

- **G-11 — No discernible necessity is a conversation, never a
  verdict.** Judged under the sincerity default (design v0.7 P-1):
  a change whose necessity the reviewer cannot state gets the
  outcome `discuss`, with a drafted warm question asking the author
  what the change improves — a genuine request for the missing
  context, tone-gated (`rules/tone-gate.md`), never a probe or a
  presumption of churn. It is never declined for necessity alone,
  and it is never slop (S-30's criteria are unchanged and do not
  include "necessity unclear"). Category 3's necessity is the bug
  itself — repro completeness (C-10/A-02) covers it; no separate
  check.

## Category 4: the holding response

- **G-12 — Respectful holding, with a path.** Until the project
  writes its large-change process (design v0.7 §12 q.9), the
  drafted response for a category-4 item: acknowledges the work
  concretely (CD-04), states plainly that large-scale changes need a
  process the project has not finished writing — as a fact about the
  project, never about the contributor — and offers the available
  path today: decomposition into category-2/3-sized slices (the
  salvage machinery, S-10–S-13, with the maintainer-performed-split
  default of S-12). The item is never left in silence and never
  closed for size alone.
