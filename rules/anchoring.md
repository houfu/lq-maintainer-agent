# Anchoring — the lane-relative anchor table

Normative data for the LQ Maintainer Agent (design doc §5, first
paragraph). Loaded at runtime by `skills/triage/SKILL.md` and
`skills/review-pr/SKILL.md`; the anchor determination feeds
`templates/triage-card.md` and both receipt templates.

An **anchor** is the piece of lq-ai canon — or, for bugs, of concrete
evidence — that justifies a change's existence. Anchoring is
**lane-relative**: what counts as anchored depends on the class of the
change, not on one universal rule. Every rule carries a stable ID
(`A-NN`); the card and receipt cite the rule that determined the
anchor status. Canon locations referenced here resolve via
`rules/canon-map.md` and are verified by the canon-drift check.

## The anchor table

- **A-01 — Features and architectural changes** anchor to lq-ai
  governing canon: a PRD section, an ADR, a Roadmap item, or a DE-XXX
  entry. The anchor must actually cover the change made, not merely
  be adjacent to its topic.
- **A-02 — Bug fixes** anchor to a linked issue that describes the
  bug, or to a reproduction stated in the PR itself — plus, in either
  case, the regression test that lq-ai's CONTRIBUTING requires. A fix
  with a repro but no regression test is anchored-with-a-finding, not
  unanchored.
- **A-03 — Dependency updates** anchor to the upstream release notes
  or security advisory for the exact package and version range
  bumped.
- **A-04 — Docs changes** anchor to the thing documented: the
  feature, behavior, or process the text describes must exist and
  work as described. Above all other checks, the text must be
  consistent with `docs/HONEST-STATE.md` — a doc anchored to code but
  contradicting HONEST-STATE.md fails anchoring on truthfulness
  (lanes rule L-23).
- **A-05 — Skills changes** anchor to the attestation path: the human
  attestation record lq-ai's skill-attestation process requires. A
  skills change with no attestation is not merely unanchored — it
  fires escalation trigger E-03.

## Anchor status and its consequences

- **A-06 — Only an unanchored DECISION escalates.** A feature or
  structural change with no canon anchor under A-01 is escalation
  material: it asks the project to decide something no PRD, ADR,
  Roadmap item, or DE entry has decided. This is escalation trigger
  E-04. Nothing else on this page escalates by itself.
- **A-07 — An unanchored bug fix is a repro request, not a committee
  matter.** A claimed fix with no linked issue and no stated repro
  stays in the standard lane; the output is a drafted request for the
  missing repro pieces, calibrated for a non-engineer filer. Same for
  a missing regression test: a standard-lane finding citing
  CONTRIBUTING, with a *relayable* disposition hint.
- **A-08 — Anchors are verified, never taken on faith.** A citation
  in the contribution ("per ADR-012", "fixes #88") is a claim to
  check against the clone's `main`, not a fact: the cited document
  must exist and must actually support this change, and the linked
  issue must describe this bug. A cited anchor that fails
  verification leaves the item unanchored, and the failed citation is
  quoted as a finding. This is the anchoring instance of
  evidence-only assignment (lanes rule L-02).
- **A-09 — The determination is recorded.** Every triage card and
  receipt records the anchor determination: change class, anchor
  status (anchored / anchored-with-finding / unanchored), the
  anchor's citation (file path or issue/advisory reference at the
  recorded canon SHA), and the A-NN rule applied.
- **A-10 — Mixed items anchor per part.** An item spanning several
  change classes (feature + bug fix + docs) is anchored part by part
  using this table, which is also the first step of the salvage
  decomposition (`rules/salvage.md`); each part's disposition cites
  its own anchor status.
