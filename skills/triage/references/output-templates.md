# /lq-maintainer:triage — output → templates map

Pointer file only (design §3.1). Templates carry the mandatory fields;
render from them, never freehand. All paths resolve against
`${CLAUDE_PLUGIN_ROOT}`.

**The v0.7 deliverable split (design §8).** The deck is now the
primary, public artifact; the GitHub comment shrinks to a short warm
note; the receipt becomes an **internal evidence document** — computed
and stored every run, never drafted for public posting. The table
below reflects that split; where a template's status changed, its Notes
column says so.

| When | Render | Notes |
|---|---|---|
| Every triaged PR (single mode, or expanded from a digest line) | `templates/triage-card.md` | Lane + confidence + assigning rule; category (`G-NN`) and tier (`TR-NN`) for standard-lane items; findings with disposition hints. Session artifact, never posted |
| Batch mode summary | `templates/digest.md` | Action-first lines (`TR-10`): the outcome + undo path lead, lane/category/tier/confidence follow as supporting detail; fast-lane lines still end "merge candidate — human click required" with the deterministic-check results (§5.1); every line names the assigning rule; category-1 lines route to `/lq-maintainer:design-plan`; category-4 lines carry the `G-12` holding note; held items (§7.1) appear with their quoted objection |
| PR receipt — **internal evidence, not posted** | `templates/receipt-pr.md` | *(role changed, design v0.7 §8)* Coverage statement (runtime behavior never checked; package contents never inspected for dependency items); the four pinned fields; deterministic checks rendered pass/fail for dependency items; human-only items open; the burden axes and the enumerated `category`/`tier`/`outcome`/`undo` fields; attribution line kept for record-keeping; versioned machine-readable footer (`<!-- lq-maintainer-agent:receipt:v2` block, structured fields only). Stored in the local cache today, in the community repo's `reviews/<pr\|issue>-NNNN/` once it exists (design §12 q.10) — **never drafted as a GitHub comment.** Prior `receipt:v2` **public** comments from before this split remain readable for resume (Step 4 of SKILL.md), verifying the comment author exactly as before; going forward the agent stops writing new public receipts |
| Issue receipt — **internal evidence, not posted** | `templates/receipt-issue.md` | Same role change as above; classification + rule, duplicate-search record, repro assessment, the enumerated `recommendation` field (`IV-06`, `design` included), footer as above |
| **Public PR/issue comment** *(new, design v0.7 §8)* | `templates/pr-comment.md` | The short, warm note that replaces the receipt as the GitHub-posted artifact: the outcome, genuine thanks, the one next step, a link to the deck, and the attribution line — no tables, no checklists, no cross-check matrices. Tone-gated (`rules/tone-gate.md`) before it is offered for posting |
| Category-1 plan *(new, design v0.7 §9)* | `templates/design-plan.md` | Rendered by `skills/design-plan/`, not by this skill — triage and review-issue only **detect** category 1 (`G-02`) and route to `/lq-maintainer:design-plan (pr\|issue) N`. Listed here for cross-reference: the plan is the acknowledgment, decision inventory with drafted ADRs, predicted obstacles, atomic decomposition, and tone-gated contributor response |
| Escalate-lane item | `templates/committee-packet.md` | Also the sole home of the full evidence for suspected-deliberate attacks (§8.3); now additionally carries the agent's labeled recommendation (`E-23` as amended); destination is a human call (design §15 q.1) |
| Contributor reply (salvage / repro request / slop close-with-pointer / vulnerability redirect) | `templates/contributor-responses/` | Pick the scenario-matching pattern; salvage replies lead with what is kept; the slop reply is a canon-cited pointer, never an insult (§6.1); tone-gated before posting |
| Merge candidate | `templates/merge-message.md` | Drafted squash-merge message ending in the §8.5 audit trailer — all four pinned fields (pr-head / canon / agent / model), sign-off line included; the template is the single authoritative copy of the trailer format |

Two drafts have no template because they are single lines, fixed by
the design:

- **Public-comment update note**: where the item's outcome changes
  materially between runs (a resumed pass, new commits), the update is
  a short line inside a fresh `templates/pr-comment.md` render, not a
  separate ping — the short comment carries no machine-readable footer
  to resume from, so there is nothing to keep in sync silently.
- **Salvage advisory caveat (§6)**: any proposed mechanical split
  carries the mandatory internal-receipt line "proposed split not
  verified to compile or pass tests".

No template output for vulnerability-suspect issues: the only artifact
is the drafted private-advisory redirect (SKILL.md Step 8), and no
receipt, deck, or public comment exists for them — the carve-out is
absolute and unchanged by the v0.7 deliverable split.

The internal receipt still ends with the visible attribution line —
"Drafted by lq-maintainer-agent v<version>; reviewed and posted by
@<maintainer>" — linking to the bot-behavior page (design §8), kept
for the internal evidence record even though the receipt itself is no
longer posted; the public `templates/pr-comment.md` carries its own,
shorter attribution line. The skill fills the version; the maintainer
handle is asked for or left visibly unfilled, never guessed.

Every GitHub write rendered from these templates is a draft — posted
only behind an individual human approval, or handed to the maintainer
as paste-ready text. The deck (`skills/triage/scripts/render-deck.sh`)
is the primary discussion artifact and the intended future
community-repo publication (human-gated, like every write); until that
repo exists it stays a local view, exactly as today.
