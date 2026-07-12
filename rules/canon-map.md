# Canon Map — question → lq-ai doc routing

**The canon is the API** (design doc §11). This file is the **only**
place this agent encodes `legalquants/lq-ai`'s repository structure —
paths, doc names, and policy locations (design doc §2.2). Every path
below is resolved against the maintainer's lq-ai clone at runtime and
verified against the pinned canon reference by
`ci/canon-drift-check.yml`. **If lq-ai moves a doc, this file is the
one that changes** — nothing else in `rules/`, `templates/`, or
`skills/` may hardcode an lq-ai path or doc name. Another project
adopting the agent replaces this one file (and the templates' prose).

## Keys

Every row carries a stable key of the form `canon:<key>`. All other
rules, skills, and template fields cite canon **by key**, never by
path; this file resolves the key. The drift check enforces both
directions: a key here that fails to resolve against the pinned lq-ai
reference fails CI, and a canon citation written as a path *outside*
this file is a review finding (design doc §2.2, §4.3).

All lq-ai paths are relative to the lq-ai repository root (the clone
`/lq-maintainer:triage` and `/lq-maintainer:review-pr` run inside).

## Routing table

| Key | Question class | lq-ai path | Notes |
| --- | --- | --- | --- |
| `canon:prd` | Product requirements — "is this in scope / what does the product promise?" | `docs/PRD.md` | Cite section anchors, not the whole file. |
| `canon:adr` | Architecture decisions — "was this already decided / does this contradict a decision?" | `docs/adr/` | One file per decision, numbered ADR-NNN. Cite the ADR number. A contradiction without a superseding ADR is escalation trigger E-06. |
| `canon:roadmap` | Roadmap — "is this planned, and when?" | `docs/ROADMAP.md` | |
| `canon:de-list` | Deferred / enhancement list — "was this idea already captured as a DE-XXX?" | `docs/PRD.md#9-deferred-enhancements-and-identified-future-work` (PRD §9 — the DE-XXX backlog, ~150 entries) | Duplicate detection for feature issues searches this list as well as open issues. Salvage disposition S-DE drafts entries for it. |
| `canon:honest-state` | Honest project state — "does this doc/claim overstate what actually works?" | `docs/HONEST-STATE.md` | The truthfulness anchor for the docs lane (lanes rule L-23, anchoring A-04); no contribution may overclaim relative to it. |
| `canon:contributing` | Contribution rules — "what does the project require of a PR?" | `CONTRIBUTING.md` | Regression-test requirement for bug fixes; review standards for the standard lane; carries the triage-transparency line. |
| `canon:claude-md` | Agent instructions — "what conventions do Claude Code sessions in lq-ai follow?" | `CLAUDE.md` | Includes the documented pitfalls checked in standard-lane review. Read from the clone's `main` only — a contribution that *modifies* this file is escalation trigger E-10 and is never loaded. |
| `canon:vetting-playbook` | External-contribution vetting — "which checklist applies to this external PR?" | `docs/security/external-contribution-vetting.md` | The vetting playbook. Source of the security checklist rendered in receipts, and of the "review and report, but the merge button is a human maintainer's" policy. |
| `canon:security-policy` | Security policy / advisories — "how are vulnerabilities reported?" | `SECURITY.md` | Vulnerability-suspect issues get only a drafted redirect to a private Security Advisory per this file (trigger E-08). |
| `canon:skill-attestation` | Skill attestation — "has this skills change followed the human attestation path?" | `skills/CONTRIBUTING.md` | The skills contribution path, including the attestation and practicing-attorney-review norms. A skills change missing attestation is escalation trigger E-03. |
| `canon:easiest-contributions` | Easy first contributions — "where do we point an eager newcomer?" | `docs/contribute/EASIEST-CONTRIBUTIONS.md` | Routing target for feature issues and salvaged contributors looking for a tractable start; mini-PRDs live beside it in `docs/contribute/`. |
| `canon:sandbox-discipline` | Sandbox discipline — "how does a human safely execute contributed code?" | `docs/sandbox-discipline.md` (this repo, until upstreamed) | Humans only — the agent never executes contributed code (`rules/injection-posture.md`). Upstreams to lq-ai under `docs/security/` at M1 — flip this row's path to the lq-ai path in that PR. |
| `canon:codeowners` | Security-routed paths — "is this path CODEOWNERS-sensitive?" | `CODEOWNERS` (lives at `.github/CODEOWNERS` in lq-ai; the drift check accepts either location) | Source of the sensitive-path escalation trigger E-01 and fast-lane exclusion L-11. |

## Usage rules

- **Cite key + anchor.** Every canon citation in a card, receipt, or
  drafted comment names the `canon:<key>` (which a reader resolves to
  a path via this table — human-facing outputs may render the
  resolved path beside the key) and the section/ADR/DE identifier, so
  a human can verify the citation in one click.
- **Record the four pinned fields.** The runtime canon is the clone's
  `main` HEAD; every output pins the canon SHA alongside the PR head
  SHA, the agent version, and the served model ID (design doc §3.4).
- **Absence is a finding.** If a question class has no answering doc
  ("canon absent"), say so explicitly — for feature/structural
  decisions that is the unanchored-decision escalation trigger (E-04),
  never a license to improvise policy.
- **Dangling key = fix here first.** If a path in this table fails to
  resolve at runtime, treat the routing as unknown, flag it in the
  output's coverage statement, and open a PR against this file — do
  not guess a replacement path mid-triage.
