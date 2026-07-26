# Template — batch digest (in-chat)

Rendered by `skills/triage/SKILL.md` in batch mode: one digest for the
whole open queue, PRs and issues. The digest is a session artifact for
the maintainer; individual triage cards, committee packets, and
drafted comments hang off its lines — receipts are computed as
internal evidence for every item, never posted (design doc v0.7 §8).
Pagination / `--since` thresholds are deferred until scale hurts
(design doc §15 q.3) — list everything open.

## Field rules

- **DG-01 — Every line names the assigning rule(s)** — lane, and for
  standard-lane items the tier (`rules/tiers.md` TR-NN) and category
  (`rules/change-categories.md` G-NN) too — so the human can audit
  the routing of the whole batch at a glance (`rules/lanes.md` L-05).
- **DG-02 — Fast-lane lines** carry the deterministic-check result
  (`7/7 pass`, or the failing check for near-misses that demoted) and
  MUST end with exactly: `merge candidate — human click required.`
- **DG-03 — Vulnerability-suspect lines** read exactly:
  `issue #<n> — vulnerability-suspect: private-advisory redirect
  drafted.` — nothing else about the item appears in the digest
  (`rules/issues.md` C-40).
- **DG-04 — Held items** (design doc §7.1) get their own section:
  the agent lists them and drafts nothing for them.
- **DG-05 — Stale-sweep drafts** appear only in batch mode, governed
  by `rules/stale-sweep.md`; every drafted close must cite evidence
  of resolution — "stale" is not "resolved."
- **DG-06 — Session pinning.** The digest header pins canon SHA,
  agent version, and served model ID once for the batch; per-PR head
  SHAs ride the item lines/cards.
- **DG-07 — Nothing in the digest is an action.** Every write it
  mentions is a draft awaiting an individual human approval.
- **DG-08 — Standard-lane lines are action-first** (`rules/tiers.md`
  TR-10). Every category-2/3 line leads with the TR-05 outcome
  (`merge` / `merge-after: <fix>` / `discuss: <question>`), a
  one-clause reason, and the RV-05 undo path; the tier
  (`rules/tiers.md` TR-NN, with the TR-07 entering condition when
  Tier 2) and lane/rule/confidence follow as supporting detail, and
  the category call (`rules/change-categories.md` G-NN) closes the
  line. A Tier-1 pass that ends `route-to-design` has found a
  category-1 item, not a standard-lane one — it moves to the Design
  path section (DG-09), not this one.
- **DG-09 — Design path section.** Category-1 items
  (`rules/change-categories.md` G-02) get their own section: each
  line names the item and points at
  `/lq-maintainer:design-plan (pr|issue) N` — the digest drafts
  nothing further for them; the plan itself is a separate, dedicated
  render (`G-07`).
- **DG-10 — Category-4 holding lines.** Category-4 items
  (`rules/change-categories.md` G-12) get their own section: one line
  each, naming the drafted holding response and the decomposition
  offer — never a decline, never silence.
- **DG-11 — "Drafts awaiting your approval" is enumerated only.**
  Lists only what actually gets posted: the short public comment
  (`templates/pr-comment.md`) or its update ping, a drafted
  contributor response, or a design plan's contributor note. The
  receipt is internal evidence and is never posted (design doc v0.7
  §8) — it never appears in this list.

## Template

```markdown
## Triage digest — <owner>/<repo> — <date>

Canon `<sha>` · agent `<x.y.z>` · model `<served model ID>`
Open PRs: <n> · open issues: <n>

### Fast lane — merge candidates
- #<n> — <one-line summary> — fast (<rule-id>, <confidence>) —
  checks 7/7 pass (head `<sha>`) — merge candidate — human click required.

### Docs lane
- #<n> — <one-line summary> — docs (<rule-id>, <confidence>) —
  <facet findings count> finding(s)

### Standard lane — action recommended (category 2/3; TR-10)
- #<n> — <outcome: merge | merge-after: <one-clause named fix> |
  discuss: <specific question>> — <one-clause reason> — undo:
  <one-clause undo path> — tier <0-3>[, entering: <TR-07 condition>]
  — standard (<rule-id>, <confidence>) — category <2|3> (<G-NN>)
  <if salvage: ; salvage applied, <k> parts>

### Design path — category 1 (`rules/change-categories.md` G-02)
- #<n> — <one-line summary> — route-to-design (<rule-id>,
  <confidence>) — plan: `/lq-maintainer:design-plan <pr|issue> <n>`

### Category 4 — refactor / large-scale, holding (G-12)
- #<n> — <one-line summary> — holding response drafted: large-scale
  process not yet written; decomposition offered (<rule-id>,
  <confidence>)

### Escalate lane
- #<n> — <one-line summary> — escalate (<E-NN>[, E-NN…], <confidence>)
  — committee packet drafted

### Issues
- #<n> — <bug | feature | question | spam-suspect> (<C-NN>) —
  <lane> (<rule-id>) — <one-line status: repro complete / dup of #k /
  DE stub drafted / answer drafted / slop-close drafted>
- issue #<n> — vulnerability-suspect: private-advisory redirect drafted.

### Held at contributor request (§7.1)
- #<n> — held: "<three-word gist>" — awaiting a human response;
  nothing drafted.

### Stale sweep (batch mode; rules/stale-sweep.md)
- #<n> — status-check drafted (last activity <date>; awaiting
  contributor, not maintainer)
- #<n> — close-with-pointer drafted (resolved by <evidence citation>)

### Drafts awaiting your approval
<one line per pending write: the short public comment
(`templates/pr-comment.md`) or its update ping, a drafted contributor
response (`templates/contributor-responses/`), or a design plan's
drafted contributor note — each will get its own permission prompt.
The receipt is internal evidence, saved automatically, and is never
posted (design doc v0.7 §8).>
```
