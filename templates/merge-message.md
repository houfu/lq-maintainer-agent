# Template — drafted squash-merge message (§8.5 audit trailer)

Rendered for every merge candidate: fast-lane items, and standard-lane
items once findings are resolved. **This file is the single
authoritative copy of the trailer format** — render from it, never
freehand, so `git log --grep` queries stay reliable. The human
performs the merge and owns the message; the agent only drafts it
(sign-off line included, which also smooths the GitHub-web-UI merge
path where adding trailers by hand is irritating).

## Field rules

- **MM-01 — Subject.** `<summary> (#<pr-number>)`, ≤72 characters,
  imperative mood, stated from the verified diff — not the PR title
  if the title overclaims.
- **MM-02 — Body.** A few lines: what changed and why, anchored
  (cite the anchor the review verified). No marketing, no contributor
  narrative repeated unverified.
- **MM-03 — Trailer block, exact keys.** One blank line before it,
  then exactly these four trailers, in this order:
  `Triage:`, `Reviewed-At:`, `Disposition:`, `Signed-off-by:`.
  `Reviewed-At` carries all **four pinned fields** — pr-head SHA,
  canon SHA, agent version, and the served **model** ID.
- **MM-04 — Disposition wording.** Standard lane: findings-resolved
  count. Fast lane: the deterministic-gate result. Both name the
  human who reviewed the permanently-open human-only items.
- **MM-05 — Sign-off is the merging human's.** Leave the
  name/email placeholders unfilled unless told who is merging; the
  agent never signs off on anything.
- **MM-06 — Immutable skeleton.** Once merged, this block is the
  deletion-proof audit record (receipt comments are editable; the
  trailer is not). It is the *entire* committed audit surface — no
  receipt files, no ledger docs. Trailers cover merged work only, by
  design.

## Template — standard lane

```text
<summary of the change, imperative, ≤72 chars> (#<pr-number>)

<2–5 lines: what changed and why. Anchor: <kind> <reference>.
Contributed by @<contributor>.>

Triage: standard lane; receipt at <receipt-comment-url>
Reviewed-At: pr-head <sha> / canon <sha> / agent <version> / model <id>
Disposition: <n> findings resolved; human-only items reviewed by <maintainer>
Signed-off-by: <maintainer name> <email>
```

## Template — fast lane (dependency bump / verified typo fix)

```text
<summary, e.g. "Bump <package> from <a> to <b>"> (#<pr-number>)

<1–2 lines: upstream release anchor; e.g. "Anchored to <package> <b>
release notes. Patch-level; no new packages in lockfile churn.">

Triage: fast lane; receipt at <receipt-comment-url>
Reviewed-At: pr-head <sha> / canon <sha> / agent <version> / model <id>
Disposition: deterministic gate 7/7 pass; human-only items reviewed by <maintainer>
Signed-off-by: <maintainer name> <email>
```

## Queryability (why the exact keys matter)

- "Every merge this quarter with its triage disposition":
  `git log --grep='^Triage:' --since=<date>`
- "Which merges were reviewed by agent version X / model Y":
  `git log --grep='^Reviewed-At:.*agent <version>'`

A warn-only lq-ai CI check for missing trailers is an upstream
candidate (design doc §8.5/§11); warn-only stays absolute — merges are
never hard-gated on agent output.
