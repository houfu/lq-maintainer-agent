# Template — PR/issue comment (the short warm note)

Rendered by `skills/triage/SKILL.md`, `skills/review-pr/SKILL.md`,
`skills/review-issue/SKILL.md`, and `skills/design-plan/SKILL.md` for
every reviewed PR or issue. **This is the only thing routinely posted
to a PR or issue from v0.7 on** (design doc v0.7 §8) — the internal
evidence record (`templates/receipt-pr.md` / `templates/receipt-issue.md`)
is no longer posted; it is drafted for the maintainer's local cache
and, once it exists, the community repo's `reviews/<pr|issue>-NNNN/`
(`docs/community-repo.md`). **Render, never freehand**: the field
rules (`PC-NN`) are normative. Posted (or updated in place) only
behind an individual human approval, same as every other draft.

**Delivery (decided 2026-07-26).** The rendered draft is embedded in
the internal receipt as a fenced block (`### Drafted public comment`,
`templates/receipt-pr.md` RP-19) and surfaced on the deck as a
paste-ready card — it is **not** presented as a separate chat
deliverable. The posting flow is unchanged: still tone-gated first,
still one individually approved human write.

One template, two profiles (PR and issue) — the outcome vocabulary
differs (`rules/tiers.md` TR-05 for PRs; `rules/issues.md` IV-01 for
issues), everything else is shared. Prior `receipt:v2` public comments
(pre-v0.7) remain readable for resume (I-09 author verification
unchanged); this template is what the agent drafts going forward.

## Field rules

- **PC-01 — The outcome, first, in plain language.** One sentence,
  translated from the routing vocabulary into words a contributor
  needs no glossary for — never the enum, never a rule ID:
  - PR `merge` → "this looks ready to merge once CI is green."
  - PR `merge-after-<fix>` → "we'd love one change before merging:
    <the named fix, in plain words>."
  - PR `discuss-<question>` → "we want to talk through one question:
    <the specific question>."
  - PR/issue `route-to-design` or issue `recommendation: design` →
    "this is bigger than a code review — we're drafting a design plan
    from it, and you'll see it before anything is decided."
  - Issue `needs-info` → "we need a bit more before we can act on
    this: <the specific missing piece>."
  - Issue `decompose` → "there's a lot here — we're splitting it into
    smaller pieces so each can move on its own."
  - Issue `proceed` → "this is ready to become a PR."
  - PR/issue `security-escalate` → the PC-08a generic line, verbatim:
    "This item has been escalated for security review." — no outcome
    sentence, no thanks framing that could read as engaging with
    attack content; this template is not used for anything else on
    an E-21 item.
  - `hold` → the hold framing of
    `templates/contributor-responses/contest-acknowledgement.md`.
  The sentence is specific to *this* item — never boilerplate.
- **PC-02 — Genuine, specific thanks.** Names the actual thing done —
  the bug found, the case covered, the question raised — concretely,
  not effusively (`rules/conduct.md` CD-04). "Thanks for this" alone
  never satisfies the rule.
- **PC-03 — Exactly one next step, and who owns it.** Stated plainly:
  theirs (a named, doable ask) or ours ("nothing needed from you —
  this is on us now" is a valid, complete answer) — never both, never
  a list (`rules/tone-gate.md` TG-03.2).
- **PC-04 — Deck link, optional, and only once the community repo
  exists.** Until `docs/community-repo.md` bootstraps (open question
  §12 q.10 of design doc v0.7), the deck stays a local view and this
  line is **omitted entirely** — no placeholder, no "coming soon".
  Once the repo exists, the line links the item's public deck
  (`reviews/<pr|issue>-NNNN/deck.html`).
- **PC-05 — Attribution line, mandatory.** The same line every
  receipt and drafted response carries — agent version, posting
  maintainer, linked to `docs/bot-behavior.md`
  (`templates/contributor-responses/README.md` CR-04). Not removable.
- **PC-06 — Hard bans.** This comment never contains: a table; a
  checklist; a rule, lane, tier, or category ID (`G-NN`/`TR-NN`/
  `RV-NN`/`E-NN`/…) or any lane/tier jargon, glossed or not; a
  self-attestation cross-check result in any form, tabulated or
  prose (`rules/self-attestation.md` T-07, `rules/tone-gate.md`
  TG-02.2); or burden-axis grades. It is pure prose — no markdown
  structure beyond paragraph breaks.
- **PC-07 — Tone-gated, mandatorily.** Every rendering of this
  template passes `rules/tone-gate.md` before it is offered for
  posting — no exception, no fast path. A draft that fails the gate
  is rewritten, not shortened around.
- **PC-08 — No machine footer.** State (category, tier, outcome,
  undo, lane, findings, coverage) lives only in the internal receipt
  (design doc v0.7 §8). This comment carries no HTML comment, no
  enumerated block, nothing machine-parsed — it is addressed to a
  person, not to a future session.
- **PC-08a — Carve-outs.** Suspected-deliberate attack
  (`rules/escalation-triggers.md` E-21): the public comment reduces to
  the generic line "This item has been escalated for security
  review." plus attribution — no outcome sentence, no thanks framing
  that could read as engaging with attack content. Vulnerability-
  suspect issues get no comment from this template at all (`rules/issues.md`
  C-40) — only the private-advisory redirect
  (`templates/contributor-responses/vulnerability-redirect.md`).
- **PC-09 — Update in place, with a ping.** Because this comment is
  now the living public artifact (design doc v0.7 §8), it follows the
  receipt's §8.4 convention exactly: the agent locates its own prior
  comment and edits it rather than posting a new one (one
  permission-gated approval per update), and — because edited
  comments notify nobody on GitHub — every in-place update is paired
  with the one-line ping below, drafted and posted through the same
  gated flow.
- **PC-10 — Length.** Under ~12 rendered lines, attribution line
  included. If the outcome needs more than that to state honestly,
  the extra belongs in the internal receipt or the deck, not here —
  this comment points at where the depth lives; it does not carry it.

## Template

```markdown
Hi @<contributor> — <PC-01 outcome sentence, plain language, specific
to this item>.

<PC-02: one to two sentences of genuine, specific thanks — the actual
thing done, named.>

<PC-03: the one next step, and who owns it — "over to you: <ask>" or
"nothing needed from you — this is on us now.">

<if PC-04 applies: The fuller writeup, if you're curious: <deck link>.>

---
*Drafted by [lq-maintainer-agent](https://github.com/legalquants/lq-maintainer-agent/blob/main/docs/bot-behavior.md)
v<x.y.z>; reviewed and posted by @<maintainer>.*
```

## Update ping — one-line reply (mandatory companion to in-place edits)

```markdown
Comment updated (lq-maintainer-agent v<x.y.z>): <what changed, in
plain language — e.g. "CI is green now, so this is ready to merge">.
```

One line, plain language, no footer, no quoted contributor content —
the same discipline as the receipt's update ping
(`templates/receipt-pr.md` RP-14), applied to this comment now that it
is the artifact watchers actually read.
