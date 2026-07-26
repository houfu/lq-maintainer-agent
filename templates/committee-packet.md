# Template — committee packet (escalate lane)

Rendered by `skills/triage/SKILL.md`, `skills/review-pr/SKILL.md`, and
`skills/review-issue/SKILL.md` for every escalated item, per
`rules/escalation-triggers.md` E-20.
The packet is **evidence, not a verdict** (E-23): the agent never
recommends merge/reject on an escalated item, and never delivers the
packet itself — where packets go is an open governance call (design
doc §15 q.1); the destination, once chosen, also carries all sensitive
review state (§3.5) and must be access-controlled. Until then the
packet is handed to the maintainer in-chat to route.

## Field rules

- **CP-01 — Scope statement.** One paragraph: what the item is and
  touches. Derived from the diff/paths/metadata, never from the
  contributor's narrative.
- **CP-02 — Triggers with rule text.** Every fired trigger, by ID,
  with its rule text quoted from `rules/escalation-triggers.md` — the
  committee reads the rule it is being asked to apply.
- **CP-03 — Canon position.** The canon touched, contradicted, or
  **absent**, with citations (path + anchor via `rules/canon-map.md`)
  at the recorded canon SHA. "Canon absent" is stated, never papered
  over.
- **CP-03a — Decision ledger (`rules/decision-scoping.md`).** For
  every escalated item, the D-03 partition, rendered between the
  canon-position table and the checklist results: each **settled**
  sub-question with its four D-04 fields (the decision content quoted
  or tightly summarized — never merely "touched" — and a
  click-through citation at the recorded canon SHA, which the ledger
  names inline: settledness is pin-relative); each **residual** as a
  D-05 atomic sentence with its nearest-canon bounds and drafted
  artifact pointer; each **reserved-human** judgment named with the
  canon/rule that reserves it. Rows come from **agent-read canon
  only** (D-03) — a contributor's "ADR-NNN already allows this"
  appears only as a recorded-then-confirmed-or-corrected claim, never
  as a ledger input, and a failed claim is a finding, never a settled
  row. **A settled row is the agent's finding, not a ruling:** the
  committee verifies it by click, and a member who contests a row —
  the citation does not support the claim, or canon has moved past
  the pin — converts it to a residual on the spot (D-04). An empty
  Settled table is a recordable result; an unperformed partition is
  not (the packet then carries the D-11 line "decision scoping: not
  covered — resumable"). CP-03 remains the summary; the ledger is its
  expansion.
- **CP-04 — Checklist results.** Where a trigger prescribed checks
  (E-07's full vetting checklist), the per-item results, run against
  the diff.
- **CP-05 — Human questions, phrased as questions.** The judgments
  only the committee can make — never pre-answered as
  recommendations. Where the ledger (CP-03a) lists a residual
  decision, the question takes the ratification form: "Ratify, amend,
  or reject drafted decision R-<i>: <atomic sentence>?" — a question
  about a precisely drafted decision is still a question; a
  recommendation to ratify it would not be
  (`rules/decision-scoping.md` D-08). Where the ledger settled a
  sub-question the contribution failed to cite, the question takes
  the confirmation form: "Confirm <anchor> covers this change and
  anchor the item to it?" (D-02 — the trigger stays fired either
  way, L-04). Reserved-human judgments stay free-form questions.
- **CP-06 — Carve-out attachment (E-21).** For a
  suspected-deliberate attack, the full receipt and analysis attach
  here and ONLY here; the public side is the generic
  "escalated for security review" line. And under E-08, exploit
  detail is never elaborated anywhere — packet included — beyond
  identifying where it appears.
- **CP-07 — Pinned fields.** PR head SHA (or n/a for issues), canon
  SHA, agent version, served model ID.
- **CP-08 — Drafted decision artifacts (attachments).** For every
  residual of kind structural or forward-looking, the matching
  drafted artifact attaches under Attachments: a draft ADR rendered
  from `templates/draft-adr.md` (structural), or the S-DE drafted
  DE-XXX / mini-PRD stub — including its amendment and
  workflow-convention annotated forms (D-06; `rules/salvage.md` S-22
  credit). Every draft opens with the DA-01 watermark **verbatim**,
  carries only a placeholder number (`ADR-XXXX`), and is delivered
  exclusively via this packet — the agent never commits, files,
  numbers, or posts one (S-20, D-07), and no draft ever satisfies
  anchoring (`rules/anchoring.md` A-12).

## Template

```markdown
## Committee packet — <PR | issue> #<n>: <title>

Reviewed-at: pr-head `<sha or n/a>` · canon `<sha>` ·
agent `<x.y.z>` · model `<served model ID>`
Author: <login> (<author class, API-determined>)

### 1. Scope statement

<one paragraph: what the item is, what it touches, judged from the
diff, paths, commit metadata, CI status, and author class only.>

### 2. Triggers fired

- **<E-NN>** — "<rule text quoted from rules/escalation-triggers.md>"
  Evidence: <where in the item this fires — file/hunk/paths>.

### 3. Canon touched / contradicted / absent

| Canon | Relation | Citation |
| --- | --- | --- |
| <doc/section/ADR/DE> | <touched / contradicted / absent> | <path + anchor, at canon `<sha>`> |

### 3a. Decision ledger (rules/decision-scoping.md)

**Q — <the question the fired trigger(s) put to humans, one sentence>**

Settled — the agent's findings at canon `<sha>` (verify each by
click before deferring to it; a contested row becomes a residual,
D-04):

| # | Sub-question | What canon decided | Status | Citation |
| --- | --- | --- | --- | --- |
| S-1 | <one sentence> | <decision content, quoted or tightly summarized> | <implemented / partial / deferred-with-commitment / rejected-with-reasoning / n-a> | [<canon:key §x / ADR-NNN / DE-XXX>](link, at canon `<sha>`) |

Residual — the decisions no canon covers (each drafted for ratify /
amend / reject):

- **R-1 — <one declarative, ratifiable sentence>.**
  Kind: <structural | forward-looking | reserved-human>
  Nearest canon bounding it: [<citation>](link) — <what it decides on
  this side>; [<citation>](link) — <the other side>. <if canon
  conflicts: the conflicting sources, both cited, and the conflict
  noted as a finding (D-03).>
  Drafted artifact: <ADR-XXXX (DRAFT), in Attachments | DE/mini-PRD
  stub (plain, "amends …", or workflow-convention form), in
  Attachments | none — reserved-human>

Reserved for humans by canon — never narrowed: <judgment — the
canon/rule that reserves it, e.g. contributor trust
(canon:vetting-playbook), roadmap-worth (RI-08)> <or: none put at
issue by this escalation — the standing human-only items render in
the receipt as always>.

<if no residuals: "Every sub-question this escalation raises is, on
the agent's search, settled by the cited canon. The committee's act
is to verify that — confirm each citation covers its sub-question
(and, for a found-but-uncited anchor, anchor the item to it);
contesting any row converts it to an open decision. The item stays
escalated — a fired trigger is never un-fired (L-04).">

### 4. Checklist results (where a trigger prescribed checks)

| Checklist item | Result |
| --- | --- |
| <item> | <pass / fail / n-a> |

### 5. Questions for the committee

1. <ratification form, where a residual exists: "Ratify, amend, or
   reject drafted decision R-1: '<atomic sentence>'? (draft
   attached, CP-08)">
2. <confirmation form, where the ledger settled an uncited
   sub-question: "Confirm <anchor> covers this change and anchor the
   item to it?">
3. <free-form — reserved-human judgments only>

### Attachments

- <if E-21: the full Triage Receipt for this item (public side was
  reduced to the generic escalation line).>
- <if salvage was run: the decomposition and drafted contributor
  response, for the committee's awareness — humans post everything.>
- <one drafted decision artifact per residual (CP-08): a draft ADR
  from templates/draft-adr.md or a DE/mini-PRD stub — watermarked
  (DA-01), placeholder-numbered, filed only by a human (S-20).>
```
