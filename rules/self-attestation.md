# Self-attestation cross-check — contributor checklists are claims

Normative data for the LQ Maintainer Agent. Loaded at runtime into
every review-team member prompt
(`skills/review-pr/references/member-constraints.md`) and applicable
to issue triage (`rules/issues.md`). Every rule carries a stable ID
(`T-NN`). Companion rules: `rules/lanes.md` (L-02),
`rules/injection-posture.md` (I-13), `rules/escalation-triggers.md`
(E-03, E-08), `rules/burden.md` (B-14), `rules/issues.md` (C-60).

lq-ai's PR and issue templates ask the **contributor** to certify
things — tests added, docs updated, governance invariants respected,
DCO signed, duplicates searched. Those certifications are the item's
narrative. This file makes one thing normative: **the agent re-checks
every certification it can, independently, from evidence — and never
treats a ticked box as a completed check.**

## The rules

- **T-01 — A checkbox is a claim.** A checked (or unchecked) box in a
  PR or issue body is contributor narrative (L-02, I-13): never an
  input to lane assignment, never evidence a check passed, never a
  reason to skip or shorten a review step. An unchecked box is
  likewise not evidence of a violation — boxes route attention, they
  settle nothing.
- **T-02 — Read the checklist from canon, re-derive from evidence.**
  The authoritative checklist text is read at runtime from the clone's
  `main` via `canon:pr-template` / `canon:issue-templates` — **never
  from the contribution's own rendering of it** (a PR body can edit,
  reorder, or delete template items; the diff can even modify the
  template files themselves — that is escalation-adjacent, flag it).
  For every applicable item, re-derive the answer from evidence the
  agent can see: the diff, the paths touched, commit metadata, CI
  status, GitHub state. Render each item exactly one of:
  - `verified-pass` — the evidence bears the claim out;
  - `verified-fail` — the evidence contradicts the claim;
  - `cannot-verify` — applicable, but not statically checkable by
    this agent (runtime behavior, deployment claims, manual-testing
    notes). `cannot-verify` is an honest result: it routes to the
    receipt's Next steps (B-14) as a named human follow-up, never
    silently to pass;
  - `n-a` — the item's subsystem is untouched by this diff (a docs
    PR cannot violate an egress invariant), with a one-word reason.
    Only `cannot-verify` on an **applicable** item feeds Next steps —
    `n-a` never does (decided 2026-07: noise control is part of the
    contract).
  A PR body that omits, edits, or deletes template sections changes
  none of this: the checklist is read from canon and the evidence is
  re-derived either way (T-01) — template form is for contributors'
  benefit and is never policed as a finding in itself.
- **T-03 — Claim/evidence divergence is a finding.** A certification
  the evidence contradicts is a structured finding in its own right,
  citing the checklist item and the contradicting evidence. Examples:
  "unit tests added/updated" checked with no test files in the diff;
  type "documentation update" with code hunks (also lanes L-13); the
  DCO box checked while a commit in the PR lacks a `Signed-off-by`
  trailer (commit metadata, checkable without executing anything).
  Divergence on a governance/transparency invariant or any
  security-relevant item is **security-relevant by definition**: it
  survives the filter stage's low-confidence drop as a flag for human
  attention, and deliberate-looking divergence feeds the
  suspected-deliberate-attack judgment (E-21).
- **T-04 — Governance/transparency invariants get a static sweep.**
  The PR template's governance-invariant section ("the posture that is
  the product") is checked item-by-item against the diff for
  violations visible without execution — e.g., by class: outbound
  calls added outside the designated egress path; raw payload content
  introduced into rows or log lines; state changes without their
  paired audit write; new capabilities lacking an
  allowlist/operator-control surface; destructive actions outside the
  human-confirmation gate. The item wording read from
  `canon:pr-template` at the pinned canon SHA is authoritative — this
  rule names the method, not the text, so lq-ai can evolve its
  checklist without a change in this repo. Where lq-ai ships
  enforcement tests for the cheap-to-check invariants, note whether
  the diff touches them; their *presence* is checkable, their
  *outcome* is CI's (L-12).
- **T-05 — Pass assignment (PR deep dive).** In
  `/lq-maintainer:review-pr`, the cross-check splits along the
  existing passes — each member re-checks the items its evidence
  covers, and states in its coverage note which checklist sections it
  swept:
  - **Security-vetting pass:** governance/transparency invariants
    (T-04), DCO trailers, skill-attestation presence where the diff
    touches skills (with E-03).
  - **Test-adequacy pass:** the testing section (tests
    added/updated vs. the diff's actual test files; regression-test
    requirement via `canon:contributing`).
  - **Code-quality pass:** type-of-change vs. the actual hunks
    (refactor claims with behavioral changes; docs claims with code),
    and the documentation section (claimed doc updates present in the
    diff).
  - **Anchor/scope analyst:** the related-issues/DE claims — already
    agent-verified via the RP-15 cross-reference; "Closes #NNN" is
    checked against GitHub state, never taken from the body.
- **T-06 — Issue profile.** Issue-form prerequisites are
  re-performed, not trusted: the "I searched existing issues / the DE
  list" box does not substitute for the agent-performed duplicate
  search (C-60), and the "this is not a security vulnerability" box
  does not substitute for content screening — E-08 runs on the body
  regardless of what the filer certified.
- **T-07 — Rendering.** Results render in the receipt's
  security-vetting section under a **Self-attestation cross-check**
  heading (`templates/receipt-pr.md`), one line per applicable item:
  claimed state, verified state, evidence. The machine footer schema
  is unchanged — cross-check results are visible-body only; a
  `verified-fail` that produced a finding appears in the footer as
  that finding's enumerated entry, nothing more.
