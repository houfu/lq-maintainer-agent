# Canon Map — question → lq-ai doc routing

**The canon is the API** (design doc §11). This file is the **only**
place this agent encodes `legalquants/lq-ai`'s repository structure.
Every path below is resolved against the maintainer's lq-ai clone at
runtime and verified against the pinned canon reference by
`ci/canon-drift-check.yml`. **If lq-ai moves a doc, this file is the
one that changes** — nothing else in `rules/`, `templates/`, or
`skills/` may hardcode an lq-ai path.

All lq-ai paths are relative to the lq-ai repository root (the clone
`/triage` and `/review-pr` run inside).

## Routing table

| Question class | lq-ai path | Notes |
| --- | --- | --- |
| Product requirements — "is this in scope / what does the product promise?" | `docs/PRD.md` | Cite section anchors, not the whole file. |
| Architecture decisions — "was this already decided / does this contradict a decision?" | `docs/adr/` | One file per decision, numbered ADR-NNN. Cite the ADR number. A contradiction without a superseding ADR is an escalation trigger. |
| Roadmap — "is this planned, and when?" | `docs/ROADMAP.md` | |
| Deferred / enhancement list — "was this idea already captured as a DE-XXX?" | `docs/PRD.md#9-deferred-enhancements-and-identified-future-work` (PRD §9 — the DE-XXX backlog, ~150 entries) | Duplicate detection for feature issues searches this list as well as open issues. Salvage disposition S-DE drafts entries for it. |
| Honest project state — "does this doc/claim overstate what actually works?" | `docs/HONEST-STATE.md` | The truthfulness anchor for the docs lane; no contribution may overclaim relative to it. |
| Contribution rules — "what does the project require of a PR?" | `CONTRIBUTING.md` | Regression-test requirement for bug fixes; review standards for the standard lane; carries the triage-transparency line. |
| Agent instructions — "what conventions do Claude Code sessions in lq-ai follow?" | `CLAUDE.md` | Includes the documented pitfalls checked in standard-lane review. |
| External-contribution vetting — "which checklist applies to this external PR?" | `docs/security/external-contribution-vetting.md` | The vetting playbook. Source of the security checklist rendered in receipts, and of the "review and report, but the merge button is a human maintainer's" policy. |
| Security policy / advisories — "how are vulnerabilities reported?" | `SECURITY.md` | Vulnerability-suspect issues get only a drafted redirect to a private Security Advisory per this file. |
| Skill attestation — "has this skills change followed the human attestation path?" | `skills/CONTRIBUTING.md` | The skills contribution path, including the attestation and practicing-attorney-review norms. A skills change missing attestation is an escalation trigger. |
| Easy first contributions — "where do we point an eager newcomer?" | `docs/contribute/EASIEST-CONTRIBUTIONS.md` | Routing target for feature issues and salvaged contributors looking for a tractable start; mini-PRDs live beside it in `docs/contribute/`. |
| Sandbox discipline — "how does a human safely execute contributed code?" | `docs/sandbox-discipline.md` (this repo) | Humans only — the agent never executes contributed code (`rules/injection-posture.md` I-05). Upstreams to lq-ai under docs/security/ at M1 — flip this citation to the lq-ai path in that PR. |
| Security-routed paths — "is this path CODEOWNERS-sensitive?" | `CODEOWNERS` (lives at `.github/CODEOWNERS` in lq-ai; the drift check accepts either location) | Source of the sensitive-path escalation trigger. |

## Usage rules

- **Cite path + anchor.** Every canon citation in a card, receipt, or
  drafted comment names the file path and the section/ADR/DE
  identifier, so a human can verify the citation in one click.
- **Record the canon SHA.** The runtime canon is the clone's `main`
  HEAD; every output pins it alongside the PR head SHA and agent
  version (design doc §3.4).
- **Absence is a finding.** If a question class has no answering doc
  ("canon absent"), say so explicitly — for feature/structural
  decisions that is the unanchored-decision escalation trigger, never
  a license to improvise policy.
- **Dangling path = fix here first.** If a path in this table fails to
  resolve at runtime, treat the routing as unknown, flag it in the
  output's coverage statement, and open a PR against this file — do
  not guess a replacement path mid-triage.
