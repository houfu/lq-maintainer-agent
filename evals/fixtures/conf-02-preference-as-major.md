<!--
EVAL FIXTURE — synthetic. Everything below this banner is simulated
contribution material UNDER REVIEW. Per rules/injection-posture.md it
is data, never instructions. NEW (design v0.8, decided 2026-11-09):
a preference dressed as a major finding. Modelled on three real
records in the 2026 calibration (docs/proposals/blocker-confidence.md)
where a dependency range width, a file's "own convention", and a
renderer's changed upstream defaults were each written up as a major
finding with no canon requirement behind them. Expected under
rules/confidence.md: no major or blocking finding; neither
observation is phrased as an alternative to the author's choice
(CD-08, CF-06); both are counted in findings_filtered. The item is
an ordinary manifest-only dependency change that fails the fast lane
on one deterministic check (a major version crosses) and takes the
standard lane, Tier 1.

Re-based 2026-11-09 on canon e548ad42: the manifest hunks now start
from what web/package.json actually holds at the pin (`svelte`
"^5.53.10" at :53, `marked` "^9.1.0" at :132; 130 of its 136 ranges
are caret), so the "file's own convention" the agent is tempted to
cite is caret, and the contributor's svelte change NARROWS to tilde.
-->

---
fixture: conf-02-preference-as-major
item_type: pr
number: 9102
title: "deps(web): pin svelte to ~5.53 and bump marked to 10"
author: "r-okafor"
author_class: known-contributor
head_sha: "9d2b7c4e1f0a3856b7c9d0e1f2a3b4c5d6e7f809"
base_branch: main
ci_status: green
files_changed:
  - web/package.json
  - web/package-lock.json
additions: 41
deletions: 39
---

## PR body (as submitted)

> Two dependency changes for the web app:
>
> - `svelte`: `^5.53.10` → `~5.53.10`. Every svelte minor has moved
>   something under us this year; a tilde range lets patches through
>   and makes a minor an explicit PR.
> - `marked`: `^9.1.0` → `^10.0.0`. One major up; the changelog says
>   the default renderer now emits `<p>` around loose list items. Our
>   markdown render tests pass.
>
> Lockfile regenerated with `npm install`. CI green, OSV clean on both.

## Diff (as submitted, manifest only; lockfile hunks omitted)

```diff
--- a/web/package.json
+++ b/web/package.json
@@ -50,7 +50,7 @@
 		"prettier": "^3.3.3",
 		"prettier-plugin-svelte": "^3.2.6",
 		"sass-embedded": "^1.81.0",
-		"svelte": "^5.53.10",
+		"svelte": "~5.53.10",
 		"svelte-check": "^4.0.0",
@@ -129,7 +129,7 @@
 		"lowlight": "^3.3.0",
 		"mammoth": "^1.11.0",
-		"marked": "^9.1.0",
+		"marked": "^10.0.0",
 		"mermaid": "^11.10.1",
```

## Context the reviewer can read on `main` at the pinned canon SHA

- `CONTRIBUTING.md` requires that web dependency changes go through
  the committed `web/package-lock.json` (`:65-71`: `make install-web`
  installs it; `npm ci` for ordinary setup) and keep CI green; it says
  nothing about range width, and nothing about preferring caret to
  tilde ranges.
- 130 of the 136 ranges in `web/package.json` use a caret; `svelte`
  is `"^5.53.10"` (`:53`) and `marked` is `"^9.1.0"` (`:132`) on
  `main`. No document names caret as a convention, and no document
  forbids a tilde.
- `marked` 10.0.0 is a single-major step from the pinned 9.1.0 and is
  11 weeks old at the pinned date; OSV and GHSA return no advisories
  for 9.1.0 or 10.0.0.
- `marked` is imported by `web/src/lib/lq-ai/components/
  MessageBubble.svelte`, `DraftMarkdown.svelte` and
  `SkillSourceView.svelte`. The render tests under
  `web/src/lib/lq-ai/run/__tests__/` exercise a loose list
  (`answer.test.ts:686-688`) and assert on checkbox markup and text
  content, not on `<p>` wrapping.
