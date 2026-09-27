# Changelog

Loosely Keep-a-Changelog shaped, but plainer: what changed, why (the
field feedback or decision behind it), and what it touches. Versions
match `.claude-plugin/plugin.json`; releases are tagged `vX.Y.Z` per
[CONTRIBUTING.md](CONTRIBUTING.md)'s release steps. Design-doc deltas
are recorded in [docs/design/](docs/design/); this file is the
maintainer-facing summary of what shipped, not the rationale of
record.

## [0.6.0] — 2026-09-27

Two strands: milestone scanning (a design delta), and context-budget
work that changes only *when* rule and skill bytes are read, never what
is decided. The latter has been in field use on `legalquants/lq-ai`
since 2026-08-27.

### Milestone scanning

Design doc: [v0.7.4](docs/design/lq-maintainer-agent-design-v0.7.4.md)
(delta over v0.7.3, adopted 2026-08-17). Request, rulings and spec in
[docs/proposals/milestone-scanning.md](docs/proposals/milestone-scanning.md).
From a maintainer field request: "im wishing i can scan PRs and issues
by milestone."

- **The milestone becomes a scan unit** (new
  [rules/milestones.md](rules/milestones.md), `MS-NN`). GitHub already
  carries the grouping on every PR and issue; the agent never read it.
  It now does — as a **selector and never a signal**. `MS-02`: no lane,
  category, tier, issue class, anchor, escalation trigger, burden
  verdict, or merge-order group may read the field, so a scoped run
  produces exactly the per-item calls an unscoped run would. A due date
  is not an argument for a lighter touch, and an item's absence from
  the milestone is not evidence against it either. The agent never
  writes the field: creating, closing, re-dating a milestone or moving
  an item into or out of one is a handed-over command, one at a time
  (`MS-10`).
- **`/lq-maintainer:triage milestone "<name>"`** — the same batch
  digest, scoped. New scope line
  ([templates/digest.md](templates/digest.md) `DG-15`) carrying the
  resolved milestone (title, number, state, due date), the open-only
  bound in words, and the two **omission counts** — how many open items
  carry no milestone, how many were excluded for carrying a different
  one. A filter's failure mode is a silent omission that reads like a
  complete answer, so the counts are mandatory and the excluded items
  are never enumerated (`MS-04`). Milestone resolution is exact: zero or
  two matches **stop the run** and ask, and the whole queue is never
  scanned as a fallback (`MS-01`).
- **Merge-order groups are computed queue-wide, then filtered for
  display** (`MS-05`). The `rules/queue.md` Q-01 collision is a property
  of the shared manifest, not of anyone's milestone: grouping inside the
  scope would report a two-PR group as clean while a third PR one
  milestone over moves the same lockfile out from under both. Every
  out-of-scope member of a rendered group is named, with its own
  milestone, and marked — and Q-02's security-first ordering still
  names it first when it is the advisory-backed one.
- **`/lq-maintainer:milestone "<name>"`** — new skill
  ([skills/milestone/](skills/milestone/), rendering
  [templates/milestone-scan.md](templates/milestone-scan.md) `MI-NN`).
  What is **left** in a milestone and what is blocking it, in four
  buckets: blocking / ready to close out / needs work / not yet
  assessed, each line citing the rule that placed it. **Open items
  only** (`MS-03`) — the closed side is never fetched, so the scan
  reports what is left and never a completion figure, and an empty
  milestone reports emptiness rather than "done". Bare
  `/lq-maintainer:milestone` lists the open milestones and asks which.
- **It reads evidence; it does not re-review** (`MS-11`). The scan is in
  `/lq-maintainer:label`'s weight class, not triage's. Every line names
  its source — `receipt @<sha>` or `provisional` — and the asymmetry is
  one-directional: "blocking" and "needs work" may rest on a mechanical
  fact the fetch established (a dirty merge state, failing CI), while
  **"ready to close out" is a clearance and always needs a non-stale
  receipt**. A cheap pass may add work; it may never clear it.
- **Stale evidence never counts as ready** (`MS-12`). A receipt written
  at a head SHA that is no longer the item's head renders
  `receipt (stale — evidence at <sha>, head is now <sha>)` and moves the
  item to *not yet assessed*. A merge candidate from three commits ago
  is not a merge candidate; the ratchet holds its usual direction.
- **Counts, never a forecast** (`MS-08`). "4 blocking, due in 6 days" is
  the report. "On track", "at risk", "will slip", a velocity, a
  burn-down, and a completion percentage are banned outright — a tool
  that has never seen the closed side of a milestone would be inventing
  one. Carve-outs survive scoping unchanged (`MS-06`): the C-40
  one-liner, an E-21 suspension and a §7.1 hold each render inside a
  scope exactly as outside it, never folded into a bucket count.
- **Evals:** two new fixtures and goldens — `mil-01-milestone-scope-filter`
  (the advisory-backed member of a shared-lockfile group sits one
  milestone over; both omission counts stated; a "keep the review light"
  milestone description that must move nothing) and
  `mil-02-milestone-readiness-stale-evidence` (a clean, green,
  never-assessed PR that must not be called ready, and a recorded
  `merge` two commits stale that must lose its clearance). Both carry
  `kind: milestone-scan`, a new cross-item golden kind that
  `ci/scripts/grade-evals.sh` exempts from lane grading exactly as it
  exempts `kind: release-range` — a milestone is not routed. Grading
  contract in [evals/run-checks.md](evals/run-checks.md); the corpus
  index and counts in [evals/README.md](evals/README.md) are corrected
  to the real 28 fixtures (the v0.7.2 additions had never been listed).

### Context budget — read the same rules, later, and only the ones that bear

From the maintainer sessions of 2026-08-20/26 on `legalquants/lq-ai`: a
single `/lq-maintainer:review-pr` on #535 loaded fifteen rule files
(38,958 tokens) before reading a line of diff and cited 36 of the 245
rule IDs they define; batch triage re-read five files per item (~14,000
tokens each time); peak context ran 248k–504k, and one session
compacted — the failure design §3.3 names, since a call made from a
compacted summary is invalid (B-00a). **No output changes** in any of
the items below: same lanes, categories, tiers, decks and receipts.

- **Progressive rule loading** (new [rules/loading.md](rules/loading.md),
  `LD-NN`). Each rule file is classified by one question: does
  correctness require evaluating every entry, or only those that apply?
  Every-entry files (injection-posture, escalation-triggers,
  change-categories, tiers, reversibility, breaking-changes, conduct,
  tone-gate, self-attestation, anchoring, stale-sweep, queue, canon-map)
  still load whole — a trigger you did not read is a trigger you did not
  clear. Conditional files (lanes, salvage, burden, labels, issues,
  decision-scoping, milestones) load as a spine first; anything under
  ~2,000 tokens loads whole regardless (`LD-03`). **`LD-05`: a spine
  routes, it never decides** — a rule is fetched in full before it is
  applied, cited or rendered. `LD-06` fails toward loading on any doubt,
  `LD-09` never defers injection-posture or escalation-triggers, and
  `LD-08` records each deferral as a work-log row. Standard-lane review:
  ~52,500 → ~35,600 tokens before any diff.
- **`skills/triage/scripts/rules-index.sh`** extracts spines and
  sections rather than authoring them (`LD-04`): IDs, titles and full
  rule text verbatim from the file, so a spine cannot drift from what it
  indexes and a section cannot be a paraphrase. Fails closed.
  `ci/scripts/test-rules-index.sh` — 128 checks over all 21 rule files
  (every emitted line verbatim in its source, every spine exactly the
  IDs its file defines, all fail-closed paths exit non-zero with no
  content) — wired blocking in `rules-index-test`.
- **Batch triage's per-item fan-out is executable** (design §3.3).
  `skills/triage/SKILL.md` offered "fork a fresh subagent per item" while
  its own allow-list omitted `Task`, so every batch run took the
  re-read branch (sidechain count across four sessions: 0). `Task` joins
  the allow-list, read-only, and new
  [agents/triage-item.md](agents/triage-item.md) pins what gets forked —
  no Write/Edit/Bash, no further fan-out, the C-40 / E-21 / §7.1
  carve-outs verbatim. The brief carries **rule paths, never rule
  content**; the hand-back is enumerated — the `receipt:v2` footer and
  one digest line, never findings prose or quoted contributor text
  (I-09/I-12). The four-pass deep-dive team still lives only in
  `/lq-maintainer:review-pr`.
- **`review-pr`'s Tier-2 deep dive moves to a reference file**
  ([skills/review-pr/references/tier-2-deep-dive.md](skills/review-pr/references/tier-2-deep-dive.md)),
  loaded only when a TR-07 condition fires. The Tier-1 quick pass — the
  default and most runs — no longer carries it (~2,300 tokens per
  invocation; one measured session injected `SKILL.md` four times and
  entered Tier 2 zero times). Procedure unchanged phrase for phrase; the
  stub fails toward loading, and the load is an `RP-21` work-log row.

## [0.5.1] — 2026-08-12

Design doc: [v0.7.3](docs/design/lq-maintainer-agent-design-v0.7.3.md)
(delta over v0.7.2, adopted 2026-08-12). Spec and measurement in
[docs/proposals/deck-findings-and-work-log.md](docs/proposals/deck-findings-and-work-log.md).
Both items come from maintainer field feedback on v0.5.0 decks.

- **Findings render as their L-33 structure, not as a paragraph**
  (design v0.7.3 §2). Each finding is now a card: severity / scope /
  disposition chips, the diagnosis, then labelled `where` (a
  click-through blob link pinned to the reviewed head SHA), `change`
  (the L-33 ask) and `why` (the impact) slots, the drafted
  replacement **verbatim** in a click-to-select block with its apply
  path, and the per-finding comment and follow-up stub one disclosure
  down. A scan strip above the cards lists every finding — including
  the minor ones folded below — with a ⚡ on the ones carrying a
  one-click replacement. **Bug fixed:** the inline-backtick pass was
  chewing the ` ```suggestion ` fence, so the L-33a one-click block
  arrived mangled and unselectable — the single most actionable
  element on the page. Disposition/scope glosses moved to the how-to
  card and each chip's tooltip instead of a sentence per finding.
- **The work log** (`templates/receipt-pr.md` RP-21,
  `templates/receipt-issue.md` RI-15; design v0.7.3 §1). Every
  internal evidence record now carries one row per act the run
  performed, in order — what was read, which scripts ran, which named
  passes ran and which did **not** — with enumerated `Act`/`Result`
  and a `not-run` row (never a silence) for every skipped pass, updated
  rather than deleted on resume. Emission steps added to
  `skills/review-pr` (Step 4 and 5.2), `skills/review-issue` (Step 5
  and 7) and `skills/triage` (Step 9). Visible body only — the
  `receipt:v2` footer schema is **unchanged**, no version bump.
- **"What I checked" is a visible deck card** (design v0.7.3 §2). The
  work log, the anchor determination, the checks that ran, the vetting
  checklist and the self-attestation cross-check with its evidence
  column were all already in the record and were rendered nowhere but
  the raw dump at the foot of the page. They now render as one visible
  card, directly above "what was not checked".
- **The seven-point gate stops claiming a clearance it never ran.**
  The gate tile, dot meter and explainer render only on items the
  dependency gate actually judged; a code PR no longer shows "Safety
  gate — 3 / 3 — all passed" for a gate where four checks were `n-a`.
  The checks that did run still render as evidence, without their
  dependency-flavoured glosses.
- **The "Decisions to make" panel renders the decisions** (design v0.7.3
  §2). It was rendering the footer's counts and enums only, so an
  escalated deck named no decision to be made and repeated a 30-word
  explainer of what a draft ADR is, once per row. Each residual now
  carries its sentence, each settled entry its click-through citation,
  and each reserved-human row the permanently-open badge; the artifact is
  a short chip and its gloss moved to the how-to card. A residual the
  footer counts but the body never states renders as a row marked
  unstated. Fixes a defect against `rules/decision-scoping.md` D-13 as
  written. The drafted ADR / DE stub stays in the committee packet — the
  panel now says so.
- **A standing caveat is no longer a "next step."** Never-by-design
  coverage entries stop seeding the Next-steps list; they render,
  unresolvable, in the "what was not checked" card as always.
- Renderer hardening: a finding location containing a `..` segment or a
  leading slash never builds a link.
- `ci/scripts/test-render-deck.sh` — 42 new checks (169 total): the
  L-33 slots and the label words never rendering as prose, the
  head-SHA-pinned location link, the `suggestion` fence surviving
  verbatim, the scan strip's presence/absence rules, each evidence
  table, `not-run` rendering as not run, gate suppression on code
  items, the injection allow-list holding on every new surface, and the
  decision ledger.

## [0.5.0] — 2026-08-06

Design doc: [v0.7.2](docs/design/lq-maintainer-agent-design-v0.7.2.md)
(delta over v0.7.1, adopted 2026-08-06). PRs #11 and #12.

- **Deck leanness** (renderer implementation per design v0.7.1 §5;
  spec in
  [docs/proposals/deck-leanness.md](docs/proposals/deck-leanness.md)).
  The visible spine reorders to what the maintainer actually uses:
  findings and the paste-ready drafts are visible cards; the drafted
  comment and merge message share one card; the ruling and the
  agent's recommendation share one decision card (ruling leads);
  References ride above the fold; the runtime caveat renders once
  visibly; scaffolding prose consolidates into a single closed "How
  to read this page" card; "What was not checked" folds each item's
  gloss behind its still-visible badge + title. No fact deleted;
  nothing moves more than one disclosure level down. Touches
  `skills/triage/scripts/render-deck.sh` and
  `ci/scripts/test-render-deck.sh` (new regressions: the runtime
  gloss renders once in the visible region; no merge-message block on
  issue decks).
- **Breaking-change detection** — new deterministic check script
  `skills/triage/scripts/check-breaking.sh` (diff-text-only, no
  network) and `rules/breaking-changes.md` (BC-01–BC-04); wired into
  triage Step 6b and review-pr. A detection (`findings ≥ 1`) fires
  the RV-02 public-API class; a fail-closed FAIL is an
  infrastructural failure, not a detection; a PASS proves nothing and
  moves nothing lighter.
- **Label projection** — new skill `/lq-maintainer:label` and
  `rules/labels.md` (LB-01–LB-05): provisional classification mapped
  onto the target repo's own labels, hand-over of one exact command
  per label (the hooks block `gh pr edit`/`gh issue edit` outright),
  sync steps in triage/review-pr/review-issue, `labels_synced` footer
  field. Security carve-outs bind labels as public output; the agent
  never proposes `security` or the judgment labels.
- **Release narrative** — new skill `/lq-maintainer:release-notes`
  and `templates/release-notes.md` (RN-NN): drafts the target repo's
  release notes from merge trailers and receipt evidence, breaking
  changes leading, semver suggested with evidence but never decided.
  Security note: the skill's allow-list carries `git tag --list` only
  — plain `git tag` would permit promptless local tag creation, which
  the hook does not block.
- **Eval suite** — five new fixture/golden pairs (BC positive and
  negative, E-21 empty-label-delta, label-sync correction,
  release-range narrative) and the v0.7.2 golden-file lint in
  `ci/scripts/grade-evals.sh` (closed label vocabulary, three-state
  `labels_synced`, semver enum, the E-21/C-40 label-suspension
  consistency check, release-range lane-pass skip).
- **Canon-drift check green again** — the nightly job had been red
  since 2026-08-03 on six pre-existing dangling citations (bare-domain
  `canon:repo` tokens; literal evidence-store paths). Fixed alongside
  the four this cycle introduced: the labels component-path table
  moved into `rules/canon-map.md` as `canon:component-paths` (§2.2 —
  the only file allowed to encode target-repo structure), and
  evidence-store citations take the angle-bracket placeholder form.
- **Agent-repo links corrected** — every template attribution line
  and the check scripts' User-Agent URLs now point at
  `houfu/lq-maintainer-agent` (they said `legalquants/`, which is not
  where this repo lives). Archived design docs keep their original
  references, per the never-edit-old-versions convention.

## [0.4.1] — 2026-07-30

Design doc: [v0.7.1](docs/design/lq-maintainer-agent-design-v0.7.1.md)
(delta over v0.7). Driven by real maintainer field sessions on
`legalquants/lq-ai` in July 2026 — PRs 316, 398, 399, 441, a full
dependabot-queue sweep, and the mkorpela squash.

- **The finding contract.** Every finding now carries an **impact**
  (what breaks, for whom), an **ask** (who does what next), and a
  **scope** (in-scope / follow-up / pre-existing) — findings like
  "does not touch a test" were reaching maintainers with no stated
  stakes and no concrete next step, and scope kept getting litigated
  by hand. A new binding test, L-33b, rejects any finding — at any
  tier, including the Tier-1 quick pass — that leaves the reader
  asking "so what do I do?" Out-of-diff observations now land as
  scoped pre-existing/follow-up findings instead of vanishing into a
  bare coverage note. (`rules/lanes.md`, `rules/tone-gate.md`,
  `templates/receipt-pr.md`, `templates/receipt-issue.md`,
  `templates/triage-card.md`, `skills/review-pr/references/member-constraints.md`;
  new `std-10-finding-contract-scope` eval.)
- **Batch queue intelligence.** A maintainer running a dependabot
  sweep asked for a table of which open PRs collide on merge order,
  and said babysitting each rebase by hand "seems a bit painful."
  Batch triage now computes **merge-order groups** from the fetched
  diff files (PRs sharing a manifest/lockfile), orders each group
  security-first (advisory-backed members lead), and states — per
  remaining PR — what merging the recommended-first one invalidates.
  The digest reorders security-first and gains a mergeability table,
  merge-order-groups section, and a deck-path index; report-only
  throughout, one human click per write as everywhere else. (New
  `rules/queue.md` Q-01–Q-03; `skills/triage/SKILL.md` fetch gains
  `mergeable`/`mergeStateStatus`/`baseRefName`; `templates/digest.md`;
  new `bat-01-dependabot-merge-order` eval — first `item_type: batch`
  fixture; corpus at 21.)
- **Deck legibility.** Findings now split by severity: blocking/major
  render inline and auto-open; minor/nit fold into a quieter nested
  disclosure — a maintainer asked to "read at least the major findings
  and be able to click to reveal the minor ones." Dispositions and
  scope render as plain-language glossed captions instead of raw enum
  words, fired escalation triggers get a "Why this escalated" card,
  and the deck's provenance footer now stamps the **renderer's own
  version** (read fresh from the installed plugin at render time), so
  a stale install is visible on the artifact itself instead of only in
  the receipt's pinned `agent_version`. (`skills/triage/scripts/render-deck.sh`;
  `templates/deck/glossary.md` +17 keys; renderer CI 99 → 114 checks.)
- **Squash attribution and ruling sync.** The drafted squash-merge
  message now preserves every contributor's `Signed-off-by` trailer,
  adds a `Co-authored-by` per distinct squashed author, fixes trailer
  order, and explains in plain language what the two certifications
  mean (prompted by the mkorpela squash, where two `Signed-off-by`
  lines needed unpacking by hand). At finalize and on any resumed
  session, the recorded maintainer ruling now syncs from **live
  GitHub state** — a maintainer asked the agent to check the PR itself
  rather than trust the chat session's memory — with GitHub always
  winning over a stale in-session guess and any discrepancy surfacing
  as a dated note, never a silent rewrite. The stale `receipt at
  <receipt-comment-url>` placeholder is fixed to point at the evidence
  store. (`templates/merge-message.md` MM-05a; RP-18 mirrored into
  RI-13 and all three skills' finalize/resume steps.)

## [0.4.0] — 2026-07-27

Design doc: [v0.7](docs/design/lq-maintainer-agent-design-v0.7.md)
("Momentum"), adopted 2026-07-26 from the first 2–3 weeks of live
operation.

- The deck becomes the one surface a maintainer reads: it now carries
  the paste-ready drafts (the short public comment; the drafted
  squash-merge message for merge candidates) as collapsed cards, so
  nothing is delivered as loose chat text.
- The maintainer's final ruling is recorded — who ruled, in their
  words, and its alignment with the agent's recommendation
  (accepted/adjusted/overridden) — API-verified against the
  authenticated `gh` identity and repo permissions, with an honest
  `stated` fallback where that check is declined. Recording is
  optional by design: a contributor's own self-check session records
  no ruling and is never pressed for one.
- A cross-item feedback log
  (`templates/feedback-log.md`) aggregates divergences and explicit
  maintainer feedback, local-cache only — the raw material for new
  golden evals.
- Findings with a concrete textual fix now carry a drafted GitHub
  suggestion block and a stated apply path (L-33a), so acting on one
  is one click for the maintainer or the contributor; the tone gate
  gains the "what do I do now?" test (TG-03.2).
- The committee packet aligns with the amended E-23/D-08 posture (new
  CP-09 plus a recommendation section; the stale "never recommends"
  preamble is removed).

## [0.3.0] — 2026-07-26

Design doc: [v0.7](docs/design/lq-maintainer-agent-design-v0.7.md)
adopted. Every contribution is treated as sincere and with respect
(probing/challenging language banned and tone-gated); reviewers defer
to authors on approach; the canon is amenable to change; PRs classify
into four change categories, with categories 2–3 (behavioral changes,
bug fixes) as the review target and category 1 (greenfield / the DE
series) routed to a new design path that drafts the plan, ADRs, and an
atomic decomposition. Review is tiered with a quick-pass default
(≤400 lines) that must end in one concrete action with its undo path;
conservatism attaches to irreversibility instead of uncertainty.
Escalation softens where it was decision-shaped (E-04 retired for
categories 2/3; the agent now recommends a resolution on escalated
items) while every security trigger stays absolute. Deliverables split
public/internal: the deck becomes the public primary artifact (bound
for a future community repo), the PR comment shrinks to a short warm
note, and the receipt becomes internal evidence.

## [0.2.0] — 2026-07-12

Design doc: [v0.6](docs/design/lq-maintainer-agent-design-v0.6.md).
First full plugin build: `rules/` (anchoring, lanes, escalation
triggers, injection posture, issues, salvage, canon-map, stale sweep),
`skills/` (`triage` and `review-pr` with the deterministic fast-lane
check scripts), `templates/` (receipts, merge trailer, committee
packet, contributor responses, digest), `evals/` (13 fixture+golden
pairs and the structural grader), `ci/` + `.github/` workflows
(`eval-run`, `canon-drift-check`), and the guardrail hook
(`block-writes.sh` allow-list) with the plugin/marketplace manifests.
The `check-*.sh` and `block-writes.sh` files are intentional
sh/python3 polyglots (run under `sh`, `exec python3`).
