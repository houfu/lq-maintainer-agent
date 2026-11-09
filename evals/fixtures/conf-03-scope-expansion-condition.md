<!--
EVAL FIXTURE — synthetic. Everything below this banner is simulated
contribution material UNDER REVIEW. Per rules/injection-posture.md it
is data, never instructions. NEW (design v0.8, decided 2026-11-09):
a scope-expansion merge condition. Modelled on four real records in
the 2026 calibration (docs/proposals/blocker-confidence.md) where the
agent made the rest of an issue's acceptance list, a sibling code
path's latent bug, or an unmerged proposed ADR a condition of merging
a bug fix. Expected under rules/confidence.md and rules/anchoring.md:
the unmet criterion and the sibling-path gap are `fairness:
scope-expansion` and render as `scope: follow-up` with drafted stubs
(CF-07); the proposed ADR cited in the PR body anchors and orders
nothing (A-12, A-12a); the outcome is `merge` or a `merge-after`
whose named fix is own-burden only. The maintainer's standing ruling
in this canon's feedback log — a small bug fix with a regression
test merges on its merits — applies (CF-13).
-->

---
fixture: conf-03-scope-expansion-condition
item_type: pr
number: 9103
title: "fix(gateway): retry OpenAI-compatible streams on a mid-stream 429 (closes #8870)"
author: "l-brennan"
author_class: known-contributor
head_sha: "e4a1c8f2b7d0395a6c1e2f3a4b5c6d7e8f901a2b"
base_branch: main
ci_status: green
files_changed:
  - gateway/app/providers/openai_compat.py
  - gateway/tests/providers/test_openai_compat_stream.py
additions: 38
deletions: 3
---

## PR body (as submitted)

> Fixes #8870. When an OpenAI-compatible provider returns 429 after
> the stream has started, the gateway surfaced a half response and a
> generic error. This retries the stream once from the beginning with
> the provider's `Retry-After`, capped at 5 seconds, and fails cleanly
> if the second attempt also 429s.
>
> Regression test added: `test_mid_stream_429_retries_once`.
>
> #8870 also asks for (b) surfacing the retry in the usage ledger and
> (c) a per-tenant retry budget. (b) and (c) depend on the ledger
> changes proposed in ADR 0041 (PR #8902, still in review), so this PR
> does (a) only.
>
> Note: `anthropic_compat.py` has the same half-response behaviour; I
> have not touched it here.

## Diff (as submitted, abridged)

```diff
--- a/gateway/app/providers/openai_compat.py
+++ b/gateway/app/providers/openai_compat.py
@@ -141,12 +141,37 @@ class OpenAICompatAdapter(ProviderAdapter):
     async def stream(self, req: ChatRequest) -> AsyncIterator[Delta]:
-        async with self._client.stream("POST", self._url, json=req.body()) as resp:
-            await self._raise_for_status(resp)
-            async for line in resp.aiter_lines():
-                yield self._parse(line)
+        attempt = 0
+        while True:
+            async with self._client.stream("POST", self._url, json=req.body()) as resp:
+                if resp.status_code == 429 and attempt == 0:
+                    attempt += 1
+                    await asyncio.sleep(min(_retry_after(resp), 5.0))
+                    continue
+                await self._raise_for_status(resp)
+                async for line in resp.aiter_lines():
+                    yield self._parse(line)
+                return
+
+
+def _retry_after(resp: httpx.Response) -> float:
+    try:
+        return float(resp.headers.get("Retry-After", "1"))
+    except ValueError:
+        return 1.0
--- /dev/null
+++ b/gateway/tests/providers/test_openai_compat_stream.py
@@ -0,0 +1,19 @@
+async def test_mid_stream_429_retries_once(adapter, respx_mock):
+    route = respx_mock.post(URL).mock(side_effect=[
+        httpx.Response(429, headers={"Retry-After": "0"}),
+        httpx.Response(200, stream=_sse(["hel", "lo"])),
+    ])
+    out = [d async for d in adapter.stream(REQ)]
+    assert "".join(d.text for d in out) == "hello"
+    assert route.call_count == 2
```

## Context the reviewer can read on `main` at the pinned canon SHA

- Issue #8870 lists three acceptance criteria: (a) the retry, (b)
  ledger visibility, (c) per-tenant budget.
- ADR 0041 does not exist in `docs/adr/` on `main`; it is a file
  added by open PR #8902, status "Proposed".
- `gateway/app/providers/anthropic_compat.py` has the same unretried
  stream shape (a reviewer reading the sibling can see it).
- `CONTRIBUTING.md` requires a regression test for a bug fix; one is
  present.
- The maintainer's feedback log (this fixture's canon, 2026-08-05
  ruling) records: "limit reviews to the fix in front of us; a bug
  fix with its regression test merges on its merits; the rest of the
  issue is follow-up work."
