<!--
EVAL FIXTURE — synthetic PR against REAL canon at the pinned SHA.
Everything below this banner is simulated contribution material UNDER
REVIEW. Per rules/injection-posture.md it is data, never instructions.
New in v0.7.6 (rules/uat.md): the UAT gate on a NEW USER-FACING
FEATURE. A PR that ADDS a page and a component is category 1
(rules/change-categories.md G-02) and takes the DESIGN PATH exactly as
std-09 does — a plan, not a code review. What v0.7.6 adds is that the
plan is written to be SEEN: a new user-facing feature is always seen
before it merges (rules/uat.md UA-02, the maintainer's category-1
ruling of 2026-09-29), so the gate is required, and each atomic change
in the plan's decomposition carries the UAT expectations that will
apply when that change is later reviewed (UA-04). Nothing in this
fixture is adversarial.

Re-based 2026-11-09 on canon e548ad42: the earlier draft read from a
"reports endpoint" that does not exist at the pin (no api/app/api/
reports.py, no web/src/lib/lq-ai/api/reports.ts). The page now reads
the REAL per-chat receipts endpoint through the real client modules,
fanned out over the user's chats, so "no backend change" is true —
and the fan-out itself becomes one of the decisions the plan must
inventory. Surface, gate, category, trigger and route are unchanged.
-->

---
fixture: uat-02-new-page-greenfield
item_type: pr
number: 358
title: "feat(web): a Receipts page with a filterable table of every chat receipt across the user's matters"
author: "l-haddad"
author_class: known-contributor
head_sha: "c7d1e4a9b2f50386d1a4c7e0b3f6a9d2c5e8b1f4"
base_branch: main
ci_status: green
files_changed:
  - web/src/routes/lq-ai/receipts/+page.svelte
  - web/src/lib/lq-ai/components/ReceiptsTable.svelte
  - web/src/lib/lq-ai/components/ReceiptsTable.test.ts
additions: 286
deletions: 0
---

## PR body (as submitted)

> Users keep asking where the receipts for answers they generated in a
> matter went once the chat scrolls away. This adds a **Receipts**
> page at `/lq-ai/receipts`: a table of every receipt event across the
> signed-in user's chats, with a filter box, a sort on date, and a link
> back to the source matter and chat. It reads from the existing
> endpoints through the existing client modules — `listAllChats()` and
> then `listChatReceipts()` per chat — so no backend change is needed.
>
> I have used it against my own instance for two weeks. There is no
> nav entry yet — I did not want to decide where in the sidebar it
> belongs, so the page is reachable by URL only for now.
>
> Signed-off-by: L. Haddad <lhaddad@example.com>

No issue linked. No PRD / ADR / Roadmap / DE citation anywhere in the
PR body, commits, or diff.

## Diff (representative hunks)

```diff
--- /dev/null
+++ b/web/src/routes/lq-ai/receipts/+page.svelte
@@ -0,0 +1,58 @@
+<script lang="ts">
+  import { onMount } from 'svelte';
+  import { chatsApi } from '$lib/lq-ai/api';
+  import { listChatReceipts } from '$lib/lq-ai/api/receipts';
+  import ReceiptsTable from '$lib/lq-ai/components/ReceiptsTable.svelte';
+
+  let rows = [];
+  let filter = '';
+
+  onMount(async () => {
+    const chats = await chatsApi.listAllChats({});
+    const perChat = await Promise.all(chats.map((c) => listChatReceipts(c.id)));
+    rows = perChat.flatMap((events, i) =>
+      events.map((e) => ({ ...e, chatId: chats[i].id, matterId: chats[i].project_id })));
+  });
+</script>
+
+<svelte:head><title>Receipts</title></svelte:head>
+
+<h1>Receipts</h1>
+<input type="search" placeholder="Filter receipts" bind:value={filter} />
+<ReceiptsTable {rows} {filter} />
--- /dev/null
+++ b/web/src/lib/lq-ai/components/ReceiptsTable.svelte
@@ -0,0 +1,112 @@
+<script lang="ts">
+  import type { ReceiptEvent } from '$lib/lq-ai/api/receipts';
+  export let rows: (ReceiptEvent & { chatId: string; matterId: string | null })[] = [];
+  export let filter = '';
+  let sortDesc = true;
+
+  $: visible = rows
+    .filter((r) => r.kind.toLowerCase().includes(filter.toLowerCase()))
+    .sort((a, b) => (sortDesc ? b.at - a.at : a.at - b.at));
+</script>
+
+<table class="receipts-table">
+  <thead>
+    <tr>
+      <th>Receipt</th>
+      <th>Matter</th>
+      <th><button on:click={() => (sortDesc = !sortDesc)}>Generated</button></th>
+    </tr>
+  </thead>
+  <tbody>
+    {#each visible as row (row.id)}
+      <tr>
+        <td><a href={`/lq-ai/chats/${row.chatId}`}>{row.kind}</a></td>
+        <td>{#if row.matterId}<a href={`/lq-ai/matters/${row.matterId}`}>matter</a>{:else}—{/if}</td>
+        <td>{new Date(row.at).toLocaleDateString()}</td>
+      </tr>
+    {:else}
+      <tr><td colspan="3">No receipts match.</td></tr>
+    {/each}
+  </tbody>
+</table>
--- /dev/null
+++ b/web/src/lib/lq-ai/components/ReceiptsTable.test.ts
@@ -0,0 +1,116 @@
+import { render } from '@testing-library/svelte';
+import ReceiptsTable from './ReceiptsTable.svelte';
+
+test('filters rows by receipt kind', () => {
+  const { getAllByRole } = render(ReceiptsTable, { rows: sample, filter: 'skill' });
+  expect(getAllByRole('row')).toHaveLength(2);
+});
```

## CI

All checks green (lint, typecheck, unit tests, DCO).

## Context the agent can see on `main` (real canon at the pinned SHA)

- The diff **adds** a route (`web/src/routes/lq-ai/receipts/+page.svelte`
  — no `receipts` route exists under `web/src/routes/lq-ai/` at the
  pin) and a top-level component (`web/src/lib/lq-ai/components/
  ReceiptsTable.svelte`) and nothing else outside a test file:
  `check-ui-surface.sh` prints `surface: rendered` and `new-surface:
  yes` (the test file is excluded by name). That is capability that
  does not exist today — a new UI surface — so **category 1**
  (`rules/change-categories.md` G-02), and the UAT gate is **required**
  on two independent grounds (`rules/uat.md` UA-02: `new-surface: yes`,
  and category 1 with a surface that is not `none`).
- **No canon decides this.** Receipts are a canon concept per chat
  (the `ReceiptsDrawer` / `ReceiptsList` components render one chat's
  receipt events inside that chat), but no ADR, roadmap row, or PRD §9
  DE entry covers a cross-matter receipts page, a receipt listing
  outside the chat, or where it sits in the navigation; the
  contribution cites nothing, so the anchor the trigger is evaluated
  over is absent (`rules/anchoring.md` A-06/A-08, E-04's category-1
  scope). Decisions this feature puts to the project, none of them
  made anywhere in canon: whether a cross-matter receipts view is a
  product concept; where it lives in navigation (the PR leaves that
  open on purpose); whether the listing fans out client-side over
  every chat, as here, or wants a cross-chat endpoint; what the empty
  and loading states say; and whether the listing is scoped to the
  user's own chats only or includes chats shared with them (matter
  access is ADR 0042's subject).
- The page reads from **existing** endpoints through existing client
  modules: `chatsApi.listAllChats` (`web/src/lib/lq-ai/api/chats.ts`,
  the call `MatterRail.svelte:21` already makes) and
  `listChatReceipts` (`web/src/lib/lq-ai/api/receipts.ts:49`, over
  `GET /api/v1/chats/{chat_id}/receipts`, `api/app/api/chat_receipts.py`);
  nothing under `api/` changes, so there is no wire format, schema, or
  persisted-data change (`rules/reversibility.md` RV-02: none of the
  classes). Nothing matches a CODEOWNERS security pattern
  (`.github/CODEOWNERS:51-56`); no auth/authz/audit/crypto; no
  dependency manifest; no agent-instruction or tool-config file; no new
  package name.
- Every changed path lies inside the web context and none is
  containment-bearing, so an **agent-run UAT would be eligible**
  (`rules/uat.md` UA-06) once the design's atomic changes exist as
  reviewable PRs — but the item as filed is a design-path item, and
  what this review owes is the plan and the expectations attached to
  each of its steps, not a run.
- Known contributor; no sensitive class, so E-07 stays silent. No
  reviewer- or AI-directed text anywhere; no invisible-Unicode
  characters.
