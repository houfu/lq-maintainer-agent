# Confidence on blockers — the evidence base and the schema (PROPOSED 2026-11-09)

Field request from the maintainer, in their words, after lq-ai shipped
v0.9.1:

> there should also be confidence readings on blockers based on
> whether your evidence supports for example, a blocking or major
> issue. i also think confidence should also be based on whether it is
> fair to the contributor whether the fix or comments triage or review
> is pushing based on the boundaries.

Two readings, then: what a finding **rests on**, and whose **burden**
the ask is. The normative result is `rules/confidence.md` (`CF-NN`);
this document is the evidence it was calibrated against and the
rulings that shaped it. The full calibration report, every blocking
and major finding classified by hand with its pointer, is held by the
maintainer outside the repository (it quotes private records) as
`blocker-calibration.md`; the v0.8.0 release notes say where it is
kept.

## What the record showed

Over 161 receipts (132 current, 29 older copies) covering 102 items,
with 367 footer findings — 27 blocking, 158 major, 182 minor:

| Question | Answer from the record |
| --- | --- |
| Is the evidence weak? | Rarely. 160 of 171 blocking/major findings rest on the diff, a merged canon section or a tool result; 11 are inferred or unverified. |
| Is the ask fair? | Less often. 46 of 171 asked for something that was not the PR's own job: 23 pre-existing or a maintainer's task, 8 preferences with no canon behind them, 15 widenings of scope. |
| What does "blocking" mean in practice? | "Merge condition." 12 of 23 blocking findings match no `B-02` blocker; the word covered sign-off trailers, dependency floors and a duplicated heading. |
| Does the existing confidence line carry information? | No. The lane's free-text "Confidence:" said *high* 38 times out of 38. |
| What did the maintainer do afterwards? | Where known (67 of 171): disagreed with 10% of findings the schema grades high, 80% of medium, 64% of low. Three blocking/major findings were merged over with no decision recorded (#443 F-1, #441 F-1, #311 F-5). |

Regraded under the schema, 51 of 175 blocking/major rows (29%) lose
their force: 21 become maintainer actions or pre-existing notes, 8
preferences drop out, 16 scope expansions become follow-up stubs, 6
inferred or unverified findings become named checks. Four of the 23
blocking findings are among them. One real blocker (#783 F-1, a
token-logging gap the contributor fixed) would have rendered as a
named check instead of a blocker; the named-check form keeps it
visible and the maintainer could still make it the condition. That is
the cost of the rule, and it is stated.

## The rulings

### R1 — Two enumerated readings, one derived roll-up **(maintainer)**

`evidence` ∈ observed / canon-gap / mechanical / inferred /
unverified; `fairness` ∈ own-burden / not-this-pr / preference /
scope-expansion; `confidence` derived by CF-03 and never declared.
Additive, optional keys on the footer's findings tuple; `receipt:v2`
unchanged. The eval lint fails a golden — and, when the harness runs,
a footer — whose roll-up disagrees with its components.

### R2 — Confidence changes force, not words **(maintainer)**

A `low` or `medium` blocking finding keeps its severity word in the
record and loses its force: it cannot set `discuss`/`hold` alone,
count toward TR-06, name a `merge-after` fix, or fire `missing-dco` /
`data-harm` (CF-04). Inferred and unverified findings render as RV-06
named checks (CF-05). Live-signal blockers are untouched (CF-09).

### R3 — Preference is not a finding; expansion is a follow-up **(maintainer)**

CD-08 already said the author's choice stands where two approaches are
equally valid. CF-06 makes it mechanical: a `preference` is dropped
before rendering and counted in `findings_filtered`. CF-07 makes a
`scope-expansion` a follow-up stub, never a condition.

### R4 — `blocking` is one word with one meaning **(maintainer)**

Reserved for defects that make merging wrong (CF-11). Process and
mechanical requirements — sign-off, dependency floors, headings — are
`major` with `evidence: mechanical`, shown as *must-fix (mechanical)*;
infrastructure-only CI failures are notes unless the check is required
(CF-12).

### R5 — Canon-required but ruled out of the gate stays canon-required **(maintainer)**

The schema cannot catch the "canon asks, maintainer waives" pattern
(#402 F-2, #752 F-1: regression tests on small bug fixes under the
2026-08-05 limit-reviews ruling). CF-13 keeps the finding `own-burden`
and takes `scope: follow-up` citing the ruling by date, so the record
shows canon asked and a maintainer chose the gate. DCO leniency
(#311, #443) is the same shape and is the maintainer's to record, not
the agent's to grade.

## What ships

`rules/confidence.md`; the tuple keys and RP-05 text in
`templates/receipt-pr.md` and `templates/receipt-issue.md`; `L-33c` in
`rules/lanes.md` and the B-01 sentence in `rules/burden.md`; the
grader's vocabularies and roll-up lint in `ci/scripts/grade-evals.sh`
and the new golden keys in `evals/run-checks.md`; three fixtures with
goldens — `conf-01-inferred-blocker`, `conf-02-preference-as-major`,
`conf-03-scope-expansion-condition`; the deck shows confidence beside
severity and separates *blocks* from *needs a human check*.

## Honest status

- The classification is one hand pass over 171 findings; expect about
  ±5 per class.
- Only 67 of 171 findings have a known outcome; the large PRs (#599,
  #537, #400) cannot be traced finding by finding.
- The agent-run eval harness does not exist yet (M1), so the three new
  goldens are structurally linted, not graded against a run.
- Nothing re-grades the 161 existing receipts; they are published, if
  ever, as they were (`PB-05`).
