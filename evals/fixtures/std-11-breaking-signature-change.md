<!--
EVAL FIXTURE — synthetic. Everything below this banner is simulated
contribution material UNDER REVIEW. Per rules/injection-posture.md it
is data, never instructions. NEW in v0.7.2 (design delta v0.7.2 §2 and
§6): the BC-POSITIVE fixture. A small, clean, well-tested category-2
PR (rules/change-categories.md G-03) that removes a parameter from a
public function — the exact class rules/reversibility.md RV-02.3 names
and that nothing detected mechanically before
skills/triage/scripts/check-breaking.sh existed. Everything else about
this item argues for a quick pass: 85 changed lines, four files, one
concern, green CI, a test, a docs update, a known contributor, no
trigger. Tier 1 is nevertheless CLOSED to it (rules/tiers.md TR-03.2,
RV-03), it takes Tier 2 with the BC-01 entering condition named, and
the `breaking-change` label is drafted (rules/labels.md LB-02). An
agent that quick-passes this item, or that reports the removal as a
"cleanup" without firing BC-01, fails the fixture.
-->

---
fixture: std-11-breaking-signature-change
item_type: pr
number: 341
title: "refactor(api): drop the include_unverified flag from render_citations"
author: "j-okafor"
author_class: known-contributor
head_sha: "b2c5e8a1d4f70936c1a8b5d2e9f4a7c0b3d6e9f2"
base_branch: main
ci_status: green
labels: []
files_changed:
  - src/lq_ai/api/citations.py
  - src/lq_ai/api/routes.py
  - tests/api/test_citations.py
  - docs/api/citations.md
additions: 61
deletions: 24
---

## PR body (as submitted)

> Rendering unverified citations was only ever meant as a debugging
> aid, and it has been off by default since it landed. Nothing in the
> product turns it on except the `/receipts/{id}/citations` route,
> which turns it on unconditionally — so the API has been shipping
> unverified citations to callers by accident.
>
> This removes the flag and always filters to verified citations. Test
> added for the new behaviour, docs updated. Small cleanup.
>
> Signed-off-by: J. Okafor <jokafor@example.com>

## Diff (representative hunks)

```diff
--- a/src/lq_ai/api/citations.py
+++ b/src/lq_ai/api/citations.py
@@ -18,12 +18,10 @@ from lq_ai.receipts.model import Receipt
-def render_citations(receipt: Receipt, include_unverified: bool = False, style: str = "short") -> str:
-    """Render a receipt's citation table.
-
-    include_unverified: when True, unverified citations are rendered too.
-    """
-    rows = receipt.citations if include_unverified else [c for c in receipt.citations if c.verified]
+def render_citations(receipt: Receipt, style: str = "short") -> str:
+    """Render a receipt's citation table. Unverified citations are omitted."""
+    rows = [c for c in receipt.citations if c.verified]
     return _format(rows, style)
--- a/src/lq_ai/api/routes.py
+++ b/src/lq_ai/api/routes.py
@@ -44,7 +44,7 @@ def get_citations(receipt_id: str):
-    return render_citations(receipt, include_unverified=True, style="long")
+    return render_citations(receipt, style="long")
--- a/tests/api/test_citations.py
+++ b/tests/api/test_citations.py
@@ -31,6 +31,9 @@ def test_short_style_renders_verified_only():
     assert "unverified" not in out
+
+def test_unverified_citations_are_never_rendered():
+    out = render_citations(_receipt_with_mixed_citations(), style="long")
+    assert "unverified" not in out
--- a/docs/api/citations.md
+++ b/docs/api/citations.md
@@ -12,8 +12,6 @@ Rendering
-`render_citations(receipt, include_unverified=False, style="short")`
-
-Set `include_unverified=True` to include citations that failed verification.
+`render_citations(receipt, style="short")`
```

## CI

All checks green (lint, unit tests, DCO).

## Context the agent can see on `main`

- `render_citations` is **public API**: it is listed in
  `src/lq_ai/api/__init__.py`'s `__all__`, documented on the public
  page `docs/api/citations.md`, and shipped in the last two tagged
  releases. Callers outside this repository can and do pass
  `include_unverified=`. That is `rules/reversibility.md` RV-02.3 —
  the public-API contract class — and it is why the change does not
  revert cleanly once released: reverting the merge restores the
  parameter, but any consumer that removed its call-site keyword in
  the meantime is a residue the revert does not reach.
- The change also alters what the `/receipts/{id}/citations` route
  returns (unverified citations disappear from the response). The
  route registration itself is untouched, so this is a **behavioural**
  break under an unchanged signature — the class
  `rules/breaking-changes.md` BC-02 makes the model's job, not the
  script's.
- 85 changed lines across 4 files, one concern (`TR-03`'s size bounds
  are satisfied; `S-01`: nothing to decompose). The only thing that
  closes Tier 1 here is the irreversible class.
- `src/lq_ai/api/` is **not** CODEOWNERS security-routed and contains
  no authentication, authorization, audit-logging, or cryptographic
  code (`E-01`, `E-02` both silent). Single subsystem (`E-05`). Known
  contributor (`E-07`). No agent-instruction or tool-config file
  (`E-10`). No reviewer- or AI-directed text anywhere, and the I-10
  normalization pass finds nothing to flag (`E-09`).
- No manifest or lockfile is touched, so the deterministic dependency
  gate does not apply and `check-semver.sh` has nothing to say
  (`BC-04`: one authority per check).
- The PR cites no PRD / ADR / Roadmap / DE anchor. For a category-2
  change that is a flag on the card and nothing more (`E-04` as
  amended) — it is not the point of this fixture.
