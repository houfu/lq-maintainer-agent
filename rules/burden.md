# Maintainer burden — internal evidence behind the verdict

Normative data for the LQ Maintainer Agent (design doc §5.2, amended by
design v0.7 §7/§8). Loaded at runtime by `skills/triage/SKILL.md` and
`skills/review-pr/SKILL.md`. Companion rule sets: `rules/tiers.md`
(TR-NN — the outcome vocabulary that now leads every headline),
`rules/reversibility.md` (RV-NN — the undo path every outcome states),
`rules/change-categories.md` (G-NN).

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

**As of v0.7, the receipt that carries this block is an internal
evidence document** (design v0.7 §8): it is no longer posted to the
PR or issue, only stored — in the local cache today, in the community
repo's `reviews/<pr|issue>-NNNN/` once it exists. What the five axes
feed contributor-facing is no longer their own grades but the single
action outcome they support (`B-09`); the axes themselves, the
self-attestation cross-check, and the full coverage detail are
maintainer evidence, available on request, never rendered where a
contributor reads.

**Scope: burden is a PR verdict.** Its five axes grade a code diff,
which an issue does not have. Issues carry **no `burden` block** and are
never graded on these axes. An issue instead gets its **own** deck and a
verdict-first headline — a categorical **triage recommendation**
(`needs-info` / `decompose` / `proceed` / `design` / `escalate`) over a
rule-grounded preview of the PR it would become — defined in
`rules/issues.md` `IV-NN`
and rendered per `templates/receipt-issue.md` RI-11 (design §8.6a). The
conduct standard (`rules/conduct.md`) and the Next-steps idea (`B-14`)
apply to issues too; only the five-axis grade does not.

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
  - `high`: an unanchored **category-1** decision (`A-06`/`E-04` —
    `E-04` fires for category-1 items only, `rules/change-categories.md`
    G-02), a change that contradicts an ADR with no superseding one
    (`E-06`), a re-proposal of an idea already deferred on the DE
    list, or a multi-concern/overreaching diff (salvage applied). An
    unanchored category-2/3 change does not fire `E-04`: it is a flag
    plus the necessity check (`G-10`/`G-11`), at most `medium` on
    Scope.

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

- **B-09 — The action outcome leads; the five axes are internal
  evidence** *(REPLACED, design v0.7 §7)*. The public/deck/digest
  headline for every reviewed item is the **action outcome**
  (`rules/tiers.md` TR-05 vocabulary — `merge` /
  `merge-after-<fix>` / `discuss-<question>` / `route-to-design`,
  plus the escalate/hold output classes), stated with its **undo
  path** (`rules/reversibility.md` RV-04/RV-05). The five burden axes
  (`B-03`–`B-07`) no longer head anything a contributor or the deck's
  primary surface shows: they are **internal evidence** — computed
  every run exactly as before, recorded in the internal receipt's
  burden block (`B-10`), and available to the maintainer on request —
  but never the deck hero and never rendered on any contributor-facing
  surface. The axes' own definitions (`B-03`–`B-07`) are unchanged; what
  changes is only what leads and what is public. This does not change
  routing — the internal receipt still cites the lane and its assigning
  rule (`L-NN`); the axes remain the evidence the outcome is drawn from.

- **B-14 — Next steps: the check, and its approximate cost.** A verdict
  that only grades is not enough — the human needs to know *what to do
  next*, and what it will cost them to do it. Every internal receipt
  and the reading deck carry a **Next steps** list: the concrete
  follow-ups only a human can perform, one per firing blocker,
  `medium`/`high` axis, unknown-under-B-11 axis, and
  `not-covered`/`never-by-design` coverage item, each stating the
  action, **why** (the canon or gap that requires it), **and its
  approximate cost** — the `RV-06` form. They are specific to the item,
  not boilerplate:
  - a major version jump or widened range ⇒ *"Read the dependency's
    changelog / release notes for breaking changes affecting the call
    sites this project uses, ~10 minutes"* (the `semver_delta` fail /
    Safety axis);
  - runtime-behaviour never checked ⇒ *"Smoke-test the affected feature
    (e.g. the PDF export, in light and dark) before merging, ~5
    minutes"*;
  - a bug fix with no regression test ⇒ *"Request the regression test
    `canon:contributing` requires before accepting, ~2 minutes to
    draft the ask"*;
  - an unpinned widened range with no lockfile ⇒ *"Decide: pin the
    version, narrow the ceiling, or add a lockfile so a concrete version
    is vetted, ~5 minutes"*;
  - a `blocked` verdict ⇒ each blocker's resolution is itself a next
    step (get CI green, obtain sign-off, resolve the advisory), costed
    the same way.

  **Next steps feed the action outcome** (`rules/tiers.md` TR-05): an
  item whose only next steps are cheap named checks is `merge` or
  `merge-after-<fix>` material, not high-burden material — a long list
  of expensive, unresolved checks is what earns `discuss` or a heavier
  tier (`TR-06`). Next steps are **free text and live in the visible
  body / deck only**, never the enumerated footer (`B-10`). Where a
  next step is a request to the contributor, it is drafted courteously
  per `rules/conduct.md` (CD-06) and posted only by the human (`L-01`).

- **B-10 — The footer block is enumerated only.** The burden state rides
  the internal receipt's versioned footer (`templates/receipt-pr.md`,
  marker unchanged at `lq-maintainer-agent:receipt:v2`) as a block of
  **enumerated fields only**: `overall`
  (`blocked`/`low`/`medium`/`high`), `blockers` (a list of the `B-02`
  slugs, empty if none), and the five axis levels (`low`/`medium`/`high`).

  The footer additionally carries **four optional enumerated fields**,
  additive and backward-compatible (design v0.7 §8): `category`
  (`1`/`2`/`3`/`4`, `rules/change-categories.md` G-NN), `tier`
  (`0`/`1`/`2`/`3`, `rules/tiers.md` TR-NN), `outcome` (the TR-05
  vocabulary — `merge`/`merge-after`/`discuss`/`route-to-design`/
  `hold`/`security-escalate`; issues keep the `IV-01` `recommendation`
  field and may additionally use `recommendation: design` for a
  category-1 ask), and `undo` (`revert-clean`/`residue`/
  `irreversible-class`, `rules/reversibility.md` RV-04/RV-05).

  **No free text, ever** — the canon citations, the driver phrasing a
  reader sees ("driven by Safety / risk"), the named fix, the discuss
  question, and the undo sentence live in the visible receipt body and
  are re-derived at render time from the deck glossary, never stored in
  the footer. An HTML comment is exactly the concealment channel
  injection uses (`rules/injection-posture.md`, §8.4).

## 4. Discipline

- **B-11 — Conservative grading, scoped to Safety and the irreversible
  classes** *(SCOPED, design v0.7 §5/§7)*. Fail-closed grading — an
  unverifiable signal graded up, never down — applies in full to the
  **Safety axis** (`B-07`, disciplined further by `B-13`) and to any
  item touching an **irreversible class**
  (`rules/reversibility.md` RV-02/RV-03): those keep the original
  posture without exception. For the **other four axes**
  (`B-03`–`B-06`) on everything else, a signal or its governing canon
  (`B-00`) that cannot be computed is **never** graded up: it reports
  as **unknown**, paired with the named human check that settles it
  and that check's **approximate cost**, in the `RV-06` form ("not
  verified: X — check: Y, ~Z minutes"). An inflated grade with no
  named check attached is the v0.6 pattern this rule retires. Where a
  blocker's signal is not yet live (`B-12`), it still surfaces as an
  open human-only check, never as passed — that discipline is
  unchanged. A confident `low` still requires positive evidence, read
  from canon.

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
