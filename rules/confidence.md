# Confidence — what a finding rests on, and whose burden it is (CF-NN)

Normative data for the LQ Maintainer Agent (design delta v0.8 §2).
Loaded by `skills/review-pr/SKILL.md`, `skills/review-issue/SKILL.md`
and `skills/triage/SKILL.md` wherever a finding is written, and by the
deck renderer and the eval grader as the vocabulary they check. Every
rule carries a stable ID (`CF-NN`). Companion rule sets:
`rules/lanes.md` (`L-33` — the finding slots this file adds two
readings to; `L-33b` actionability), `rules/burden.md` (`B-01`/`B-02`
blockers, `B-11` fail-closed grading, `B-14` next steps),
`rules/reversibility.md` (`RV-06` — the named-check form a
low-confidence finding takes), `rules/tiers.md` (`TR-05` outcomes,
`TR-06` two blocking fixes), `rules/conduct.md` (`CD-08` defer to the
author), `rules/anchoring.md` (`A-08` verified anchors, `A-12`/`A-12a`
proposals anchor and order nothing), `templates/receipt-pr.md`
(`RP-05`, the footer tuple).

Prompted by the maintainer (2026-11-09): *"there should also be
confidence readings on blockers based on whether your evidence
supports, for example, a blocking or major issue. I also think
confidence should also be based on whether it is fair to the
contributor — whether the fix or comment the triage or review is
pushing is based on the boundaries."*

What the record showed (calibration over 161 receipts, 171 distinct
blocking and major findings, `docs/proposals/blocker-confidence.md`):
the evidence is usually sound — 160 of 171 rest on something read in
the diff, in merged canon, or in a tool result — and the weak point is
**fairness**: 46 asked for something that was not the PR's own job (23
pre-existing or a maintainer's task, 8 preferences with no canon
behind them, 15 widenings of scope). "Blocking" had come to mean
"merge condition": 12 of 23 blocking findings matched no `B-02`
blocker. The free-text "Confidence:" line on the lane said *high* 38
times out of 38 and carried no information. Where the maintainer's
later ruling is known, they disagreed with 10% of the findings this
file grades high, 80% of those it grades medium, and 64% of those it
grades low.

## The two readings

- **CF-01 — Every finding carries an evidence reading.** Exactly one
  of, judged at the moment the finding is written and never revised
  upward afterwards without a new act in the work log:
  - `observed` — the defect is settled by what the run read at the
    pinned head: the cited `file:line`, the repository state, the
    hunk itself.
  - `canon-gap` — the diff lacks what a cited section of **merged**
    canon requires, the section having been read this run at the
    pinned canon SHA (`B-00a`, `A-08`). An in-contribution or draft
    decision document never supplies a `canon-gap` (`A-12`).
  - `mechanical` — a tool's verdict is the evidence: a CI job, an
    OSV/GHSA lookup, a sign-off trailer read, `check-breaking.sh`, a
    UAT measurement.
  - `inferred` — the defect itself is inferred, not read: unobserved
    runtime or upstream behaviour, "would", "can", "likely", a
    presumption about deployments or data the run did not see.
  - `unverified` — the finding rests on a source the run did not
    verify, on a claim the run has reversed without checking, or on a
    fact the run itself says it cannot establish.
  The reading names the *weakest* link: an observed hunk whose harm is
  inferred is `inferred`.
- **CF-02 — Every finding carries a fairness reading.** Exactly one
  of:
  - `own-burden` — required of **this** change by cited canon or by
    correctness, or a gap the change introduces against its own
    stated goal.
  - `not-this-pr` — real, but pre-existing, inherited from a parent
    or stacked PR, or something a maintainer does rather than a
    contributor is asked for.
  - `preference` — an alternative approach, a matter of taste, or
    "you could also", with no canon requirement and no concrete cost
    named (`CD-08`: where two approaches are equally valid, the
    author's stands).
  - `scope-expansion` — asks for more than the change set out to do:
    other paths, other providers, the rest of an issue's acceptance
    list, adjacent hardening.
  The reading answers one question in the contributor's favour when
  in doubt: *is this mine to carry, in this PR?*
- **CF-03 — Confidence is derived, never declared.** From the two
  readings, by rule:
  - **`high`** — evidence is `observed`, `canon-gap` or `mechanical`
    **and** fairness is `own-burden`.
  - **`medium`** — evidence is `observed`, `canon-gap` or `mechanical`
    **and** fairness is `not-this-pr`.
  - **`low`** — evidence is `inferred` or `unverified`, **or**
    fairness is `preference` or `scope-expansion`.
  A footer whose `confidence` disagrees with its two components is
  malformed, and the eval grader fails it. The lane's own confidence
  line (`RP-01`) is a different thing and is unchanged.

## What confidence does to the outcome

- **CF-04 — Only a high-confidence blocking finding blocks.** A
  blocking finding graded `medium` or `low` may not, on its own, set
  the outcome to `discuss` or `hold`, does not count toward `TR-06`'s
  two-blocking-fixes threshold, may not be the named fix of a
  `merge-after-<fix>`, and may not fire a finding-derived blocker slug
  (`missing-dco`, `data-harm`). Its severity word is kept in the
  record for honesty; its force is not.
- **CF-05 — A low-confidence inferred or unverified finding renders as
  a named human check.** In the `RV-06` form — "not verified: X —
  check: Y, ~Z minutes" — as a **Next steps** entry (`B-14`, `RP-16`),
  addressed to the maintainer, never phrased as a contributor ask. The
  check names what would raise the reading to `observed` or
  `mechanical`; when a maintainer runs it and it confirms the defect,
  the finding is re-graded with the act in the work log and takes its
  full force from then. The one real blocker in the record this rule
  would have softened (a token-logging gap, since fixed by the
  contributor) would have read "not verified: whether opaque tokens in
  free-form response bodies survive the redactor — check: one
  free-text token case in the rejection-log test, ~10 minutes" — still
  visible, still the maintainer's to make a condition.
- **CF-06 — A preference is not a finding.** A finding whose fairness
  reading is `preference` is dropped before rendering, counted in
  `findings_filtered`, and recorded in the work log as considered and
  dropped under `CD-08`. It never appears on the deck, in the drafted
  comment, or as a "you could also" aside. A genuine cost the author's
  approach carries — a canon citation, a correctness gap, a measured
  cost — makes it `own-burden`, not a preference, and it stays.
- **CF-07 — A scope expansion is a follow-up, never a condition.** A
  finding whose fairness reading is `scope-expansion` takes
  `scope: follow-up` with its drafted stub (`L-33`), is never a merge
  condition, never part of a `merge-after` named fix, and never counts
  toward `TR-06`. The contributor reads, at most, one courteous
  sentence that the wider work has been noted and filed.
- **CF-08 — What is not this PR's is never asked of its author.** A
  finding whose fairness reading is `not-this-pr` is a maintainer
  action in **Next steps** where a maintainer is the one to act, or
  `scope: pre-existing` where the defect predates the change. It does
  not count toward `TR-06` and is not a contributor ask in the drafted
  comment.
- **CF-09 — Live signals are untouched.** `ci-red`, `known-vuln`,
  `attack-escalation` and `vuln-suspect` derive from their signals
  (`B-02`), not from any finding's confidence; `B-11`'s fail-closed
  grading of the Safety axis and of the irreversible classes stands.
  This file governs a finding's own severity, its effect on the
  outcome, and the two finding-derived slugs — nothing else.
- **CF-10 — A merged or closed item over an open high-confidence
  blocking finding is a discrepancy, not a correction.** It is
  surfaced under `RP-18` (GitHub state wins; absence of a decision is
  not agreement) and recorded as the maintainer confirms; the finding
  is never silently downgraded to match what happened.

## Severity words mean one thing

- **CF-11 — `blocking` is reserved for defects that make merging
  wrong.** A correctness, security or data-handling defect in this
  change, `own-burden`, whose presence means the change should not
  merge as it stands. It is not the word for a process item or a
  mechanical gate: a missing sign-off trailer, a dependency floor, a
  duplicated heading, a formatting rule. Those are **`major` with
  `evidence: mechanical`** where canon requires them, and the deck
  calls them *must-fix (mechanical)*; a missing sign-off additionally
  surfaces through the `missing-dco` slug when that signal is live
  (`B-12`), where the maintainer's own leniency, if any, is a recorded
  ruling and not the agent's. A finding and a `B-02` blocker are two
  different things and are never written as one.
- **CF-12 — A failing check that is not required is a note.** An
  infrastructure-only CI failure (an image pull, a runner outage, a
  check the branch protection does not require — verified through the
  API, never assumed) is recorded in the coverage statement and, if
  the maintainer should look, in Next steps; it is not a finding, and
  `ci-red` fires only on the reviewed head's required checks as
  `F-07` defines them.
- **CF-13 — A canon-required ask the maintainer has ruled out of the
  merge gate stays canon-required.** Where a standing ruling in the
  feedback log limits what is asked of contributors (the "minimal
  merge conditions" rulings: a regression test for a small bug fix,
  documentation completeness), the finding keeps `own-burden` and its
  evidence reading, and takes `scope: follow-up` **citing the ruling by
  date**, so the record shows canon asked for it and a maintainer chose
  the gate. The agent never silently drops a canon requirement and
  never silently re-imposes a ruled-out one.

## Where the readings live

- **CF-14 — Footer and body.** The footer's findings tuple gains three
  optional enumerated keys — `evidence`, `fairness`, `confidence` —
  additive to `receipt:v2` (`RP-05`). The sentence that justifies each
  reading, and the named check of `CF-05`, are visible-body free text
  beside the finding's impact and ask, never in the footer. The deck
  shows the confidence beside the severity on every finding and
  separates what *blocks* from what *needs a human check*; the
  contributor-facing comment never carries the words `evidence`,
  `fairness` or `confidence`, or any value of them (`PC-06`).
- **CF-15 — Graded, two-sided.** The evals assert both directions: a
  fixture whose blocker is inferred must not end `discuss` on its
  strength (`conf-01`); a preference must not appear as a finding
  (`conf-02`); a scope expansion must not be a merge condition
  (`conf-03`); and a genuine `observed`, `own-burden` blocking finding
  must still block (`std-10`, unchanged). A rules change that removes
  force from real defects fails the suite exactly as one that invents
  it does.
