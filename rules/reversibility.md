# Reversibility — conservatism attaches to irreversibility, not uncertainty

Normative data for the LQ Maintainer Agent (design doc v0.7 §5).
Loaded at runtime by `skills/triage/SKILL.md`,
`skills/review-pr/SKILL.md`, and `skills/design-plan/SKILL.md`.
Every rule carries a stable ID (`RV-NN`). Companion rule sets:
`rules/tiers.md` (TR-NN), `rules/burden.md` (B-NN),
`rules/escalation-triggers.md` (E-NN), `rules/canon-map.md` for path
routing.

The v0.6 posture graded every uncertainty up (`B-11` everywhere).
v0.7 replaces that with a sharper question: **how expensive is it to
be wrong?** Where being wrong is cheap and cleanly undoable, the
agent recommends action and says exactly what the undo is. Where
being wrong cannot be undone, the full fail-closed discipline
remains, unchanged. Uncertainty itself is never answered with an
inflated grade — it is answered with the named check that resolves
it.

## The principle

- **RV-01 — Grade the cost of being wrong, not the fear of the
  unknown.** Every recommendation is made against the change's
  **undo cost**. A revertible change with an unknown does not become
  "high risk"; it becomes a recommendation with a named residual
  check and a stated undo. An irreversible change with an unknown
  stays fail-closed (RV-03).

## The irreversible classes

- **RV-02 — Enumerated irreversible classes.** A change is
  irreversible-class if it touches any of the following — by path or
  by content, whichever catches it:
  1. **Auth / authz / audit / crypto** (the E-02 surface): a leaked
     credential or a silently-weakened check cannot be unleaked or
     retro-enforced.
  2. **Data handling, storage schemas, and migrations**: migrated or
     deleted data does not come back with `git revert`; privacy
     exposure is permanent.
  3. **Public API contracts and wire formats**: once consumed by
     clients, a contract is a commitment; reverting it breaks the
     consumers the mistake invited.
  4. **CI / workflow files and agent-instruction / tool-config
     files** (the E-01 `.github/workflows/**` and E-10 surfaces):
     they execute with elevated credentials on arrival.
  5. **New dependencies** (any new package name, F-04's surface):
     adopting a dependency is a long-lived trust decision; a
     compromised one has already run by the time it is reverted.
  6. **Releases and versioning artifacts**: a published version
     cannot be unpublished from its consumers.
  7. **Anything CODEOWNERS security-routed** (`canon:codeowners`,
     the E-01 surface) not already covered above.

- **RV-03 — Irreversible classes never take Tier 1, and stay
  fail-closed.** An irreversible-class item takes Tier 2 at minimum
  (`rules/tiers.md` TR-07.3) regardless of size, and the
  conservative grading discipline (`rules/burden.md` B-11/B-13)
  continues to apply to it in full: absence of evidence on this
  surface is never "low". The security escalation triggers layer on
  top unchanged (G-08).

## Everything else

- **RV-04 — The revert-clean check.** Outside the irreversible
  classes, a change is presumed revertible once the pass confirms,
  from the diff: no persisted data or schema is written, no external
  consumer contract changes, no new package names appear, and no
  irreversible-class path is touched. That confirmation — cheap,
  mechanical, from evidence already in hand — is the **revert-clean
  check**, and it is what licenses the quick pass's confidence.

- **RV-05 — Every recommendation states its undo path.** Every
  outcome (`rules/tiers.md` TR-05) carries one explicit undo-path
  line, e.g.: "Undo: one `git revert` — no migrations, no API
  consumers, no persisted data affected." The line is honest about
  residue where there is some ("undo reverts the code; the three
  rows already written by the new default remain and are harmless").
  The claim being made is never "this change is certainly correct";
  it is "the cost of being wrong is bounded, and here is the bound."
  A recommendation that cannot state its undo path has discovered an
  irreversible-class change — re-route per RV-03.

- **RV-06 — Uncertainty becomes a named check, never a grade.**
  Outside the irreversible classes, anything the pass could not
  verify is reported as: *what was not verified* → *the specific
  human check that settles it* → *its approximate cost* ("not
  verified: the retry path under timeout — check: run the retry
  integration test locally, ~5 minutes"). Rendering an unknown as an
  elevated risk grade, with no named check attached, is a v0.6
  pattern this rule retires (`rules/burden.md` B-11 as amended
  applies fail-closed grading to the Safety axis and RV-02 classes
  only).
