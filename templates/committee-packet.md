<!--
TEMPLATE: committee-packet.md — escalation packet (design §5 escalate
lane, §3.5, §8.3).

Fill conventions (remove this comment block from rendered output):
- {{placeholders}} filled at render time.
- Every trigger row quotes the rule text verbatim from
  rules/escalation-triggers.md — the committee judges against the rule
  as written, not a paraphrase.
- The "Questions for the committee" are phrased as QUESTIONS — the
  packet asks, it never recommends a verdict.
- For suspected-deliberate attacks, the packet additionally contains
  the full receipt content that was withheld from the public comment.
-->

> **Routing note.** This packet goes to the committee's
> access-controlled destination. Which destination that is (Discussion
> category / label + board / Slack) is an open governance decision —
> design §15 q.1; the agent drafts the packet either way and a human
> forwards it. Because that destination also carries all sensitive
> review state (§3.5), it must be access-controlled: **the full receipt
> for a suspected-deliberate attack exists ONLY here** (§8.3 carve-out
> — the public comment says only "escalated for security review"), so
> nothing in this packet may be pasted into a public thread.

# Committee Packet — {{PR/Issue}} #{{number}}: {{title}}

Drafted by lq-maintainer-agent v{{agent_version}} · reviewed at
{{"pr-head `{{pr_head_sha}}` / " if PR}}canon `{{canon_sha}}` ·
{{date}}

## Scope statement

{{Two to four sentences: what this item changes or asks for, in plain
terms; who the author is (author class, not identity judgment); what
part of lq-ai it touches; why it could not be resolved in a lower
lane.}}

## Triggers fired

| Trigger | Rule text (verbatim) | Evidence in this item |
|---|---|---|
| `{{trigger_id}}` | "{{exact sentence(s) from rules/escalation-triggers.md}}" | {{file/path/line or quoted text that fired it}} |
| `{{trigger_id}}` | "{{…}}" | {{…}} |

## Canon position

- **Canon touched:** {{lq-ai docs/ADRs/DE entries this item implements
  or modifies, with citations — or "none"}}
- **Canon contradicted:** {{ADR/governance invariants this item
  conflicts with, citation + one-line nature of the conflict, and
  whether any superseding ADR exists — or "none"}}
- **Canon absent:** {{the decision this item embodies that no PRD /
  ADR / Roadmap / DE entry covers — the unanchored-decision core, if
  that is why we are here — or "none"}}

## Checklist results

Security-vetting checklist per
`docs/security/external-contribution-vetting.md`, run against the diff
(never the self-description). ✅ pass · ❌ fail · ➖ n/a.

| Check | Result | Note |
|---|---|---|
| {{check name}} | {{✅ / ❌ / ➖}} | {{one-line evidence}} |

## Withheld receipt content

<!-- OMIT-IF-NOT-APPLICABLE: delete this section unless this is a
suspected-deliberate attack whose full receipt was withheld from the
public comment (§8.3). -->
The public comment on this item reads only "escalated for security
review." The full receipt follows and lives only in this packet — do
not teach an attacker to hide better.

{{full rendered receipt content, per templates/receipt-pr.md or
receipt-issue.md, including its machine footer}}

## Questions for the committee

Phrased as questions; the packet does not recommend a verdict.

1. {{e.g. "Does lq-ai want to make the architectural decision this PR
   embodies — and if so, should it enter the canon as an ADR before or
   instead of this implementation?"}}
2. {{e.g. "Does this author's class plus the sensitivity of the touched
   paths warrant the full-checklist condition on their future PRs?"}}
3. {{…}}

**What the agent can do next on your answer:** {{one line per possible
answer, e.g. "if 'yes, ADR first' — draft the ADR stub crediting the
contributor; if 'decline' — draft the canon-cited decline response."}}
All follow-up outputs are drafts; a human posts, files, and decides.
