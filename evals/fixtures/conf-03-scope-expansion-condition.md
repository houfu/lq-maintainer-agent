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

Re-based 2026-11-09 on canon e548ad42. The earlier draft lived in
gateway/app/providers/ (CODEOWNERS security-routed at this pin — E-01
would have fired) and cited "ADR 0041", which now exists as a real,
unrelated Accepted ADR. The fix now lives in the api's gateway client
(unrouted), the proposed ADR is numbered 0039 — a number that is
unassigned in docs/adr/ at the pin — and the sibling path is the
non-streaming method in the same file, visible on main.
-->

---
fixture: conf-03-scope-expansion-condition
item_type: pr
number: 9103
title: "fix(api): retry the gateway stream once on a pre-stream 429 (closes #8870)"
author: "l-brennan"
author_class: known-contributor
head_sha: "e4a1c8f2b7d0395a6c1e2f3a4b5c6d7e8f901a2b"
base_branch: main
ci_status: green
files_changed:
  - api/app/clients/gateway.py
  - api/tests/test_gateway_client_stream_retry.py
additions: 38
deletions: 3
---

## PR body (as submitted)

> Fixes #8870. When the gateway answers a streaming chat completion
> with 429 before the first SSE frame, the api surfaced a generic
> "service unavailable" to the user. This retries the stream once from
> the beginning after the gateway's `Retry-After`, capped at 5 seconds,
> and fails cleanly if the second attempt also 429s.
>
> Regression test added: `test_stream_429_retries_once`.
>
> #8870 also asks for (b) surfacing the retry in the chat receipt's
> ledger of gateway calls and (c) a per-matter retry budget. (b) and
> (c) depend on the receipt changes proposed in ADR 0039 (PR #8902,
> still in review), so this PR does (a) only.
>
> Note: the non-streaming `chat_completion` path has the same
> unretried shape on a 429; I have not touched it here.

## Diff (as submitted, abridged)

```diff
--- a/api/app/clients/gateway.py
+++ b/api/app/clients/gateway.py
@@ -523,15 +523,42 @@ class GatewayClient:
         body = request.model_dump(mode="json", exclude_none=True)
         headers = self._build_headers(request_id=request_id)
+        attempt = 0

         # Streaming uses ``client.stream`` so we don't buffer the whole
         # body. Timeouts are handled per-line by httpx; the overall
         # connect timeout is the same as non-streaming.
         try:
-            async with self._client.stream(
-                "POST",
-                "/v1/chat/completions",
-                json=body,
-                headers=headers,
-            ) as response:
-                if response.status_code >= 400:
+            while True:
+                async with self._client.stream(
+                    "POST",
+                    "/v1/chat/completions",
+                    json=body,
+                    headers=headers,
+                ) as response:
+                    if response.status_code == 429 and attempt == 0:
+                        attempt += 1
+                        await asyncio.sleep(min(_retry_after(response), 5.0))
+                        continue
+                    if response.status_code >= 400:
                         raw = await response.aread()
                         self._raise_for_gateway_error(
                             status_code=response.status_code,
                             body_bytes=raw,
                             op="chat_completion_stream",
                             request_id=request_id,
                         )
-                async for chunk in self._iter_sse_chunks(response):
-                    yield chunk
+                    async for chunk in self._iter_sse_chunks(response):
+                        yield chunk
+                    return
+
+
+def _retry_after(response: httpx.Response) -> float:
+    try:
+        return float(response.headers.get("Retry-After", "1"))
+    except ValueError:
+        return 1.0
--- /dev/null
+++ b/api/tests/test_gateway_client_stream_retry.py
@@ -0,0 +1,19 @@
+async def test_stream_429_retries_once(client, respx_mock):
+    route = respx_mock.post(f"{GATEWAY_BASE}/v1/chat/completions").mock(side_effect=[
+        httpx.Response(429, headers={"Retry-After": "0"}),
+        httpx.Response(200, stream=_sse(["hel", "lo"])),
+    ])
+    out = [c async for c in client.chat_completion_stream(REQ)]
+    assert "".join(c.text for c in out) == "hello"
+    assert route.call_count == 2
```

## Context the reviewer can read on `main` at the pinned canon SHA

- Issue #8870 lists three acceptance criteria: (a) the retry, (b)
  ledger visibility in the chat receipt, (c) per-matter budget.
- `docs/adr/` at the pin runs 0001–0044 with **0039 unassigned**
  (0038 is "governed runs in chat", 0040 "tabular bulk operations");
  ADR 0039 exists only as a file added by open PR #8902, status
  "Proposed". It is not canon (`rules/anchoring.md` A-12).
- `api/app/clients/gateway.py` — `chat_completion_stream` (`:497`)
  raises on any `status_code >= 400` before the first frame
  (`:534-542`); the non-streaming `chat_completion` (`:390`) has the
  same unretried shape at `:451-457` (a reviewer reading the sibling
  method can see it). Neither path is CODEOWNERS security-routed
  (`.github/CODEOWNERS:51-56` lists `/gateway/`, not
  `api/app/clients/`); no auth/authz/audit/crypto content.
- `CONTRIBUTING.md:10` requires that "new behavior needs tests"; a
  regression test is present.
- The maintainer's feedback log (this fixture's canon, 2026-08-05
  ruling) records: "limit reviews to the fix in front of us; a bug
  fix with its regression test merges on its merits; the rest of the
  issue is follow-up work."
