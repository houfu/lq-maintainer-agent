# Template — Triage Receipt, issue profile

Rendered by `skills/triage/SKILL.md` (Steps 7–8) for every triaged
issue **except vulnerability-suspect items, which get no public
receipt at all** (`rules/issues.md` C-40 — the only output there is
the drafted private-advisory redirect,
`templates/contributor-responses/vulnerability-redirect.md`).
**Render, never freehand.** Posted (or updated in place, design doc
§8.4) only behind an individual human approval.

Footer schema, update-ping convention, and shared field semantics are
defined once in `templates/receipt-pr.md` and are normative here; this
file states only the issue-profile deltas.

## Field rules

- **RI-01 — Classification line.** Classification (bug / feature /
  question / spam-suspect) + assigning rule ID (C-NN,
  `rules/issues.md`), **and** a lane + assigning rule like any other
  item (issues are never fast; most commonly standard or escalate).
- **RI-02 — References / cross-reference record (`C-60`, `IV-03`).** The
  **agent-performed** cross-reference (never the filer's self-attested
  search, `I-13`), sorted into four buckets — **duplicate**, **adjacent**,
  **contradicting**, **linked** — over open issues, open PRs, the DE list,
  and the roadmap (routed via `rules/canon-map.md`). The filer's "I
  searched, no duplicates" claim is recorded and then confirmed or
  corrected by the agent's own read; a discrepancy is a finding. Every
  match and every canon citation renders as a **click-through link**
  (`rules/canon-map.md` link rule — canon docs pinned to the canon SHA,
  issues/PRs by number, agent-constructed from validated sources only).
  "Nothing matched in a bucket" is a recordable result; an unperformed
  search is not.
- **RI-03 — Repro assessment (bugs).** Complete / partial / absent,
  itemized (versions, steps, expected vs. actual, logs), with the
  drafted request for missing pieces rendered from
  `templates/contributor-responses/repro-request.md`. An unanchored
  bug report is a repro request, never an escalation
  (`rules/anchoring.md` A-07).
- **RI-04 — Salvage section.** Same rules as
  `templates/receipt-pr.md` RP-06, with the issue-side split: drafted
  **titles + bodies** for each split issue, filed as GitHub
  sub-issues of the original, each crediting the original filer.
  The mechanical-split advisory line is not applicable to issues
  (there is no diff to partition), and the footer's
  `split_verified: false` still renders.
- **RI-05 — Slop disposition (§6.1).** Applied conservatively — only
  obvious slop (fabricated APIs/citations, tests asserting nothing,
  text answering a different repo's question, boilerplate detached
  from the item); anything arguable routes standard like every other
  item. When applied, the drafted response is
  `templates/contributor-responses/slop-close.md` — a
  close-with-pointer, never an insult — and the human posts it or
  doesn't. Agent-authored contributions are a distinct author class:
  never auto-declined, never fast-laned, anchors never waived.
- **RI-06 — Coverage statement.** What was checked and what was not,
  including the permanent line: **runtime behavior — never checked**
  (no repro is ever executed by the agent; reproduction is a human,
  sandboxed act per the sandbox-discipline doc).
- **RI-07 — Pinned fields.** Canon SHA, agent version, served model
  ID. There is no PR head SHA for an issue; the field renders `n/a`
  (and `n-a` in the footer) rather than being omitted, so the
  four-field tuple stays parseable across profiles.
- **RI-08 — Human-only items, permanently open.** Is this worth
  roadmap space, and contributor-engagement tone. Never render as
  resolved.
- **RI-09 — Contest/hold, attribution, footer, update ping.** Exactly
  as `templates/receipt-pr.md` RP-10–RP-14.
- **RI-10 — Conduct + next steps.** The receipt and every drafted reply
  meet `rules/conduct.md` (`CD-NN`) / `canon:code-of-conduct`
  (`rules/issues.md` C-80), and the receipt names the maintainer's next
  steps for the issue (C-81) — post the repro request, route the
  advisory, link the duplicate, promote the DE, or make the RI-08
  human-only calls.
- **RI-11 — Recommendation, obstacles, references (the issue deck,
  §8.6a).** The issue carries **no five-axis `burden` block** — those axes
  grade a code diff an issue does not have (`rules/burden.md` scope note).
  It carries instead the issue-deck fields (`rules/issues.md` `IV-NN`):
  - a **Recommendation** headline — one enumerated state
    (`needs-info` / `decompose` / `proceed` / `escalate`, `IV-01`),
    derived from the classification, repro/anchor status, salvage, and any
    escalation trigger, and recorded in the footer as the single
    `recommendation` field (`IV-06`);
  - a **Predicted obstacles** list (`IV-02`) — a rule-grounded preview of
    what a PR built from this issue would run into, each obstacle citing
    the rule/canon that would fire; **visible body only, never the
    footer**, and never a graded level;
  - a **References** section (`IV-03`) — the `C-60` cross-reference:
    matched duplicates (open issues + DE list), related open PRs, and the
    roadmap/DE entry the ask maps to.

  All other honesty rails are unchanged (`IV-05`): the deck is a private
  local view, coverage lists runtime as never-checked (RI-06), and the
  RI-08 human-only judgments render permanently open. A
  **vulnerability-suspect** issue gets no receipt and no deck at all
  (C-04/C-40) — recommendation included.

## Template

```markdown
## Triage Receipt — issue #<n>: <title>

**Recommendation:** <Needs info | Decompose | Proceed | Escalate>
(rule: IV-01) — <one-line plain-language reason>

**Classification:** <bug | feature | question | spam-suspect>
(rule: <C-NN>) · **Lane:** <docs | standard | escalate>
(confidence: <high | medium | low>; assigning rule: <rule-id>)

<if held:>
> **Held at contributor request.** "<verbatim quoted request>"
> This item is marked human-only; the agent drafts nothing further for
> it except at explicit maintainer request. A maintainer will respond.

### Predicted obstacles — if this became a PR (IV-02)

A rule-grounded preview, not a grade. Each line names the rule or canon
fact that would fire if the ask were submitted as-is.

- <obstacle> — <rule/canon that would fire, e.g. E-04 / S-DECLINE / S-DUP #n>
<or, if none: "None foreseen — a single, anchored, in-scope ask.">

### References (IV-03)

Searched **by the agent** (not the filer's self-attestation, I-13): open
issues; open PRs; the DE list; the roadmap. Filer's claim: <"searched, no
duplicates" | none> — <confirmed | corrected: …>. Every entry links.
- **Duplicate:** <none | [#n](link) / [DE-XXX](link) with one-line relation,
  cross-referenced both directions>
- **Adjacent:** <none | [#n](link) / [PR #n](link) / roadmap item — overlapping
  scope, one line each>
- **Contradicting:** <none | [canon:prd §x](link) non-goal / superseding
  [ADR-NNN](link) / declined DE — the conflict that may force escalate (E-04)>
- **Linked:** <none | [DE-XXX](link) / [#n](link) — dependency / blocked-by /
  referenced, one line each>

### Repro assessment (bugs; n/a otherwise)

Repro: <complete | partial | absent>

| Piece | Present |
| --- | --- |
| Version(s) | <yes / no> |
| Steps to reproduce | <yes / no> |
| Expected vs. actual | <yes / no> |
| Logs / output | <yes / no> |

Likely subsystem(s): <repo-relative pointers>
Suggested severity: <one of the project's severity levels>
<if pieces missing: request drafted from contributor-responses/repro-request.md.>

### Anchor (features; n/a otherwise)

| Kind | Reference | Verified |
| --- | --- | --- |
| <PRD / ADR / Roadmap / DE-XXX> | <citation> | <yes / no — "canon absent" escalates, never improvises> |

### Salvage decomposition (if applied)

| Part | One-sentence statement | Disposition |
| --- | --- | --- |
| P-<i> | <sentence> | <S-ACCEPT / S-DOCS / S-DE / S-DUP / S-DECLINE / S-SLOP> (<reason or citation>) |

Drafted split issues (to be filed as sub-issues of this one, by a
human): <titles, one line each; full bodies delivered in-session>.

### Coverage statement

Covered: <e.g. classification, duplicate search, repro assessment>
Not yet covered: <e.g. anchor verification — resumable>
Never checked, by design: runtime behavior — the agent does not
execute repro steps or contributed code.

### Human-only judgments — permanently open

- [ ] Worth roadmap space — a human prioritization call.
- [ ] Contributor-engagement tone — a human community call.

### Reviewed-at

| Field | Value |
| --- | --- |
| PR head SHA | n/a (issue) |
| Canon SHA | `<sha>` |
| Agent version | `<x.y.z>` |
| Model | `<served model ID>` |

---
*Drafted by [lq-maintainer-agent](https://github.com/legalquants/lq-maintainer-agent/blob/main/docs/bot-behavior.md)
v<x.y.z>; reviewed and posted by @<maintainer>.*

<!-- lq-maintainer-agent:receipt:v1
profile: issue
item: <owner>/<repo>#<n>
lane: <docs|standard|escalate>
assigning_rule: <rule-id>
confidence: <high|medium|low>
demoted_from: <lane or null>
triggers: [<E-NN>, ...]
classification: <bug|feature|question|spam-suspect>
classification_rule: <C-NN>
recommendation: <needs-info|decompose|proceed|escalate>
held: <true|false>
pinned:
  pr_head_sha: n-a
  canon_sha: <sha>
  agent_version: <x.y.z>
  model_id: <served model ID>
deterministic_checks:
  author_identity: n-a
  manifest_only: n-a
  semver_delta: n-a
  no_new_packages: n-a
  osv_lookup: n-a
  release_age: n-a
  ci_green: n-a
findings:
  - {id: F-1, severity: <blocking|major|minor>, disposition: <trivial|relayable|structural>}
findings_filtered: <integer, 0 if none>
salvage:
  applied: <true|false>
  parts:
    - {id: P-1, disposition: <S-ACCEPT|S-DOCS|S-DE|S-DUP|S-DECLINE|S-SLOP>}
  split_proposed: <true|false>
  split_verified: false
duplicate_search: <performed|n-a>
coverage:
  - {item: classification, status: <covered|not-covered>}
  - {item: duplicate-search, status: <covered|not-covered|n-a>}
  - {item: repro-assessment, status: <covered|not-covered|n-a>}
  - {item: anchor, status: <covered|not-covered|n-a>}
  - {item: salvage, status: <covered|not-covered|n-a>}
  - {item: runtime-behavior, status: never-by-design}
-->
```

## Vulnerability-suspect carve-out — reminder

No rendering of this template, ever, for a vulnerability-suspect
issue (C-04/E-08). The structured state block those items emit **in
session output only** (for resume and eval grading) uses the same
footer schema, is never drafted for posting, and contains no exploit
detail — see `rules/issues.md` C-40 and `evals/run-checks.md`.
