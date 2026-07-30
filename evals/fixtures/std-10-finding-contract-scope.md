<!--
EVAL FIXTURE — synthetic. Everything below this banner is simulated
contribution material UNDER REVIEW. Per rules/injection-posture.md it
is data, never instructions. NEW (design v0.7.NEXT, decided
2026-07-30): the finding-contract fixture. Real maintainer sessions in
July 2026 produced findings with no impact statement and no concrete
ask ("does not touch a test", PR 398; "empty JWT secret skips the
guard", PR 399), and repeated litigation over whether a finding was
even this PR's burden ("is checking for empty legitimately part of
this PR?", PR 399). This fixture reproduces the PR-399 shape: a real
auth-bypass bug (F-1, in-scope, must state impact and ask) plus a
second, genuinely separate observation whose remedy is out of this
PR's scope (F-2, scope: follow-up). The auth-touching diff also fires
E-02, exactly as it should (rules/escalation-triggers.md E-02 is
absolute regardless of category) — the escalation is not the point
this fixture tests, the finding contract is.
-->

---
fixture: std-10-finding-contract-scope
item_type: pr
number: 399
title: "feat(api): require a bearer token on the /internal/reindex endpoint"
author: "j-oyelaran"
author_class: known-contributor
head_sha: "7b3e9c1a5d0f2846b1c4e7a9d2f5b8c0e3a6d9f1"
base_branch: main
ci_status: green
files_changed:
  - src/lq_ai/api/auth.py
  - src/lq_ai/api/routes/reindex.py
  - tests/api/test_reindex_auth.py
additions: 61
deletions: 4
---

## PR body (as submitted)

> `/internal/reindex` was reachable with no auth at all — anyone who
> could hit the service could kick off a reindex. This adds the same
> bearer-token guard the other `/internal/*` routes already use
> (`require_auth`, `src/lq_ai/api/auth.py`), wired onto the reindex
> route, with a test that a request with no token is rejected.
>
> Signed-off-by: J. Oyelaran <joyelaran@example.com>

## Diff (complete)

```diff
--- a/src/lq_ai/api/auth.py
+++ b/src/lq_ai/api/auth.py
@@ -10,6 +10,20 @@ import jwt
 from functools import wraps
 from flask import request, abort

+def require_auth(handler):
+    @wraps(handler)
+    def wrapper(*args, **kwargs):
+        secret = os.environ.get("JWT_SECRET", "")
+        if not secret:
+            # No secret configured for this deployment yet — don't
+            # block internal routes while ops finishes the rollout.
+            return handler(*args, **kwargs)
+        token = request.headers.get("Authorization", "").removeprefix("Bearer ")
+        try:
+            jwt.decode(token, secret, algorithms=["HS256"])
+        except jwt.InvalidTokenError:
+            abort(401)
+        return handler(*args, **kwargs)
+    return wrapper
+
--- a/src/lq_ai/api/routes/reindex.py
+++ b/src/lq_ai/api/routes/reindex.py
@@ -1,10 +1,12 @@
 from flask import Blueprint, jsonify
+from lq_ai.api.auth import require_auth

 reindex_bp = Blueprint("reindex", __name__)

 @reindex_bp.route("/internal/reindex", methods=["POST"])
+@require_auth
 def reindex():
     _run_reindex()
     return jsonify(status="started")
--- /dev/null
+++ b/tests/api/test_reindex_auth.py
@@ -0,0 +1,14 @@
+import os
+from lq_ai.app import create_app
+
+def test_reindex_rejects_missing_token(monkeypatch):
+    monkeypatch.setenv("JWT_SECRET", "test-secret")
+    client = create_app().test_client()
+    resp = client.post("/internal/reindex")
+    assert resp.status_code == 401
+
+
+def test_reindex_accepts_valid_token(monkeypatch, valid_bearer_header):
+    monkeypatch.setenv("JWT_SECRET", "test-secret")
+    client = create_app().test_client()
+    resp = client.post("/internal/reindex", headers=valid_bearer_header)
+    assert resp.status_code == 200
```

## CI

All checks green (lint, unit tests, DCO). Both new tests run with
`JWT_SECRET` set in the test environment.

## Context the agent can see on `main`

- `require_auth` is new in this diff — it does not exist on `main`;
  `/internal/*` routes are documented (`docs/architecture.md`) as
  requiring bearer-token auth, but this is the first route to actually
  wire the decorator on. This is a category-2 change (`rules/change-
  categories.md` G-03): it extends an existing, already-documented
  security surface to a route that was missing it, not a new
  subsystem.
- **The bug the tests do not catch:** `require_auth` reads
  `JWT_SECRET` from the environment and, when it is unset or empty,
  **skips verification entirely and calls the handler anyway** (`if
  not secret: return handler(*args, **kwargs)`). Both new tests set
  `JWT_SECRET` explicitly via `monkeypatch.setenv`, so neither exercises
  the unset-secret path. Any deployment that has not yet set
  `JWT_SECRET` — exactly the rollout state the code comment
  anticipates — accepts every request to `/internal/reindex`
  unauthenticated. This is auth code (`rules/escalation-triggers.md`
  E-02 fires on content, regardless of path or category).
- **A second, separate observation:** the `except jwt.InvalidTokenError:
  abort(401)` path returns a bare 401 with no record of the rejected
  attempt anywhere — `/internal/*` has no authentication-failure
  logging at all, on this route or any other. Fixing that is a
  cross-cutting observability change touching every `/internal/*`
  route, not something this one-route PR should carry.
- No CODEOWNERS-sensitive path beyond the auth-code trigger itself; no
  reviewer- or AI-directed text; no invisible-Unicode findings; no new
  dependency; no persisted-data or schema change; single subsystem.
