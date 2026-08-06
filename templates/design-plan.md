# Template — design plan (the category-1 path)

Rendered by `skills/design-plan/SKILL.md` for every category-1
contribution (`rules/change-categories.md` G-02) — the greenfield /
new-feature work the DE series lives in (design doc v0.7 §9). The plan
is what a category-1 item gets **instead of** a code review: the
decisions the feature would require the project to make, drafted; the
obstacles it would hit, rule-grounded; and the ordered sequence of
small, reviewable changes that would implement it once the design is
ratified. **Render, never freehand**: the field rules (`DP-NN`) are
normative.

The plan is a **maintainer-and-committee artifact**, stored like the
internal evidence record (`templates/receipt-pr.md` — local cache
today, the community repo's `reviews/<pr|issue>-NNNN/` once it
exists, `docs/community-repo.md`). The only thing posted to the item
is the short warm note rendered from `templates/pr-comment.md`, whose
outcome sentence for this path is the design-plan one (`PC-01`). The
agent drafts everything and files, numbers, and posts nothing
(`rules/salvage.md` S-20, `rules/decision-scoping.md` D-07).

Canon citations inside a rendered plan use `canon:<key>` + section as
routed by `rules/canon-map.md`, as click-through links pinned to the
canon SHA; this template names no lq-ai paths.

## Field rules

- **DP-01 — Header, pinned fields, and the category call.** The plan
  opens with the item, its title, the author and author class
  (API-determined, `rules/lanes.md` L-07), and the category call with
  its assigning rule and confidence (`G-01`/`G-02`) — a
  recommendation, contestable and maintainer-reassignable (`G-09`).
  The **four pinned fields** (PR head SHA or `n/a`, canon SHA, agent
  version, served model ID; design §3.4) render in the Reviewed-at
  block and in the footer, always.

- **DP-02 — Acknowledgment first, specific, never effusive.** Section
  1 names concretely what the contribution does and what it already
  got right — the problem seen, the surface designed, the work
  already done (`rules/conduct.md` CD-04). It is written to the
  contributor and passes `rules/tone-gate.md` with every other
  contributor-facing passage (`TG-01`): no probing, no competence
  implications, no suspicion hedges, no posturing (`TG-02`). "Thanks
  for this" alone never satisfies this rule.

- **DP-03 — The decision inventory: what this feature asks the
  project to decide.** Section 2 lists, as **one atomic ratifiable
  sentence each** (`rules/decision-scoping.md` D-05 form — a
  decision, not a question; if stating it honestly needs "and", split
  it), the decisions the feature would require. Each entry carries:
  its **kind** (structural / forward-looking / workflow-convention /
  amends-existing-canon / reserved-human, `D-06`), its **nearest
  canon** — the adjacent decided items and foreclosures that bound
  the hole, each cited as a click-through link at the pinned canon
  SHA — and its **drafted artifact** pointer. Entries the agent's own
  canon search found **already settled** render in the Settled table
  above the open ones, with the four `D-04` fields (sub-question;
  what canon decided, quoted or tightly summarized, never merely
  "touched"; citation; status word). A settled row is the agent's
  finding, not a ruling: a human who contests one converts it to an
  open decision on the spot (`D-04`). "Canon absent" never renders
  alone — the absence is stated **and mapped** (`D-05`).

- **DP-04 — Drafted artifacts are attachments: watermarked,
  unnumbered, uncommitted, never anchors.** One artifact per open
  decision, routed by kind (`D-06`): structural → a draft ADR
  rendered from `templates/draft-adr.md`, opening with the `DA-01`
  watermark **verbatim** and carrying only the placeholder
  `ADR-XXXX (DRAFT)`; forward-looking → the S-DE DE-XXX / mini-PRD
  stub, including its amendment and workflow-convention annotated
  forms; reserved-human → no artifact, listed with the reserving
  citation. Every artifact attaches under Attachments and is handed
  over as text — the agent never files, numbers, commits, or posts
  one (`S-20`, `D-07`), and no draft ever satisfies anchoring
  (`rules/anchoring.md` A-12) until a human adopts, numbers, and
  merges it.

- **DP-05 — Predicted obstacles: a rule-grounded list, never a
  grade.** Section 3 previews what this feature would run into, in
  the `rules/issues.md` IV-02 style: each line names the rule or
  canon fact that **would fire** — a `canon:prd` non-goal that would
  decline a part (`S-DECLINE`), a sensitive-path proximity that
  escalates regardless of category (`E-01`, `G-08`), an
  irreversible-class surface that can never take Tier 1 (`RV-02`/
  `RV-03`), a duplicate or contradicting reference (`S-DUP`, `C-60`),
  a decomposition the size bounds would require (`TR-03`, `S-01`).
  There is **no worst-of level and no axis tile**: obstacles are
  facts about what the agent's own rules would do, not speculation
  about unwritten code. Where a would-fire prediction depends on an
  implementation choice the contribution does not pin down, say so
  plainly rather than guessing. Where verified canon settles part of
  the ask, an obstacle line may take the sanctioned `D-14` split
  form.

- **DP-06 — The atomic-change decomposition: the path from idea to
  merged code.** Section 4 is the **ordered** sequence of
  category-2/3-sized changes that would implement the feature *after*
  the design is ratified. Each is **one sentence** (`S-01`
  atomicity — if it needs "and", split it), sized inside the Tier-1
  bounds where possible (≤ 400 changed lines and ≤ 10 files,
  `rules/tiers.md` TR-03), and carries its category (2 or 3), what it
  depends on, and a flag where it touches an irreversible class — the
  latter can never take Tier 1 and is marked as Tier-2-from-the-start
  (`RV-03`). The sequence is a **plan, not a verified split**: it is
  never claimed to compile, pass tests, or preserve behavior. Where
  the item is a PR whose existing diff is being mapped onto the
  sequence, the salvage machinery governs and its mandatory line
  renders **verbatim** — "proposed split not verified to compile or
  pass tests" (`rules/salvage.md` S-13/S-14, with the S-16 file-level
  degradation above the size threshold and the S-12
  maintainer-performed-split default).

- **DP-07 — The drafted contributor response.** Section 5 is the text
  the maintainer may post, drafted for a possibly non-engineer reader
  (`CD-05`): what happens next with their idea, the credit it
  carries, and **exactly one next step** — theirs or ours ("nothing
  needed from you — this is on us now" is a complete answer,
  `TG-03.2`). It never asks the contributor to defend the idea, never
  implies the ask was too big, and never promises ratification. The
  short public note is rendered separately from
  `templates/pr-comment.md`; this section is the fuller text the
  maintainer may draw on. Both pass `rules/tone-gate.md` before they
  are offered for posting (`TG-05`).

- **DP-08 — The committee handoff carries a labeled recommendation.**
  Section 6 hands the plan to whoever ratifies it: the open decisions
  as ratify / amend / reject questions (`CP-05` form), and — new in
  v0.7 — the agent's **recommended resolution per open decision**,
  clearly labeled as a recommendation and kept visually separate from
  the evidence above it (`rules/escalation-triggers.md` E-23 as
  amended, `rules/decision-scoping.md` D-08 as amended). The
  recommendation is never folded into the Settled table or into a
  drafted artifact's Decision section. Where two decision texts are
  both canon-consistent they are drafted as Alternatives A/B, never
  ranked, and the recommendation may itself be "either — the
  committee's preference". Adopting, amending, or rejecting the
  recommendation is the human's act, every time.

- **DP-09 — Credit is not optional.** The contributor is named in
  every drafted artifact whose idea originated in the contribution
  (`rules/salvage.md` S-22) and in the plan's own credit line: the
  idea enters the canon with its origin attached, whether the design
  is ratified or rejected.

- **DP-10 — Honesty rails.** The plan carries a **coverage
  statement** with two permanent lines: *no code review was performed
  — this is the design path, not a review of the diff*, and *runtime
  behavior — never checked: the agent does not execute contributed
  code*. It also carries the permanently-open human-only judgments
  (contributor trust, roadmap-worth) as open questions; they can
  never render as resolved, by anyone, ever.

- **DP-11 — Attribution line.** The plan ends its visible body with
  the standard attribution line — agent version, the posting/owning
  maintainer, linked to `docs/bot-behavior.md`. Not removable; the
  handle is prefilled with the API-verified session identity
  (`templates/receipt-pr.md` RP-18 — a verified prefill is not a
  guess, confirmed at the gated write), and otherwise asked for or
  left visibly unfilled — never filled from an unverified source.

- **DP-12 — Footer last, enumerated only.** The machine-readable
  footer is the final element, after the attribution line, and
  carries **enumerated fields only** — no free text, ever, and never
  quoted contributor content (§8.4; an HTML comment is exactly the
  concealment channel injection uses). The acknowledgment, the
  decision sentences, the obstacle lines, the change sentences, and
  the drafted response live in the visible body. The marker is
  `lq-maintainer-agent:receipt:v2`, and the schema is
  `templates/receipt-pr.md`'s with `profile: plan` and the additive
  `plan` counts block below.

- **DP-13 — Carve-outs win.** A vulnerability-suspect item (`C-04`/
  `C-40`, `E-08`) gets **no plan and no deck** — the only output is
  the drafted private-advisory redirect. Under `E-21`
  (suspected-deliberate attack) no public output is drafted until the
  maintainer rules, and the plan, if any, goes only into the
  committee packet (`CP-06`). A held item (`H-01`/`H-02`) is marked
  held and nothing further is drafted for it except at explicit
  maintainer request.

## Template

```markdown
## Design plan — <PR | issue> #<n>: <title>

Author: <login> (<author class, API-determined>)
**Category 1 — greenfield / new feature** (assigning rule: <G-02>;
confidence: <high | medium | low>) — this item takes the design path,
not a code review (`G-07`).
<if held (DP-13): **Held at contributor request.** "<verbatim quoted
request>" — a maintainer will respond; nothing further is drafted.>

### 1. What you built, and what it gets right

<Two to four sentences, to the contributor: the problem this addresses,
the surface it designs, and the specific thing already done well —
concrete, not effusive (CD-04). Tone-gated (TG-01).>

### 2. What this asks the project to decide

Searched **by the agent** at canon `<sha>` (never the contribution's
claims, I-13): <corpora searched — canon:prd body, the ADR directory,
canon:roadmap, canon:de-list, plus any key a fired trigger names>.

Already settled — the agent's findings; verify each by click. A
contested row becomes an open decision (D-04):

| # | Sub-question | What canon decided | Status | Citation |
| --- | --- | --- | --- | --- |
| S-1 | <one sentence> | <decision content, quoted or tightly summarized> | <implemented / partial / deferred-with-commitment / rejected-with-reasoning / n-a> | [<canon:key §x / ADR-NNN / DE-XXX>](link, at canon `<sha>`) |

<or: none — nothing this feature raises is already decided.>

Open decisions — one ratifiable sentence each:

- **D-1 — <one declarative, ratifiable sentence>.**
  Kind: <structural | forward-looking | workflow-convention |
  amends-existing-canon | reserved-human>
  Nearest canon: [<citation>](link) — <what it decides on this side>;
  [<citation>](link) — <the other side>. <if canon conflicts: both
  sources cited, and the conflict stated as a finding (D-03).>
  Drafted artifact: <ADR-XXXX (DRAFT), in Attachments | DE/mini-PRD
  stub, in Attachments | none — reserved-human>

Reserved for humans by canon — never narrowed: <judgment — the
canon/rule that reserves it> <or: none put at issue by this feature>.

### 3. What this would run into (predicted obstacles)

Each line names the rule or canon fact that would fire — facts about
this project's own rules, not speculation about unwritten code.

- <obstacle> — <the rule/canon that would fire, cited as a link>.
- <obstacle> — <rule/canon citation>.

### 4. The path from here: <k> atomic changes

Once the design above is ratified, this is the ordered sequence of
small, reviewable changes that would implement it. Each is one
sentence and sized for a quick pass (≤400 changed lines, ≤10 files,
TR-03) unless flagged otherwise. **This is a plan, not a verified
split — nothing here is checked to compile or pass tests.**

| # | The change, in one sentence | Category | Depends on | Notes |
| --- | --- | --- | --- | --- |
| C-1 | <one sentence> | <2 / 3> | <none / C-i> | <e.g. irreversible class (RV-02): Tier 2 from the start> |

<if an existing diff was mapped onto this sequence (S-13):>
**proposed split not verified to compile or pass tests**
Sanity checks: partition covers the whole diff — <pass / fail>;
no symbol split across parts — <pass / fail>;
<if degraded: proposal degraded to file-level (diff above the size
threshold, S-16).>
Default offer: the split is maintainer-performed unless the
contributor prefers otherwise (S-12).

### 5. Drafted response to the contributor

<The text a maintainer may post: what happens next with the idea, the
credit it carries, and exactly one next step — theirs or ours. Plain
words, no rule IDs, no lane/tier/category jargon. Tone-gated (TG-01).>

### 6. For whoever ratifies this

Questions — one per open decision:

1. Ratify, amend, or reject drafted decision D-1: "<atomic sentence>"?
   (draft attached)
2. <further questions; reserved-human judgments stay free-form>

**Agent's recommended resolution** — a recommendation, not a finding;
the human decides in every case (E-23, D-08):

- **D-1** — <recommended resolution, one or two sentences> <or:
  "either — Alternatives A and B are both canon-consistent; the
  committee's preference">.

### Coverage statement

Covered: <e.g. category call, canon search over the D-02 corpora,
decision inventory, obstacle preview, decomposition>
Not covered: <e.g. decision scoping trimmed — resumable>
Never checked, by design:
- No code review was performed — this is the design path, not a review
  of the diff.
- Runtime behavior — this agent does not execute contributed code.

### Human-only judgments — permanently open

- [ ] Contributor trust — a human call; the agent does not score people.
- [ ] Roadmap-worth — whether this belongs on the roadmap, and when.

### Credit

<contributor name/handle> — this feature's idea, and the drafted
decisions and stubs above, carry their name (S-22).

### Attachments

- <one drafted artifact per open decision: a draft ADR from
  templates/draft-adr.md (watermarked verbatim, ADR-XXXX placeholder)
  or a DE/mini-PRD stub — handed over as text, filed only by a human
  (S-20, D-07).>

### Reviewed-at

| Field | Value |
| --- | --- |
| PR head SHA | `<sha or n/a>` |
| Canon SHA | `<sha>` |
| Agent version | `<x.y.z>` |
| Model | `<served model ID>` |

---
*Drafted by [lq-maintainer-agent](https://github.com/houfu/lq-maintainer-agent/blob/main/docs/bot-behavior.md)
v<x.y.z>; reviewed and owned by @<maintainer>.*

<!-- lq-maintainer-agent:receipt:v2
profile: plan
item: <owner>/<repo>#<n>
kind: <pr|issue>
lane: <standard|escalate>
assigning_rule: <rule-id>
confidence: <high|medium|low>
triggers: [<E-NN>, ...]
held: <true|false>
category: 1
category_rule: G-02
tier: 3
outcome: route-to-design
recommendation: <design|n-a>
undo: null
tone_gate: <applied|n-a>
pinned:
  pr_head_sha: <sha or n-a>
  canon_sha: <sha>
  agent_version: <x.y.z>
  model_id: <served model ID>
plan:
  decisions: <integer>
  settled: <integer>
  adrs_drafted: <integer>
  de_stubs: <integer>
  obstacles: <integer>
  atomic_changes: <integer>
coverage:
  - {item: category-call, status: <covered|not-covered>}
  - {item: canon-search, status: <covered|not-covered>}
  - {item: decision-inventory, status: <covered|not-covered>}
  - {item: obstacles, status: <covered|not-covered>}
  - {item: decomposition, status: <covered|not-covered>}
  - {item: code-review, status: never-by-design}
  - {item: runtime-behavior, status: never-by-design}
decision_scoping:
  applied: <full|partial|n-a>
  questions: <integer>
  settled: <integer>
  residual: <integer>
  reserved_human: <integer>
  residuals:
    - {id: R-1, kind: <structural|forward-looking|reserved-human>, artifact: <adr-draft|de-stub|none>}
-->
```

## Footer notes — `profile: plan`

- The schema is `templates/receipt-pr.md`'s (the authoritative
  definition) with three plan-specific deltas: `profile: plan`; the
  additive `plan` counts block (all integers); and `kind`, which
  records whether the planned item is a PR or an issue, so
  `pinned.pr_head_sha: n-a` on the issue side stays parseable.
  `category` is always `1`, `tier` always `3`, and `outcome` always
  `route-to-design` on this profile; `recommendation: design` is the
  issue-side `IV-01` value (`n-a` for a PR). `undo` is `null` — a
  plan merges nothing; each atomic change states its own undo path
  when it is reviewed (`RV-05`).
- `decision_scoping` follows `D-12` unchanged: `applied: n-a` if and
  only if no trigger fired. The plan's own decision inventory (`D-1`,
  `D-2`, …) is the same partition rendered for a design audience; the
  `residuals` list uses the ledger's `R-<i>` IDs where a trigger
  fired, so a resuming session reads one vocabulary.
- **Enumerated only**, like every footer in this plugin: the decision
  sentences, obstacle lines, change sentences, and drafted response
  are visible-body free text and are never written here.
