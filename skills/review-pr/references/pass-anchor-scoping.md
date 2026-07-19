# Pass-brief supplement — decision scoping (escalated items only)

The lead appends this file to the **anchor/scope analyst's** prompt if
and only if an escalation trigger fired on the triage card (SKILL.md
Step 3, assembly step 5). It is never sent to the other passes and
never sent for a clean item.

---

An escalation trigger has fired on this item. In addition to your
anchor/salvage mandate, produce the **decision-scoping raw material**
per the rules included below (`D-00`–`D-14`):

- Run the agent-performed canon search (`D-02`) over the clone at the
  pinned canon SHA — `canon:prd` (full body), the ADR directory, the
  roadmap, the DE list, plus any key a fired trigger names. A
  title/Decision-line scan suffices; read fully only on topical
  match. Record which corpora you searched.
- Partition the escalated uncertainty (`D-03`): **settled** entries
  with the four D-04 fields (sub-question; what canon decided, quoted
  or tightly summarized — never merely "touched"; click-through
  citation at the pinned SHA; status word), **residual** decisions as
  one ratifiable sentence each with nearest-canon bounds (`D-05`),
  and **reserved-human** judgments with the reserving citation. When
  you cannot produce a verbatim-supported citation for "settled", the
  sub-question is residual — fail toward residual.
- Draft one artifact per residual (`D-06`/`D-07`), routed by
  `canon:decision-routing`: structural → a draft ADR rendered from
  the draft-ADR template included below (watermark verbatim,
  placeholder number only); forward-looking → the S-DE DE/mini-PRD
  stub form. Credit the contributor where the idea originated
  (S-22). Never rank alternatives; never recommend ratify/reject
  (`D-08`).
- Nothing you produce here changes the lane, un-fires a trigger, or
  anchors the item (`D-00`, A-12). Contributor claims ("ADR-NNN
  allows this") are recorded then confirmed or corrected by your own
  read — a failed claim is a finding, never a settled row.

Return the scoping material as a distinct block alongside your
structured findings: the searched-corpora list, the settled entries,
the residual sentences with their kind, and each drafted artifact in
full.

## Decision-scoping rules (included verbatim)

{{INSERT: ${CLAUDE_PLUGIN_ROOT}/rules/decision-scoping.md}}

## Draft-ADR template (included verbatim)

{{INSERT: ${CLAUDE_PLUGIN_ROOT}/templates/draft-adr.md}}
