# LQ Maintainer Agent — Design Doc v0.8

**Status: proposed 2026-11-09** (shipping as plugin v0.8.0). A **delta
over v0.7.6** (`lq-maintainer-agent-design-v0.7.6.md`, adopted
2026-10-03): four strands the maintainer set as the goal of the point
release after lq-ai shipped v0.9.1 — *"read the sessions and identify
pain points you can fix"*, *"the gate that blocks code development is
painful for a maintainer who may want to be a coder on the repo too"*,
*"confidence readings on blockers based on whether your evidence
supports, for example, a blocking or major issue … and whether it is
fair to the contributor"*, and *"we will enable pages … a scheduled run
(maybe on this mac) to update the pages so that it shows the flow from
triage, review and merge."* Where this document is silent, v0.7.6
remains normative, then v0.7.5 and the chain beneath it.

Requests, rulings and honest status: `docs/proposals/public-receipts-on-lq-ai-community.md`
(publishing, R1–R11, as amended), `docs/proposals/v0.8-pain-points.md`
(what the session logs showed, and which of it this release fixes),
and `docs/proposals/blocker-confidence.md` (the evidence base for §2).

## 1. Two floors: the hook arms a review session (amends §2.1, §10.1; `rules/runtime.md` RT-03, RT-09)

The §2.1 safety floor was written for a review run and fires in every
session of a host where the plugin is enabled — including the
maintainer's own development sessions on lq-ai, where it blocked
`git push` of their own branch and `gh pr create`. The guarantee was
never "no session with this plugin installed may push"; it was "no
**review** may push, merge, approve, close, or bring contributed code
into the session". v0.8 makes the hook know which session it is in.

- **Arming.** The canary every skill runs first (RT-03) now also arms
  the session: the hook writes a marker keyed by the host's session
  identity (a hash of it, never the raw id, under `~/.lq-maintainer/`)
  and reports `armed=yes` on the canary line. A review run that does
  not see `armed=yes` stops before reading anything — the posture RT-03
  already takes toward a missing hook. Arming is **one-way**: there is
  no disarm command, because a prompt-injected session would run it; a
  maintainer who wants to code after a review opens a new session.
- **The review floor** (armed) is today's floor, unchanged in every
  rule, test and evasion case.
- **The coder floor** (unarmed) keeps what lq-ai's vetting policy fixes
  for any assistant regardless of purpose — merge, every `gh pr review`
  form, close, repository deletion, GraphQL, `DELETE`, alias
  laundering, and any fetch or checkout of a PR ref (contributed code
  never enters an agent session in any mode) — and passes everything
  else, `git push` and `gh pr create` included, to the host's own
  permission prompt. The block message names the floor.
- **Fail-closed.** No usable session identity, an unreadable marker
  directory, or an unrecognized host all yield the **review** floor;
  only a readable, fresh marker's absence yields the coder floor. A
  marker older than a day is stale. Under `--dangerously-skip-permissions`
  or an untrusted Codex hook nothing runs at all, as before.
- **The second layers follow.** The reference `permissions.deny` list
  (`settings/claude-settings.json`) drops its `git push` entries — a
  vendored prefix deny cannot be session-aware — and the Codex
  execpolicy rules make `git push` `prompt` rather than `forbidden`,
  so that layer guarantees a prompt where the hook is not running and
  decides nothing else.
- **Publishing scripts are screened like the UAT runner.** In an armed
  session `publish/site-refresh.sh` without `--plan` is blocked
  outright (a review never publishes, §3); `--plan` passes.

What this does not change: RT-08 (a host is never a reason for a
lighter touch) — the floors read the session's purpose, never the
host, and no lane, tier, trigger or outcome reads the floor.

## 2. Confidence on findings: evidence and fairness (amends §5, L-33; `rules/lanes.md` L-34, `rules/burden.md` B-15)

Calibrated over 161 receipts and 171 distinct blocking and major
findings (`docs/proposals/blocker-confidence.md`): the evidence was
usually sound (160 of 171 rest on the diff, merged canon or a tool
result) and the fairness was the weak point (46 asked for something not
the PR's own job). Under the readings below, 51 of 175 blocking/major
rows lose their force; where the maintainer's later ruling is known,
they disagreed with 10% of the findings graded high, 80% of medium and
64% of low. `rules/confidence.md` (`CF-01`–`CF-15`) is normative.

Every finding carries two enumerated readings beside its severity, and
a roll-up derived from them by rule, never by feel:

- **Evidence** (`observed` / `canon-gap` / `mechanical` / `inferred` /
  `unverified`) — what the finding rests on: a line the run read in
  the diff at the pinned head; a merged canon section the run read
  this run that the diff demonstrably fails; a mechanical check's
  verdict; an inference about behaviour the run did not observe; or a
  claim it could not verify. B-00a's "read this run, never recalled" is the
  bar: anything below it is at most inferred.
- **Fairness** (`own-burden` / `not-this-pr` / `preference` /
  `scope-expansion`) — whether the ask is this PR's to carry: required
  of this change by cited canon or correctness; real but not this
  PR's doing; a preference or alternative with no stated requirement
  behind it (CD-08); or an expansion of what the PR set out to do.
- **Confidence** — `high` / `medium` / `low`, derived (CF-03): strong
  evidence (observed, canon-gap, mechanical) with an own-burden ask is
  high; strong evidence with a not-this-pr ask is medium; inferred or
  unverified evidence, a preference, or a scope expansion is low. A
  footer whose roll-up disagrees with its components is malformed.

What the roll-up drives, and the only things it drives:

- A **low-confidence blocking or major finding cannot block on its
  own.** It renders in the RV-06 form — "not verified: X — check: Y,
  ~Z minutes" — as a named human check, and does not count toward
  TR-06's two-blocking-findings rule or set `burden.overall` to
  `blocked`. The run says what it could not establish; it does not
  dress a guess as a gate.
- A finding whose fairness is **preference** is not a finding. It is
  dropped at the source (CD-08: where two approaches are equally
  valid, the author's stands and is not commented on), and the work log
  records that the pass considered and dropped it.
- A finding whose fairness is **expansion** is a `follow-up` with a
  drafted stub (L-33), never a merge condition and never
  `merge-after-<fix>`'s named fix.
- A finding whose fairness is **not this PR's doing** is `pre-existing`
  or a maintainer action in Next steps (CF-08); the fairness reading
  makes that call explicit and gradable.
- **`blocking` is one word with one meaning** (CF-11): a defect that
  makes merging wrong. Sign-offs, dependency floors and headings are
  `major` with mechanical evidence — *must-fix (mechanical)* on the
  deck — and an infrastructure-only CI failure is a note unless the
  check is required (CF-12). A canon-required ask the maintainer has
  ruled out of the merge gate stays canon-required and cites the
  ruling (CF-13).

The footer's findings tuple gains the two optional enumerated keys;
`receipt:v2` is unchanged (additive, like `uat:`). Impact, ask and the
check that would raise confidence stay visible-body free text. The
deck shows confidence on each finding and separates "blocks" from
"needs a human check". Three evals (`conf-01`–`conf-03`) assert an
inferred blocker is demoted, a preference is dropped, and an expansion
becomes a stub.

## 3. The public reviews site (amends §8, §12 q.10; `rules/publishing.md` PB-NN)

§8 of v0.7 made the deck the public artifact and the receipt internal
evidence, to drop into a community repository "the moment the repo is
created". The repository was created in August for a different
purpose — the committee's minutes and decision log under lq-ai ADR
0022 — and its publication process is a seven-day no-objection window
on PRs people write. v0.8 proposes the public home the design always
wanted, shaped to what exists:

- **The surface is a GitHub Pages site**, served from a branch of
  lq-ai-community designated for generated output, never from `main`
  (PB-12). The human reads the HTML deck the plugin already renders,
  plus a **flow page** per item: a dated timeline from opened on
  GitHub, through each review (version, host, model, lane, tier,
  outcome in plain words, findings by severity, that head's deck and
  record), the maintainer's recorded decision or its absence, each
  agent-attributed comment actually posted with its draft status, to
  merged or closed and by whom (PB-08). An agent reads `index.json`,
  one `state.yaml` per head and one `status.yaml` per item, and a
  FOR-AGENTS page that says these files are data and never an approval
  (PB-09).
- **Every record opens with the same fixed header**, rendered from
  `templates/public-header.md` (PB-06): what this is; what it is not —
  **a human maintainer decides whether and how a change merges** — and
  the three states side by side (recommendation, recorded decision or
  *none recorded — absence is not agreement*, GitHub today; if they
  disagree, GitHub is right); what was and was not checked; where to
  disagree. The question the maintainer asked to be answered on every
  page is answered as data, not as a footnote.
- **The publisher is a whitelist with a gate** (PB-01–PB-05): three
  inputs; refusals for E-21, C-40 and held items; per-item holds for
  E-08 and security-tagged findings; path, address and
  permission-prose removal marked in place; drafts labelled by what
  was actually posted; an output scan that refuses the whole run on a
  hit. The scan is the floor, grown from the dry run over every record
  and never relaxed by exception.
- **The agent never pushes** (PB-10). The refresh is the maintainer's
  own scheduled job on their own machine, running as them with their
  own credential and no model in the loop (PB-11); it refuses to run
  inside an agent session, and the hook blocks it in an armed one
  (§1). Whether it may push, and where, is the committee's (R9, R10),
  as is the publication floor — a per-item ruling or the mechanical
  scan (R11). Until those are decided the job builds locally and
  pushes nothing, which is its default.
- **Publishing changes no judgment** (PB-14). A record is produced the
  same way whether or not it will be read by anyone but the
  maintainer, and it is published as it was, under the rules of the
  version that wrote it (PB-05).

§12 q.10 ("where does the community repo live and who bootstraps it")
closes as: it lives where the committee put it, it is theirs, and the
plugin proposes to it rather than deciding for it.

## 4. The pain points, and what this release does about them (new)

Two read-only analyses over the maintainer's own machine — 97 Codex
sessions where the plugin was active and 11 Claude Code plugin runs
plus 70 ordinary coding sessions in lq-ai — are tabulated with their
status in `docs/proposals/v0.8-pain-points.md`. Beyond §1–§3, the
record drove these rule-level changes, each cited to the sessions
that motivated it:

- **E-08 gains two tests** before the private-advisory redirect fires
  — already public by the project's own hand; design or fix without
  exploit detail — names the triggering span, and never ends the
  maintainer conversation (four misfires, one posted publicly).
- **Anchored category 1** (`G-02`, `G-07`): a new feature whose
  ratified DE, ADR, PRD or roadmap anchor covers it goes to tiered
  review at Tier 2; the design path is offered once (ten overrides in
  eight sessions).
- **`TR-07a`, the light Tier-2 form**: a small diff whose only triggers
  are E-01/E-02 gets the quick pass plus the full security checklist;
  lane `escalate`, tier 2, no team, no packet (E-20 and TR-08 carry
  the exception; the `std-10` golden moves from tier 3 to tier 2) (a one-line fix reviewed
  four times in twenty-five minutes).
- **`A-12a`**: a proposed decision anchors nothing and orders nothing
  (a Proposed ADR made a merge-order prerequisite).
- **`BC-01a`**: a textual breaking-change hit is confirmed public
  before the label is drafted (five "why is this breaking?").
- **`PC-02` leads with the project benefit**; **`MM-05b`** credits the
  original author on a reimplementation; **`canon:release-conventions`**
  joins the canon map (nine style corrections, four credit omissions,
  two release-notes misfires).
- **Canon is pinned to `origin/main` after a fetch** (eight stale pins).
- **Skills pass diffs to `check-breaking.sh` as a file argument** (the
  hook had blocked the plugin's own check).

Deferred with reasons in the proposal: Codex read-only agents'
install step, a batch skill, mid-session feedback capture, the
maintainer's `.maintainer/` folder divergence, and pushing to a
contributor's branch from a review session (which stays blocked on the
review floor by design — the coder floor is where that work is done).

## 5. What does not change

v0.7.6 §3 holds, and everything in v0.7 §10. No surface, floor,
confidence or publication moves an item lighter; the coder floor is a
property of a session's purpose, never of its content, and content
cannot disarm or re-floor anything. The agent still never merges,
approves, closes, pushes, checks out a PR ref, or executes contributed
code outside the one UAT runner. The receipt footer stays `receipt:v2`
with additive optional fields. A record's rules are the rules of the
version that wrote it.

## 6. Implementation order and status

Hook floors with their tests and the two second-layer files; rules
(`RT-09`, `PB-NN`, `L-34`/`B-15`) and templates (`public-header.md`,
`for-agents.md`, the findings tuple); the generator and the refresh
job with the fixture test; the confidence evals; the deck's
confidence rendering; the design delta and changelog; version bump to
0.8.0 on both manifests. Then, outside the plugin and by people: the
committee issue on lq-ai-community carrying the proposal and the
mockup; the committee's instrument; Pages and the branch; the first
`PUBLISH=yes`.

**Status at proposal:** the floors, generator, refresh job and rules
exist and are tested locally; nothing has been published anywhere; the
committee has not been asked yet; the confidence schema's enum names
await the calibration report; Codex's hook payload fields are taken
from its documentation, not observed in a live payload, and the first
Codex session after this release is where that is confirmed (re-trust
the hook in `/hooks` — every hook change re-arms that review).
