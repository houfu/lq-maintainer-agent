# The community repo — design for the public home of the project's reviews

Status: **pre-bootstrap** (design doc v0.7 §12 q.10). This document is
the proposed design, not a running system: the repo named below does
not exist yet. It is written now because the v0.7 deliverable split
(design doc v0.7 §8) — deck public, PR/issue comment short, receipt
internal — is shaped to drop into this layout the moment the repo is
created, without another redesign. Until then, every artifact this
document describes lives in the maintainer's local cache
(`${CLAUDE_PLUGIN_DATA}`) exactly as it does today.

## Purpose

A public home for the project's own analyses of its PRs and issues —
not the code, not the canon, but the project's **thinking about**
its incoming work: reading decks, design plans, and published ADR
drafts under discussion. Carried from design doc v0.7 §1 and §8:

- **The deck is the product.** Three weeks of live operation showed
  the reading deck — plain-language, verdict-first — is the artifact
  the maintainer actually uses. A public home lets the deck *be* the
  public artifact instead of a private view reconstructed from a
  comment.
- **A design mature somewhere durable.** A category-1 (greenfield)
  contribution's plan — decision inventory, ADR drafts, atomic
  decomposition (§9) — today lives only in-session and in a committee
  packet. A public repo gives it a linkable home the contributor and
  committee can both point at.
- **One index beats scattered comments.** "What's the state of
  PR #317" today means finding the right GitHub comment. A
  `README.md` index (below) makes the whole queue's state one page.

## Proposed layout

```
reviews/
  pr-317/
    deck.html       # the public reading deck (rules/tiers.md TR-10 headline)
    state.yaml       # the enumerated footer state (rules/burden.md B-10)
    notes.md         # free-text evidence: findings, coverage, next steps
  issue-482/
    deck.html
    state.yaml
    notes.md
plans/
  pr-317/            # only for category-1 items routed to the design path
    plan.md          # skills/design-plan/ output (design doc v0.7 §9)
adr-drafts/
  ADR-0031-DRAFT-<slug>.md   # templates/draft-adr.md output, pre-ratification
README.md            # the index — see below
```

- **`reviews/<pr|issue>-NNNN/`** — one directory per reviewed item,
  keyed by its GitHub number. `deck.html` is the self-contained,
  no-JavaScript render `skills/triage/scripts/render-deck.sh` already
  produces (design v0.6 §8.6); `state.yaml` is the enumerated footer
  block (`lq-maintainer-agent:receipt:v2` schema, unchanged) lifted
  out of the HTML comment into its own file; `notes.md` is the
  free-text evidence the footer deliberately never carries —
  findings, coverage statement, self-attestation cross-check,
  decision-scoping ledger. Together `state.yaml` + `notes.md` **are**
  the internal receipt (`templates/receipt-pr.md` / `templates/receipt-issue.md`),
  split into a machine part and a prose part instead of one file with
  a hidden footer, because a real file tree needs no concealment
  discipline.
- **`plans/pr-NNNN/`** — a category-1 item's design-path output
  (`skills/design-plan/`): the plan, predicted obstacles, and atomic
  decomposition. Keyed by the originating PR or issue number, even
  though the plan precedes any implementing PR.
- **`adr-drafts/`** — every drafted ADR still carrying the
  `templates/draft-adr.md` watermark (DA-01), unratified, unnumbered.
  A *waiting room*: a ratified draft moves to lq-ai's `docs/adr/`
  under a real number and its file here is deleted, not
  archived-in-place, so nothing here can be mistaken for canon.
- **`README.md`** — the index: one action-first line per item, newest
  first — `#317 — merge-after: pin the timeout default → deck` — so
  the repo's whole state is one page, not a directory listing.
  Regenerated whenever a `state.yaml` changes; never hand-maintained
  prose, for the same reason the merge-commit audit trailer
  (design v0.6 §8.5) is generated, not maintained.

## Naming and identity

- **Keyed by number, always.** Every directory is `<kind>-<number>`
  against the single canonical remote (`canon:repo`, `rules/canon-map.md`)
  — the same numbers GitHub already uses, so a link never needs a
  second lookup table.
- **Every artifact carries the four pinned fields.** Deck, state file,
  and notes all restate PR-head SHA (or `n-a` for issues), canon SHA,
  agent version, and served model ID (design doc §3.4) — reproducibility
  does not weaken for moving out of a GitHub comment.
- **Every artifact carries the attribution line** linking
  `docs/bot-behavior.md`, exactly as the PR/issue comment and the
  internal receipt do (`templates/pr-comment.md` PC-05) — a public
  repo of AI-assisted analysis is precisely where "who posted this and
  under what rules" must stay one click away.

## State home

Today, the enumerated footer state (`category`/`tier`/`outcome`/`undo`
and everything else in the `lq-maintainer-agent:receipt:v2` schema)
lives in the maintainer's local cache — there is no other durable
home yet. Once this repo exists, `reviews/<kind>-NNNN/state.yaml`
**becomes** that state's durable home: a resuming session reads
`state.yaml` first, the local cache second. Nothing about the schema
changes in the move — `templates/receipt-pr.md` remains the
authoritative definition; this repo just gives the YAML a file
instead of an HTML comment to live in.

**The `canon:` key is added only when the repo exists.** Per
`rules/canon-map.md`'s dangling-key rule ("if a path in this table
fails to resolve at runtime, treat the routing as unknown... do not
guess a replacement path"), no `canon:community-repo` row is added
until there is a real repository to resolve it against. Until then,
any rule citing this design cites `docs/community-repo.md` in *this*
repo — never a placeholder path pretending the repo already exists.

## Publishing flow

Human-gated, like every write this agent makes (design doc v0.7 §10,
"a human decides, every time"):

1. The agent drafts the deck, `state.yaml`, `notes.md`, and (for
   category-1 items) the plan or ADR draft — locally, same cache as
   today.
2. The maintainer reviews the drafted files in the same session flow
   as any other draft — the destination being a repo, not a PR
   comment, skips no review step.
3. The maintainer pushes. **The agent never pushes to the community
   repo directly** — no write credential for it is ever added to any
   allowed-tools list, exactly as none exists for merging, approving,
   or closing on lq-ai itself. A push is the human's own git
   operation.
4. A ratified ADR draft is *removed* from `adr-drafts/` here and
   lands, numbered, in lq-ai's `docs/adr/` — the same human-performed
   step §9 already describes; this repo is where the draft waited,
   never where it was decided.

This mirrors, at repo scale, what `docs/bot-behavior.md` already
states for lq-ai: "it cannot post anything on its own."

## Privacy / carve-outs

**Never published here, full stop, no exception:**

- **Suspected-deliberate-attack items** (`rules/escalation-triggers.md`
  E-21). These stay inside the committee packet only — the public
  comment reduces to the generic escalation line
  (`templates/pr-comment.md` PC-08a), and nothing more detailed is
  ever drafted for this repo either.
- **Vulnerability-suspect issues** (`rules/issues.md` C-40, E-08). No
  receipt, no deck, no comment, and no entry here — the only output
  is the private-advisory redirect. The carve-out is total, not
  partial-with-redaction.
- **Committee packets.** `templates/committee-packet.md` may carry
  reserved-human judgments and contested findings not yet safe to
  make public even for an ordinary item — never mirrored here. What
  the committee ratifies (an ADR, a plan) may become public through
  the flow above; the packet that produced it does not.

No maintainer-only judgment (contributor trust, roadmap prioritization
— the RP-09/RI-08 permanently-open items) is ever resolved by
publishing it here; those stay open exactly as in the internal
receipt.

## What is NOT here

To keep this repo legible as *one thing* — the project's public
reasoning about its own queue — three categories stay elsewhere:

- **The lq-ai code itself.** This repo holds analysis, never a
  mirror, fork, or vendored copy of `legalquants/lq-ai`.
- **The canon.** PRD, ADRs (once ratified), ROADMAP, CONTRIBUTING, and
  the rest stay in lq-ai, where `rules/canon-map.md` already routes to
  them. This repo cites canon by link; it never restates or forks it.
- **Committee packets**, per the carve-out above — maintainer-facing
  material with no public-readiness bar applied yet.

## Open questions this document does not close

Carried forward, not resolved here (design doc v0.7 §12 q.10):

- **Name and visibility** of the actual repository — public from
  creation, or public after an initial seeding pass over already-
  closed items.
- **The bootstrap moment** — a release milestone, or a threshold
  number of decks accumulated locally.
- **Whether `README.md` regeneration is agent-drafted-and-human-pushed
  or a small deterministic script**, parallel to `render-deck.sh`
  (design v0.6 §8.6) — likely the latter, for the same reason the
  deck itself is a deterministic render, but undecided until the repo
  exists to test it against.
