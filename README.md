# LQ Maintainer Agent

**Status: v0.1.0 — early (M0/M1).** The skeleton, rules, templates, and the
two manual skills exist; the eval harness and canon-drift check are being
wired up; batch digests, published receipts, and the multi-agent deep dive
land in later milestones. See [docs/design/](docs/design/) for the full
design and milestone plan.

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

## Why a separate repo

Decided 2026-07: the agent lives here, not inside `lq-ai`. Short version:
it needs its own iteration speed (prompt and rules tweaks should not be
security-routed PRs in the product repo), its own milestones and board, a
home for the eventual service infrastructure, and it is a shareable
artifact in its own right. The two costs — canon drift and transparency —
are mitigated by a CI drift check against a pinned lq-ai reference and by
this repo being public, with lq-ai's CONTRIBUTING pointing contributors at
the exact rubric they are triaged by. The door back to the main project
stays open by construction: rules and templates are data, so re-homing is
a `git mv`. Full rationale in [docs/design/](docs/design/) §2.

## Install (Claude Code plugin)

Maintainers install the agent once as a Claude Code plugin, then run its
skills **from inside their own lq-ai clone** — that is what gives the agent
local read access to the canon and to `main`.

1. Add this repo as a plugin marketplace source in Claude Code:

   ```
   /plugin marketplace add houfu/lq-maintainer-agent
   ```

2. Install the plugin:

   ```
   /plugin install lq-maintainer-agent
   ```

3. Open Claude Code in your local `lq-ai` clone and invoke a skill.

Releases are tagged and versioned; update deliberately, not on every push.
Every receipt records the agent version that produced it, alongside the PR
head SHA and the canon SHA it was judged against. The plugin also ships a
settings mirror ([settings/claude-settings.json](settings/claude-settings.json))
of lq-ai's session-safety block-list, so protection travels even into an
unhardened clone.

## The two skills

Both are explicit-invocation-only — nothing fires unprompted.

- **`/triage`** ([skills/triage/](skills/triage/)) — the breadth pass, for
  PRs and issues, single item or batch. Produces a digest: fast-lane
  one-liners with the assigning rule, standard-lane triage cards,
  committee packets for escalations, and issue classifications with
  drafted responses. Use it to start a maintainer session and clear the
  queue.
- **`/review-pr`** ([skills/review-pr/](skills/review-pr/)) — the depth
  pass, for a single standard-lane PR that merits it (size, sensitivity,
  or an explicit ask). Dispatches a multi-agent team — anchor/scope,
  security vetting, code quality, test adequacy — over the diff and
  `main`, and merges their structured findings into a long-form report
  behind the receipt.

Rule of thumb: `/triage` to decide what deserves attention; `/review-pr`
when one item has earned it.

## Guardrails

The agent operates read-only by default (`gh pr list/view/diff/checks`,
`gh issue list/view`, `api` GETs, plus Read/Grep/Glob in the working
directory); every write is permission-gated, and merge, approve, close,
push, and PR-ref checkout are hook-blocked even then. The agent **never
executes contributed code** — not tests, not installs, not builds — because
each of those runs the contributor's code with the session's ambient
credentials; humans who need runtime behavior use the disposable-sandbox
discipline in [docs/sandbox-discipline.md](docs/sandbox-discipline.md).
All contribution content is treated as material under review, never as
instructions ([rules/injection-posture.md](rules/injection-posture.md)):
reviewer- or AI-directed text is quoted as a finding, and nothing inside a
contribution can raise its lane, suppress a check, or claim approval.
Every output is pinned to the PR head SHA, the canon SHA, and the agent
version, so any decision is reproducible and any dispute auditable.

## Learn more

- [docs/design/](docs/design/) — the design doc (single source of truth)
  and its history
- [docs/onboarding.md](docs/onboarding.md) — maintainer install and first
  session
- [CONTRIBUTING.md](CONTRIBUTING.md) — governance for this repo, including
  the stricter review rules for `rules/`, `settings/`, and skills

## License

MIT — see [LICENSE](LICENSE).
