<!--
TEMPLATE: digest.md — batch triage output (design §5, §7, §13).

Fill conventions (remove this comment block from rendered output):
- {{placeholders}} filled at render time.
- Sections with no items render with a single line "None this run."
  rather than being omitted — an empty section is information.
- Every fast-lane line MUST name its assigning rule and MUST end with
  "merge candidate — human click required." — no exceptions, no
  abbreviation of that phrase.
- Standard cards use templates/triage-card.md in compact form.
- The digest is in-chat output; it carries no machine footer. Receipts
  hold the shared state.
-->

# Triage Digest — {{repo}} — {{date}}

Canon `{{short_canon_sha}}` · agent v{{agent_version}} ·
{{n_prs}} PRs and {{n_issues}} issues examined
{{scope note, e.g. "(all open)" or "(--since {{date}})"}}

## Fast lane

One line per item; each is a recommendation only — every merge is a
human click, and the drafted squash-merge message with the audit
trailer (templates/merge-message.md) is attached per item.

- PR #{{n}} {{title}} — {{one-line basis, e.g. "dependabot lockfile-only
  patch bump, no sensitive paths, CI green"}} — rule
  `{{assigning_rule_id}}` — merge candidate — human click required.
- PR #{{n}} {{…}} — rule `{{assigning_rule_id}}` — merge candidate —
  human click required.

## Docs lane

- PR #{{n}} {{title}} — {{one line: placement / truthfulness vs
  HONEST-STATE / register / docs-vs-code / link-hygiene verdicts}} —
  rule `{{assigning_rule_id}}` — {{recommended action}}

## Standard lane

<!-- one compact card per item, from templates/triage-card.md -->
{{compact triage cards}}

## Escalations — committee packets

Packets are drafted per templates/committee-packet.md and routed to the
committee destination; only pointers appear here.

- PR/Issue #{{n}} {{title}} — triggers: {{trigger IDs}} — packet:
  {{where the drafted packet is in this session's output / where it was
  routed}} — awaiting: {{the human question, one line}}

## Issue classifications

- #{{n}} {{title}} — {{bug / feature / question / vulnerability-suspect}}
  (rule `{{assigning_rule_id}}`) — {{one line: duplicate verdict,
  repro state, or drafted next step. For vulnerability-suspect: "drafted
  private-advisory redirect attached — no public receipt, no detail
  here."}}

## Stale sweep

Drafted comments attached in session output; humans post everything.

- #{{n}} {{title}} — stale {{n}} days — drafted:
  {{status-check comment / close-with-pointer to {{citation}}}}

---
**Human queue from this digest:** {{n_fast}} merge clicks ·
{{n_posts}} drafted comments/receipts awaiting approval ·
{{n_packets}} packets to forward · {{n_deep}} candidates for
`/review-pr`
