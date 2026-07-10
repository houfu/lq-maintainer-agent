<!--
TEMPLATE: receipt-issue.md — Triage Receipt, issue profile (design §7, §8).

Fill conventions (remove this comment block from rendered output; the
machine-readable footer at the end MUST be kept):
- {{placeholders}} are filled by the skill at render time.
- Sections marked "OMIT-IF-NOT-APPLICABLE" are deleted entirely when
  they do not apply; never render them empty.
- The "Human-only judgments" checkboxes are PERMANENTLY OPEN; the agent
  never renders them checked or omits them.
- Update-in-place (§8.4): edit the prior receipt comment when one
  exists; one living receipt per issue.
- HARD CARVE-OUT (§8.3): a vulnerability-suspect issue gets NO public
  receipt at all — not this template, not a redacted version. The only
  output for that classification is the drafted private-advisory
  redirect (templates/contributor-responses/vulnerability-redirect.md).
  The agent never elaborates exploit detail in any output.
-->

## Triage Receipt — Issue #{{issue_number}}: {{issue_title}}

> Produced by lq-maintainer-agent v{{agent_version}}. The agent
> recommends, drafts, and reports; a human maintainer decides, every
> time. This receipt is the shared review state for this issue and is
> updated in place across sessions.

### Classification

| | |
|---|---|
| **Classification** | {{bug / feature / question}} |
| **Confidence** | {{high / medium / low}} |
| **Assigning rule** | `{{classification_rule_id}}` — {{one-line quote of the rule, from rules/issues.md}} |
| **Recommended lane** | {{standard / escalate}} — `{{assigning_rule_id}}` {{lane rule from rules/lanes.md, or the fired E-NN trigger(s)}} |
| **Severity suggestion** | {{for bugs; otherwise "n/a"}} |
| **Suggested routing** | {{e.g. "EASIEST-CONTRIBUTIONS / P1", "Discussions", "DE-promotion pipeline", "keep as bug"}} |

### Duplicate search performed

Searched against **open issues AND the DE-XXX list** (rules/canon-map.md
routes to the DE list's location in lq-ai).

- **What was searched:** {{search terms / labels / subsystems queried, one line each}}
- **What matched:**
  - {{`#NNN` or `DE-NNN` — one-line relationship: exact duplicate / overlaps part P2 / related background}}
  - {{…or "no matches found"}}
- **Duplicate verdict:** {{not a duplicate / duplicate of #NNN (drafted cross-reference attached) / partially covered by DE-NNN}}

### Repro assessment

<!-- OMIT-IF-NOT-APPLICABLE: delete this section for non-bug classifications. -->
- **Repro completeness:** {{complete / partial / absent}}
- **Present:** {{what the filer already gave us — versions, steps, expected/actual, logs}}
- **Missing:** {{the specific pieces needed, each phrased so a non-engineer can supply it}}
- **Subsystem pointers:** {{likely lq-ai files/modules involved, repo-relative paths}}
- **Drafted repro request:** rendered from
  templates/contributor-responses/repro-request.md, attached in the
  session output. A human edits and posts it.

### Salvage decomposition

<!-- OMIT-IF-NOT-APPLICABLE: delete this entire section when the issue does not overreach. -->
Applied per rules/salvage.md — decomposing the idea now means the
400-line PR never gets written.

| Part | Description (one sentence) | Disposition | Path forward |
|---|---|---|---|
| P1 | {{…}} | {{S-ACCEPT accept as-is / S-DOCS redirect to docs / S-DE preserve as drafted DE-XXX or mini-PRD stub crediting the contributor / S-DUP duplicate (cross-referenced) / S-DECLINE decline}} | {{…}} |

**Drafted split** (humans file everything):

- **Split issue 1 — title:** {{drafted title}}
  **Body:** {{drafted body, or pointer to the attached draft in session output}}
- **Split issue 2 — title:** {{…}}

**Drafted contributor response:** rendered from
templates/contributor-responses/salvage-partial-accept.md, attached in
the session output, leading with what is kept.

### Coverage statement

**Covered:**
- {{item, e.g. "classification", "duplicate search (open issues + DE list)"}}

**Explicitly not covered:**
- {{item + why, e.g. "severity confirmation against production telemetry — no such access"}}
- **Runtime behavior — never checked.** The agent does not execute any
  contributed code or attempt to reproduce bugs by running anything
  (§10); repro assessment above is a reading of the report, not a
  reproduction.

### Reviewed at

- **Canon SHA (lq-ai `main`):** `{{canon_sha}}`
- **Agent version:** `{{agent_version}}`

### Human-only judgments — never auto-resolved

Rendered open by every version of this template and every update of
this receipt; only a human maintainer may check them, by hand.

- [ ] **Worth roadmap space** — should this occupy roadmap/DE space at
  all, against everything else competing for it?
- [ ] **Contributor-engagement tone** — is the drafted response the
  relationship we want with this contributor? (Tone is edited and owned
  by the posting human.)

<!-- lq-maintainer-agent:receipt — machine-readable state. Do not remove.
A later /triage session parses this block to resume (§8.4).
{
  "receipt_schema_version": 1,
  "profile": "issue",
  "item": "legalquants/lq-ai#456",
  "classification": "bug",
  "classification_rule": "C-01",
  "lane": "standard",
  "assigning_rule": "L-30",
  "confidence": "high",
  "triggers_fired": [],
  "duplicates_matched": ["#123", "DE-041"],
  "canon_sha": "1111111111111111111111111111111111111111",
  "agent_version": "0.1.0",
  "findings": [
    {
      "id": "F1",
      "file": "n/a",
      "line": 0,
      "severity": "info",
      "disposition": "relayable",
      "status": "open"
    }
  ],
  "coverage": {
    "classification": "done",
    "duplicate_search": "done",
    "repro_assessment": "pending",
    "runtime_behavior": "never-checked"
  }
}
-->
