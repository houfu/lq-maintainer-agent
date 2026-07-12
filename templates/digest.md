# Template — batch digest (in-chat)

Rendered by `skills/triage/SKILL.md` in batch mode: one digest for the
whole open queue, PRs and issues. The digest is a session artifact for
the maintainer; individual receipts, cards, packets, and drafted
comments hang off its lines. Pagination / `--since` thresholds are
deferred until scale hurts (design doc §15 q.3) — list everything
open.

## Field rules

- **DG-01 — Every line names the assigning rule** (ID), so the human
  can audit the routing of the whole batch at a glance
  (`rules/lanes.md` L-05).
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

### Standard lane
- #<n> — <one-line summary> — standard (<rule-id>, <confidence>) —
  <flag count> flag(s)<if salvage: ; salvage applied, <k> parts>

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
<one line per pending write: receipt post/update, update ping,
comment, redirect — each will get its own permission prompt.>
```
