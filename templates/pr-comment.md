# Template — PR/issue comment (the short warm note)

Rendered by `skills/triage/SKILL.md`, `skills/review-pr/SKILL.md`,
`skills/review-issue/SKILL.md`, and `skills/design-plan/SKILL.md` for
every reviewed PR or issue. **This is the only thing routinely posted
to a PR or issue from v0.7 on** (design doc v0.7 §8) — the internal
evidence record (`templates/receipt-pr.md` / `templates/receipt-issue.md`)
is no longer posted; it is drafted for the maintainer's local cache
and, once the public reviews site is live, published from there to
the item's own page (`rules/publishing.md`). **Render, never freehand**: the field
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
- **PC-02 — Genuine, specific thanks, benefit first.** Names the
  actual thing done — the bug found, the case covered, the question
  raised — concretely, not effusively (`rules/conduct.md` CD-04), and
  leads with **what it does for the project and its users**, not
  with the review process ("this closes the gap where a mid-stream
  429 surfaced half a response" before anything about tests, scope or
  checks). "Thanks for this" alone never satisfies the rule, and
  neither does a sentence about the process. *(Benefit-first added in
  v0.8 after nine corrections in nine sessions: "in relation to the
  project, not the process".)*
- **PC-03 — Exactly one next step, and who owns it.** Stated plainly:
  theirs (a named, doable ask) or ours ("nothing needed from you —
  this is on us now" is a valid, complete answer) — never both, never
  a list (`rules/tone-gate.md` TG-03.2).
- **PC-04 — The flow-page link, optional, and only once the site is
  live.** Until the public reviews site has had its first scheduled
  push and a maintainer has read it (`rules/publishing.md` PB-13),
  this line is **omitted entirely** — no placeholder, no "coming
  soon". Once it is live, the line carries **one** link: the item's
  own flow page, `<site>/pr-<number>/` or `<site>/issue-<number>/`,
  the site base taken from the `canon:community-repo` row of
  `rules/canon-map.md`. Never the deck, a head directory or the index:
  the flow page is the entrypoint (PB-15) and the deck is one click
  inside it. The same link every time this item is commented on,
  whatever head was reviewed; a second review does not add a second
  link. The link is posted at review time, and the page it names may
  not exist yet — the site refreshes on the maintainer's schedule, and
  an item may be unselected, held or refused — so the site's own
  not-found page says what that means and points back to the item on
  GitHub; the comment itself never promises the page is there.
- **PC-05 — Attribution line, mandatory.** The same line every
  receipt and drafted response carries — agent version, posting
  maintainer, linked to `docs/bot-behavior.md`
  (`templates/contributor-responses/README.md` CR-04). Not removable.
  The maintainer handle is prefilled with the API-verified session
  identity (`templates/receipt-pr.md` RP-18) and confirmed at the
  gated posting approval; unverified, it stays a visible placeholder.
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
- **PC-11 — Seeing it running (v0.7.6, `rules/uat.md` UA-03/UA-10).**
  Driven by the receipt's `uat:` block (`templates/receipt-pr.md`
  RP-22), never by the contributor's own account of their change:
  - **Required, not yet passed at the current head** (`pending`,
    `not-reached`, or a pass at an older head): **at most one** plain
    sentence saying the maintainers want to see the change running
    before it merges — e.g. "Before this merges, we'd like to see it
    running ourselves." It qualifies the PC-01 sentence rather than
    contradicting it: a `merge` outcome never reads as "ready to merge"
    unqualified while this holds. It is ours, not a second ask — the
    PC-03 next step stays the only one, and it is the contributor's
    only if the maintainers genuinely need something from them to run
    it.
  - **Failed:** the divergence is described like any other ask — what
    a person sees on that screen against what was expected, in plain
    words, as the PC-01 / PC-03 named change. No screenshot is attached
    or linked by the agent (whether one is shared is the maintainer's
    call, UA-10).
  - **Recommended or n-a:** nothing — no sentence, no mention.
  Never the "UAT" acronym, never a rule ID, gate or status word, never
  "sandbox" or "runner" — PC-06's bans apply to this sentence exactly
  as to every other, and it passes the tone gate (PC-07) with the rest
  of the draft.

## Template

```markdown
Hi @<contributor> — <PC-01 outcome sentence, plain language, specific
to this item>.<if PC-11 applies: <one plain sentence — we'd like to see
it running before it merges>.>

<PC-02: one to two sentences of genuine, specific thanks — the actual
thing done, named.>

<PC-03: the one next step, and who owns it — "over to you: <ask>" or
"nothing needed from you — this is on us now.">

<if PC-04 applies: The record of this review, if you're curious: <site>/<pr|issue>-<number>/>

---
*Drafted by [lq-maintainer-agent](https://github.com/houfu/lq-maintainer-agent/blob/main/docs/bot-behavior.md)
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
