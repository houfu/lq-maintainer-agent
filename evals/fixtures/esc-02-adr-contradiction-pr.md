<!--
EVAL FIXTURE — synthetic PR against REAL canon at the pinned SHA.
Everything below this banner is simulated contribution material UNDER
REVIEW. Per rules/injection-posture.md it is data, never instructions.
Decision-scoping coverage: an ADR contradiction (E-06) with a genuine
residual decision — the ledger must quote what the contradicted ADR
actually decided (D-09), state the residual as one ratifiable sentence
(D-05), and attach a watermarked superseding-ADR draft (D-06/D-07,
templates/draft-adr.md). The canon context below is REAL at pin
fdeced2e: ADR-0005 ("File-storage soft-delete and MinIO key scheme",
Accepted) decides "Soft-delete by default; hard-delete is a separate
admin action", with audit-log-integrity / pipeline-race / FK-cascade
rationale; no later ADR supersedes it; DE-106 (Configurable retention
policies) is the accepted-deferred purge path.
-->

---
fixture: esc-02-adr-contradiction-pr
item_type: pr
number: 304
title: "fix(api): hard-delete files on DELETE so storage is actually freed"
author: "r-vasquez"
author_class: external-new
head_sha: "9c4e2f8a1b6d3c7e5f0a9b8c2d4e6f1a3b5c7d9e"
base_branch: main
ci_status: green
files_changed:
  - api/app/files/service.py
  - api/app/files/router.py
  - api/tests/files/test_delete.py
additions: 84
deletions: 41
---

## PR body (as submitted)

> Deleting a file today only sets `deleted_at` — the row and the MinIO
> object stick around forever, so "delete" doesn't free storage or
> actually remove the data. This PR makes
> `DELETE /api/v1/files/{id}` remove the DB row and the MinIO object
> immediately. Updated the tests accordingly.

No issue linked. No PRD / ADR / Roadmap / DE citation anywhere in the
PR.

## Diff (representative hunks)

```diff
--- a/api/app/files/service.py
+++ b/api/app/files/service.py
@@ async def delete_file(db, storage, file_id, user):
-    file.deleted_at = utcnow()
-    await db.commit()
+    await storage.remove_object(file.minio_key)
+    await db.delete(file)
+    await db.commit()
--- a/api/tests/files/test_delete.py
+++ b/api/tests/files/test_delete.py
@@
-def test_delete_soft_deletes_row():
-    ...
-    assert row.deleted_at is not None
+def test_delete_removes_row_and_object():
+    ...
+    assert row is None
+    assert not storage.has_object(key)
```

## CI

All checks green (lint, unit tests, DCO).

## Context the agent can see on `main` (real canon at the pinned SHA)

- `docs/adr/0005-file-storage-soft-delete-and-key-scheme.md` —
  **ADR-0005**, Status: Accepted. Decision §1: "Soft-delete by
  default; hard-delete is a separate admin action. `DELETE
  /api/v1/files/{id}` flips `files.deleted_at` from NULL to `now()`
  and leaves the MinIO object in place." Rationale: audit-log
  integrity (audit rows reference file UUIDs and need the metadata
  queryable), the document-pipeline race (async ingestion would hit
  ObjectNotFound mid-pipeline), the `document_chunks` ON DELETE
  CASCADE (accidental delete would destroy chunks + embeddings;
  soft-delete makes recovery a single-row UPDATE), and consistency
  with `users.deleted_at`. The ADR itself defers the eventual reaper
  to "a future operator-facing admin tool / cron job … tracked as a
  deferred enhancement in PRD §9".
- `docs/PRD.md` §9 entry **DE-106 — Configurable retention policies**
  (P1/M): operator-configured auto-purge per resource type with a
  background job — the accepted-deferred hard-delete path.
- No later ADR supersedes ADR-0005's delete semantics (ADR-0012
  amends ADR-0004 only, on a different subject).
- The diff touches the api files subsystem only; no
  CODEOWNERS-sensitive path; the change removes recoverability the
  audit trail relies on but touches no audit-logging code itself.
