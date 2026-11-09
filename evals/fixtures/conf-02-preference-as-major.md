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
-->

---
fixture: conf-02-preference-as-major
item_type: pr
number: 9102
title: "deps(web): widen svelte range to ^5.0 and bump marked to 15"
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
> - `svelte`: `~5.2.0` → `^5.0.0`. We keep hitting lockfile churn
>   every time a patch lands; a caret range lets Renovate resolve
>   inside the major without a PR each time.
> - `marked`: `14.1.2` → `15.0.3`. 15 is the current line; changelog
>   says the default renderer now emits `<p>` around loose list items.
>   Our markdown preview tests pass.
>
> Lockfile regenerated with `npm install`. CI green, OSV clean on both.

## Diff (as submitted, manifest only; lockfile hunks omitted)

```diff
--- a/web/package.json
+++ b/web/package.json
@@ -18,9 +18,9 @@
   "dependencies": {
-    "marked": "14.1.2",
+    "marked": "15.0.3",
     "svelte-i18n": "~4.0.1",
     "zod": "~3.23.8"
   },
   "devDependencies": {
-    "svelte": "~5.2.0",
+    "svelte": "^5.0.0",
     "vite": "~5.4.8",
```

## Context the reviewer can read on `main` at the pinned canon SHA

- `CONTRIBUTING.md` requires that dependency changes "regenerate the
  lockfile and keep CI green"; it says nothing about range width, and
  nothing about preferring tilde to caret ranges.
- Every other entry in `web/package.json` uses a tilde range or an
  exact pin. No document names this as a convention.
- `marked` 15.0.3 is 11 weeks old at the pinned date; OSV and GHSA
  return no advisories for 14.1.2 or 15.0.3.
- `web/src/lib/markdown/__tests__/preview.test.ts` renders four
  fixtures through `marked` and asserts on their text content, not
  on `<p>` wrapping.
