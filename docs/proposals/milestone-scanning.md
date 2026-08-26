# Scanning the queue by milestone (PROPOSED 2026-08-17)

Field request from the maintainer, in their words:

> let's write new features. im wishing i can scan PRs and issues by
> milestone

The queue router sorts *everything* open. That is the right default the
first time a maintainer sits down, and the wrong one every time after:
a maintainer working a milestone — a release, a sprint, an M-number —
is asking a narrower question than "what is in the queue", and today
the agent can only answer the wide one and let them read past the rest.
GitHub already carries the grouping (`milestone` on every PR and
issue). The agent never reads it.

Two surfaces follow from the request, and they are different tools:

1. **A scope on the router.** `/lq-maintainer:triage milestone "<name>"`
   — the same batch digest, over the items carrying that milestone.
2. **A readiness view.** `/lq-maintainer:milestone "<name>"` — not a
   digest at all: what in this milestone is blocking, what is ready to
   close out, what needs work, and what nobody has actually assessed.

Both ship; the second is built on the first's scoping rules. Neither
one closes a milestone, moves an item into or out of one, or decides
whether the milestone ships.

## The rulings

### R1 — Open items only (maintainer ruling, 2026-08-17)

A milestone scan reads **open** PRs and issues. Closed and merged items
are out of scope: not listed, not summarized, not counted.

The alternative — fetching the closed side too, and rendering `18 done
/ 11 left` — was considered and declined. It buys a progress bar and
costs a contract: triage's whole surface is the open queue, and a
"milestone" view that silently spans a second population would be the
one place in the agent where the item set means something different.
The scan therefore answers **"what is left in this milestone that needs
a decision"**, and says so in its header, so a short list is never
misread as a nearly-finished milestone (`MS-03`).

### R2 — A milestone selects; it never judges

This is `rules/labels.md` LB-01's direction-of-flow rule, restated for
a second piece of GitHub metadata the agent now reads. Scoping changes
**which** items are judged and never **how** one is judged: no lane,
category, tier, issue class, anchor, escalation trigger, or merge-order
group may read the milestone field (`MS-02`).

The pressure this rule exists to resist is real and one-directional. A
milestone with a due date on Friday is exactly the context in which
"it's in the release" starts to sound like an argument for a lighter
touch. It is not one. The reverse is also barred: an item's *absence*
from the milestone is not evidence against it either.

The agent also never writes the field. `gh issue edit --milestone` is a
write like every other — handed over as an exact command, one at a
time, never in this skill's allow-list, and hook-blocked regardless
(`MS-02a`, `MS-10`).

### R3 — The omission is stated, or the filter is a liability

A filter's failure mode is not a wrong answer; it is a **silent
omission** that reads like a complete one. Every scoped run therefore
states, in its header: how many open items carry **no milestone at
all**, and — in a scoped digest — how many open items were excluded
because they sit in a different milestone (`MS-04`). Counts, plus the
command that shows them; never an enumeration, which would undo the
scoping the maintainer asked for.

A milestone with zero open items reports exactly that, and never
"done" — under R1 the scan cannot see the closed side, so "done" is a
claim it has no evidence for (`MS-04a`).

### R4 — Merge-order groups are computed queue-wide, then filtered for display

The one place scoping the *input* would produce a wrong answer rather
than a partial one. `rules/queue.md` Q-01 groups open PRs that share a
dependency manifest or lockfile, because merging any member invalidates
the others' mergeability. That collision is a property of the shared
file — **not** of the milestone. A group computed inside the scope
would report a two-PR group as clean when a third PR, one milestone
over, is about to move the same lockfile out from under both.

So: group over the whole open queue, then render the groups that touch
the scope, with any out-of-scope member named and marked as such
(`MS-05`). The maintainer sees the collision that is actually coming.

### R5 — Carve-outs survive scoping and aggregation

A vulnerability-suspect issue in the scope renders as its `C-40`
one-liner and nothing more; an `E-21` item is still suspended; a held
item (§7.1) is still listed as held with nothing drafted. A milestone
view is a narrower window, never a summary that softens a carve-out
into a bucket count (`MS-06`).

### R6 — The readiness view reads evidence; it does not re-review

`/lq-maintainer:milestone` is a **light** pass in the weight class of
`/lq-maintainer:label`, not of `/lq-maintainer:triage`: it does not run
the findings passes, and a scan over a 30-item milestone that quietly
did would be a 30-deck session the maintainer did not ask for.

It therefore reads what the fuller passes already recorded, and every
line names its **evidence source** (`MS-11`):

- `receipt` — this agent's recorded internal evidence for the item,
  with the head SHA that evidence was written at;
- `provisional` — computed this run from metadata and paths only.

A `provisional` line may never carry an outcome only a fuller pass can
produce. It reads `unassessed` and carries the command that would
assess it. And a receipt whose recorded head SHA is **not** the item's
current head is reported **stale**, and its outcome does not count
toward "ready to close out" (`MS-12`) — a merge candidate from three
commits ago is not a merge candidate.

### R7 — Counts and arithmetic, never a forecast

The scan may state "4 blocking, due in 6 days". It may not state "on
track", "will slip", or a velocity. The two numbers are the honest
input to a judgment that is the maintainer's (`MS-08`), and a
forecast-shaped sentence from a tool that has never seen the closed
side of the milestone (R1) would be invented, not computed.

Readiness buckets are computed from evidence the passes already
produced — outcome, lane, escalation, hold state, CI, mergeability —
never from the due date and never from a title, and every line cites
the rule that placed it (`MS-07`, `MS-09`).

## What ships

| Surface | File | Note |
| --- | --- | --- |
| Rule set (`MS-NN`) | `rules/milestones.md` | New. Loaded by both surfaces. |
| Scope on the router | `skills/triage/SKILL.md` | Step 1 mode, Step 2 load, Step 3 fetch. |
| Scope line in the digest | `templates/digest.md` | `DG-15`. |
| Readiness skill | `skills/milestone/SKILL.md` | New. |
| Readiness report | `templates/milestone-scan.md` | New (`MI-NN`). |
| Evals | `evals/fixtures/mil-01…`, `mil-02…` + goldens | Scoped digest; readiness with a stale receipt. |

`rules/queue.md` gains a companion pointer to `MS-05` and nothing else:
the grouping rule is unchanged, and the scoped view is a rendering
concern layered above it.

## What was considered and left out

- **Milestone as a routing input** — declined under R2, permanently.
- **Closed-side progress** — declined under R1; revisitable on
  evidence, and the revisit would be a new ruling, not a quiet widening
  of the fetch.
- **Writing the milestone field** (auto-assigning items to a milestone
  from a category or a roadmap row) — out of scope. It is a write, and
  a judgment write at that; `MS-10` bars it from both surfaces.
- **A cross-milestone dashboard** (every open milestone, side by side)
  — deferred. It is the batch digest's problem shape, one level up, and
  nothing in the request asked for it.
