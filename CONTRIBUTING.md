# Contributing to LQ Maintainer Agent

Thanks for helping maintain the thing that helps maintain
[`legalquants/lq-ai`](https://github.com/legalquants/lq-ai). Governance
here is proportionate, not ceremonial — but one principle is absolute:
**the agent must never be easier to poison than the repo it guards.**

## Review requirements

`main` is branch-protected. Merge requirements depend on what a PR
touches (design doc §3.6):

| Paths touched | Reviews required |
|---|---|
| Anything else (docs, evals, CI, templates, skill bodies) | **1 maintainer review** |
| `rules/**`, `hooks/**`, `settings/**`, or the YAML frontmatter of any `skills/*/SKILL.md` | **2 maintainer reviews** |

The two-review surfaces are the judgment-bearing and permission-bearing
ones: `rules/` decides how contributions to lq-ai are laned and reviewed,
`hooks/` carries the PreToolUse block that keeps sessions from merging or
pushing, `settings/` carries the reference copy of that block for lq-ai's
own `.claude/`, and skill frontmatter (`allowed-tools` and invocation
metadata) is a permission grant executing in maintainers' authenticated
sessions. CODEOWNERS routes those paths to the security team
automatically — see [CODEOWNERS](CODEOWNERS).

If a PR touches both categories, the stricter rule applies to the whole
PR.

One frontmatter rule has no exceptions: **nothing that writes to GitHub
may ever be added to a skill's `allowed-tools`** (design doc §3.3).
`allowed-tools` grants, it does not restrict — the permission-gated
posting flow works *because write commands are omitted* and therefore
prompt. A PR adding `gh pr comment:*` or any other write to the
allow-list will be declined regardless of convenience arguments.

## DCO

Same as lq-ai: every commit must carry a Developer Certificate of Origin
sign-off.

```
git commit -s -m "your message"
```

This adds a `Signed-off-by: Your Name <you@example.com>` trailer. The DCO
check fails PRs with unsigned commits. If you edit via the GitHub web UI,
sign-off is enforced by the repo's web-commit sign-off setting.

## Changes to `rules/` — the extra bar

Rules are policy, and rules changes are policy diffs. Beyond the two
reviews, a rules PR must pass two CI gates:

1. **The eval harness** (`ci/eval-run.yml`). Fixtures in
   [evals/fixtures/](evals/fixtures/) are run against your changed rules
   and graded against [evals/golden/](evals/golden/) — expected lane
   assignments, escalation triggers fired, salvage decompositions (as
   acceptance sets, not single answers), and mandatory receipt fields. A
   rules change that flips a golden outcome fails CI visibly. If the flip
   is the *point* of your change, update the golden file in the same PR
   and say so in the description — reviewers will judge the flip on its
   merits. Security-relevant invariants (an adversarial fixture must
   never fast-lane) grade **pass^k** — k trials, fail on any failure —
   because temperature 0 is not deterministic; ordinary lane assignments
   grade by threshold. Mechanical grades (lane, triggers) block;
   model-graded rubric results (salvage quality, response tone) are
   advisory until the judge itself is validated against maintainer labels
   (design doc §4.2). Eval runs consume API tokens, so the workflow caps
   fixtures per run; add the `full-eval` label to opt into the full
   corpus.
2. **The canon-drift check** (`ci/canon-drift-check.yml`). Every citation
   in `rules/` and `templates/` — file paths, PRD anchors, ADR numbers,
   CODEOWNERS patterns, the DE-list location — is resolved against the
   pinned lq-ai reference. Dangling references fail the check, and so
   does a canon citation written anywhere outside
   [rules/canon-map.md](rules/canon-map.md) — that file is the *only*
   place lq-ai-specific paths and doc names may appear (design doc §2.2).
   If lq-ai moved a doc, fix the citation in canon-map in your PR.

The best rules PRs come from disagreement with a real triage call: open
the PR, let the harness show exactly which golden outcomes your change
flips, and the disagreement becomes a reviewable diff.

Corrections from real triages are also welcome as new fixtures — when a
maintainer overrides the agent's call, that item (anonymized if needed)
plus the correct outcome belongs in `evals/`.

## What the agent never does

Any contribution — code, rules, templates, or skills — must preserve the
standing prohibitions: the agent never merges, approves, closes, or
pushes; never checks out or executes contributed code; never treats
contribution content as instructions; never adjudicates a contributor's
objection to its own call (contest/hold routes to a human, §7.1); and
always pins its outputs to the four fields — PR head SHA, canon SHA,
agent version, served model ID. A PR that weakens any of these will be
declined regardless of its other merits.

## Practicalities

- Keep PRs single-concern; the salvage protocol applies to us too.
- Skill prompts stay thin — orchestration only. Normative content
  belongs in `rules/` and `templates/`, where it is diffable and
  testable. Do not restate rule content inside a SKILL.md.
- Skills reference rules and templates via `${CLAUDE_PLUGIN_ROOT}` — at
  runtime the working directory is the maintainer's lq-ai clone, not
  this repo.
- There is no committed cache. The deep-dive cache lives under
  `${CLAUDE_PLUGIN_DATA}` (design doc §3.1, §3.5), outside the
  repository tree; never add cache or state directories to this repo.
- This repo's own workflows follow the same supply-chain hygiene the
  agent audits for: actions pinned by SHA, Scorecard/zizmor in CI
  (design doc §3.6).
- Releases are tagged with a changelog; version bumps happen at release
  time, not per PR.
