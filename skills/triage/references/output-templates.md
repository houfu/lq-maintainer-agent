# /triage — output → templates map

Pointer file only (§3.1). Templates carry the mandatory fields; render
from them, never freehand. All paths resolve against
`${CLAUDE_PLUGIN_ROOT}`.

| When | Render | Notes |
|---|---|---|
| Every triaged PR (single mode, or expanded from a digest line) | `templates/triage-card.md` | Lane + confidence + assigning rule; findings with disposition hints |
| Batch mode summary | `templates/digest.md` | One line per fast-lane item ending "merge candidate — human click required"; every line names the assigning rule |
| PR receipt draft | `templates/receipt-pr.md` | Coverage statement, both SHAs + agent version, human-only items open, machine-readable footer (`<!-- lq-triage-receipt` block — the template defines the exact format; Step 4 of SKILL.md parses it to resume) |
| Issue receipt draft | `templates/receipt-issue.md` | Classification + rule, duplicate-search record, repro assessment, footer as above |
| Escalate-lane item | `templates/committee-packet.md` | Also the sole home of the full receipt for suspected-deliberate attacks (§8.3); destination is a human call (§15 q.1) |
| Salvage contributor reply | `templates/contributor-responses/` | Pick the scenario-matching pattern; lead with what is kept |
| Merge candidate | `templates/merge-message.md` | Drafted squash-merge message ending in the §8.5 audit trailer, sign-off line included; the template is the single authoritative copy of the trailer format |

No template output for vulnerability-suspect issues: the only artifact
is the drafted private-advisory redirect (SKILL.md Step 7), and no
public receipt exists for them.

Every GitHub write rendered from these templates is a draft — posted
(or updated in place, §8.4) only behind an individual human approval,
or handed to the maintainer as paste-ready text.
