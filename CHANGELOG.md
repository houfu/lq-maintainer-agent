# Changelog

Loosely Keep-a-Changelog shaped, but plainer: what changed, why (the
field feedback or decision behind it), and what it touches. Versions
match `.claude-plugin/plugin.json` (and its Codex twin,
`.codex-plugin/plugin.json`); releases are tagged `vX.Y.Z` per
[CONTRIBUTING.md](CONTRIBUTING.md)'s release steps. Design-doc deltas
are recorded in [docs/design/](docs/design/); this file is the
maintainer-facing summary of what shipped, not the rationale of
record.

## [0.8.0] — 2026-11-09

Four strands, one design delta
([v0.8](docs/design/lq-maintainer-agent-design-v0.8.md)), all from a
read of the field record after lq-ai shipped v0.9.1: the session logs
on both hosts, the 161 receipts, and the maintainer's own corrections.
**Read before updating:** on Codex, re-trust the plugin's hook in
`/hooks` after this update (the hook changed; the canary refuses to
run until you do), and the first command of every review run must now
report `armed=yes`.

### Two floors — a maintainer can code through the agent again

Design §1; `rules/runtime.md` RT-03 (amended), RT-09;
`settings/README.md` "Two floors". From the session logs: the hook
fired in every session on a host where the plugin is enabled —
including the maintainer's own development sessions in lq-ai and four
unrelated projects — and blocked 29 pushes the maintainer had asked
for on Codex and 106 hand-run writes on Claude Code
([docs/proposals/v0.8-pain-points.md](docs/proposals/v0.8-pain-points.md)).

- **The canary arms the session.** `lq-maintainer-safety-canary` now
  writes a per-session marker (a hash of the host's session id under
  `~/.lq-maintainer/armed/`) and reports `armed=yes`; a review run
  that does not see it stops (RT-03). Arming is one-way — no disarm
  command exists, because an injected session would run it.
- **Review floor (armed): unchanged.** Every rule, test and evasion
  case of v0.7 holds. Two additions from the record: fetching,
  pulling or cloning by URL, adding or repointing a remote, and
  submodules by URL are blocked (a fork-URL fetch had brought
  contributed code into a review session); `publish/site-refresh.sh`
  is blocked except `--plan`.
- **Coder floor (unarmed): targeted deny only.** Merge, every
  `gh pr review` form, close, repository and release deletion,
  GraphQL mutations, `gh api` DELETE and the REST merge/review
  endpoints, alias and extension laundering, push plumbing binaries
  and PR-ref checkout stay blocked in every mode. `git push`,
  `gh pr create/edit`, `gh issue create`, label edits, GraphQL
  queries and non-GET `gh api` otherwise pass to the host's own
  permission prompt.
- **Fail-closed.** No usable session id, an unreadable marker
  directory or an unrecognized host all give the review floor; only a
  readable, fresh marker's absence gives the coder floor.
- **False positives fixed, both floors** (117 of 147 ordinary-session
  blocks on Claude Code were "unparseable shell quoting"): heredoc
  bodies are data unless the receiving command executes them;
  unparseable text on the coder floor is regex-scanned for the
  invariants instead of blocked; risky words are screened in command
  position only (a `grep "gh pr merge"` passes); `gh run
  download/watch` and `gh release download` are allow-listed.
- **Second layers follow:** `settings/claude-settings.json` drops its
  `git push` deny entries (a vendored prefix deny cannot be
  session-aware); `settings/codex/lq-maintainer.rules` makes `git
  push` `prompt` rather than `forbidden`.
- Tests: `ci/scripts/test-block-writes.sh` 459 checks (arming, both
  floors, stale and garbled markers, heredocs, fork URLs);
  `test-runtime-compat.sh` 62.
- **Known limits, stated:** Codex's payload fields are taken from its
  documentation, not observed; subagents are assumed to share the
  parent's session id; MCP connector tools are not screened (the hook
  is registered on the Bash tool).

### Confidence on findings — evidence and fairness

Design §2; new [rules/confidence.md](rules/confidence.md) (`CF-NN`);
evidence base in
[docs/proposals/blocker-confidence.md](docs/proposals/blocker-confidence.md).
From the maintainer: "confidence readings on blockers based on whether
your evidence supports … a blocking or major issue … and whether it is
fair to the contributor".

- Every finding carries an **evidence** reading (observed / canon-gap
  / mechanical / inferred / unverified) and a **fairness** reading
  (own-burden / not-this-pr / preference / scope-expansion); the
  **confidence** (high / medium / low) is derived by rule, never
  declared. Additive optional keys on the footer's findings tuple;
  `receipt:v2` unchanged.
- **Only a high-confidence blocking finding blocks** (CF-04); an
  inferred or unverified one renders as an RV-06 named check (CF-05);
  a **preference is not a finding** (CF-06); a **scope expansion is a
  follow-up**, never a condition (CF-07); what is not this PR's is
  never asked of its author (CF-08). Live-signal blockers are untouched
  (CF-09).
- **`blocking` means one thing** — a defect that makes merging wrong
  (CF-11); sign-offs, dependency floors and headings are *must-fix
  (mechanical)*; an infrastructure-only CI failure is a note (CF-12).
- Calibrated over 171 blocking/major findings: 51 would lose their
  force; the maintainer had disagreed with 10% of those graded high
  and 64–80% of the rest.
- Eval lint learns the vocabularies and the roll-up rule; three new
  fixtures (`conf-01`–`conf-03`) with goldens; new golden keys
  documented in `evals/run-checks.md`.

### The public reviews site — Pages, a flow page, a scheduled refresh

Design §3; new [rules/publishing.md](rules/publishing.md) (`PB-NN`);
proposal amended in
[docs/proposals/public-receipts-on-lq-ai-community.md](docs/proposals/public-receipts-on-lq-ai-community.md)
(R2, R7 amended; R9–R11 added). From the maintainer: "allows people to
read receipts on lq-ai-community … add in the requisite disclaimers
about whether maintainers decide how to merge"; "we will enable pages
… a scheduled run (maybe on this mac) to update the pages so that it
shows the flow from triage, review and merge."

- **`skills/triage/scripts/publish-site.sh`** — a whitelist generator
  (reads only `receipt.md`, `deck.html` and the footer) that builds a
  static, no-JavaScript site built around the **item page as the
  entrypoint** (`PB-15`: a stable `pr-<number>/` address a PR comment
  can carry before the page exists, the item on GitHub and the newest
  deck led, an anchor per review, a root-anchored `404.html` for a
  link whose page is not there; `PC-04` now links that page, never a
  deck); an index as the overview, one **flow page** per item
  (opened → each review → decision or "not recorded — absence is not
  agreement" → comments actually posted → merged/closed), the deck for
  every reviewed head with the fixed public header at its top, the
  sanitized receipt, `state.yaml`, `status.yaml`, `index.json` and a
  FOR-AGENTS page. Refuses E-21, C-40 and held items; holds E-08 and
  security-tagged items until a per-item ruling; strips paths,
  addresses and permission prose; labels drafts by what was actually
  posted; scans every output and refuses the whole run on a hit.
  `--plan`, `--dry-run`, `--self-test`.
- **`templates/public-header.md`** (`PH-NN`) and
  **`templates/for-agents.md`** — the disclaimer block every page opens
  with ("a human maintainer decides whether and how a change merges";
  recommendation, recorded decision and GitHub state side by side — if
  they disagree, GitHub is right) and the page for machine readers.
- **`publish/site-refresh.sh`** with a `launchd` template — the
  maintainer's own scheduled job, running as them with their own
  credential and no model in the loop; `PUBLISH=no` by default; pushes
  only to the branch the committee designates and never to `main`;
  refuses to run inside an agent session.
- **Nothing publishes yet.** Pages, the branch and the publication
  floor are the committee's decisions (R1, R9–R11); a draft of the
  issue to put to them is
  [docs/proposals/lq-ai-community-reviews-issue-draft.md](docs/proposals/lq-ai-community-reviews-issue-draft.md).
  `docs/community-repo.md` carries a superseded note until the first
  publication lands.

### Rule fixes from the session record

Each cited to the sessions that motivated it in
[docs/proposals/v0.8-pain-points.md](docs/proposals/v0.8-pain-points.md).

- `E-08` gains two tests before the private-advisory redirect fires
  (already public by the project's hand; design or fix without exploit
  detail), names the triggering span, and never ends the maintainer
  conversation.
- **Anchored category 1** (`G-02`, `G-07`, review-pr Step 3): a new
  feature covered by a ratified DE/ADR/PRD/roadmap anchor goes to
  tiered review at Tier 2; the design path is offered once.
- `TR-07a` — the light Tier-2 form for small E-01/E-02-only diffs:
  quick pass plus the full security checklist; lane `escalate`, no
  team, no packet.
- `A-12a` — a proposed decision anchors nothing and orders nothing.
- `BC-01a` — a textual breaking-change hit is confirmed public before
  the `breaking-change` label is drafted.
- `PC-02` leads with the benefit to the project; `MM-05b` credits the
  original author on a reimplementation; `canon:release-conventions`
  joins the canon map.
- The canon SHA is `origin/main` after a named-remote fetch; skills
  pass the diff to `check-breaking.sh` as a file argument.

### Status

Rules, templates, hook, generator, refresh job and evals exist and
pass their local tests; none has run against a live PR, and nothing
has been published anywhere. The three field reports behind the
pain-points and confidence proposals are kept by the maintainer at
`~/.lq-maintainer/field-reports/2026-11-09/` (they quote private
session logs and are not in the repository). Deferred with reasons in the pain-points
proposal: the Codex read-only agents' install step, a batch skill,
mid-session feedback capture.

## [0.7.0] — 2026-10-03

Two strands, each its own design delta: the agent now runs on Codex as
well as Claude Code with every guarantee intact, and a change a person
will see is seen running before it merges. **Read before updating:**
on Codex, re-trust the plugin's hook in `/hooks` after this update
(the hook changed, and Codex skips an untrusted hook — the new safety
canary will refuse to run until you do); and in Claude Code's `auto`
mode, posts are now handed over for you to run instead of posting.

### Seen running before it merges — user acceptance (UAT)

Design doc: [v0.7.6](docs/design/lq-maintainer-agent-design-v0.7.6.md)
(adopted 2026-10-03; delta over v0.7.5). Request, rulings and honest status in
[docs/proposals/uat-for-user-facing-changes.md](docs/proposals/uat-for-user-facing-changes.md).
From the maintainer: "check whether a PR affects the layout or frontend
or user facing situation, and if yes, recommend or require a UAT
check", and "the agent should also require it for new user facing
features."

- **Detection** ([rules/uat.md](rules/uat.md) `UA-01`): new
  `check-ui-surface.sh` classifies changed paths against
  `canon:ui-surface` — rendered / indirect / none, plus an added-page
  flag. Triage puts the result on the card; the PR's own words never
  change it.
- **The gate** (`UA-02`/`UA-03`): **required** for rendered surfaces,
  added pages/components, and new user-facing features (category 1);
  **recommended** for copy, translations and API shapes the UI shows.
  A required UAT holds `merge` ("merge — after UAT") until it passes at
  the reviewed head SHA.
- **Expectations first** (`UA-04`), confirmed by the maintainer; the
  design path now writes them into each user-facing step (`DP-06a`).
- **The agent may run it — I-05 amended.** New `uat-run.sh` builds an
  eligible, web-only PR from `main`'s recipe with the contributed source
  compiled offline, runs it on an internal network with throwaway
  secrets and no credentials, screenshots each expectation with a
  digest-pinned headless browser, and tears everything down. It refuses
  on its own any PR touching manifests, lockfiles, Docker/compose,
  workflows or anything outside `web/`. Each run is a **gated action**
  (approved per head SHA, or handed over); `--plan` shows the exact
  sequence and runs nothing.
- **Verdicts** (`UA-09`): matches / differs / not-reached per
  expectation; a `differs` is a normal finding. Optional additive
  `uat:` footer block (`RP-22`), a UAT card on the deck, and the
  coverage line "never checked, except the screens the UAT card lists".
- **Status: the runner has not yet completed a real run on lq-ai.** The
  first run is the field spike — Docker required, ~25 GB / 20–30 min
  cold build, cached afterwards.

### One agent, two hosts — Claude Code and Codex

Design doc: [v0.7.5](docs/design/lq-maintainer-agent-design-v0.7.5.md)
(adopted 2026-10-03; delta over v0.7.4). Request, findings and rulings in
[docs/proposals/codex-compat.md](docs/proposals/codex-compat.md). From a
maintainer request: "i need to improve claude/codex compatibility."

Codex was already loading v0.6.0 from the Claude layout, and silently
dropping explicit invocation, the `allowed-tools` write gate, and the
pinned read-only subagents. This release makes each guarantee hold on
both hosts ([rules/runtime.md](rules/runtime.md), `RT-NN`).

- **Safety canary** (`RT-03`). Every skill's first command is
  `lq-maintainer-safety-canary`; the hook always blocks it with a
  status line, and a run that does not see it stops. It catches an
  untrusted Codex plugin hook (skipped silently), disabled hooks, and
  `--dangerously-skip-permissions`, and names the fix.
- **Gated writes hand over where no prompt is guaranteed** (`RT-04`).
  The hook now reads the host and permission mode: `gh pr|issue
  comment` and `gh api` comment writes pass only in Claude Code's
  `default`/`acceptEdits`/`plan` modes. On Codex, and in Claude Code
  `auto`/`dontAsk`/`bypassPermissions`, they are blocked and the agent
  prints the command for you to run. **Behavior change for Claude Code
  users in `auto` mode.**
- **Hook hardening.** A Bash call with no readable command is now
  blocked (was allowed); an argv-shaped command is screened. The hook
  has its first direct test suite (258 checks, both payload shapes).
- **Explicit invocation on Codex** (`RT-05`): `agents/openai.yaml` with
  `allow_implicit_invocation: false` beside every skill.
- **Plugin root and data dir bind on Codex** (`RT-01`/`RT-02`), which
  substitutes neither into skill text nor model shells.
- **Read-only fan-out or none** (`RT-06`): a Codex custom agent for the
  Tier-2 review member (`agents/codex/`); batch triage on Codex takes
  the single-context path.
- **Codex manifests and command rules**: `.codex-plugin/plugin.json`,
  `.agents/plugins/marketplace.json`, and
  `settings/codex/lq-maintainer.rules` (execpolicy, the Codex
  counterpart of the deny list).
- **E-10 / I-11** now cover `AGENTS.override.md`, `.codex/**`,
  `.agents/**`.
- Decks spell next-step commands the host's way (`$lq-maintainer:…` on
  Codex).
- **After updating on Codex, re-trust the hook in `/hooks`** — every
  release that touches `hooks/` or the hook script re-arms Codex's
  review.

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
