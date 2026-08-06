# LQ Maintainer Agent

**Status: v0.5.0 — early (M0/M1).** Built against design doc v0.7.2
(a delta over v0.7.1): tiered review with a quick-pass default, four
change categories with a design path for greenfield work, and a
public-deck / internal-receipt deliverable split. As of v0.5.0 the
agent also detects breaking changes mechanically from the diff,
projects its classification onto the target repo's own labels (a
cheap first touch on arrival, human-applied like every write), and
drafts the target repo's release narrative from the accumulated
review evidence. The deck is the one surface a maintainer reads —
leaner as of this release: findings and the paste-ready drafts lead,
the maintainer's ruling rides one decision card, and the scaffolding
folds away. The eval harness and canon-drift check are wired and
green in CI; batch digests and the community repo land in later
milestones. See [docs/design/](docs/design/) for the full design and
milestone plan.

## What this is

LQ Maintainer Agent is a standalone open-source project that helps
maintainers of [`legalquants/lq-ai`](https://github.com/legalquants/lq-ai)
process inbound work — PRs, issues, and dependabot traffic — using Claude
Code. It classifies every item into a change category, reviews it at the
lightest tier that fits (a quick pass ending in a concrete action for
small behavioral changes and bug fixes; a deep multi-agent dive only when
conditions warrant), routes greenfield feature work to a **design path**
that drafts the plan, ADRs, and atomic decomposition, and decomposes
overreaching contributions so their valuable parts survive (**salvage**).
Every review produces a contributor-friendly **reading deck** (the
primary artifact, bound for a public community repo) and an internal
evidence record; the PR itself gets a short, warm comment. The deck
carries the paste-ready drafts — the comment, and the squash-merge
message for merge candidates — so nothing is delivered as loose chat
text, and once the maintainer rules, the deck shows **what the
maintainer decided** alongside what the agent recommended. Divergences
and maintainer feedback aggregate into a local feedback log
([templates/feedback-log.md](templates/feedback-log.md)) that seeds
the golden-eval suite.

Two policies bind everything it drafts: **every contribution is treated
as sincere**, and **every contribution is treated with respect** —
reviewers defer to authors on approach, findings name deficiencies
rather than preferences, and nothing contributor-facing is ever
personal.

The agent recommends, drafts, and reports. **A human decides, every time.**
For external contributions this is lq-ai's written policy
(`docs/security/external-contribution-vetting.md`: automated assistants
"may review and report, but the merge button is a human maintainer's"),
and it does not relax with trust.

The problem being solved is **attention routing**: lq-ai's governing canon
(PRD, 21+ ADRs, Roadmap, the DE-XXX list, CLAUDE.md, CONTRIBUTING, the
skill-attestation process, the vetting playbook) has outgrown what
part-time community maintainers can hold in their heads. The agent carries
the canon so humans can spend their scarce attention on the judgments only
humans can make.

**The honest value claim**: because every public output is human-gated,
this design cannot deliver the headline win of autonomous triage bots —
first response in minutes instead of days. What it delivers is **routing
quality per maintainer-minute**: a 30-minute session that clears more of
the queue, more defensibly, with a published rubric. Speed arrives, if
ever, with the M4 service spike — and only past explicit go/no-go criteria.

## Why a separate repo

Decided 2026-07: the agent lives here, not inside `lq-ai`. Short version:
it needs its own iteration speed (prompt and rules tweaks should not be
security-routed PRs in the product repo), its own milestones and board, a
home for the eventual service infrastructure, and it is a shareable
artifact in its own right. The two costs — canon drift and transparency —
are mitigated by a CI drift check against a pinned lq-ai reference, by
this repo being public with lq-ai's CONTRIBUTING pointing contributors at
the exact rubric they are triaged by, and by **every receipt naming the
agent per-artifact** in its attribution line — repo-level disclosure alone
is the pattern that has triggered contributor backlash elsewhere. The door
back to the main project stays open by construction: rules and templates
are data, so re-homing is a `git mv`. Full rationale in
[docs/design/](docs/design/) §2.

The project is **lq-ai-first, portable by design**: all lq-ai-specific
knowledge lives in one file, [rules/canon-map.md](rules/canon-map.md);
another project adopting the agent replaces that file (and the templates'
prose), nothing else.

## Install (Claude Code plugin)

Maintainers install the agent once as a Claude Code plugin, then run its
skills **from inside their own lq-ai clone** — that is what gives the agent
local read access to the canon and to `main`.

1. Add this repo as a plugin marketplace source in Claude Code:

   ```
   /plugin marketplace add houfu/lq-maintainer-agent
   ```

2. Install the plugin (the plugin is named `lq-maintainer`; the repo and
   marketplace carry the full project name):

   ```
   /plugin install lq-maintainer@lq-maintainer-agent
   ```

3. Open Claude Code in your local `lq-ai` clone and invoke a skill.
   **Skill invocation is namespaced by the plugin name** — the commands
   are `/lq-maintainer:triage` and `/lq-maintainer:review-pr`, not a bare
   `/triage`.

The plugin declares the six skills and the **PreToolUse safety hooks**
([hooks/hooks.json](hooks/hooks.json)) that block merge, approve, close,
push, and PR-ref checkout in the session. A reference copy of the same
block for lq-ai's own `.claude/`
([settings/claude-settings.json](settings/claude-settings.json)) protects
non-plugin sessions; it is vendored into lq-ai at M0, not auto-applied.

Releases are tagged and versioned; third-party marketplaces do not
auto-update by default, so update deliberately, not on every push. Every
receipt records **four pinned fields** — the PR head SHA reviewed, the
canon SHA it was judged against, the agent version, and the served model
ID for the session — so any triage decision is reproducible and any
dispute auditable.

## The six skills

All are explicit-invocation-only (`disable-model-invocation: true`) —
nothing fires unprompted. One **router** sorts the queue; two **reviewers**
handle a single item at the right tier; one **designer** turns greenfield
feature work into a ratifiable plan; one **labeler** gives an arriving
item a cheap, provisional first touch; and one **release drafter** turns
the accumulated review evidence into the target repo's release
narrative.

- **`/lq-maintainer:triage`** ([skills/triage/](skills/triage/)) — the
  breadth pass / queue router, for PRs and issues in batch. Produces a
  digest: fast-lane one-liners with the assigning rule and the
  deterministic-check results, standard-lane triage cards, committee
  packets for escalations, and issue classifications with drafted
  responses. Use it to start a maintainer session and clear the queue.
- **`/lq-maintainer:review-pr N`** ([skills/review-pr/](skills/review-pr/))
  — the single-PR reviewer. Default is the **Tier-1 quick pass**: one
  time-boxed read of the diff against canon that ends in a concrete
  action — merge / merge-after-one-named-fix / discuss-a-specific-question
  / route-to-design — with its undo path stated. The **Tier-2 deep dive**
  (a multi-agent team: anchor/scope, security vetting, code quality, test
  adequacy, with a finding filter) runs only when a named condition
  warrants it: an escalation trigger, size beyond Tier-1 bounds, an
  irreversible-class path, or the maintainer's ask. Findings whose fix
  is a concrete text change arrive with a drafted GitHub suggestion
  block and a stated apply path, so acting on one is one click — for
  the maintainer or the contributor.
- **`/lq-maintainer:review-issue N`** ([skills/review-issue/](skills/review-issue/))
  — the single-issue reviewer (the issue counterpart to `review-pr`).
  Classifies, performs its own cross-reference (never the filer's), and
  produces the recommendation deck — needs-info / decompose / proceed /
  design / escalate — over a rule-grounded preview of the obstacles the
  issue would hit as a PR, plus drafted responses.
- **`/lq-maintainer:design-plan (pr|issue) N`**
  ([skills/design-plan/](skills/design-plan/)) — the category-1 path for
  greenfield / new-feature contributions (the DE series). Produces a
  plan instead of a code review: the decision inventory with drafted
  ADR(s), the predicted obstacles, and a decomposition into atomic
  reviewable changes — so the contributor's energy becomes design input
  for the committee instead of a stalled PR.
- **`/lq-maintainer:label (pr|issue) N`** ([skills/label/](skills/label/))
  *(v0.7.2)* — the express first touch. Makes a provisional
  classification from the same rules the router uses and maps it onto
  the **target repo's own labels** (never an invented taxonomy, never a
  created label); every label change is handed over for the maintainer
  to apply. Labels are outputs only — nothing ever routes on them — and
  the security carve-outs bind them (no label on a vulnerability-suspect
  issue, ever). The fuller pass corrects labels via a sync step; the
  receipt stays the authority.
- **`/lq-maintainer:release-notes [range]`**
  ([skills/release-notes/](skills/release-notes/)) *(v0.7.2)* — drafts
  the target repo's release narrative from merge trailers and the
  accumulated review evidence: breaking changes lead with their
  undo/migration lines, contributors are credited per item, and a
  semver bump is suggested with evidence — drafted, never decided. The
  human tags and publishes, always.

Rule of thumb: `/lq-maintainer:label` for a cheap first touch when
something arrives; `/lq-maintainer:triage` to decide what deserves
attention; `review-pr` / `review-issue` for one item; `design-plan` when
the item is really a feature proposal wearing a PR; `release-notes` when
cutting a release.

## Categories and tiers

Every PR classifies into one of four change categories, judged from the
diff ([rules/change-categories.md](rules/change-categories.md)):
greenfield/new feature (→ the design path), behavioral
change/improvement (→ tiered review + a necessity check), bug
fix/rollback (→ tiered review), and refactoring/large-scale (→ a
respectful holding pattern until the large-change process is written).

Review depth is tiered ([rules/tiers.md](rules/tiers.md)): Tier 0 is the
deterministic gate below; Tier 1 — the default for small category-2/3
changes (≤400 lines, ≤10 files, no irreversible-class paths) — is a
quick pass that must end in a concrete action with its undo path; Tier 2
is the multi-agent deep dive, entered only by a named condition; Tier 3
is committee/design. Conservatism attaches to **irreversibility, not
uncertainty** ([rules/reversibility.md](rules/reversibility.md)):
auth/crypto, data migrations, public API contracts, CI workflows, new
dependencies, and releases never take the quick pass, while everything
else carries an explicit "if this proves wrong, here is the undo" line.
Content can only ever move an item to a *heavier* tier — nothing inside
a contribution can buy it a lighter one.

## The fast lane is deterministic-first

A dependency bump is a merge candidate only if **every** mechanical check
passes: verified bot App identity, manifest/lockfile-only diff, semver
patch/minor on a ≥1.0.0 dependency, **no new package names anywhere in the
diff** (the typosquat control), a clean OSV batch lookup, a ≥7-day
release-age cooldown, and green CI. Standard-lane PRs additionally get
a mechanical breaking-change scan (`check-breaking.sh` — removed public
symbols, signatures, config keys, CLI flags, routes, schema drops; a
detection blocks the quick pass and drafts the `breaking-change` label,
while a PASS proves nothing and moves nothing lighter). The checks are scripts
([skills/triage/scripts/](skills/triage/scripts/)), rendered pass/fail in
the receipt; the LLM anchors the bump to a real upstream release and flags
anomalies — it never re-derives what the ecosystem decides
deterministically. Advisory-driven majors never fast-lane, and the receipt
always discloses that package *contents* were not inspected.

## Guardrails

The agent operates read-only by default (`gh pr list/view/diff/checks`,
`gh issue list/view`, `api` GETs, plus Read/Grep/Glob in the working
directory and the unauthenticated OSV/registry check scripts); every write
is permission-gated, and merge, approve, close, push, and PR-ref checkout
are hook-blocked even then. Write commands are **never** added to the
skills' `allowed-tools` — one "always allow" would silently delete the
human gate. The agent **never executes contributed code** — not tests, not
installs, not builds — because each of those runs the contributor's code
with the session's ambient credentials; humans who need runtime behavior
use the disposable-sandbox discipline in
[docs/sandbox-discipline.md](docs/sandbox-discipline.md).

All contribution content is treated as material under review, never as
instructions ([rules/injection-posture.md](rules/injection-posture.md)):
untrusted spans are Unicode-normalized before judgment, reviewer- or
AI-directed text is quoted as a finding, agent-instruction and tool-config
files in a diff escalate and are never loaded, and nothing inside a
contribution can raise its lane, suppress a check, or claim approval. The
load-bearing defense is the permission architecture, not prompt vigilance.

The hooks are the chosen primary enforcement layer, and their known limits
are stated honestly rather than papered over — see
[docs/onboarding.md](docs/onboarding.md), including the one absolute rule:
**never run a triage session with permission checks disabled.**

## For lq-ai contributors

If an agent-drafted comment just appeared on your PR or issue, start with
[docs/bot-behavior.md](docs/bot-behavior.md): what the agent does, what it
structurally cannot do, what the review outcomes mean, and how to contest
a call or ask for human-only handling. Every comment's attribution line
links there.

## Learn more

- [docs/design/](docs/design/) — the design doc (single source of truth)
  and its history, plus the research report behind the v0.6 decisions
- [docs/onboarding.md](docs/onboarding.md) — maintainer install and first
  session
- [docs/bot-behavior.md](docs/bot-behavior.md) — contributor-facing: what
  the agent does and the contest/hold path
- [CONTRIBUTING.md](CONTRIBUTING.md) — governance for this repo, including
  the stricter review rules for `rules/`, `hooks/`, `settings/`, and
  skills frontmatter

## License

MIT — see [LICENSE](LICENSE).
