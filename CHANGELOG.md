# Changelog

Loosely Keep-a-Changelog shaped, but plainer: what changed, why (the
field feedback or decision behind it), and what it touches. Versions
match `.claude-plugin/plugin.json`; releases are tagged `vX.Y.Z` per
[CONTRIBUTING.md](CONTRIBUTING.md)'s release steps. Design-doc deltas
are recorded in [docs/design/](docs/design/); this file is the
maintainer-facing summary of what shipped, not the rationale of
record.

## [Unreleased] — lands as 0.5.0

Design doc: [v0.7.2](docs/design/lq-maintainer-agent-design-v0.7.2.md)
(delta over v0.7.1, drafted 2026-08-05/06, pending adoption).

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
