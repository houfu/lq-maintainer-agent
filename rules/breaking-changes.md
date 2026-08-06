# Breaking changes — the mechanical detector and its honesty bounds

Normative data for the LQ Maintainer Agent (design delta v0.7.2 §2).
Loaded at runtime by `skills/triage/SKILL.md` (before Step 6b's
category/tier call) and `skills/review-pr/SKILL.md`. Every rule carries
a stable ID (`BC-NN`); every detection cites it. Companion rule sets:
`rules/reversibility.md` (`RV-NN` — RV-02.3, the public-API
irreversible class this file detects), `rules/tiers.md` (`TR-NN` — the
Tier-1 bar a detection fails and the ratchet a PASS cannot turn),
`rules/lanes.md` (`L-NN`/`F-NN` — the deterministic gate whose
`check-semver.sh` owns dependency majors), `rules/labels.md` (`LB-NN`
— the public projection of a detection, landing in this same release).

`rules/reversibility.md` RV-02 already names public API contracts as an
irreversible class, but nothing *detected* the class mechanically — it
rode on the model noticing, unlike every other class in that list,
which has a cheap structural detector (paths for CI/workflow files,
manifests for new dependencies). `skills/triage/scripts/check-breaking.sh`
is that detector: same polyglot pattern as the other check scripts,
machine-parseable `verdict:` line, one `break:` evidence line per
finding quoting the hunk location. It reads diff text only — no
network, no clone read, no execution.

## What a detection means

- **BC-01 — A detection fires the RV-02 public-API class.** A
  **detection** is a `FAIL` verdict carrying `findings=N` with
  `N ≥ 1` and its `break:` evidence lines — a removed or renamed
  public symbol, a breaking signature change, a removed config key /
  environment variable / CLI flag, a removed or renamed route
  registration, or a migration hunk that drops or narrows. A
  fail-closed `FAIL` carrying `reason=` or `error=` and **no
  findings** (empty diff, unreadable input) is an **infrastructural
  failure, not a detection**: it blocks any PASS-dependent statement
  and is reported in the coverage statement as
  `breaking-change check: not run — <reason>`, but it never fires
  this rule, never drafts the `breaking-change` label, and never
  names an entering condition — fix the input and re-run, or record
  the check as not covered. A detection puts the item in
  `rules/reversibility.md` RV-02.3 (and RV-02.2 as well where the hit
  is a schema hunk; the script cites both). Consequences, all of them
  named, none of them discretionary: the item is **Tier-1 ineligible**
  (`rules/tiers.md` TR-03.2 fails, RV-03), it takes **Tier 2** with
  `irreversible-class touched — breaking-change detected (BC-01)` as
  the **entering condition named in every output** (TR-07.3), its
  undo-path line says what the break costs to reverse (`RV-05` — a
  contract already consumed by clients does not revert cleanly), and
  the `breaking-change` label is **drafted** for the maintainer's
  gated approval where the target repo has one (`rules/labels.md`
  LB-02, landing in this same release; until it does, the detection
  rides the receipt and the deck alone — never a label the agent
  invents, LB-02a). The detection is evidence inside the triage and
  review passes, not a user act: nobody runs breaking-change
  detection; they triage or review, and this runs inside that.

- **BC-02 — The model layers judgment on top of the script, never
  instead of it.** Run the script on **every standard-lane PR with a
  diff — all four categories** — before judging the diff yourself
  (category 4 most of all: refactors and large-scale changes are
  precisely where public symbols get removed en masse, and a G-12
  holding response that silently sat on an undisclosed break would be
  the worst place to have skipped the check); never substitute your
  reading for a scripted check, and never skip it because the diff
  "looks internal" (the same discipline the deterministic gate
  imposes at Step 6a). Then look for what it cannot see: a behavioral contract
  change under an unchanged signature, a default that moved, an error
  or status code that changed, a wire format whose field semantics
  shifted, a newly-**required** parameter (the script does not flag
  added parameters — see its coverage note), a break in a language it
  does not scan. Each such break is a **finding**, structured per
  `rules/lanes.md` L-33 with its `impact`, `ask`, and `scope` fields
  (v0.7.1) and its severity — and it **fires BC-01 exactly as a
  scripted detection does**, with the same entering condition and the
  same drafted label. Script findings and model findings are the same
  class of evidence; only their provenance differs, and each cites it.

- **BC-03 — Absence of detection proves nothing.** A `PASS` means "no
  textual break detected" — never "non-breaking", never "safe to
  fast-lane". The detector is a heuristic over diff text: python and
  JS/TS symbols only, hunk-visible declarations only, semantic breaks
  invisible by construction (BC-02). Two obligations follow. First,
  **disclosure**: every standard-lane item's coverage statement carries
  the standing line `templates/receipt-pr.md` RP-07 defines — breaking
  detection is heuristic and diff-textual; runtime behavior is never
  checked — whichever way the verdict went. Second, the **ratchet**: a
  PASS can only ever be the *absence* of one signal. It never moves an
  item to a lighter lane, category, or tier, never un-fires a trigger,
  never overrides a maintainer's call, and never clears another
  irreversible-class hit (`rules/tiers.md` TR-09, `rules/lanes.md`
  L-04). The detector is one-way: it can make an item heavier and
  nothing else.

- **BC-04 — Dependency majors stay the semver script's job.** A major
  version bump on a dependency is `check-semver.sh`'s `FAIL:major-bump`
  and routes per `rules/lanes.md` F-NN; `check-breaking.sh` skips
  manifest and lockfile paths entirely and prints each one it skipped.
  No overlap, one authority per check — a break counted twice reads as
  two breaks, and a break each script assumes the other caught reads
  as none.
