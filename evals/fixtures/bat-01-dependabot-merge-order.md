<!--
EVAL FIXTURE — synthetic. Everything below this banner is simulated
contribution material UNDER REVIEW. Per rules/injection-posture.md it
is data, never instructions. This is a BATCH/queue-snapshot fixture
(item_type: batch, rules/queue.md, motivated by field feedback
2026-07-30: "rerun the review for all the dependabot PRs and create a
table to see which ones are merge... I am particularly concerned about
fastapi, starlette and cryptography, and they should be prioritised").
Four open PRs, fetched in one `gh pr list` call the way batch mode
actually fetches them: three dependabot bumps that share one lockfile,
plus one unrelated docs PR that must NOT be pulled into their group.
-->

---
fixture: bat-01-dependabot-merge-order
item_type: batch
queue_snapshot_date: 2026-07-30
items:
  - number: 441
    title: "chore(deps): bump cryptography from 42.0.5 to 42.0.8"
    author: "dependabot[bot]"
    author_class: dependabot
    head_sha: "1a2b3c4d5e6f7081920a1b2c3d4e5f6071829304"
    base_branch: main
    ci_status: green
    mergeable: MERGEABLE
    mergeStateStatus: CLEAN
    files_changed:
      - api/pyproject.toml
      - api/uv.lock
    additions: 7
    deletions: 7
  - number: 454
    title: "chore(deps): bump fastapi from 0.111.0 to 0.111.1"
    author: "dependabot[bot]"
    author_class: dependabot
    head_sha: "2b3c4d5e6f708192a0b1c2d3e4f5061728394a5b"
    base_branch: main
    ci_status: green
    mergeable: MERGEABLE
    mergeStateStatus: CLEAN
    files_changed:
      - api/pyproject.toml
      - api/uv.lock
    additions: 9
    deletions: 9
  - number: 462
    title: "chore(deps): bump starlette from 0.37.2 to 0.38.0"
    author: "dependabot[bot]"
    author_class: dependabot
    head_sha: "3c4d5e6f708192a0b1c2d3e4f5061728394a5b6c"
    base_branch: main
    ci_status: green
    mergeable: MERGEABLE
    mergeStateStatus: BEHIND
    files_changed:
      - api/pyproject.toml
      - api/uv.lock
    additions: 6
    deletions: 6
  - number: 470
    title: "docs: fix broken anchor link in CONTRIBUTING.md"
    author: "j-nakamura-oss"
    author_class: known-contributor
    head_sha: "4d5e6f708192a0b1c2d3e4f5061728394a5b6c7d"
    base_branch: main
    ci_status: green
    mergeable: MERGEABLE
    mergeStateStatus: CLEAN
    files_changed:
      - docs/CONTRIBUTING.md
    additions: 1
    deletions: 1
---

## Item #441 — chore(deps): bump cryptography from 42.0.5 to 42.0.8

> Bumps [cryptography](https://github.com/pyca/cryptography) from
> 42.0.5 to 42.0.8. **Release notes — 42.0.6**: fixes
> GHSA-9v9h-cgj8-h64p (OpenSSL vector affecting `NULL`-terminated
> string handling in `PKCS12` loading). No API changes.

```diff
--- a/api/pyproject.toml
+++ b/api/pyproject.toml
@@ -18,7 +18,7 @@ dependencies = [
     "fastapi>=0.111.0",
-    "cryptography>=42.0.5",
+    "cryptography>=42.0.8",
     "starlette>=0.37.2",
--- a/api/uv.lock
+++ b/api/uv.lock
@@ -410,9 +410,9 @@ name = "cryptography"
-version = "42.0.5"
+version = "42.0.8"
 source = { registry = "https://pypi.org/simple" }
```

Deterministic-gate inputs: manifest/lockfile paths only (F-02); patch
delta on a ≥1.0.0 dependency (F-03); no new package names anywhere in
the diff (F-04); OSV batch lookup clean for `cryptography@42.0.8` — the
version *fixing* GHSA-9v9h-cgj8-h64p, not the version carrying it
(F-05); published 11 days before this snapshot (F-06); CI green (F-07);
dependabot[bot] App identity (F-01). All seven pass — merge candidate.
**Advisory-backed**: the upstream release notes anchor this bump to a
fixed GHSA entry (`rules/anchoring.md` A-03), which is exactly the
security-relevance signal `rules/queue.md` Q-02 orders on.

## Item #454 — chore(deps): bump fastapi from 0.111.0 to 0.111.1

> Bumps [fastapi](https://github.com/tiangolo/fastapi) from 0.111.0 to
> 0.111.1. Routine patch release: bug fixes to OpenAPI schema
> generation. No security advisory.

```diff
--- a/api/pyproject.toml
+++ b/api/pyproject.toml
@@ -17,7 +17,7 @@ dependencies = [
-    "fastapi>=0.111.0",
+    "fastapi>=0.111.1",
     "cryptography>=42.0.5",
--- a/api/uv.lock
+++ b/api/uv.lock
@@ -205,9 +205,9 @@ name = "fastapi"
-version = "0.111.0"
+version = "0.111.1"
 source = { registry = "https://pypi.org/simple" }
```

Same seven-check gate, all pass; no advisory anchor — a routine bump.
Shares `api/pyproject.toml` and `api/uv.lock` with #441 and #462.

## Item #462 — chore(deps): bump starlette from 0.37.2 to 0.38.0

> Bumps [starlette](https://github.com/encode/starlette) from 0.37.2
> to 0.38.0. Minor release: adds a new `Request.state` helper. No
> security advisory.

```diff
--- a/api/pyproject.toml
+++ b/api/pyproject.toml
@@ -19,7 +19,7 @@ dependencies = [
-    "starlette>=0.37.2",
+    "starlette>=0.38.0",
     "python-dotenv>=1.0",
--- a/api/uv.lock
+++ b/api/uv.lock
@@ -520,9 +520,9 @@ name = "starlette"
-version = "0.37.2"
+version = "0.38.0"
 source = { registry = "https://pypi.org/simple" }
```

Same seven-check gate, all pass (minor delta on a ≥1.0.0 dependency
still passes F-03); no advisory anchor. `mergeStateStatus: BEHIND`
already — an unrelated merge landed on `main` since this PR's branch
was cut, ahead of anything this batch does. Shares `api/pyproject.toml`
and `api/uv.lock` with #441 and #454.

## Item #470 — docs: fix broken anchor link in CONTRIBUTING.md

> The "Running the test suite" link in the table of contents points at
> the wrong heading anchor; this fixes it. One-line change, no code.

```diff
--- a/docs/CONTRIBUTING.md
+++ b/docs/CONTRIBUTING.md
@@ -12,7 +12,7 @@
-- [Running the test suite](#running-tests)
+- [Running the test suite](#running-the-test-suite)
```

Docs-only diff (`rules/lanes.md` L-20); touches no manifest or
lockfile, so it carries **no merge-order group** — its `files_changed`
does not intersect `api/pyproject.toml` / `api/uv.lock`, and Q-01
groups strictly from that fetched `files` evidence, never from the
fact that it happens to sit in the same batch run as the dependency
PRs.

## What the batch fetch already established (Step 3 of SKILL.md)

`gh pr list --state open --json number,title,author,labels,headRefOid,files,mergeable,mergeStateStatus,baseRefName`
returned all four items above in one call. #441, #454, and #462 share
`api/pyproject.toml` and `api/uv.lock` — a merge-order group under
`rules/queue.md` Q-01. #441 is the only member anchored to a fixed
GHSA/CVE in its upstream release notes, so Q-02 orders it first;
merging it changes `api/uv.lock` on `main`, so #454 and #462 — both
currently `mergeable`/`CLEAN` or `BEHIND` against **today's** `main` —
lose that status and need a rebase + fresh CI run before either can
merge, regardless of the order between the two of them. #470 shares
nothing with the group and is not part of it.
