# Maintainer burden — the two-layer verdict

Normative data for the LQ Maintainer Agent (design doc §5.2). Loaded at
runtime by `skills/triage/SKILL.md` and `skills/review-pr/SKILL.md`.

Every rule carries a stable ID (`B-NN`). The burden verdict is
**additive** — it does not replace lane assignment (`rules/lanes.md`,
`L-NN`/`F-NN`), anchoring (`A-NN`), findings, or the coverage statement;
it summarises what those already establish into a single answer to the
question a part-time maintainer most needs: *what will accepting this
cost me?* Burden is computed **from signals the other rules already
produce** — it introduces no new judgment about the code, only a
roll-up of existing ones.

Burden is a **recommendation, not a ruling** (as with lanes, `L-01`): a
human decides, every time. The verdict never implies a merge, approval,
close, or post occurred.

**Scope: burden is a PR verdict.** Its five axes grade a code diff,
which an issue does not have. Issues carry **no `burden` block**; their
cost-to-you signal is the classification, repro assessment, duplicate
result, and the RI-08 human-only judgments (`rules/issues.md` C-81,
`templates/receipt-issue.md` RI-11). The conduct standard (`rules/conduct.md`)
and the Next-steps idea (`B-14`) *do* apply to issues; the five-axis
grade does not.

## 0. Grounding and the two layers

- **B-00 — Grounded in lq-ai canon, never generic standards.** Every
  axis and blocker grades against the maintained project's own canon,
  routed by `rules/canon-map.md` and cited by `canon:<key>` (never a
  path). What counts as "in scope", "adequately tested", "clean", or
  "sensitive" is whatever **lq-ai's** PRD, ADRs, roadmap, CONTRIBUTING,
  CLAUDE.md, and vetting playbook say it is — not a generic OSS default.
  Where the governing canon for a question is **absent**, that absence
  is surfaced (per `canon-map.md` usage: an unanchored decision escalates,
  `E-04`; a dangling canon key is flagged in the coverage statement, not
  guessed): burden then grades **conservatively** (`B-11`), never by an
  improvised standard. A burden grade must be traceable to the canon it
  read, the same way a lane cites its assigning rule.

- **B-00a — Grade only from canon read *this run*.** The canon a grade
  cites must be **read this run from the clone Step 0 verified, at the
  pinned canon SHA** — never recalled, paraphrased, or assumed. The
  §3.3 batch re-read discipline that binds lane calls binds burden
  identically: in a long or compacted session, re-read the governing
  canon immediately before grading, or fork a per-item subagent with the
  canon in its brief. If the run is **not inside the clone**, or a
  governing canon doc cannot be resolved (a dangling `canon-map` key),
  the axes it feeds are graded conservatively (`B-11`) and the receipt's
  coverage statement records that the canon was unavailable. A grade
  from memory of what a doc "usually says" is invalid, exactly as a lane
  assigned from summarised rules is (`rules-loading.md`).

- **B-01 — Blockers gate above the graded burden.** The verdict has two
  layers. **Layer 1** is a set of binary **blockers** (`B-02`): any one
  present makes the overall verdict `blocked` — "resolve first" — and
  **no burden level is shown until it clears**. **Layer 2** is the
  graded **burden** across five axes (`B-03`–`B-07`), rolled up
  worst-of (`B-08`). "Can't merge yet" is kept distinct from "costs you
  work"; a blocker is never merely "high burden".

## 1. Layer 1 — blockers

- **B-02 — The blocker set (enumerated).** Any one ⇒ overall `blocked`.
  Each maps to a live signal grounded in canon, or is explicitly
  deferred (`B-12`):
  - `ci-red` — CI not green on the reviewed head (`F-07` fail); the
    pipeline is lq-ai's own. *(live)*
  - `known-vuln` — a changed dependency matches a known advisory
    (`F-05` OSV/GHSA hit). *(live)*
  - `attack-escalation` — a suspected-deliberate-attack or
    agent-instruction/tool-config trigger fired (`rules/escalation-triggers.md`,
    grounded in `canon:codeowners` E-01 and `canon:claude-md` E-10,
    §10.2). *(live)*
  - `vuln-suspect` — a vulnerability-suspect issue: the carve-out routes
    to a private advisory per `canon:security-policy` (`E-08`,
    `rules/issues.md`). No public receipt; no exploit detail. *(live)*
  - `data-harm` — a blocking-severity finding in the security/data-harm
    class **as the vetting playbook defines it** (`canon:vetting-playbook`,
    `canon:security-policy`). *(partial — until the harm taxonomy exists
    (`B-12`), any finding a maintainer marks blocking-severity in this
    class fires it; the agent never invents the classification.)*
  - `missing-dco` — the contributor has not signed off, where
    `canon:contributing` requires it (DCO/CLA). *(to build — `B-12`;
    leverages the M0 sign-off repo setting, design §14.)*
  - `incompatible-license` — the change, or a newly added dependency,
    carries a license incompatible with the terms `canon:contributing`
    and the project's manifests state. *(to build — `B-12`.)*
- **B-02a — Blockers are named, never summarised away.** A `blocked`
  verdict lists every firing blocker by its enumerated slug so the human
  sees exactly what to resolve. A blocker whose signal is not yet
  computable (`B-12`) is surfaced as an open human-only check, never
  silently treated as passed.

## 2. Layer 2 — the five burden axes

Each axis is graded `low` / `medium` / `high` from the signals named,
**against the canon named** (`B-00`). Where a signal or its governing
canon cannot be evaluated, grade **conservatively** (`B-11`): absence of
evidence is not `low`.

- **B-03 — Scope** — *does it stay within what lq-ai has decided?*
  Grades against `canon:prd` (is it promised / in scope?),
  `canon:roadmap` (planned?), `canon:de-list` (already captured as a
  DE-XXX?), `canon:adr` (already decided, or contradicted?), and
  `canon:honest-state` (does it overclaim vs. actual state?), via
  anchoring `A-01`/`A-06`.
  - `low`: anchored to an accepted PRD section / ADR / roadmap item / DE
    entry; single concern; scope legible.
  - `medium`: anchored but broad, or drifts slightly beyond the cited
    canon (a single scope flag).
  - `high`: an unanchored decision (`A-06`/`E-04`), a change that
    contradicts an ADR with no superseding one (`E-06`), a re-proposal
    of an idea already deferred on the DE list, or a
    multi-concern/overreaching diff (salvage applied).

- **B-04 — Review effort** — *how hard is it to review, by lq-ai's own
  standard?* Grades against `canon:contributing` (its review standards)
  and `canon:claude-md` (documented pitfalls + conventions); subsystem
  boundaries are lq-ai's, and `canon:codeowners` marks the sensitive
  ones.
  - `low`: small diff; one subsystem; no bundled refactor; at most one
    finding.
  - `medium`: moderate size, or two subsystems, or a few findings.
  - `high`: large diff; many files/subsystems; an unexplained bundled
    refactor (`rules/lanes.md` L-32); many findings.

- **B-05 — Tests** — *does it meet lq-ai's test requirement for its
  change class?* Grades against `canon:contributing`, which sets the bar
  — notably **a regression test for bug fixes** — not a generic "is it
  tested".
  - `low`: meets what `canon:contributing` requires for this change
    class — **or** the change has no runtime behaviour to test (a
    dependency-manifest, lockfile, or docs change). Absence of tests
    where canon requires none is not a burden.
  - `medium`: partial against what `canon:contributing` asks.
  - `high`: a change class `canon:contributing` requires tests for (e.g.
    a bug fix without its regression test), or tests that assert nothing
    (`rules/lanes.md` L-32).

- **B-06 — Carry cost** — *what do you maintain forever, against lq-ai's
  conventions?* Grades against `canon:claude-md` (conventions + the
  documented pitfalls: duplication, dead code) and `canon:honest-state`
  (does new surface overclaim what works?).
  - `low`: clean by `canon:claude-md`; no new dependency; existing
    patterns; no new public surface.
  - `medium`: some duplication, or one well-known new dependency, or
    modest new surface.
  - `high`: adds dependencies or surface you carry indefinitely, or is
    duplicative/unclear against `canon:claude-md`'s pitfalls.

- **B-07 — Safety / risk** — *how much residual risk do you inherit,
  short of a blocker, by the vetting playbook?* Grades against
  `canon:vetting-playbook` (which checklist classes apply and their
  results), `canon:security-policy`, `canon:codeowners` (sensitive-path
  proximity, `E-01`), and `canon:sandbox-discipline`. This axis exists
  so risk that does not rise to a `B-02` blocker is graded, not waved
  through.
  - `low`: pinned and vetted; small blast radius; no `canon:codeowners`
    sensitive surface.
  - `medium`: an unpinned or widened dependency range, a borderline-fresh
    release, or a moderately sensitive area — nothing with a known
    advisory.
  - `high`: wide blast radius, privacy/data-adjacent surface, or
    supply-chain uncertainty the mechanical checks cannot resolve — but
    **not** a confirmed vulnerability (that is a `known-vuln` blocker).
  - *Worked example (PR-132 class):* a widened, unpinned pre-1.0
    dependency range with no lockfile — no known advisory, so no
    blocker, but the mechanical OSV/release-age checks cannot evaluate
    what will resolve ⇒ Safety `medium`.

## 3. Roll-up and output

- **B-08 — Worst-of roll-up.** Overall burden = the **highest** of the
  five axes. One `high` axis makes the item high-burden even if the
  other four are `low` — a maintainer feels the worst dimension most,
  and a single serious axis must not be diluted by calm ones. A firing
  blocker (`B-02`) supersedes the roll-up: overall = `blocked`, and the
  five axes are still reported beneath it.

- **B-09 — Burden leads the verdict.** The receipt records the burden
  block (`B-10`); the reading deck (design §8.6) headlines the overall
  burden and shows the five axes as its glance tiles, with the lane
  demoted to a supporting detail. This does not change routing — the
  receipt still cites the lane and its assigning rule (`L-NN`); burden
  is an added summary, not a replacement.

- **B-14 — Next steps: what the reviewer must still check.** A verdict
  that only grades is not enough — the human needs to know *what to do
  next*. Every receipt and the reading deck carry a **Next steps** list:
  the concrete follow-ups only a human can perform, one per firing
  blocker, `medium`/`high` axis, and `not-covered`/`never-by-design`
  coverage item, each stating the action **and why** (the canon or gap
  that requires it). They are specific to the item, not boilerplate:
  - a major version jump or widened range ⇒ *"Read the dependency's
    changelog / release notes for breaking changes affecting the call
    sites this project uses"* (the `semver_delta` fail / Safety axis);
  - runtime-behaviour never checked ⇒ *"Smoke-test the affected feature
    (e.g. the PDF export, in light and dark) before merging"*;
  - a bug fix with no regression test ⇒ *"Request the regression test
    `canon:contributing` requires before accepting"*;
  - an unpinned widened range with no lockfile ⇒ *"Decide: pin the
    version, narrow the ceiling, or add a lockfile so a concrete version
    is vetted"*;
  - a `blocked` verdict ⇒ each blocker's resolution is itself a next
    step (get CI green, obtain sign-off, resolve the advisory).

  Next steps are **free text and live in the visible body / deck only**,
  never the enumerated footer (`B-10`). Where a next step is a request to
  the contributor, it is drafted courteously per `rules/conduct.md`
  (CD-06) and posted only by the human (`L-01`).

- **B-10 — The footer block is enumerated only.** The burden state rides
  the versioned receipt footer (`templates/receipt-pr.md`) as a block of
  **enumerated fields only**: `overall`
  (`blocked`/`low`/`medium`/`high`), `blockers` (a list of the `B-02`
  slugs, empty if none), and the five axis levels (`low`/`medium`/`high`).
  **No free text, ever** — the canon citations and the driver phrasing a
  reader sees ("driven by Safety / risk") live in the visible receipt
  body and are re-derived at render time from the deck glossary, never
  stored in the footer. An HTML comment is exactly the concealment
  channel injection uses (`rules/injection-posture.md`, §8.4).

## 4. Discipline

- **B-11 — Conservative under uncertainty.** Burden inherits the
  fail-closed posture (`F`-gate, §5.1). Where an axis's signal or its
  governing canon (`B-00`) cannot be computed, grade it up, not down;
  where a blocker's signal is not yet live (`B-12`), surface it as an
  open human-only check, never as passed. A confident `low` requires
  positive evidence, read from canon.

- **B-12 — Deferred signals (build order).** Three signals are not yet
  computed and are named so the gaps are visible, not silent:
  `missing-dco` and `incompatible-license` blockers (grounded in
  `canon:contributing`; the §2 Legal & compliance coverage gap), and the
  **data-harm taxonomy** (grounded in `canon:vetting-playbook`) that
  sharpens the `data-harm` blocker and the Safety axis (`B-07`). Until
  they land, Layer 1 runs on the live signals (`F-05`, `F-07`,
  escalation triggers, vuln-suspect) and the deferred blockers appear as
  open human-only checks. The burden verdict is honest about what it
  could not compute (`B-11`) rather than presenting a falsely clean
  result.

- **B-13 — Safety / risk is the priority axis.** Worst-of (`B-08`)
  already gives a `high` Safety axis the overall verdict; this rule
  ensures Safety is never *under*-graded for lack of effort or canon:
  - **Never trimmed.** A maintainer may cut deep-dive passes for budget
    (§9); the Safety axis is always computed. Its grounding canon —
    `canon:vetting-playbook` and `canon:codeowners` — is read every run
    (`B-00a`), not sampled.
  - **Fails closed hardest.** Where the vetting playbook or CODEOWNERS
    could not be read, or a mechanical safety check (`F-05` OSV, `F-06`
    release-age) could not run against a concrete version, Safety grades
    **up**, not down — an unresolvable supply-chain question is `medium`
    at least, never `low`. Confirmed danger is a `B-02` blocker; only
    genuinely small, vetted, non-sensitive change earns Safety `low`.
  - **First in the build order.** Of the deferred signals (`B-12`), the
    data-harm taxonomy that sharpens this axis and the `data-harm`
    blocker leads — it is the axis the maintainer weights highest.
