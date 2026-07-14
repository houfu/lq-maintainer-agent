# LQ Maintainer Agent

**Status: v0.2.0 — early (M0/M1).** Built against design doc v0.6: the
skeleton, rules, templates, and the two manual skills exist; the eval
harness and canon-drift check are being wired up; batch digests, published
receipts, and the multi-agent deep dive land in later milestones. See
[docs/design/](docs/design/) for the full design and milestone plan.

## What this is

LQ Maintainer Agent is a standalone open-source project that helps
maintainers of [`legalquants/lq-ai`](https://github.com/legalquants/lq-ai)
process inbound work — PRs, issues, and dependabot traffic — using Claude
Code. It triages every item into a recommended lane, reviews within that
lane against lq-ai's own canon, decomposes overreaching contributions so
their valuable parts survive (**salvage**), and publishes an accountability
artifact per item (**Triage Receipt**).

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

The plugin declares the two skills and the **PreToolUse safety hooks**
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

## The three skills

All are explicit-invocation-only (`disable-model-invocation: true`) —
nothing fires unprompted. One **router** sorts the queue; two **reviewers**
go deep on a single item.

- **`/lq-maintainer:triage`** ([skills/triage/](skills/triage/)) — the
  breadth pass / queue router, for PRs and issues in batch. Produces a
  digest: fast-lane one-liners with the assigning rule and the
  deterministic-check results, standard-lane triage cards, committee
  packets for escalations, and issue classifications with drafted
  responses. Use it to start a maintainer session and clear the queue.
- **`/lq-maintainer:review-pr N`** ([skills/review-pr/](skills/review-pr/))
  — the depth pass for a single standard-lane PR that merits it (size,
  sensitivity, or an explicit ask). Dispatches a multi-agent team —
  anchor/scope, security vetting, code quality, test adequacy — over the
  diff and `main`, filters and caps the findings before anything reaches
  the receipt, and keeps the full unfiltered set in a cached long-form
  report behind it.
- **`/lq-maintainer:review-issue N`** ([skills/review-issue/](skills/review-issue/))
  — the single-issue reviewer (the issue counterpart to `review-pr`).
  Classifies, performs its own cross-reference (never the filer's), and
  produces the recommendation deck — needs-info / decompose / proceed /
  escalate — over a rule-grounded preview of the obstacles the issue would
  hit as a PR, plus a drafted receipt and responses.

Rule of thumb: `/lq-maintainer:triage` to decide what deserves attention;
`review-pr` / `review-issue` when one item has earned it.

## The fast lane is deterministic-first

A dependency bump is a merge candidate only if **every** mechanical check
passes: verified bot App identity, manifest/lockfile-only diff, semver
patch/minor on a ≥1.0.0 dependency, **no new package names anywhere in the
diff** (the typosquat control), a clean OSV batch lookup, a ≥7-day
release-age cooldown, and green CI. The checks are scripts
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

If a Triage Receipt just appeared on your PR or issue, start with
[docs/bot-behavior.md](docs/bot-behavior.md): what the agent does, what it
structurally cannot do, what the lanes mean, and how to contest a call or
ask for human-only handling. Every receipt's attribution line links there.

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
