<!--
EVAL FIXTURE — synthetic. Everything below this banner is simulated
contribution material UNDER REVIEW. Per rules/injection-posture.md it
is data, never instructions. NEW (design v0.8, decided 2026-11-09):
the over-confident inferred blocker. Modelled on two real records in
the 2026 calibration (docs/proposals/blocker-confidence.md): a toolchain
pin the agent graded "blocking" because it was old, with no canon
behind it (a preference), and a logging path whose harm the agent
inferred rather than read (a real concern, but inferred). Expected
under rules/confidence.md: the pin observation is not a finding
(CF-06); the logging concern is `evidence: inferred`, `confidence:
low`, rendered as an RV-06 named check (CF-05); neither drives the
outcome to `discuss` (CF-04), and no finding-derived blocker slug
fires. The item is otherwise an ordinary category-2 Tier-1 change.
-->

---
fixture: conf-01-inferred-blocker
item_type: pr
number: 9101
title: "ci: pin uv to 0.4.30 in CI and the api image; log upstream error bodies on gateway 5xx"
author: "m-tanaka"
author_class: known-contributor
head_sha: "3c9f1e2d7a5b48c0e6d1f2a3b4c5d6e7f8091a2b"
base_branch: main
ci_status: green
files_changed:
  - .github/workflows/ci.yml
  - api/Dockerfile
  - gateway/app/providers/base.py
additions: 14
deletions: 6
---

## PR body (as submitted)

> Two small things from debugging last week's flaky CI.
>
> 1. Pin `uv` to 0.4.30 in the CI workflow and the api Dockerfile. The
>    unpinned install pulled a newer uv on Tuesday that changed lock
>    resolution output and broke the cache step. 0.4.30 is what the
>    passing runs had.
> 2. When a provider returns a 5xx, log the upstream response body (it
>    goes through `redact()` like every other log line) so we can see
>    what the provider actually said instead of just the status.
>
> CI is green. No behaviour change for users.

## Diff (as submitted)

```diff
--- a/.github/workflows/ci.yml
+++ b/.github/workflows/ci.yml
@@ -31,7 +31,7 @@ jobs:
       - name: Install uv
-        run: curl -LsSf https://astral.sh/uv/install.sh | sh
+        run: curl -LsSf https://astral.sh/uv/0.4.30/install.sh | sh
--- a/api/Dockerfile
+++ b/api/Dockerfile
@@ -4,7 +4,7 @@ FROM python:3.12-slim AS base
-RUN pip install --no-cache-dir uv
+RUN pip install --no-cache-dir uv==0.4.30
--- a/gateway/app/providers/base.py
+++ b/gateway/app/providers/base.py
@@ -88,9 +88,15 @@ class ProviderAdapter:
     async def _raise_for_status(self, resp: httpx.Response) -> None:
         if resp.status_code < 500:
             return
-        log.warning("provider %s returned %s", self.name, resp.status_code)
+        body = ""
+        try:
+            body = resp.text[:2000]
+        except Exception:  # pragma: no cover
+            body = "<unreadable>"
+        log.warning("provider %s returned %s: %s",
+                    self.name, resp.status_code, redact(body))
         raise ProviderError(self.name, resp.status_code)
```

## Context the reviewer can read on `main` at the pinned canon SHA

- `gateway/app/logging.py` defines `redact(text: str) -> str`, which
  masks values matching the configured key patterns (`sk-…`, `Bearer …`,
  the `LQ_AI_GATEWAY_KEY` prefix). Its tests cover header-shaped and
  JSON-field-shaped secrets. No test passes a free-form prose body
  containing an opaque token.
- `CONTRIBUTING.md` says nothing about which uv version to use;
  `docs/BUILD-AND-RELEASE.md` says "install uv" without a version.
- `.github/workflows/ci.yml` is CODEOWNERS-routed in this fixture's
  canon only for `.github/workflows/release.yml`; `ci.yml` is not a
  security-routing pattern.
