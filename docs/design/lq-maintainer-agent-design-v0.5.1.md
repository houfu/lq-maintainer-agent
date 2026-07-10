# LQ Maintainer Agent — Design Doc

Status: Draft v0.5.1
Owner: LegalQuants maintainers
Date: 2026-07-10
Supersedes: v0.4 (which carried the full behavioral derivation; this
document is a fresh cut now that the home decision is made — behavior
is restated in condensed, normative form in §5–§9, and infrastructure
is specified in full in §3–§4 and §12)

**Changes in v0.5.1:** GitHub becomes the shared review state — the
Triage Receipt comment is canonical, carries a machine-readable footer,
and is updated in place; the local workspace demotes to a rebuildable
cache and the private-companion-repo question is dropped (§3.5, §8.4).
Partial receipts are legitimate and explicit (§8.4). A merge-commit
**audit trailer** convention gives every merged change an immutable,
`git log`-queryable triage record with zero new committed files (§8.5).
M0 gains the web-commit sign-off repo setting; M2 gains the footer,
update-in-place resume, and trailer drafting (§14).

---

## 1. What this is

**LQ Maintainer Agent** is a standalone open-source project that helps
maintainers of [`legalquants/lq-ai`](https://github.com/legalquants/lq-ai)
process inbound work — PRs, issues, and dependabot traffic — using
Claude Code. It triages every item into a recommended lane, reviews
within that lane against lq-ai's own canon, decomposes overreaching
contributions so their valuable parts survive (**salvage**), and
publishes an accountability artifact per item (**Triage Receipt**).

The agent recommends, drafts, and reports. A human decides, every time.
For external contributions this is lq-ai's written policy
(`docs/security/external-contribution-vetting.md`: automated assistants
"may review and report, but the merge button is a human maintainer's"),
and it does not relax with trust.

The problem being solved is **attention routing**: lq-ai's governing
canon (PRD, 21+ ADRs, Roadmap, the DE-XXX list, CLAUDE.md,
CONTRIBUTING, the skill-attestation process, the vetting playbook) has
outgrown what part-time community maintainers can hold in their heads.
The agent carries the canon so humans can spend their scarce attention
on the judgments only humans can make.

## 2. Why a separate project

Decided (2026-07): the agent lives in its own repository,
`legalquants/lq-maintainer-agent`, not inside `lq-ai`. Recorded
rationale, kept short:

- **Iteration speed.** This is experimental — few open-source projects
  run anything comparable. Inside lq-ai, every prompt tweak is a
  security-routed PR reviewed by exactly the people the agent exists to
  relieve. The agent needs its own review rules and its own cadence.
- **Its own momentum.** The agent has milestones, issues, and PRs of
  its own (§13); inside lq-ai those would pollute the product's board.
- **A home for the service.** The ongoing-service ambition (§12) means
  eventual infra — schedulers, tokens, isolation — that does not belong
  as a subdirectory of a legal-AI product.
- **A shareable artifact.** "We publish the agent that maintains our
  repo, rubric and all" is squarely on-brand for an organization whose
  thesis is open work product, and a contribution to an ecosystem where
  little comparable exists.

The two costs of separation, and their standing mitigations:

- **Canon drift** → a CI job resolves every canon citation against
  lq-ai nightly and on every rules change (§4.3).
- **Transparency** → the agent repo is public, and lq-ai's CONTRIBUTING
  carries one line: "PRs and issues here are triaged with the help of
  lq-maintainer-agent — you can read the exact rubric."

**The door to the main project stays open.** §11 defines the interface
contract and the upstreaming path: the pieces of this project that
stabilize into policy (receipt formats, the sandbox discipline, the
contributor PR template) migrate into lq-ai's canon, and if the agent
itself ever stops being experimental and starts being how the project
simply works, re-homing it is a `git mv`, not a redesign — the
rules/prompts separation (§3.2) guarantees that.

### 2.1 What ships into lq-ai regardless (M0)

Two safety artifacts protect *all* Claude Code sessions in the product
repo, agent or not, and belong there whichever home the agent has:

1. `.claude/settings.json` hooks hard-blocking `gh pr merge`,
   `gh pr review --approve`, `gh pr close`, `gh issue close`,
   `git push` (all remotes), `gh pr checkout` / PR-ref
   fetch-checkout patterns, `gh repo delete`, and force-push patterns.
2. A CODEOWNERS line security-routing `/.claude/` — command files and
   `allowed-tools` grants executing in maintainers' authenticated
   sessions are the same threat class as `.github/workflows/**`.

## 3. The agent project — repository infrastructure

### 3.1 Layout

```
lq-maintainer-agent/
├── .claude-plugin/
│   └── plugin.json               # Claude Code plugin manifest
├── skills/
│   ├── triage/
│   │   ├── SKILL.md              # /triage — batch + single, PRs & issues
│   │   └── references/           # pointers into rules/ and templates/
│   └── review-pr/
│       └── SKILL.md              # /review-pr — deep dive, multi-agent
├── rules/                        # DATA, not prose-in-prompt (§3.2)
│   ├── lanes.md                  # lane definitions + assignment rules
│   ├── anchoring.md              # the lane-relative anchor table
│   ├── escalation-triggers.md    # the mechanical trigger list
│   ├── salvage.md                # decomposition protocol + dispositions
│   ├── canon-map.md              # question → lq-ai doc routing table
│   └── injection-posture.md      # content-as-data rules
├── templates/
│   ├── receipt-pr.md
│   ├── receipt-issue.md
│   ├── triage-card.md
│   ├── digest.md
│   ├── committee-packet.md
│   └── contributor-responses/    # salvage reply patterns, by scenario
├── settings/
│   └── claude-settings.json      # mirror of the §2.1 block-list
├── evals/                        # the test suite for judgment (§4.2)
│   ├── fixtures/                 # corpus of past + synthetic items
│   └── golden/                   # expected lane / trigger / salvage calls
├── ci/
│   ├── canon-drift-check.yml     # §4.3
│   └── eval-run.yml              # §4.2
├── workspace/                    # gitignored local cache (§3.5)
└── docs/
    ├── design/                   # this document and its history
    ├── onboarding.md             # maintainer install + first session
    └── sandbox-discipline.md     # until upstreamed to lq-ai (§11)
```

### 3.2 Rules/prompts separation — the load-bearing decision

The `rules/` and `templates/` trees are **trigger-independent data**.
The skill prompts are thin: they orchestrate, and they load the rules.
This buys three things:

1. **The future service (§12) reuses the exact rule set** — only the
   invocation layer swaps.
2. **Rules changes are reviewable as policy diffs**, small and legible,
   rather than edits buried in a long prompt.
3. **Rules are testable** — the eval harness (§4.2) exercises
   `rules/` against fixtures; a rules PR that flips a golden lane
   assignment fails CI visibly.

### 3.3 Distribution — Claude Code plugin

Maintainers install the agent once as a Claude Code plugin (the repo
is added as a plugin marketplace source; `plugin.json` declares the
skills and the settings mirror). They then run `/triage` and
`/review-pr` **from inside their own lq-ai clone**, which is what gives
the agent local read access to the canon and to `main`.

- **Versioned releases**: tagged, with a changelog; maintainers update
  deliberately, not on every push. A receipt records the agent version
  that produced it (§8).
- **Skill invocation**: both skills are explicit-invocation-only. A
  review skill firing unprompted mid-conversation is surprising with no
  upside.
- **Settings mirror**: the plugin ships the §2.1 block-list so
  protection travels even into an unhardened clone; lq-ai's own copy
  (M0) covers non-plugin sessions.

### 3.4 Canon versioning at runtime vs. in CI

Two different needs, two mechanisms:

- **Runtime canon = the maintainer's clone.** The agent reads lq-ai
  docs and code from the clone it is running in, at that clone's
  `main`. Every card and receipt records **two SHAs**: the PR head SHA
  reviewed, and the canon SHA (the clone's `main` HEAD) it was judged
  against. That pair makes any triage decision reproducible and any
  dispute auditable ("the rule you were judged by, at the version you
  were judged against").
- **CI canon = a pinned lq-ai reference** in the agent repo (shallow
  fetch at a recorded SHA, advanced by a scheduled job), used by the
  drift check (§4.3) and the eval fixtures — so agent-repo CI is
  deterministic and doesn't break because lq-ai merged something an
  hour ago. The scheduled advance is itself a PR, so canon updates to
  the agent's world-model are visible and reviewed.

### 3.5 Shared state lives on GitHub; the workspace is a cache

**The canonical record of review state is the Triage Receipt comment on
the PR or issue itself** (§8.4), carrying a machine-readable footer
with the structured state. Continuity across maintainers, machines, and
sessions therefore comes from GitHub, not from any synced store: a
re-review — by anyone — starts by fetching the item's prior receipt via
`gh`, parsing the footer, and diffing from there. Half-finished reviews
are first-class: a receipt whose coverage statement says "not yet
covered: code-quality pass" is a resumable checkpoint, and the next
maintainer's `/triage` picks up exactly there.

`workspace/` (gitignored, local) demotes to a **rebuildable cache** of
deep-dive long-form reports (§9), keyed by
`<repo>/<pr-number>/<head-sha>/` — a convenience for fast re-runs,
never a source of truth, and rebuildable from the diff plus the
receipt footer. No private companion repo is needed.

The one category that must not live in a public comment — the full
receipt for a suspected-deliberate attack (§8.3) — routes to the
committee packet, so "where committee packets go" (§15 q.1) is also
where sensitive review state lives. One destination decision instead of
two.

### 3.6 The agent repo's own governance

Proportionate, not ceremonial: branch protection on `main`; one
maintainer review to merge, **two for `rules/`, `settings/`, or
`skills/` frontmatter** (the judgment-bearing and permission-bearing
surfaces); its own CODEOWNERS routing those paths; DCO, same as lq-ai.
The agent must never be easier to poison than the repo it guards.

## 4. CI for a judgment system

Conventional CI (lint, link-check) is trivial here. The interesting
infrastructure is testing *judgment*:

### 4.1 What "correct" means
A rules change is correct if it assigns the expected lane, fires the
expected escalation triggers, decomposes an overreaching item into the
expected parts, and never lets an adversarial fixture reach the fast
lane. Those expectations live in `evals/golden/`.

### 4.2 The eval harness
- **Fixtures**: a corpus of real past lq-ai PRs and issues (selected
  and, where needed, anonymized) plus **synthetic adversarial cases**:
  reviewer-directed instructions embedded in diffs and PR bodies;
  scope-creep camouflage (the docs-PR-with-a-code-hunk); typosquat
  dependency names; a PR-#134-shaped deployment blob for the salvage
  path; a vulnerability filed as a public issue.
- **Golden outcomes**: per fixture — lane + assigning rule, triggers
  fired, salvage part-list and dispositions, receipt profile fields
  that must appear (coverage statement, both SHAs, the human-only
  items rendered open).
- **Runs**: on every PR touching `rules/`, `templates/`, or `skills/`;
  nightly against the advanced canon pin. Graded by a checker script
  where mechanical (lane, triggers) and by a model-graded rubric where
  judgmental (salvage decomposition quality, contributor-response
  tone), with model-graded results reported as advisory rather than
  blocking until they prove stable.
- **Budget**: eval runs consume API tokens; the workflow caps fixtures
  per run and supports a labeled `full-eval` opt-in.

### 4.3 Canon-drift check
Resolves every citation in `rules/` and `templates/` — file paths, PRD
anchors, ADR numbers, CODEOWNERS patterns, DE-list location — against
the pinned lq-ai reference. Fails on dangling references. Runs on rules
PRs and on the scheduled canon-pin advance, so "lq-ai moved a doc"
surfaces as a failing, fixable PR in *this* repo rather than as a
silently wrong triage six weeks later.

## 5. Behavior: anchoring and lanes (normative summary)

Full derivation in the v0.4 design history; this section is the
operative spec.

**Anchoring is lane-relative.** Features/architectural changes anchor
to PRD / ADR / Roadmap / DE-XXX; bug fixes anchor to a linked issue or
a stated repro plus the regression test CONTRIBUTING requires;
dependency updates anchor to the upstream release/advisory; docs anchor
to the thing documented (above all, HONEST-STATE.md consistency);
skills anchor to the attestation path. Only an unanchored **decision**
(feature/structural with no canon anchor) is escalation material. An
unanchored bug fix is a standard-lane request for the repro, not a
committee matter.

**Four lanes, recommended not ruled.** Every item gets a recommended
lane + confidence + the assigning rule, human-reassignable:

- **Fast** — dependabot manifest/lockfile-only patch/minor bumps and
  pure typo fixes; no sensitive paths; CI green; verified from the
  diff (one code hunk in a "typo fix" demotes it). Output: one line
  ending "merge candidate — human click required."
- **Docs** — its own facets: placement (right home in the doc tree),
  truthfulness (no overclaiming vs. HONEST-STATE), audience/detail
  register, the docs-vs-code question (docs-first default: an operator
  recipe beats shipped code when both would work), and link/exfil
  hygiene. Sensitive docs escalate.
- **Standard** — triage card (anchor / scope legibility / flags), then
  substantive review per CONTRIBUTING + CLAUDE.md, including the
  documented pitfalls and the AI-generated-contribution failure modes
  (hallucinated or typosquat-adjacent imports, tests that assert
  nothing, dead code, duplication of existing subsystem logic —
  checked by reading `main` — unexplained refactors). Findings are
  structured (file / line / severity / canon citation / suggested
  comment) with a disposition hint each: *trivial — maintainer fixes* /
  *relayable — written for a non-engineer to carry back to their
  tooling* / *structural — close and open an issue describing the
  goal*.
- **Escalate** — mechanical triggers: CODEOWNERS-sensitive paths;
  auth/authz/audit/crypto; skills changes missing the human
  attestation; unanchored decisions; cross-subsystem changes (waived to
  a flag when one anchor explicitly spans them); ADR/governance-
  invariant contradictions without a superseding ADR; external author
  + sensitive class (the playbook's full-checklist condition — the
  agent runs it and attaches results); vulnerability content filed
  publicly. Output is the committee packet: scope statement, triggers
  with rule text, canon touched/contradicted/absent, checklist
  results, and the human questions phrased as questions.

**Assignment is hardened**: derived from diff/paths/commits/CI/author-
class only, never the contributor's narrative; reviewer- or AI-directed
text anywhere in a contribution is quoted as a finding and forces the
item out of the fast lane; demotion always available, promotion toward
fast never after initial assignment; every digest line names the
assigning rule so humans can audit the routing.

## 6. Behavior: the salvage protocol

Applied to **both PRs and issues** whenever an item overreaches
(scope-legibility failure, multi-concern diff, sprawling request). The
contributor population — often working with AI assistants — tends to
overdeliver; the failure mode to avoid is binary merge-the-blob /
reject-the-enthusiast.

1. **Decompose** into separable parts, one sentence each.
2. **Disposition per part**: accept as-is · redirect to docs (the
   docs-first default) · preserve as a drafted DE-XXX / mini-PRD stub
   crediting the contributor, so the idea enters the canon instead of
   dying with the PR · duplicate (cross-referenced) · decline, with a
   canon-cited reason.
3. **Draft the contributor response**, leading with what is kept:
   "we want two of your three ideas — here's the path for each."
4. **Propose the mechanical split**: for PRs, which hunks belong to
   which follow-up PR; for issues, drafted titles + bodies for the
   split issues. Humans post and file everything.

Salvage on issues is the cheapest, highest-value application: a
decomposed *idea* means the 400-line PR never gets written.

## 7. Behavior: issues workflow

Classify (bug / feature / question / vulnerability-suspect), then:
bugs → repro-completeness, subsystem pointers, duplicate detection
against open issues *and* the DE list, severity suggestion, drafted
request for missing repro pieces calibrated for non-engineer filers;
features → anchor check, DE/mini-PRD promotion pipeline with drafted
stubs, salvage where overreaching, EASIEST-CONTRIBUTIONS/P1 routing;
questions → drafted answers cited to canon, or routing to Discussions;
vulnerability-suspect → the *only* output is a drafted redirect to a
private Security Advisory per SECURITY.md — the agent never elaborates
exploit detail in any output. Batch mode adds a stale sweep with
drafted status-check or close-with-pointer comments.

## 8. Behavior: Triage Receipts

Every triaged item gets a published accountability artifact — the
checklist rendered, in the spirit of the product's own Receipts. Posted
via the permission-gated write flow (a human approves each post). Two
profiles:

- **PR profile**: recommended lane + confidence + rule; anchor
  determination with citations; the security-vetting checklist rendered
  pass/fail/n-a for the classes that applied; findings with disposition
  hints; salvage decomposition if applied; **coverage statement** (what
  was checked and what explicitly was not — runtime behavior is never
  checked: the agent does not execute contributed code); **reviewed-at
  PR head SHA + canon SHA + agent version**; and the two human-only
  judgments rendered permanently open — contributor trust, residual
  supply-chain hygiene. Template-mandatory; can never render as
  resolved.
- **Issue profile**: classification + rule; duplicate search performed
  (what was searched, what matched); repro assessment for bugs; salvage
  decomposition with the drafted split; coverage statement; human-only
  items — is this worth roadmap space, and contributor-engagement tone.

**Carve-outs** (the playbook's own caution): suspected-deliberate
attacks get a generic public "escalated for security review" with the
full receipt going only to the committee packet — do not teach an
attacker to hide better. Vulnerability-suspect issues get **no** public
receipt — only the drafted private-advisory redirect.

### 8.4 The receipt is the shared review state

Three mechanical requirements make the receipt the team's working
record (§3.5):

- **Machine-readable footer.** Every receipt ends with an HTML comment
  block — invisible in rendered markdown — carrying the structured
  state: lane + assigning rule, triggers fired, PR head SHA, canon SHA,
  agent version, findings with dispositions, and the coverage checklist
  with per-item status. This is what a later session parses to resume.
- **Update in place.** The agent locates its own prior receipt comment
  and edits it rather than posting a new one — still a permission-gated
  write, one approval per update. A PR carries exactly one living
  receipt no matter how many sessions touched it, which also caps the
  comment-noise concern (§15 q.4).
- **Partial receipts are legitimate and explicit.** A maintainer who
  runs out of time posts the receipt with an honest coverage statement
  — "covered: vetting checklist, anchor; not yet: code-quality, test
  adequacy" — which is HONEST-STATE.md applied to reviews. Half-baked
  is fine; *silent* half-baked is not.

Receipt comments are editable, so this is a working record, not a
tamper-proof log. Reproducibility comes from the pinned SHAs and agent
version (re-run agent vX against head Y and canon Z); permanence comes
from §8.5.

### 8.5 The merge-commit audit trailer (the permanent skeleton)

For every merge, the fast-lane and standard-lane outputs include a
**drafted squash-merge message** ending in a trailer block — the same
mechanism as `Signed-off-by`, zero new files:

```
Triage: standard lane; receipt at <comment-url>
Reviewed-At: pr-head <sha> / canon <sha> / agent <version>
Disposition: 3 findings resolved; human-only items reviewed by <maintainer>
Signed-off-by: <maintainer>
```

The human performs the merge and owns the message; the agent only
drafts it (and drafting the full message, sign-off line included, also
smooths the GitHub-web-UI merge path, where adding trailers by hand is
irritating). Properties this buys:

- **Immutable once merged** — unlike the comment — and it travels with
  the code forever.
- **Queryable** — "every merge this quarter with its triage
  disposition" is a `git log --grep` one-liner, not a document anyone
  maintains. This is the product's own auditability pitch
  (`audit_log`, "compliance evidence is one query") applied to the
  project's supply chain.
- **Deletion-proof skeleton** — if a receipt comment is ever edited or
  removed, the trailer preserves the minimal facts independently.

**The line held against doc-overwhelm:** no committed receipt files, no
ledger document, no per-merge markdown — the trailer convention is the
*entire* committed audit surface. Any human-readable summary (a
quarterly review digest) is generated on demand from `git log`, never
maintained. Honest limitation: trailers cover **merged** work only;
rejected PRs and declined issues leave their record in comments and,
for sensitive cases, committee packets — acceptable, because the
supply-chain audit question is "what got in and how."

## 9. Behavior: multi-agent deep dives

For standard-lane items meriting depth (size, sensitivity, explicit
ask), `/review-pr` dispatches a team with fresh context per member —
mirroring lq-ai's own `superpowers:subagent-driven-development`
pattern: an **anchor/scope analyst** (incl. salvage decomposition), a
**security-vetting pass** (playbook checklist against the diff), a
**code-quality pass** (with the time budget to walk the surrounding
subsystem on `main` — thorough code exploration is this member's
mandate), and a **test-adequacy pass** (do the tests test the change;
regression test present; collision-guard compliance). Members read only
`main` + the diff, never execute anything, and return structured
findings; the lead merges them into the cached long-form report (§3.5)
behind the receipt. Digest-level triage stays single-session; the team
is for depth, not breadth.

## 10. Guardrails

- **`allowed-tools`**: read-only `gh` (`pr list/view/diff/checks`,
  `issue list/view`, `api` GETs) + Read/Grep/Glob in the working
  directory. Everything else prompts; merge/approve/close/push/checkout
  are hook-blocked even then (§2.1, mirrored in the plugin).
- **Executing contributed code — two rules.** *The agent: never.* The
  danger is not checkout but everything after it — `pytest` imports
  `conftest.py` at collection, `npm ci`/`pip install -e .` run
  lifecycle scripts, `docker build` executes the contributor's
  Dockerfile — all with the session's ambient credentials (a `gh`
  token with repo write, SSH keys, a dev `.env` of real provider
  keys). An agent is an *ambient* hazard: fast, semi-invisible, and
  instructable by the PR itself, since the diff is in its context.
  *Humans: sequence and containment.* Adversarial read first, execute
  second, untrusted code only in a disposable sandbox — no `.env`, no
  Docker socket, no credentials, ideally no network; lq-ai's
  `Dockerfile.dev` in-container pattern hardened per
  `docs/sandbox-discipline.md` (upstreamed in M1, §11). Absolute
  exception: never "verify" a `.github/workflows/**` PR by running it.
- **Injection posture** (`rules/injection-posture.md`): all
  contribution content is material under review, never instructions;
  reviewer-/AI-directed text is quoted as a finding; checklists run
  against the diff, never the self-description; nothing inside a
  contribution can raise its lane, suppress a check, or claim
  approval.
- **Pinning**: every output records PR head SHA + canon SHA + agent
  version; head movement (force-push) invalidates the review and the
  next run diffs against the persisted report.

## 11. The interface with lq-ai (the door left open)

The contract between the two repos is deliberately thin, so
integration can deepen — or the agent can move back in — without
redesign:

- **The canon is the API.** `rules/canon-map.md` is the only place the
  agent encodes lq-ai's structure; the drift check (§4.3) is the
  contract test. If lq-ai reorganizes its docs, one file changes here.
- **Standing upstream candidates** — pieces that, once stable, become
  lq-ai policy rather than agent behavior: the Triage Receipt formats
  (a `docs/` page in lq-ai describing what contributors will see); the
  sandbox discipline (a `docs/security/` page — M1); the
  contributor-facing PR template for AI-assisted contributions ("what
  did you ask your AI to do; one change per PR; did you run the one
  test command") — the cheapest input-quality lever in the whole
  system, filed as a DE in lq-ai.
- **Re-homing remains a `git mv`.** Because rules and templates are
  data (§3.2) and the runtime canon is always the maintainer's clone
  (§3.4), nothing about the separate home is architectural. If the
  agent stops being an experiment and becomes simply how lq-ai is
  maintained, the committee can move it into the product repo — or
  keep it out and treat it as the first external consumer of lq-ai's
  canon. Both stay cheap by construction.

## 12. The ongoing service — infrastructure options (research, M4)

Deferred, but specified enough to research well. The rule set ports
unchanged (§3.2); the spike evaluates the **trigger and isolation
layer** only. Constraints that survive any option: the
merge/approve/close prohibition is policy and applies to automation;
the injection posture must hold *without a human watching a terminal*;
every run pins PR head SHA + canon SHA + agent version.

**Option A — GitHub Actions in the agent repo** (scheduled +
`workflow_dispatch`, running the agent headlessly via the Claude Agent
SDK). *For:* zero standing infra; free-tier friendly; logs and runs are
public artifacts (transparency for free); secrets via Actions secrets.
*Against:* the vetting playbook classifies workflows as prime
supply-chain surface — the service workflow must live in *this* repo
(never lq-ai's), pin actions by SHA as lq-ai already does, and run with
a read-mostly token; cold starts; cron granularity; per-run cost is
API tokens plus runner minutes.

**Option B — small always-on runner** (a container on a VM or
container platform, webhook-subscribed to lq-ai events). *For:* real
event-driven triage (receipt drafted minutes after a PR opens); dedup
and state natural; concurrency control. *Against:* standing cost and a
standing attack surface (a public webhook endpoint); secrets management
moves to the operator; contradicts the original zero-hosting posture —
which is why this is a milestone decision, not a default.

**Option C — GitHub App + queue** (the App receives events, enqueues,
a worker drains). *For:* the right auth model regardless of A/B — a
GitHub App with **fine-grained, least-privilege permissions**:
contents read, PRs/issues read + *comment* write, checks write,
nothing else; short-lived installation tokens instead of a maintainer
PAT; the App identity makes agent-authored drafts visibly
agent-authored. *Against:* the most moving parts; overkill until volume
justifies it.

**Likely landing zone** (to be confirmed by the spike): Option A for
the scheduled digest + draft receipts as **check runs or clearly-marked
draft comments**, authenticated as a least-privilege GitHub App
(Option C's auth model without its queue), with Option B revisited only
if event latency starts to matter. **Cost controls** in any variant:
per-run token budget with hard stop; dedup by head SHA; concurrency
cap of one run per item; a monthly spend ceiling that pauses the
schedule rather than degrading judgment.

## 13. Typical workflows

**The 30-minute community-maintainer session:** `/triage` from inside
the lq-ai clone → digest (fast-lane one-liners with assigning rules;
standard cards; committee packets; issue classifications). Clear the
fast lane — every merge is a human click. One standard item →
`/review-pr N` → accept/edit/drop findings → approve the posting of
the receipt and chosen comments (permission prompt per write). Forward
packets. Done.

**Salvage session:** an overreaching PR or issue lands → decomposition,
per-part dispositions, drafted contributor response arrive with the
card → maintainer edits tone, approves the post, files the drafted DE
stub in lq-ai.

**Rules maintenance:** a maintainer disagrees with a lane call → opens
a PR against `rules/` in *this* repo → eval harness shows exactly which
golden outcomes the change flips → two-review merge → next release.
Judgment disagreements become reviewable diffs.

## 14. Milestones

Each shippable and immediately usable on the live queue — lq-ai already
has PRs waiting, and momentum is a design requirement.

**M0 — Bootstrap + safety floor.**
Create `lq-maintainer-agent` with the §3.1 skeleton, plugin manifest,
branch protection, CODEOWNERS, canon pin + drift check. Ship §2.1 into
lq-ai (hooks + CODEOWNERS line). Add the CONTRIBUTING transparency line
to lq-ai, and enable lq-ai's **"require contributors to sign off on
web-based commits"** repo setting so DCO stops failing on web-UI edits
and suggestion commits. *Exit: plugin installs; no Claude Code session
in either repo can merge, approve, close, push, or check out a PR
ref.*

**M1 — Manual triage core.**
`/triage pr N` + `/review-pr N`: triage card, lane-relative anchoring,
four-lane recommendation with confidence, salvage v1, in-chat output.
First eval fixtures (five real items + the adversarial set) with golden
lanes wired into CI. Upstream `sandbox-discipline.md` to lq-ai
`docs/security/`. *Exit: every open lq-ai PR has a card, produced the
day this lands.*

**M2 — Breadth.**
Batch digest across PRs and issues; docs lane; full issues workflow
including DE-promotion drafts and the stale sweep; receipt templates
with the machine-readable footer, human-pasted (the footer works fine
in a pasted comment — resume-from-receipt lands before publication is
automated); merge-message drafting with the §8.5 trailer. Eval corpus
grows with each real triage that a maintainer corrects (corrections
become fixtures). *Exit: the 30-minute session works end to end on
real backlog, and a second maintainer can resume a first maintainer's
partial review from the receipt alone.*

**M3 — Depth + publication.**
Multi-agent deep-dive team with cached long-form reports; receipts
posted and **updated in place** via the permission-gated flow;
contributor-response library refined against real salvage cases.
*Exit: every non-fast-lane PR carries one living published receipt;
force-push re-reviews diff against the prior footer state.*

**M4 — Service spike (research only).**
Evaluate §12 options A–C against real M1–M3 volume and cost data.
Deliverable: a go/no-go decision doc with the chosen trigger layer,
token scoping, and injection-posture-without-a-human plan. *Exit: a
committee decision, not a deployment.*

## 15. Open questions

1. **Committee mechanics** — where packets go (Discussion category /
   label + board / Slack). Governance call; the agent drafts either
   way. Note this destination now also carries all sensitive review
   state (§3.5), so it should be access-controlled.
2. **Author-trust classes** — the definition of "known contributor"
   for the external-author trigger (org membership? N merged PRs? an
   allowlist in lq-ai `docs/security/`?). Security-team call.
3. **Soft trailer check** — a lq-ai CI job that *warns* (never blocks)
   when a merge commit lacks the §8.5 trailer. Soft only: hard-gating
   merges on agent output would invert the human-decides principle.
   Worth the noise?
4. **Receipt placement** — PR comment vs. check-run summary. Update-
   in-place (§8.4) caps the noise at one comment per item, so try
   comments in M2/M3 and revisit only if that still grates.
5. **Dependabot fast-lane line** — do advisory-driven majors qualify?
   Security-team call.
6. **Eval grading** — when (if ever) model-graded rubric results
   (salvage quality, response tone) graduate from advisory to
   CI-blocking.
7. **Multi-agent cost budget** — the per-PR token ceiling before the
   M3 team requires explicit maintainer opt-in.
8. **Digest scale** — pagination / `--since` threshold. Defer until it
   hurts.
