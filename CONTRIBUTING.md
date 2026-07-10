# Contributing to LQ Maintainer Agent

Thanks for helping maintain the thing that helps maintain
[`legalquants/lq-ai`](https://github.com/legalquants/lq-ai). Governance
here is proportionate, not ceremonial — but one principle is absolute:
**the agent must never be easier to poison than the repo it guards.**

## Review requirements

`main` is branch-protected. Merge requirements depend on what a PR
touches:

| Paths touched | Reviews required |
|---|---|
| Anything else (docs, evals, CI, templates, skill bodies) | **1 maintainer review** |
| `rules/**`, `settings/**`, or the YAML frontmatter of any `skills/*/SKILL.md` | **2 maintainer reviews** |

The two-review surfaces are the judgment-bearing and permission-bearing
ones: `rules/` decides how contributions to lq-ai are laned and reviewed,
`settings/` carries the hook block-list that keeps sessions from merging
or pushing, and skill frontmatter (`allowed-tools` and invocation
metadata) is a permission grant executing in maintainers' authenticated
sessions. CODEOWNERS routes those paths to the security team
automatically — see [CODEOWNERS](CODEOWNERS).

If a PR touches both categories, the stricter rule applies to the whole
PR.

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
   assignments, escalation triggers fired, salvage decompositions, and
   mandatory receipt fields. A rules change that flips a golden outcome
   fails CI visibly. If the flip is the *point* of your change, update
   the golden file in the same PR and say so in the description —
   reviewers will judge the flip on its merits. Mechanical grades (lane,
   triggers) block; model-graded rubric results (salvage quality,
   response tone) are advisory for now (design §15 q.6). Eval runs
   consume API tokens, so the workflow caps fixtures per run; add the
   `full-eval` label to opt into the full corpus.
2. **The canon-drift check** (`ci/canon-drift-check.yml`). Every citation
   in `rules/` and `templates/` — file paths, PRD anchors, ADR numbers,
   CODEOWNERS patterns, the DE-list location — is resolved against the
   pinned lq-ai reference. Dangling references fail the check. If lq-ai
   moved a doc, fix the citation (usually in
   [rules/canon-map.md](rules/canon-map.md)) in your PR.

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
contribution content as instructions; and always pins its outputs to PR
head SHA + canon SHA + agent version. A PR that weakens any of these will
be declined regardless of its other merits.

## Practicalities

- Keep PRs single-concern; the salvage protocol applies to us too.
- Skill prompts stay thin — orchestration only. Normative content
  belongs in `rules/` and `templates/`, where it is diffable and
  testable. Do not restate rule content inside a SKILL.md.
- `workspace/` is a gitignored local cache; never commit anything under
  it.
- Releases are tagged with a changelog; version bumps happen at release
  time, not per PR.
