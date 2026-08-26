# Template — milestone readiness scan (in-chat)

Rendered by `skills/milestone/SKILL.md`: one report per milestone,
over the **open** PRs and issues carrying it. The scan is a session
artifact for the maintainer, in the weight class of
`skills/label/SKILL.md` — it reads evidence the fuller passes already
recorded and produces **no receipt, no deck, and no contributor-facing
draft of its own** (`rules/milestones.md` MS-11). For the item-by-item
router with decks and drafts, scoped the same way, the maintainer runs
`/lq-maintainer:triage milestone "<name>"`.

Field rules carry stable IDs (`MI-NN`); the normative rules they
implement are `rules/milestones.md` (`MS-NN`).

## Field rules

- **MI-01 — The header pins the session and the milestone.** Canon
  SHA, agent version, and served model ID once for the scan (the
  four-pinned-fields discipline, design §3.4 — per-item head SHAs ride
  the lines), then the **resolved** milestone: title, number, state,
  and due date or "no due date" (`MS-01`). A scan whose header cannot
  name a single resolved milestone should not have run (`MS-01`: zero
  or two matches stop the run and ask).
- **MI-02 — The open-only bound is stated in words, every run**
  (`MS-03`). "Open items only — what is left in this milestone, not how
  far along it is." The closed side was never fetched, so no completion
  figure, percentage, or done-over-total ratio may appear anywhere in the
  report. A milestone with zero open items renders "no open items
  carrying this milestone" and never "done" (`MS-04a`, `MI-12`).
- **MI-03 — Counts and arithmetic, never a forecast** (`MS-08`). The
  header carries the four bucket counts and, where a due date exists,
  the days remaining as arithmetic ("due in 6 days"). Banned outright,
  in every section and in the closing summary: "on track", "off
  track", "at risk", "will slip", "should make it", a velocity, a
  burn-down, a completion percentage, or any projection of what the
  milestone will do. The maintainer forecasts; the scan counts.
- **MI-04 — Four buckets, and every in-scope item is in exactly one**
  (`MS-07`): **Blocking** (needs a human decision), **Ready to close
  out**, **Needs work**, **Not yet assessed**. An item appearing twice,
  or in none, is a defect in the report — except a carve-out item,
  which renders in `MI-07`'s section instead and in no bucket.
- **MI-05 — Line anatomy.** Every bucket line carries, in order: the
  item (`#<n>` + its title, linked), the **one-clause reason** it is in
  this bucket, the **assigning rule ID** (`MS-09`), the **evidence
  source** (`MI-06`), the **next command** — the exact thing the
  maintainer would run next — and the **deck path** where a deck
  exists. A line missing its rule ID or its evidence source is not a
  bucket assignment, it is an opinion.
- **MI-06 — Evidence source, and the stale flag** (`MS-11`, `MS-12`).
  Two values and no third:
  - `receipt @<sha>` — this agent's recorded internal evidence, with
    the head SHA it was written at;
  - `provisional` — computed **this run** from metadata and changed
    paths only: no findings pass, no anchor check, no tier, no coverage
    statement.

  A `provisional` line may never carry `merge`, `merge-after`, a tier,
  a finding, or a burden verdict; it belongs in **Not yet assessed**
  with the command that would assess it. A receipt whose head SHA is
  not the item's current head renders
  `receipt (stale — evidence at <sha>, head is now <sha>)` and its item
  moves to **Not yet assessed** too: it never counts as ready
  (`MS-12`).
- **MI-07 — Carve-outs render as themselves** (`MS-06`). A
  vulnerability-suspect issue renders as exactly the `rules/issues.md`
  C-40 line and nothing else; an `E-21` item renders as suspended, with
  no drafted text and no label write; a §7.1 held item renders as held.
  None of the three is folded into a bucket, a count, or a readiness
  figure — an item the agent is forbidden to process is reported by
  name, as forbidden.
- **MI-08 — Merge-order collisions are rendered across the scope
  boundary** (`MS-05`, `rules/queue.md` Q-01/Q-02/Q-02a). Groups are
  computed over the **whole** open queue; the report renders the groups
  with at least one member in the scope, names every out-of-scope
  member with its own milestone (or "none") and marks it out-of-scope,
  and states per remaining member what merging the recommended-first PR
  invalidates. Report-only (`Q-03`).
- **MI-09 — The omission counts close the header** (`MS-04`): open
  items carrying no milestone, and — since this report is already
  scoped — open items in other milestones, each as a count with
  `/lq-maintainer:triage` named as the command that shows them. Never
  an enumeration.
- **MI-10 — Nothing in the report is an action** — the same standing
  rule as `templates/digest.md` DG-07 and `rules/queue.md` Q-03, and it
  needs saying here most: four buckets of items with next-commands
  beside them is the most worklist-shaped artifact this agent
  produces, and the agent works none of it. Every command in the
  **Handed over** section is for the maintainer to run, offered one at
  a time, never batched into a compound, and never executed here
  (`MS-10`). This includes every milestone edit: the agent never
  creates, closes, renames, or re-dates a milestone and never moves an
  item into or out of one.
- **MI-11 — What this pass is not.** State it in the closing lines,
  every run: no deck, no receipt, no digest, no public comment, no
  findings, no tier, no coverage statement, nothing written to the
  evidence store, and no label sync (`labels_synced` is written by the
  pass that settles a classification — `templates/receipt-pr.md` RP-20
  — and this pass settles none). Name what was deliberately not done:
  the items left `provisional`, the receipts found stale, and the
  passes not run.
- **MI-12 — An empty scope is a real result.** Zero open items renders
  the header, the MS-03 bound, the MS-04 omission counts, and the line
  "no open items carrying this milestone" — never "done", "complete",
  "ready to ship", or an empty set of bucket headings implying the
  work is finished.

## Template

```markdown
## Milestone scan — <owner>/<repo> — <date>

Canon `<sha>` · agent `<x.y.z>` · model `<served model ID>`
Milestone **<title>** (#<number>, <open|closed>, due <YYYY-MM-DD | no
due date>)

**Open items only** — what is left in this milestone, not how far
along it is (MS-03). In scope: <n> open PR(s), <n> open issue(s).
Blocking <n> · ready to close out <n> · needs work <n> · not yet
assessed <n>[ · due in <n> day(s)].
Excluded: <n> open item(s) in other milestones, <n> open item(s) with
no milestone — `/lq-maintainer:triage` for the whole queue (MS-04).

### Blocking — needs a human decision (MS-07.1)
- #<n> <title> — <one-clause reason: escalated (<E-NN>) | outcome
  `discuss: <question>` | held at contributor request | issue at
  needs-info (<C-NN>) | category-1 awaiting a design plan (G-02)>
  (<rule id>) — evidence: <receipt @<sha> | provisional> — next:
  `<command>` — deck: `<deck path | —>`

### Ready to close out (MS-07.2)
- #<n> <title> — <fast-lane merge candidate, 7/7 pass | outcome
  `merge`> — mergeStateStatus `clean` (<rule id>) — evidence: receipt
  @<sha> — next: `<the human's own merge click>` — deck: `<deck path>`

### Needs work (MS-07.3)
- #<n> <title> — <`merge-after: <named fix>` | mergeStateStatus
  `behind|dirty|blocked` | CI failing> (<rule id>) — evidence:
  <receipt @<sha> | provisional> — next: `<command>` — deck:
  `<deck path | —>`

### Not yet assessed (MS-07.4)
- #<n> <title> — <no recorded evidence | receipt (stale — evidence at
  <sha>, head is now <sha>), MS-12> — evidence: <provisional |
  receipt (stale)> — next: `/lq-maintainer:triage pr <n>` (or
  `/lq-maintainer:review-pr <n>` / `/lq-maintainer:review-issue <n>`)

### Carve-outs — reported, never bucketed (MS-06, MI-07)
- issue #<n> — vulnerability-suspect: private-advisory redirect drafted.
- #<n> — E-21 suspected deliberate attack: no drafts, no label writes;
  maintainer rules (`/lq-maintainer:review-pr <n>`).
- #<n> — held at contributor request (§7.1): awaiting a human response;
  nothing drafted.

### Merge-order collisions touching this milestone (MS-05; Q-01/Q-02)
**Group `<group-id>`** (`<manifest/lockfile path>`) — members: #<n>,
#<n> — out of scope (milestone: <title | none>). Recommended order:
#<n> first (<security-relevant/advisory-backed, Q-02 | stated judgment
call>). Merging #<n> invalidates the `mergeStateStatus`/CI-green of
#<n>[ and #<n>]: each needs rebase + CI re-run (Q-02a). Report only
(Q-03).

### Handed over — commands for you to run, one at a time (MS-10, MI-10)
- `<exact command>` — <what it does, one clause>

### What this scan did not do (MI-11)
No deck, no receipt, no digest, no public comment, no findings, no
tier, no coverage statement, no label sync, nothing written to the
evidence store. <n> item(s) were classified `provisional` this run
(metadata and paths only) and <n> recorded receipt(s) were stale;
neither counts as assessed.
```
