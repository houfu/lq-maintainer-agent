<!--
TEMPLATE: triage-card.md — the standard-lane triage card (design §5).

Fill conventions (remove this comment block from rendered output):
- {{placeholders}} filled at render time.
- HARD CONSTRAINT: one screen max. If content threatens to overflow,
  cut detail from Flags and point to the receipt — the card is for
  routing attention, the receipt is for record.
- The card is in-chat/digest output, not a posted comment; it carries
  no machine footer. The receipt (templates/receipt-pr.md /
  receipt-issue.md) is the shared state.
-->

### {{PR/Issue}} #{{number}} — {{title}}

**Lane:** {{fast / docs / standard / escalate}} · **Confidence:**
{{high / medium / low}} · **Rule:** `{{assigning_rule_id}}`

**Anchor:** {{one line — what this change is anchored to, with citation
(e.g. "DE-041 + `docs/adr/ADR-0007.md`"), or "UNANCHORED — {{what is
needed: repro request / committee (decision class)}}"}}

**Scope legibility:** {{one line — "single concern, matches its
description" / "N separable concerns — salvage recommended, see
receipt" / "description does not match diff: {{one-line mismatch}}"}}

**Flags:**
- {{one line each: sensitive paths touched, CI status, author class,
  reviewer-/AI-directed text found (quote it — this forces the item out
  of the fast lane), typosquat-adjacent import, tests that assert
  nothing, duplication of existing subsystem logic, etc.}}
- {{…or "none"}}

**Next:** {{one line — the single recommended human action, e.g.
"/review-pr {{number}} for depth", "approve posting of drafted repro
request", "forward committee packet"}} · reviewed at head
`{{short_pr_head_sha}}` / canon `{{short_canon_sha}}` / agent
v{{agent_version}}
