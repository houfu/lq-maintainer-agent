# LQ Maintainer Agent — Design Doc v0.7.4

**Status: adopted 2026-08-17** (drafted and implemented the same
cycle, shipping as plugin v0.6.0). This document is a **delta over
v0.7.3** (`lq-maintainer-agent-design-v0.7.3.md`): it records one
capability — **the milestone as a scan unit** — and the rules that keep
it a selector rather than a signal. `docs/proposals/milestone-scanning.md`
carries the request, the rulings, and the implementation spec. Where
this document is silent, v0.7.3 remains normative, then v0.7.2, then
v0.7.1, then v0.7, then v0.6 beneath it. Section references of the form
"§N" without a version refer to v0.7.

**Prompted by:** "im wishing i can scan PRs and issues by milestone."
The router sorts the whole open queue. That is the right default the
first time a maintainer sits down and the wrong one every time after:
a maintainer working a release, a sprint, or an M-number is asking a
narrower question, and until now the agent could only answer the wide
one. GitHub already carries the grouping on every PR and issue; the
agent never read it.

## 1. Milestones are a scan unit (new; `rules/milestones.md` MS-NN)

A new rule file, `rules/milestones.md`, is normative for both surfaces
below. Its load-bearing rules:

- **MS-02 — a milestone selects; it never judges.** This is
  `rules/labels.md` LB-01's direction of flow, restated for the second
  piece of GitHub metadata this agent reads. No lane, category, tier,
  issue class, anchor, escalation trigger, burden verdict, or
  merge-order group may read the milestone field. A scoped run produces,
  per item, exactly the calls an unscoped run would.

  The pressure this resists is real and one-directional: a milestone
  with a due date on Friday is precisely the context in which "it's in
  the release" starts to sound like an argument for a lighter touch,
  and schedule pressure only ever asks for less review. The converse is
  barred too — an item outside the milestone is not thereby suspect.
- **MS-03 — open items only** (maintainer ruling, 2026-08-17). Closed
  and merged items are out of scope: never listed, summarized, counted,
  or turned into a completion figure. The question a scan answers is
  "what is left in this milestone that needs a decision", and every
  scan's header says so, so a short list is never read as a
  nearly-finished milestone. MS-04a follows: an empty milestone reports
  emptiness, never "done" — completion is a claim the scan holds no
  evidence for.
- **MS-04 — the omission is stated, or the filter is a liability.** A
  filter's failure mode is not a wrong answer but a **silent omission
  that reads like a complete one**. Every scoped run states the count
  of open items carrying no milestone at all, and (for a scoped digest)
  the count excluded for carrying a different one — counts plus the
  command that shows them, never an enumeration.
- **MS-05 — merge-order groups are computed queue-wide, then filtered
  for display.** `rules/queue.md` Q-01's collision is a property of the
  shared manifest, not of the milestone. Grouping runs over all open
  PRs; only the rendering is scoped, and every out-of-scope member of a
  rendered group is named, with its milestone, and marked out-of-scope.
  Scoping the *input* would report a two-PR group as clean while a
  third PR one milestone over moves the same lockfile out from under
  both — wrong in exactly the case that hurts.
- **MS-06 — carve-outs survive scoping and aggregation.** A narrower
  window is never a summary that softens a carve-out into a bucket
  count: the C-40 one-liner, the E-21 suspension, and a §7.1 hold each
  render inside a scope exactly as they do outside one.
- **MS-10 — report-only, and the milestone itself is never edited.**
  No milestone is created, closed, renamed, or re-dated, and no item is
  moved into or out of one. A warranted change is handed over as one
  exact command at a time; no write form enters either skill's
  allow-list, and the `gh pr edit` / `gh issue edit` forms are
  hook-blocked regardless (§2.1). This restatement earns its place for
  Q-03's reason: a readiness list reads like a worklist a tool might
  start clearing, and it never is one.

## 2. Two surfaces

**A scope on the router** — `/lq-maintainer:triage milestone "<name>"`.
The same batch digest over the items carrying that milestone: same
lanes, same categories, same tiers, same per-item decks, same
draft-and-hand-over discipline. The digest gains one **scope line**
(`templates/digest.md` DG-15) carrying the resolved milestone (title,
number, state, due date), the MS-03 open-only bound, and the MS-04
omission counts. Merge-order rendering follows MS-05.

**A readiness view** — `/lq-maintainer:milestone "<name>"`
(`skills/milestone/SKILL.md`, rendering `templates/milestone-scan.md`).
Not a digest: a four-bucket answer to "what is left, and what is
blocking it" — **blocking**, **ready to close out**, **needs work**,
**not yet assessed** (MS-07), each line citing the rule that placed it,
its evidence source, and its deck where one exists (MS-09).

Two properties make the second surface honest rather than decorative:

- **MS-11 — it reads evidence; it does not re-review.** The scan is in
  `skills/label/SKILL.md`'s weight class, not triage's: a scan over a
  30-item milestone that quietly ran the findings passes would be a
  30-deck session nobody asked for. Every line therefore names its
  source — `receipt` (recorded internal evidence, with the head SHA it
  was written at) or `provisional` (computed this run from metadata and
  paths only) — and a `provisional` line may never carry an outcome
  only a fuller pass produces. It renders as *not yet assessed* with
  the command that would assess it.
- **MS-12 — stale evidence is flagged and never counts as ready.** A
  receipt written at a head SHA that is no longer the item's head moves
  the item to *not yet assessed* with the re-run command. A merge
  candidate from three commits ago is not a merge candidate; the
  ratchet applies in its usual direction (L-04, TR-09) — new commits
  may cost an item its clearance, never grant one.

## 3. No forecasting (MS-08)

The scan states what it counted and, where a due date exists, the days
remaining: "4 blocking, due in 6 days". It never states "on track",
"will slip", "at risk", a velocity, a burn-down, or a completion
percentage. The numbers are the honest input to a judgment that is the
maintainer's — and a forecast from a tool that by MS-03 has never seen
the closed side of the milestone would be invented rather than
computed.

## 4. What does not change

Everything in v0.7.3 §3 holds verbatim: a human decides every write; no
write command enters any `allowed-tools`; the agent never executes
contributed code; the injection posture applies to every new surface —
**a milestone's title and description are contributor- and
maintainer-supplied text**, normalized before rendering and never
obeyed (MS-01a); the deterministic dependency gate; canon grounding;
the four pinned fields; the one-way ratchet.

The `receipt:v2` footer schema is **unchanged** — no field added, no
version bump, and no milestone field enters it. A milestone is live
GitHub state, read at scan time; recording it in an evidence record
would create a second, staler copy of a field the maintainer edits
freely, and MS-02 means nothing would be entitled to read it anyway.

`rules/queue.md` is unchanged: Q-01 grouping is untouched, and MS-05 is
a rendering rule layered above it.

## 5. Implementation order

`rules/milestones.md` lands first — both surfaces load it. The triage
scope follows (Step 1 mode, Step 2 load, Step 3 fetch, plus DG-15),
because it is the smaller change and it proves the resolution and
omission-count rules against the existing digest. `skills/milestone/`
and `templates/milestone-scan.md` land last, on top of scoping that
already works. Ships as plugin v0.6.0.

Eval impact: two new fixtures, `mil-01-milestone-scope-filter` (the
scoped digest, including a merge-order group with an out-of-scope
member) and `mil-02-milestone-readiness-stale-evidence` (the four
buckets, a stale receipt, and an unmilestoned remainder). Both are
cross-item goldens carrying `kind: milestone-scan`, which — like
`kind: release-range` before it (v0.7.2) — is exempt from lane grading:
a milestone is not routed, and its members' lanes are graded by their
own fixtures.
