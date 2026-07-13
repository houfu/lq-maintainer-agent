# LQ Maintainer Agent — Design Doc

Status: Draft v0.6
Owner: LegalQuants maintainers
Date: 2026-07-11
Supersedes: v0.5.1
Evidence base: `docs/research/prd-research-report.md` (2026-07, twelve
research dimensions, sources inline there). Statements marked
*(research 2026-07)* were adopted from that review in maintainer
session on 2026-07-11 and are revisitable on evidence.

**Changes in v0.6** — decisions taken in maintainer review:

1. The fast lane becomes **deterministic-first** (§5.1): mechanical
   checks decide merge-candidacy; the LLM anchors and flags anomalies.
2. The safety floor stays **hook-first** (§2.1); known hook-bypass
   limits are documented honestly (§10.1) and the M0 exit criterion is
   reworded to what hooks actually enforce (§14).
3. Every receipt carries an **attribution line** naming the agent
   version and the posting maintainer (§8).
4. Human-gate instrumentation (override-rate telemetry, canaries) is
   **out of agent scope**; recorded as an lq-ai upstream candidate
   (§11).
5. Newly in scope: an **AI-slop disposition and non-human-author
   policy** (§6.1); a **contributor contest/hold path** with a
   published bot-behavior page (§7.1); a **receipt-update notification
   convention** and versioned footer schema (§8.4).
6. Positioning: **lq-ai-first, portable by design** (§2.2).
7. Salvage step 4 ships as an **explicitly-unverified advisory** with
   mechanical sanity checks (§6).
8. Five of v0.5.1's §15 open questions are **adopted with provenance**
   (§15 preamble).
9. The **served model ID** becomes the fourth pinned field in every
   receipt and trailer (§3.4, §8).
10. The deep-dive pipeline gains a **finding-filter stage and severity
    cap** before anything reaches the receipt (§9).
11. M4 gains explicit **go/no-go criteria**; public run transcripts
    are treated as an exfiltration channel, not free transparency
    (§12).
12. Plugin-mechanics corrections (§3.3) and injection-posture
    hardening (§10) per research.

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

**The honest value claim** *(research 2026-07)*: because every public
output is human-gated, this design cannot deliver the headline win of
autonomous triage bots (first response in minutes instead of days).
What it delivers is **routing quality per maintainer-minute** — a
30-minute session that clears more of the queue, more defensibly, with
a published rubric. Speed arrives, if ever, with M4.

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
- **Transparency** → the agent repo is public, lq-ai's CONTRIBUTING
  carries one line ("PRs and issues here are triaged with the help of
  lq-maintainer-agent — you can read the exact rubric"), **and every
  receipt names the agent per-artifact** (§8) — repo-level disclosure
  alone is the pattern that has triggered contributor backlash
  elsewhere *(research 2026-07)*.

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
   **Coverage note** *(research 2026-07)*: naive string patterns miss
   `gh api`/GraphQL write mutations; the block-list is therefore
   structured as an **allow-list of read-only `gh` subcommands** with
   `gh api` non-GET methods denied by default, rather than a deny-list
   of known-bad strings.
2. A CODEOWNERS line security-routing `/.claude/` — command files and
   `allowed-tools` grants executing in maintainers' authenticated
   sessions are the same threat class as `.github/workflows/**`.

Hooks are the chosen primary enforcement layer (maintainer decision,
2026-07 — over the alternative of requiring GitHub-side rulesets).
Their known limits are stated plainly in §10.1; the residual risk is
accepted because bypassing them requires the agent to *actively evade*,
which is itself detectable behavior in a human-supervised session.

### 2.2 Positioning: lq-ai-first, portable by design

The project is built for lq-ai, with rules that are concrete and
canon-specific — no premature generic engine. Portability is preserved
by one discipline, not a feature: **all lq-ai-specific knowledge lives
in `rules/canon-map.md`**; no other rule, template, or skill hardcodes
an lq-ai path, doc name, or policy location. Another project adopting
the agent replaces one file (and the templates' prose). The canon-drift
check (§4.3) doubles as the lint for this rule: a citation that
resolves against lq-ai but is written outside canon-map is a review
finding.

## 3. The agent project — repository infrastructure

### 3.1 Layout

```
lq-maintainer-agent/
├── .claude-plugin/
│   └── plugin.json               # Claude Code plugin manifest
├── hooks/
│   └── hooks.json                # §2.1 block-list as plugin PreToolUse
│                                 #   hooks (see §3.3 — a plugin's
│                                 #   bundled settings.json cannot carry
│                                 #   permission rules)
├── skills/
│   ├── triage/
│   │   ├── SKILL.md              # /lq-maintainer:triage — batch +
│   │   │                         #   single, PRs & issues
│   │   ├── scripts/              # deterministic fast-lane checks
│   │   │                         #   (§5.1): semver parse, OSV batch
│   │   │                         #   lookup, registry release-age
│   │   └── references/           # pointers into rules/ and templates/
│   └── review-pr/
│       └── SKILL.md              # /lq-maintainer:review-pr — deep
│                                 #   dive, multi-agent
├── rules/                        # DATA, not prose-in-prompt (§3.2)
│   ├── lanes.md                  # lane definitions + assignment rules
│   │                             #   incl. the §5.1 deterministic gate
│   ├── anchoring.md              # the lane-relative anchor table
│   ├── escalation-triggers.md    # the mechanical trigger list
│   ├── salvage.md                # decomposition protocol + dispositions
│   │                             #   incl. the slop disposition (§6.1)
│   ├── canon-map.md              # question → lq-ai doc routing table
│   │                             #   (the ONLY lq-ai-specific file, §2.2)
│   ├── injection-posture.md      # content-as-data rules (§10)
│   └── stale-sweep.md            # §7 guardrails for the stale sweep
├── templates/
│   ├── receipt-pr.md
│   ├── receipt-issue.md
│   ├── triage-card.md
│   ├── digest.md
│   ├── committee-packet.md
│   └── contributor-responses/    # salvage reply patterns, by scenario
├── settings/
│   └── claude-settings.json      # reference copy of the §2.1 block
│                                 #   for lq-ai's own .claude/ (M0);
│                                 #   NOT auto-applied by the plugin
├── evals/                        # the test suite for judgment (§4.2)
│   ├── fixtures/                 # corpus of past + synthetic items
│   └── golden/                   # expected lane / trigger / salvage calls
├── ci/
│   ├── canon-drift-check.yml     # §4.3
│   └── eval-run.yml              # §4.2
└── docs/
    ├── design/                   # this document and its history
    ├── research/                 # the 2026-07 research report
    ├── onboarding.md             # maintainer install + first session
    ├── bot-behavior.md           # contributor-facing: what the agent
    │                             #   does, contest/hold path (§7.1)
    └── sandbox-discipline.md     # until upstreamed to lq-ai (§11)
```

The deep-dive cache (formerly `workspace/`) moves **out of the
repository tree entirely** *(research 2026-07)*: installed plugins are
copied into a version-keyed ephemeral cache and must not hold state.
The cache lives under `${CLAUDE_PLUGIN_DATA}` (persistent across plugin
updates), keyed by `<repo>/<pr-number>/<head-sha>/`, and remains what
§3.5 says it is — a rebuildable convenience, never a source of truth.

### 3.2 Rules/prompts separation — the load-bearing decision

The `rules/` and `templates/` trees are **trigger-independent data**.
The skill prompts are thin: they orchestrate, and they load the rules.
This buys three things:

1. **The future service (§12) reuses the exact rule set** — only the
   invocation layer swaps. (Validated: the official claude-code-action
   installs plugins in CI and runs namespaced skills headlessly —
   *research 2026-07*.)
2. **Rules changes are reviewable as policy diffs**, small and legible,
   rather than edits buried in a long prompt.
3. **Rules are testable** — the eval harness (§4.2) exercises
   `rules/` against fixtures; a rules PR that flips a golden lane
   assignment fails CI visibly.

### 3.3 Distribution — Claude Code plugin

Maintainers install the agent once as a Claude Code plugin (the repo
is added as a plugin marketplace source; `plugin.json` declares the
skills and hooks). They then run `/lq-maintainer:triage` and
`/lq-maintainer:review-pr` **from inside their own lq-ai clone**, which
is what gives the agent local read access to the canon and to `main`.
(Skill invocation is namespaced by the plugin name — docs and
onboarding must not promise a bare `/triage`.)

Mechanics corrected against the platform *(research 2026-07)*:

- **The block-list ships as plugin hooks** (`hooks/hooks.json`,
  PreToolUse): a plugin's bundled `settings.json` cannot inject
  permission rules. The `settings/` directory holds the reference copy
  that M0 vendors into lq-ai's own `.claude/` for non-plugin sessions.
- **`allowed-tools` grants, it does not restrict.** The frontmatter
  allow-list makes read-only `gh` promptless; the permission-gated
  posting flow works *because write commands are omitted* and therefore
  prompt. Nothing that writes to GitHub may ever be added to the
  allow-list — one "always allow" would silently delete the human gate.
  (Anthropic's own code-review plugin allowlists `gh pr comment:*`; a
  naive copy of its frontmatter would break this design's
  accountability model.)
- **Explicit invocation is enforced**, not requested:
  `disable-model-invocation: true` on both skills. A review skill
  firing unprompted mid-conversation is surprising with no upside.
- **Paths**: skills reference rules and templates via
  `${CLAUDE_PLUGIN_ROOT}` — the working directory at runtime is the
  lq-ai clone, not the plugin.
- **Context lifecycle**: long batch `/triage` sessions can outlive the
  context window, and compaction keeps only a few thousand tokens per
  invoked skill. Batch mode therefore forks a subagent per item (or
  re-reads the governing rule file before each lane call) so late-batch
  decisions are never made from summarized memory.
- **Versioned releases**: tagged, with a changelog; `version` in
  plugin.json bumps every release; third-party marketplaces do not
  auto-update by default, so maintainers update deliberately. A receipt
  records the agent version that produced it (§8).

### 3.4 Canon versioning at runtime vs. in CI

Two different needs, two mechanisms:

- **Runtime canon = the maintainer's clone.** The agent reads lq-ai
  docs and code from the clone it is running in, at that clone's
  `main`. Every card and receipt records **four pinned fields**: the
  PR head SHA reviewed, the canon SHA (the clone's `main` HEAD) it was
  judged against, the agent version, and — new in v0.6 *(research
  2026-07)* — the **served model ID** for the session (models
  auto-switch on subscription plans; a triage record that doesn't say
  which model judged it is not reproducible even in principle). That
  tuple makes any triage decision reproducible and any dispute
  auditable ("the rule you were judged by, at the version you were
  judged against").
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

The deep-dive cache (`${CLAUDE_PLUGIN_DATA}`, §3.1) is a **rebuildable
cache** of long-form reports (§9) — a convenience for fast re-runs,
never a source of truth, and rebuildable from the diff plus the receipt
footer. No private companion repo is needed.

The one category that must not live in a public comment — the full
receipt for a suspected-deliberate attack (§8.3) — routes to the
committee packet, so "where committee packets go" (§15 q.1) is also
where sensitive review state lives. One destination decision instead of
two.

### 3.6 The agent repo's own governance

Proportionate, not ceremonial: branch protection on `main`; one
maintainer review to merge, **two for `rules/`, `hooks/`, `settings/`,
or `skills/` frontmatter** (the judgment-bearing and permission-bearing
surfaces); its own CODEOWNERS routing those paths; DCO, same as lq-ai.
The agent must never be easier to poison than the repo it guards.
The agent repo's own workflows follow the same supply-chain hygiene it
audits for: actions pinned by SHA, Scorecard/zizmor in CI *(research
2026-07)*.

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
  path; a vulnerability filed as a public issue; and — new in v0.6
  *(research 2026-07)* — an invisible-Unicode payload, a CLAUDE.md-in-
  the-diff case, and a tool-config-file case (§10.2). Fixtures also
  include **negative cases** — a trivial PR that MUST fast-lane, an
  item where escalation must NOT fire — because a one-sided suite
  drifts the rules toward escalate-everything, which quietly destroys
  the tool's value.
- **Golden outcomes**: per fixture — lane + assigning rule, triggers
  fired, salvage part-list and dispositions (as **acceptance sets**,
  not single answers — trained humans disagree on ~11% of tangled
  lines), receipt profile fields that must appear (coverage statement,
  the four pinned fields, the human-only items rendered open). Each
  golden outcome records the **canon SHA it was adjudicated under**;
  the scheduled canon-pin advance re-flags fixtures whose correct
  answer may have changed.
- **Runs**: on every PR touching `rules/`, `templates/`, or `skills/`;
  nightly against the advanced canon pin. **Grading** *(research
  2026-07)*: temperature 0 is not deterministic, so security-relevant
  invariants (never-fast-lane on adversarial fixtures) are graded
  **pass^k** — k trials, fail on any failure — while ordinary lane
  assignments grade by threshold. Mechanical outcomes (lane, triggers)
  are checker-script graded; judgmental outcomes (salvage decomposition
  quality, contributor-response tone) are model-graded and **advisory
  until the judge itself is validated**: binary rubric,
  chain-of-thought before verdict, a judge model distinct from the
  triage model, TPR/TNR measured against maintainer labels (this is
  the graduation bar — §15 preamble, former q.6). CI reports a
  per-lane confusion matrix; the fast-lane false-positive cell is the
  safety number.
- **Budget**: eval runs consume API tokens; the workflow caps fixtures
  per run and supports a labeled `full-eval` opt-in. Growth targets:
  ~20–50 fixtures by M2, 100+ by M3, fed by the corrections flywheel
  (every real triage a maintainer corrects becomes a fixture).

### 4.3 Canon-drift check
Resolves every citation in `rules/` and `templates/` — file paths, PRD
anchors, ADR numbers, CODEOWNERS patterns, DE-list location — against
the pinned lq-ai reference. Fails on dangling references, and on canon
citations written outside `canon-map.md` (§2.2). Runs on rules PRs and
on the scheduled canon-pin advance, so "lq-ai moved a doc" surfaces as
a failing, fixable PR in *this* repo rather than as a silently wrong
triage six weeks later.

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

- **Fast** — items passing the deterministic gate of §5.1 (dependency
  bumps) or verified pure typo fixes; output: one line ending "merge
  candidate — human click required."
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
  publicly; **agent-instruction or tool-config files in the diff**
  (§10.2). Output is the committee packet: scope statement, triggers
  with rule text, canon touched/contradicted/absent, checklist
  results, and the human questions phrased as questions.

**Assignment is hardened**: derived from diff/paths/commits/CI/author-
class only, never the contributor's narrative; reviewer- or AI-directed
text anywhere in a contribution is quoted as a finding and forces the
item out of the fast lane; demotion always available, promotion toward
fast never after initial assignment; every digest line names the
assigning rule so humans can audit the routing. **Author-class is
determined via the GitHub API** (App identity, org membership), never
from display names, branch names, or the item's own text.

### 5.1 The fast lane is deterministic-first *(research 2026-07)*

Decided 2026-07: the fast lane does not ask an LLM to re-derive a
judgment the dependency ecosystem makes deterministically — and the
controls with the strongest real-world evidence (release-age cooldown,
malicious-package lookup) have no LLM equivalent at all. A dependency
bump is a merge candidate **iff every check passes**:

1. Author verified as the dependabot/renovate **GitHub App identity**
   via API author-class — not display name, not branch name.
2. Diff touches only manifest/lockfile paths.
3. Semver delta parses as patch or minor on a ≥1.0.0 dependency
   (deterministic parse, not model judgment).
4. **No new package names** anywhere in the diff, including lockfile
   transitive churn — this single rule covers the typosquat and
   event-stream-style threat better than name-similarity judgment,
   because typosquats arrive as *added* names, not bumps.
5. Every changed name+version pair clears an **OSV batch lookup**
   (MAL-/CVE advisories; unauthenticated API, compatible with the
   read-only posture).
6. **Release-age cooldown**: the registry publish timestamp is ≥7 days
   old. Malicious releases are typically pulled within 24–72 hours;
   this is the control that stopped nothing in the 2025 axios incident
   because nobody ran it.
7. CI green.

Checks 3–6 are scripted lookups (`skills/triage/scripts/`), rendered
pass/fail in the receipt. The LLM's residual role in this lane:
verify "pure typo fix" claims, anchor the bump to a real upstream
release (§5 anchoring), and flag anomalies the checks can't see.

Two hard rules ride along:

- **Advisory-driven majors never fast-lane** *(adopted, former §15
  q.5)*. They route standard-lane with an "expedite" flag, and the
  advisory claim is verified against GHSA/OSV — never the PR body:
  "urgent security fix" framing is itself a lane-promotion
  social-engineering vector.
- **The receipt discloses what was not checked**: package *contents*
  are never inspected — the lockfile diff shows name+version+hash, and
  the ecosystem's worst compromises were invisible at that layer. This
  rides the coverage statement (§8) and keeps the human-only
  supply-chain-hygiene judgment honest.

### 5.2 The maintainer-burden verdict *(new)*

Full spec in `rules/burden.md` (`B-NN`); this is the operative summary.

Lanes route; they do not answer the question a part-time maintainer most
needs: **what will accepting this cost me?** The burden verdict answers
it, as an **additive** roll-up of signals the other rules already
produce — it introduces no new judgment about the code, and (like lanes,
`L-01`) it recommends, never rules.

**Burden is a PR verdict.** Its five axes grade a code diff, which an issue
does not have — so an issue carries **no five-axis burden block**. But an
issue gets its own deck and its own verdict-first headline: a categorical
**triage recommendation** (§8.6a, `rules/issues.md` `IV-NN`) — one of
`needs-info` / `decompose` / `proceed` / `escalate` — over a **rule-grounded
preview of the PR the issue would become**, not a graded roll-up. What *does*
carry across to issues is the conduct standard (§8) and the Next-steps idea
(`B-14`): every drafted issue reply is CoC-bound and names the maintainer's
follow-ups.

**Grounded in lq-ai canon, not generic standards** (`B-00`). Every axis
and blocker grades against the maintained project's own canon, routed by
`rules/canon-map.md` and cited by `canon:<key>`: what counts as "in
scope" is what `canon:prd`/`canon:roadmap`/`canon:de-list`/`canon:adr`
say; "adequately tested" is what `canon:contributing` requires (down to
its regression-test-for-bug-fixes rule); "clean" is `canon:claude-md`'s
conventions and documented pitfalls; "sensitive/risky" is
`canon:vetting-playbook` + `canon:codeowners`. Where the governing canon
is **absent**, that absence is surfaced (an unanchored decision escalates,
`E-04`) and burden grades conservatively — never by an improvised
standard. The canon must be **read this run** — in the clone Step 0
verified, at the pinned SHA, never recalled (`B-00a`, the §3.3 batch
discipline); a run outside the clone grades conservatively and says the
canon was unavailable, rather than grading from memory.

**Safety / risk is the priority axis** (`B-13`). Worst-of already gives a
high Safety axis the overall verdict; on top of that it is never trimmed
for budget, its canon (`canon:vetting-playbook`, `canon:codeowners`) is
read every run, and it **fails closed hardest** — an unresolvable
supply-chain question (a check that could not run against a concrete
version) is `medium` at least, never `low`, and the data-harm taxonomy
that sharpens it leads the `B-12` build order.

**Two layers.** *Layer 1* is a set of binary **blockers** — CI not green
(`F-07`), a known-vulnerable dependency (`F-05`), a
deliberate-attack/agent-config trigger (§10.2), a vulnerability-suspect
issue, a blocking-severity data-harm finding, missing DCO/CLA sign-off,
or an incompatible license. Any one ⇒ the verdict is **`blocked`**
("resolve first"), and **no burden level shows until it clears** —
"can't merge yet" is kept distinct from "costs you work". *Layer 2* is a
**burden** graded `low`/`medium`/`high` across five axes:

- **Scope** — anchored and single-concern (`low`) → unanchored or
  overreaching (`high`); reads anchoring (`A-NN`) and salvage.
- **Review effort** — small/one subsystem → large/many subsystems or a
  bundled refactor (`L-32`).
- **Tests** — covered, or no runtime behaviour to test (`low`) →
  untested new behaviour or assert-nothing tests (`high`).
- **Carry cost** — clean, no new surface → adds dependencies/surface you
  maintain forever, or duplicative (`L-32`).
- **Safety / risk** — the residual-risk axis for what does **not** rise
  to a blocker: an unpinned/widened dependency range, a borderline-fresh
  release, a sensitive surface. A confirmed vulnerability is a blocker,
  not this axis.

**Roll-up is worst-of** — overall burden is the highest single axis; one
serious axis is not diluted by four calm ones. Burden **inherits the
fail-closed posture** (§5.1): where a signal can't be computed, the axis
grades up, not down.

**It leads the reading deck** (§8.6): the deck headlines the overall
burden (`Blocked` / `Low` / `Medium` / `High`) with the five axes as
glance tiles, and the lane becomes a supporting detail — but the receipt
still cites lane + assigning rule; burden is added, not substituted. The
state rides the receipt footer as an **enumerated-only** block (§8.4):
`overall`, `blockers[]` (slugs), and the five axis levels — never free
text (the driver phrasing is derived at render time from the glossary).

**It says what to check next** (`B-14`). Grading is not enough; the human
needs the follow-ups only they can do. Every receipt and deck carry a
**Next steps** list — one concrete action per firing blocker, graded
axis, and coverage gap, each with its reason: *read the dependency's
changelog for breaking changes* (a major bump), *smoke-test the affected
feature* (runtime never checked), *request the regression test
`canon:contributing` requires* (an untested bug fix), *decide pin /
narrow / lockfile* (an unpinned range). Next steps are free text (visible
body and deck, never the footer); where one is a request to the
contributor it is drafted courteously (§8 conduct) and posted only by the
human.

**Honest about its gaps** *(`B-12`)*: the `missing-dco`,
`incompatible-license`, and data-harm-taxonomy signals are **not yet
computed**. Until they land, Layer 1 runs on the live signals and the
deferred blockers appear as open human-only checks — never silently
passed. This is the §2 legal-compliance and data-harm coverage gap made
visible in the verdict rather than papered over.

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
   canon-cited reason · **decline as spam/slop** (§6.1).
3. **Draft the contributor response**, leading with what is kept:
   "we want two of your three ideas — here's the path for each."
   The default offer for any split is **maintainer-performed**:
   handing a novice contributor unverified rework is a documented way
   contributions die *(research 2026-07)*.
4. **Propose the mechanical split — as an explicitly-unverified
   advisory** *(research 2026-07: concern detection is strong; hunk
   assignment tops out near 70% and nothing verifies a split
   compiles)*. For PRs: which hunks belong to which follow-up PR,
   with (a) a mandatory receipt line — "proposed split not verified to
   compile or pass tests" — (b) mechanical sanity checks that *do*
   block: the partition covers the whole diff, and a defined-here/
   used-there cross-reference finds no symbol split across parts;
   (c) degradation to **file-level proposals** above a size threshold.
   For issues: drafted titles + bodies for the split issues, filed as
   GitHub **sub-issues** of the original. Humans post and file
   everything.

Salvage on issues is the cheapest, highest-value application: a
decomposed *idea* means the 400-line PR never gets written.

### 6.1 The slop disposition and non-human authors *(new in v0.6)*

The crisis that motivated peer projects (flooded bug bounties,
low-effort AI-generated PRs) needs a disposition of its own, applied
conservatively:

- **Only obvious slop is flagged**: fabricated APIs or citations,
  tests asserting nothing, text that answers a different repo's
  question, boilerplate detached from the diff. Anything arguable
  routes standard-lane like every other item — a false slop accusation
  costs more community goodwill than ten slow reviews.
- The disposition drafts a **close-with-pointer response** (canon-cited
  contribution guide, the PR template), never an insult; the human
  posts it or doesn't.
- **Author-class gains a non-human dimension**: "external contributor"
  and "autonomous AI agent" are different classes. Contributions that
  self-identify as agent-authored (or are verifiable as such) are not
  auto-declined — lq-ai's policy on them is a governance call (§15
  q.2) — but they never fast-lane and their anchor requirements are
  never waived.

## 7. Behavior: issues workflow

Classify (bug / feature / question / vulnerability-suspect /
spam-suspect §6.1), then: bugs → repro-completeness, subsystem
pointers, an **agent-performed cross-reference against open issues, open
PRs, the DE list, *and* the roadmap** — sorted into duplicate / adjacent
/ contradicting / linked buckets, never the filer's self-attested "I
searched" claim (§10, injection posture; a ticked prerequisite box is a
claim, not the check), and feeding the deck's linked References section
(§8.6a). The same agent-performed, four-bucket grounding is carried on
**PR** receipts too (their References section), so both surfaces are
grounded. Then: severity suggestion, drafted request for missing repro
pieces calibrated for non-engineer filers; features → anchor check,
DE/mini-PRD promotion pipeline with drafted stubs, salvage where
overreaching, EASIEST-CONTRIBUTIONS/P1 routing; questions → drafted
answers cited to canon, or routing to Discussions;
vulnerability-suspect → the *only* output is a drafted redirect to a
private Security Advisory per SECURITY.md — the agent never elaborates
exploit detail in any output.

Batch mode adds a **stale sweep** with drafted status-check or
close-with-pointer comments, governed by `rules/stale-sweep.md`
*(research 2026-07 — the guardrails that keep stale-bots from becoming
community lore)*: never stale an item that is awaiting a *maintainer*
response; reactions and subscriptions count as interest; a
frozen/exempt marker is honored unconditionally; and a drafted close
must cite evidence of resolution — "stale" is not "resolved."

### 7.1 The contributor's side: contest and hold *(new in v0.6)*

The PRD previously designed only the maintainer's side. Two additions:

- **A published bot-behavior page** (`docs/bot-behavior.md`, linked
  from every receipt's attribution line): what the agent does, what it
  cannot do (merge/approve/close), what the lanes mean, and how the
  receipt footer works.
- **A contest/hold path**: a contributor who disagrees with a lane
  call or wants their item handled human-only says so in a comment
  (or uses a documented marker). The agent's next pass over that item
  quotes the request in the receipt, marks the item held, and drafts
  nothing further for it except at explicit maintainer request. The
  request routes to a human, not to the agent's own judgment — the
  agent never adjudicates objections to itself.

## 8. Behavior: Triage Receipts

Every triaged item gets a published accountability artifact — the
checklist rendered, in the spirit of the product's own Receipts. Posted
via the permission-gated write flow (a human approves each post).

**Attribution, per artifact** *(decided 2026-07)*: every receipt ends
with a visible line — "Drafted by lq-maintainer-agent vX; reviewed and
posted by @maintainer" — linking to `docs/bot-behavior.md`. Until M4
receipts post from maintainers' own accounts, and per-artifact honesty
is what keeps that from reading as ghost-writing. This also aligns with
the emerging `Assisted-by:` trailer convention (§8.5).

**Conduct — the receipt is bound by the project's own Code of Conduct**
*(new; `rules/conduct.md`, `CD-NN`)*. Every receipt and drafted response
meets `canon:code-of-conduct` (lq-ai follows the Contributor Covenant):
be kind, assume good faith, focus on the work, disagree substantively
rather than personally. Concretely — critique the change, never the
contributor (`CD-02`, extending L-02's diff-not-narrative rule to the
*voice* of the output); assume good faith even for flawed or AI-assisted
work, salvaging what is usable rather than disparaging it (`CD-03`);
acknowledge genuine effort specifically (`CD-04`); calibrate the register
to the reader (`CD-05`). This binds the agent's **own** conduct only — it
never adjudicates a human's (the agent scores changes, never people, L-02;
CoC enforcement against participants routes to a maintainer). Respectful
tone is a property of every output, never scored or traded off against
burden or time (`CD-07`).

Two profiles:

- **PR profile**: recommended lane + confidence + rule; anchor
  determination with citations; the security-vetting checklist rendered
  pass/fail/n-a for the classes that applied (including the §5.1
  deterministic checks for dependency items); findings with disposition
  hints; salvage decomposition if applied; **coverage statement** (what
  was checked and what explicitly was not — runtime behavior is never
  checked: the agent does not execute contributed code; package
  contents are never inspected, §5.1); **the four pinned fields —
  PR head SHA, canon SHA, agent version, served model ID**; and the
  two human-only judgments rendered permanently open — contributor
  trust, residual supply-chain hygiene. Template-mandatory; can never
  render as resolved.
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

Four mechanical requirements make the receipt the team's working
record (§3.5):

- **Machine-readable footer — structured fields only** *(hardened
  2026-07)*. Every receipt ends with an HTML comment block — invisible
  in rendered markdown — carrying the structured state. The schema is
  **versioned** (`<!-- lq-maintainer-agent:receipt:v1 ... -->`) so a
  format change never breaks receipt lookup, and it is restricted to
  **enumerated fields**: lane enum, assigning rule id, triggers fired
  (ids), the four pinned fields, finding ids with disposition enums,
  and the coverage checklist with per-item status. **Never free-text
  quoted contributor content** — an HTML comment is exactly the
  concealment channel injection attacks use, and a quoted payload
  re-parsed by a later session re-enters at elevated trust. Quoted
  findings live in the visible receipt body, where humans see them.
- **Trust the footer only after verifying its author.** Before
  resuming from a prior receipt, the agent confirms the comment's
  author is the expected identity (the maintainer of record pre-M4;
  the App identity after). Footer-shaped text from anyone else — or
  anywhere inside a code block or blockquote — is inert data (§10.2).
- **Update in place, and say so.** The agent locates its own prior
  receipt comment and edits it rather than posting a new one — still a
  permission-gated write, one approval per update. A PR carries exactly
  one living receipt no matter how many sessions touched it. Because
  **edited comments notify nobody on GitHub** *(research 2026-07)*,
  each in-place update is paired with a drafted one-line reply —
  "receipt updated: <what changed>" — approved and posted through the
  same gated flow, so watching co-maintainers actually learn the state
  moved.
- **Partial receipts are legitimate and explicit.** A maintainer who
  runs out of time posts the receipt with an honest coverage statement
  — "covered: vetting checklist, anchor; not yet: code-quality, test
  adequacy" — which is HONEST-STATE.md applied to reviews. Half-baked
  is fine; *silent* half-baked is not.

Receipt comments are editable, so this is a working record, not a
tamper-proof log. Reproducibility comes from the pinned fields (re-run
agent vX against head Y and canon Z); permanence comes from §8.5.

### 8.5 The merge-commit audit trailer (the permanent skeleton)

For every merge, the fast-lane and standard-lane outputs include a
**drafted squash-merge message** ending in a trailer block — the same
mechanism as `Signed-off-by`, zero new files:

```
Triage: standard lane; receipt at <comment-url>
Reviewed-At: pr-head <sha> / canon <sha> / agent <version> / model <id>
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

*(Adopted, former §15 q.3 — research 2026-07)*: a **warn-only** lq-ai
CI job that flags merge commits lacking the trailer is worth the noise
— it maps onto accepted DCO warn-check practice — and is filed as an
upstream candidate (§11). Warn-only stays absolute: hard-gating merges
on agent output would invert the human-decides principle.

**The line held against doc-overwhelm:** no committed receipt files, no
ledger document, no per-merge markdown — the trailer convention is the
*entire* committed audit surface. Any human-readable summary (a
quarterly review digest) is generated on demand from `git log`, never
maintained. Honest limitation: trailers cover **merged** work only;
rejected PRs and declined issues leave their record in comments and,
for sensitive cases, committee packets — acceptable, because the
supply-chain audit question is "what got in and how."

### 8.6 The reading deck — the discussion surface, then the receipt *(new)*

The receipt is built for auditability: dense pass/fail tables, rule IDs,
the machine-readable footer. That is correct for the record and for a
technical reviewer, but it reads as noise to a non-engineer maintainer
deciding a merge. The **reading deck** is a plain-language,
verdict-first HTML rendering of the triage — a private local *view*, not
a new published artifact.

**Ordering: deck first, receipt after** *(decided)*. The deck is the
**discussion surface**, not a post-hoc render of a finished receipt. The
flow is: the agent computes the triage facts → renders the deck (burden
verdict, the five axes, the coverage gaps, and the **Next steps** the
reviewer must check, §5.2 `B-14`) → **discusses it with the maintainer**,
who reacts, reassigns a lane if warranted (`L-01`), accepts or relays
findings, and records what they will do or ask → **then** the agent
finalises the **receipt** to reflect that conversation: the decisions
taken, the next steps agreed, and who owns each. The receipt is the
settled record of a review that happened, not a verdict handed down
before one. It still carries everything §8 mandates (pinned fields,
coverage, human-only judgments, footer), and is drafted under the §8
conduct rules; posting stays human-gated (§10, Step 10). The deck renders
from the same computed facts throughout, so the two never disagree.

- **It is a private, local view — never a published artifact.** The
  markdown receipt remains the thing posted to GitHub (§8); the deck is
  written to the `${CLAUDE_PLUGIN_DATA}` cache (§3.5), gitignored, out of
  the repo tree. It is not the M4 publication surface and is never posted
  by the agent. Hosting it (e.g. a maintainer's own GitHub Pages) is a
  human choice left open, not a plugin behaviour.
- **Deterministic render, not freehand.** A stdlib script
  (`skills/triage/scripts/render-deck.sh`) parses the receipt's
  enumerated footer and renders self-contained HTML — inline CSS, native
  `<details>`, **no JavaScript, no network**. The model does not write
  bespoke HTML per run: this keeps the deck and receipt from disagreeing
  and keeps untrusted contributor text out of executable markup. All
  contributor-derived spans (title, findings) are normalised
  (§10.2, I-10), stripped of invisible/bidi/tag characters (visibly
  flagged if any were present), then HTML-escaped — shown as data, never
  interpreted.
- **It leads with burden (§5.2)** and preserves every honesty
  constraint: the four pinned fields, the "never checked by design"
  coverage, and the permanently-open human-only judgments all render and
  can never read as resolved. Plain-language captions live in a reviewable
  `templates/deck/glossary.md` — normative content (a wrong gloss
  misrepresents a security decision), edited under the same bar as
  `rules/`.

The **burden block** rides the §8.4 footer as enumerated fields only
(`overall`, `blockers[]`, the five axis levels); the deck's driver
phrasing is derived at render time from the glossary, never stored in the
footer.

### 8.6a The issue reading deck *(new)*

Issues get a deck too — but not the burden deck. The five burden axes grade a
diff an issue does not have (§5.2), and the maintainer's need for an issue is
different: not "what will accepting this code cost me?" but **"is this ready to
act on, and what would the PR it becomes run into?"** So the issue deck answers
three questions, and grades nothing.

- **A verdict-first recommendation.** The headline is one enumerated state,
  derived from signals the issue rules already produce (`rules/issues.md`
  `IV-01`) — it introduces no new judgment, exactly as burden is additive over
  lanes:
  - **`escalate`** — an escalation trigger fired (unanchored decision `E-04`,
    sensitive path `E-01`, etc.): take it to the committee/meeting, don't decide
    it alone.
  - **`needs-info`** — a bug whose repro is absent/partial, or a feature whose
    anchor is unverified: it cannot be acted on until the reporter fills the
    gap. The drafted repro/clarification request is the next step.
  - **`decompose`** — the ask sprawls across concerns (salvage applies): split
    it into sub-issues first (§6, `S-13`) so the 400-line PR never gets written.
  - **`proceed`** — clear, grounded, single-concern: ready for a contributor to
    pick up.

  Precedence is worst-first — `escalate` > `needs-info` > `decompose` >
  `proceed` — and co-occurring conditions still appear in the obstacle list
  below regardless of which won the headline.

- **A rule-grounded preview of the PR this issue would become**, as a *list, not
  a grade* (`IV-02`). Each predicted obstacle names the rule or canon fact that
  *would fire* if the issue were submitted as-is: "unanchored decision → would
  escalate (`E-04`)"; "billing is a `canon:prd` non-goal → would be declined
  (`S-DECLINE`)"; "duplicate of #187 (`S-DUP`)"; "four concerns → would need
  decomposition." This deliberately avoids grading a diff that does not exist:
  the obstacles are facts about what *the agent's own rules* would do, not
  speculation about unwritten code. There is no worst-of level and no axis tile.

- **A References section** (`IV-03`) grounding the item in the project: the
  duplicate-search result (open issues + the DE list, `C-60`) extended to
  **related open PRs and roadmap entries** the ask maps to. Every reference and
  every canon citation in the obstacle list renders as a **click-through link** a
  maintainer or contributor can follow — canon docs pinned to the canon SHA,
  issues/PRs by number — built from `canon:repo`'s web base per
  `rules/canon-map.md`. Links are **agent-constructed from validated sources
  only** (the canon-map base + a canon path, or an API-verified item number); a
  URL lifted from contributor text is never emitted as a link. In the posted
  **receipt** these are ordinary markdown links (clickable in the GitHub
  comment); in the **deck** the deterministic renderer emits the anchors — so the
  grounding travels with both surfaces.

- **Sub-issue recommendation** (`IV-04`): when the state is `decompose`, the
  deck carries the drafted split (titles, one line each) that will be filed as
  sub-issues (`S-13`) — humans file everything.

Everything else is inherited from the PR deck unchanged: it is a **private local
view, never a published artifact**; it is a **deterministic render** from the
receipt's enumerated footer (the sole new field is `recommendation`; obstacles
and references are visible-body free text, never the footer — §8.4 injection
discipline); the coverage statement (runtime behaviour — the agent never runs
repro steps — never checked), the permanently-open human-only judgments
(roadmap-worth, engagement-tone), the pinned fields, and the conduct-bound
drafting all render and can never read as resolved. **A vulnerability-suspect
issue gets no deck at all** — the same absolute carve-out as its receipt (§8.3,
`rules/issues.md` C-40): the only output is the private-advisory redirect.

## 9. Behavior: multi-agent deep dives

For standard-lane items meriting depth (size, sensitivity, explicit
ask), `/lq-maintainer:review-pr` dispatches a team with fresh context
per member — mirroring lq-ai's own
`superpowers:subagent-driven-development` pattern: an **anchor/scope
analyst** (incl. salvage decomposition), a **security-vetting pass**
(playbook checklist against the diff), a **code-quality pass** (with
the time budget to walk the surrounding subsystem on `main` — thorough
code exploration is this member's mandate), and a **test-adequacy
pass** (do the tests test the change; regression test present;
collision-guard compliance). Members read only `main` + the diff, never
execute anything, and return structured findings. (Platform note:
plugin-shipped agents cannot carry their own hooks or permission modes
— the members' read-only posture is enforced via their `tools`
frontmatter.)

**Between the members and the receipt sits a filter stage** *(decided
2026-07; the field's #1 complaint about AI review is noise)*: the lead
deduplicates findings, drops any finding that cannot cite the specific
diff lines it is about (the evidence check), applies a confidence
threshold, and renders at most a capped number of findings in the
receipt — the tail collapses to one summary line. Nothing is hidden:
the full unfiltered set lives in the cached long-form report (§3.5)
behind the receipt, and the receipt says how many findings were
filtered and where they are.

**Budget** *(adopted, former §15 q.7 — research 2026-07)*: deep dives
are opt-in above a per-PR ceiling in the $1–5 band (market rate for
deep review; managed multi-agent products run $15–25). The skill
estimates before dispatching and asks when the estimate exceeds the
ceiling. Digest-level triage stays single-session; the team is for
depth, not breadth.

## 10. Guardrails

- **`allowed-tools`**: read-only `gh` (`pr list/view/diff/checks`,
  `issue list/view`, `api` GETs) + Read/Grep/Glob in the working
  directory + the §5.1 check scripts (unauthenticated GETs/POSTs to
  the OSV and registry endpoints only). Everything else prompts;
  merge/approve/close/push/checkout are hook-blocked even then (§2.1,
  shipped as plugin hooks §3.3). Write commands are never added to the
  allow-list (§3.3).
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
- **Injection posture** (`rules/injection-posture.md`, hardened §10.2):
  all contribution content is material under review, never
  instructions; reviewer-/AI-directed text is quoted as a finding;
  checklists run against the diff, never the self-description; nothing
  inside a contribution can raise its lane, suppress a check, or claim
  approval. The load-bearing defense is the **permission
  architecture** — human-gated writes and the read-only tool surface —
  not prompt vigilance; published residual attack-success rates on
  even hardened agents justify assuming the prompt layer alone fails.
- **Pinning**: every output records the four pinned fields (§3.4);
  head movement (force-push) invalidates the review and the next run
  diffs against the persisted report.

### 10.1 What the hooks do and do not guarantee *(honesty note)*

The hook block-list is the chosen primary enforcement layer (§2.1).
Known limits, stated so nobody believes a stronger claim than the
mechanism supports: hooks can be bypassed by settings/hook-file
self-modification, by write operations phrased as `gh api`/GraphQL
mutations (mitigated by the allow-list structure, §2.1), by
environment-variable prefixing tricks, and hooks do not run at all
under `--dangerously-skip-permissions`. Accordingly: **onboarding.md
forbids running triage sessions with permission checks disabled**; the
hook and settings files are CODEOWNERS-routed (§3.6); and the M0 exit
criterion claims "blocked at the hook layer," not "impossible" (§14).
Server-side enforcement (branch protection, rulesets) remains available
to lq-ai's admins as an independent layer, but this project does not
require it.

### 10.2 Injection hardening *(new in v0.6, research 2026-07)*

Three rules added to `rules/injection-posture.md`, each with an eval
fixture proving it runs (§4.2):

1. **Normalize before judging.** All untrusted spans — PR bodies,
   diffs, commit messages, comments, *filenames*, and prior receipt
   footers — are normalized first: NFKC, strip/flag the Unicode Tags
   block, zero-width characters, and bidi overrides. Without this,
   "quote the injection as a finding" fails silently on payloads the
   model can read but the human reviewer cannot see.
2. **Agent-instruction and tool-config files in a diff are data and an
   escalation trigger, never inputs.** CLAUDE.md, AGENTS.md,
   `.claude/**`, copilot-instructions, and executable tool configs
   (linter configs, `conftest.py`) added or modified by a contribution
   are the highest-success documented injection vector; the agent
   flags them (§5 escalation) and never loads them.
3. **Command-shaped and footer-shaped text inside code blocks or
   blockquotes is inert** — the pre-LLM triage-bot norm, adopted
   wholesale. Combined with footer author verification (§8.4), this
   closes the receipt itself as a re-injection channel.

## 11. The interface with lq-ai (the door left open)

The contract between the two repos is deliberately thin, so
integration can deepen — or the agent can move back in — without
redesign:

- **The canon is the API.** `rules/canon-map.md` is the only place the
  agent encodes lq-ai's structure (§2.2); the drift check (§4.3) is the
  contract test. If lq-ai reorganizes its docs, one file changes here.
- **Standing upstream candidates** — pieces that, once stable, become
  lq-ai policy rather than agent behavior:
  - the Triage Receipt formats (a `docs/` page in lq-ai describing
    what contributors will see);
  - the sandbox discipline (a `docs/security/` page — M1);
  - the contributor-facing PR template for AI-assisted contributions
    ("what did you ask your AI to do; one change per PR; did you run
    the one test command") — the cheapest input-quality lever in the
    whole system, filed as a DE in lq-ai;
  - *(new)* the **warn-only trailer check** (§8.5);
  - *(new)* **dependency-update hardening in lq-ai itself**: a
    `dependabot.yml` cooldown and a dependency-review/OSV required
    check, so the fast lane's "CI green" carries the malware screen
    natively;
  - *(new, maintainer decision 2026-07)* **human-gate instrumentation**
    — override-rate and decision-latency measurement, and any
    canary regime — belongs to lq-ai's own review culture and
    governance, not to this agent. The receipt/trailer formats leave
    room for such fields, but defining and reading them is an lq-ai
    improvement to be proposed there.
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
every run pins the four §3.4 fields.

**Option A — GitHub Actions in the agent repo** (scheduled +
`workflow_dispatch`, running the agent headlessly via the Claude Agent
SDK). *For:* zero standing infra; free-tier friendly; secrets via
Actions secrets. *Against:* the vetting playbook classifies workflows
as prime supply-chain surface — the service workflow must live in
*this* repo (never lq-ai's — fork-PR secrets semantics make that
structural, not just policy), pin actions by SHA as lq-ai already
does, and run with a read-mostly token; cold starts; cron granularity;
per-run cost is API tokens plus runner minutes.

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

**Option D — managed scheduled agents** (Claude Code Routines or
equivalent) *(added 2026-07)*: evaluated for completeness and likely
rejected for publication runs — they execute under a maintainer's
*personal* identity, which contradicts visibly-agent-authored receipts.
Possibly acceptable for read-only digest generation.

**Likely landing zone** (to be confirmed by the spike): evaluate the
official claude-code-action **before anything bespoke** — it installs
plugins in CI and runs namespaced skills headlessly, so it exercises
§3.2's port-unchanged claim directly. Then Option A for the scheduled
digest + draft receipts as **clearly-marked draft comments**,
authenticated as a least-privilege GitHub App (Option C's auth model
without its queue), with Option B revisited only if event latency
starts to matter.

**Go/no-go criteria for the spike** *(hardened 2026-07)* — M4 is a
no-go unless the decision doc covers, concretely:

1. **Injection posture without a human**: per-post approval is the
   load-bearing defense in M1–M3 and has no headless equivalent; the
   spike must specify its replacement (a classifier layer over drafted
   output, an egress allowlist, a zero-secrets runner design) or
   conclude no-go.
2. **Publication surface**: receipts are the public artifact; **raw
   run transcripts are suppressed** — public logs are an exfiltration
   channel (demonstrated against a comparable first-party triage
   workflow), not free transparency.
3. **Operational hygiene**: the runner never loads the lq-ai
   checkout's own `.claude/`/CLAUDE.md (settings-source restriction);
   bot/actor filtering so the agent never ingests its own or
   dependabot's comments; per-author and per-PR run caps against
   cost-DoS; a keepalive for cron (scheduled workflows silently
   disable on inactive repos); federated identity over a static API
   key where available.

**Cost controls** in any variant: per-run token budget with hard stop;
dedup by head SHA; concurrency cap of one run per item; a monthly
spend ceiling that pauses the schedule rather than degrading judgment.

## 13. Typical workflows

**The 30-minute community-maintainer session:**
`/lq-maintainer:triage` from inside the lq-ai clone → digest
(fast-lane one-liners with assigning rules and deterministic-check
results; standard cards; committee packets; issue classifications).
Clear the fast lane — every merge is a human click. One standard item →
`/lq-maintainer:review-pr N` → accept/edit/drop findings → approve the
posting of the receipt and chosen comments (permission prompt per
write). Forward packets. Done.

**Salvage session:** an overreaching PR or issue lands → decomposition,
per-part dispositions, drafted contributor response arrive with the
card → maintainer edits tone, approves the post, files the drafted DE
stub in lq-ai.

**Contest handling:** a contributor objects to a lane call or asks for
human-only handling (§7.1) → the item is marked held, the objection is
quoted in the receipt, and a human answers it.

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
and suggestion commits. **Spike test**: a marketplace install of the
plugin into a scratch clone, verifying the hooks actually fire and the
namespaced skills resolve. *Exit: plugin installs; merge, approve,
close, push, and PR-ref checkout are blocked at the hook layer in both
repos (documented limits per §10.1); the spike test passes.*

**M1 — Manual triage core.**
`/lq-maintainer:triage pr N` + `/lq-maintainer:review-pr N`: triage
card, lane-relative anchoring, four-lane recommendation with
confidence, the §5.1 deterministic check scripts, salvage v1 (steps
1–3; step-4 advisory with sanity checks), in-chat output. First eval
fixtures (five real items + the adversarial set including the §10.2
cases, plus negative fixtures) with golden lanes wired into CI.
Upstream `sandbox-discipline.md` to lq-ai `docs/security/`. *Exit:
every open lq-ai PR has a card, produced the day this lands.*

**M2 — Breadth.**
Batch digest across PRs and issues; docs lane; full issues workflow
including DE-promotion drafts, the guarded stale sweep, the slop
disposition, and the contest/hold path with `docs/bot-behavior.md`
published; receipt templates with the versioned machine-readable
footer, human-pasted (the footer works fine in a pasted comment —
resume-from-receipt lands before publication is automated);
merge-message drafting with the §8.5 trailer including the model
field; the §5.2 burden block in the footer and the §8.6 reading deck
rendered from it (burden computed from the live signals; the deferred
`missing-dco`/`incompatible-license`/data-harm signals of `B-12`
surface as open human-only checks until §15 resolves them). Eval corpus
grows with each real triage that a maintainer corrects (corrections
become fixtures). *Exit: the 30-minute session
works end to end on real backlog, and a second maintainer can resume a
first maintainer's partial review from the receipt alone.*

**M3 — Depth + publication.**
Multi-agent deep-dive team with the §9 filter stage and cached
long-form reports; receipts posted and **updated in place** (with the
update-ping convention) via the permission-gated flow;
contributor-response library refined against real salvage cases.
*Exit: every non-fast-lane PR carries one living published receipt;
force-push re-reviews diff against the prior footer state.*

**M4 — Service spike (research only).**
Evaluate §12 options A–D against real M1–M3 volume and cost data,
gated on the §12 go/no-go criteria. Deliverable: a go/no-go decision
doc with the chosen trigger layer, token scoping, and
injection-posture-without-a-human plan. *Exit: a committee decision,
not a deployment.*

## 15. Open questions

**Adopted from v0.5.1 with provenance** *(research 2026-07; maintainer
decision to fold into normative text, revisit on evidence)*: former
q.3 (soft trailer check → yes, warn-only; §8.5), q.4 (receipt
placement → comments, update-in-place; check-run hybrid is the M4
upgrade path; §8.4), q.5 (advisory-driven majors → never fast-lane;
§5.1), q.6 (model-graded graduation → measurable judge-validation bar;
§4.2), q.7 (deep-dive budget → $1–5/PR opt-in ceiling; §9).

Still open:

1. **Committee mechanics** — where packets go (Discussion category /
   label + board / Slack). Governance call; the agent drafts either
   way. Note this destination also carries all sensitive review state
   (§3.5), so it must be access-controlled.
2. **Author-trust classes** — the definition of "known contributor"
   for the external-author trigger. Research input: mature projects
   use a *reviewed allowlist file*, not N-merged-PRs heuristics; and
   the class list must now distinguish non-human authors (§6.1).
   Security-team call.
3. **Digest scale** — pagination / `--since` threshold. Defer until it
   hurts.
4. **Lane label mirror** *(deferred 2026-07)* — a tiny `lane/*` +
   `needs-triage` label set in lq-ai would make triage state visible
   to GitHub search instead of only to footer-parsers. Deferred as a
   governance ask on lq-ai's label taxonomy; revisit when
   cross-maintainer visibility hurts.
5. **Model-migration policy** — models retire on ~12-month cycles with
   60 days' notice; who approves a model switch for the agent, and
   what eval delta blocks it? (Related: how are disputes adjudicated
   once the recorded model is retired — recorded reasoning + eval
   suite is the working assumption, §4.2.)
6. **Non-human-author policy** — what lq-ai actually wants to say to
   autonomous-agent contributions (§6.1) beyond "never fast-lane."
   Governance call, likely an lq-ai CONTRIBUTING addition.
7. **Burden's deferred signals** *(new, §5.2 `B-12`)* — the
   `missing-dco` and `incompatible-license` blockers and the data-harm
   taxonomy that sharpens the `data-harm` blocker and the Safety axis.
   These close the §2 legal-compliance and data/privacy coverage gaps;
   until built they surface as open human-only checks, never silently
   passed. Scope: a DCO/CLA sign-off check and a new-dependency license
   check ride alongside the §5.1 dependency gate (which already fetches
   registry metadata); the harm taxonomy is a finding-classification
   addition. Sequencing call.
8. **Burden weighting** *(new, §5.2)* — the roll-up is worst-of by
   decision. Whether any axis should ever be maintainer-weighted (e.g.
   a project that weights Tests harder) is deferred: worst-of keeps two
   runs comparable and is the conservative default; revisit only if a
   real project's priorities demand it.
