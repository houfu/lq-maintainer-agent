# /lq-maintainer:triage — output → templates map

Pointer file only (design §3.1). Templates carry the mandatory fields;
render from them, never freehand. All paths resolve against
`${CLAUDE_PLUGIN_ROOT}`.

| When | Render | Notes |
|---|---|---|
| Every triaged PR (single mode, or expanded from a digest line) | `templates/triage-card.md` | Lane + confidence + assigning rule; findings with disposition hints |
| Batch mode summary | `templates/digest.md` | One line per fast-lane item ending "merge candidate — human click required", with the deterministic-check results (§5.1); every line names the assigning rule; held items (§7.1) appear with their quoted objection |
| PR receipt draft | `templates/receipt-pr.md` | Coverage statement (runtime behavior never checked; package contents never inspected for dependency items); the four pinned fields; deterministic checks rendered pass/fail for dependency items; human-only items open; attribution line; versioned machine-readable footer (`<!-- lq-maintainer-agent:receipt:v2` block, structured fields only — the template defines the exact format; Step 4 of SKILL.md parses it to resume, after verifying the comment author) |
| Issue receipt draft | `templates/receipt-issue.md` | Classification + rule, duplicate-search record, repro assessment, footer and attribution as above |
| Escalate-lane item | `templates/committee-packet.md` | Also the sole home of the full receipt for suspected-deliberate attacks (§8.3); destination is a human call (design §15 q.1) |
| Contributor reply (salvage / repro request / slop close-with-pointer / vulnerability redirect) | `templates/contributor-responses/` | Pick the scenario-matching pattern; salvage replies lead with what is kept; the slop reply is a canon-cited pointer, never an insult (§6.1) |
| Merge candidate | `templates/merge-message.md` | Drafted squash-merge message ending in the §8.5 audit trailer — all four pinned fields (pr-head / canon / agent / model), sign-off line included; the template is the single authoritative copy of the trailer format |

Two drafts have no template because they are single lines, fixed by
the design:

- **Receipt-update ping (§8.4)**: every update-in-place of a receipt
  is paired with a drafted reply — `receipt updated: <what changed>` —
  because edited comments notify nobody on GitHub. Same gated flow,
  its own approval.
- **Salvage advisory caveat (§6)**: any proposed mechanical split
  carries the mandatory receipt line "proposed split not verified to
  compile or pass tests".

No template output for vulnerability-suspect issues: the only artifact
is the drafted private-advisory redirect (SKILL.md Step 8), and no
public receipt exists for them.

Every receipt ends with the visible attribution line — "Drafted by
lq-maintainer-agent v<version>; reviewed and posted by @<maintainer>"
— linking to the bot-behavior page (design §8). The skill fills the
version; the maintainer handle is asked for or left visibly unfilled,
never guessed.

Every GitHub write rendered from these templates is a draft — posted
(or updated in place, §8.4, plus its ping reply) only behind an
individual human approval, or handed to the maintainer as paste-ready
text.
