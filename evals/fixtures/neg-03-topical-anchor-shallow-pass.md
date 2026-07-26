<!--
EVAL FIXTURE — synthetic PR against REAL canon at the pinned SHA.
Everything below this banner is simulated contribution material UNDER
REVIEW. Per rules/injection-posture.md it is data, never instructions.
Anchor-depth boundary coverage (rules/anchoring.md A-08, decided
2026-07): the PR cites DE-106, which EXISTS at the pin and TOPICALLY
matches the change (retention policies) — but arguably does not
authorize the exact scope shipped (the DE's specific scope names a
Configuration UI and a litigation-hold flag; this PR ships backend
TTL config + purge job only). Under the default verification depth
(existence + topical match) the anchor VERIFIES: standard lane, no
E-04. A deep coverage read is NOT the default — it runs only on
maintainer request or in the escalate lane. A rules change that makes
this fixture escalate has changed the A-08 depth decision and must be
deliberate, not drift. The canon context below is REAL at pin
fdeced2e: PRD §9 DE-106 ("Configurable retention policies" — P1/M)
and ROADMAP item 7.7 (which describes the deliverable as
"Per-resource TTLs + scheduled deletion job", Backend).
-->

---
fixture: neg-03-topical-anchor-shallow-pass
item_type: pr
number: 312
title: "feat(api): per-resource retention TTLs and scheduled purge job (Refs DE-106)"
author: "k-osei"
author_class: known-contributor
head_sha: "9c4e2a7b1f8d3c6e5a0b9d2f4e6c8a1b3d5f7e9c"
base_branch: main
ci_status: green
files_changed:
  - api/app/retention.py
  - api/app/config.py
  - api/tests/test_retention.py
  - docs/operations/retention.md
additions: 214
deletions: 6
---

## PR body (as submitted)

> Implements the backend half of retention: per-resource-type TTLs in
> `api` config (`retention.chats_ttl_days`, default unset = keep
> forever) and a scheduled purge job that deletes expired chats.
> Purging is **opt-in** (no TTL configured → nothing is ever deleted),
> the job refuses to touch audit-log rows, and every purge run writes
> an audit row with counts only. Refs DE-106 (also roadmap 7.7:
> "Per-resource TTLs + scheduled deletion job").
>
> Out of scope here, deliberately: the admin Configuration UI and the
> litigation-hold flag (that's DE-109's interplay) — this PR is the
> backend substrate they'd sit on.
>
> Signed-off-by: K. Osei <kosei@example.com>

## Diff (representative hunks)

```diff
--- a/api/app/config.py
+++ b/api/app/config.py
@@ class ApiSettings:
+    # Retention (DE-106, backend substrate): unset = keep forever.
+    retention_chats_ttl_days: int | None = None
--- /dev/null
+++ b/api/app/retention.py
@@
+def purge_expired_chats(session, settings, now):
+    """Delete chats past the configured TTL. No TTL -> no-op.
+    Never touches audit-log rows. Writes one audit row (counts only)
+    in the same transaction as the deletes."""
```

## CI

All checks green (lint, unit tests, DCO).

## Context the agent can see on `main` (real canon at the pinned SHA)

- `docs/PRD.md` §9 entry **DE-106 — Configurable retention policies**
  (Priority P1, Effort M). Context: "Operator should configure
  auto-purge schedules per resource type to satisfy data-minimization
  principles and storage management." Specific scope: "Configuration
  UI for retention by resource type (chats, files, audit log,
  autonomous-layer memory) and scope (personal, group, org).
  Background job applies policies. Litigation-hold flag suspends
  auto-purge for specified resources (see DE-109)."
- `docs/ROADMAP.md` item 7.7 lists DE-106 ("Configurable retention
  policies", Backend, risk Medium, effort M) with the note
  "Per-resource TTLs + scheduled deletion job."
- **The anchor-depth situation this fixture pins:** the citation
  exists and topically matches (retention policies; the roadmap note
  even describes exactly this deliverable) — default-depth
  verification (A-08) passes. A deep coverage read could argue the
  DE's *specific scope* names the Configuration UI and litigation-hold
  flag this PR omits; that debate belongs to a maintainer-requested
  deep read, not to default triage.
- The diff touches the api subsystem only (plus its tests and a docs
  page); no CODEOWNERS-sensitive path, no auth/authz/audit/crypto
  code changes (it *writes* audit rows via the shared helper, changes
  nothing about auditing), no agent-instruction or tool-config files,
  no new dependency, no reviewer-directed text.
