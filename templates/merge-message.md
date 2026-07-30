# Template — drafted squash-merge message (§8.5 audit trailer)

Rendered for every merge candidate: fast-lane items, and standard-lane
items once findings are resolved. **This file is the single
authoritative copy of the trailer format** — render from it, never
freehand, so `git log --grep` queries stay reliable. The human
performs the merge and owns the message; the agent only drafts it
(sign-off line included, which also smooths the GitHub-web-UI merge
path where adding trailers by hand is irritating).

**Delivery (decided 2026-07-26).** For every merge candidate the
rendered draft is embedded in the internal receipt as a fenced block
(`### Drafted merge message`, `templates/receipt-pr.md` RP-19) and
surfaced on the deck as a paste-ready card — it is **not** presented
as a separate chat deliverable. The human still pastes it whole into
the GitHub merge box.

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
  canon SHA, agent version, and the served **model** ID. On a squash
  merge this four-trailer audit block is preceded by the authorship
  trailers `MM-05a` adds — the block itself, and its internal order,
  is unchanged.
- **MM-04 — Disposition wording.** Standard lane: findings-resolved
  count. Fast lane: the deterministic-gate result. Both name the
  human who reviewed the permanently-open human-only items.
- **MM-05 — Sign-off is the merging human's.** When the operator is
  the API-verified maintainer performing the merge
  (`templates/receipt-pr.md` RP-18), default the name/email to their
  own git identity (`git config --get user.name` / `--get user.email`
  in their clone — the same declaration git itself would commit);
  otherwise leave the placeholders unfilled. The human confirms the
  line when they paste the message into the merge box. The agent
  never signs off on anything — prefilling the merging human's own
  identity for them to commit is not the agent signing.
- **MM-05a — Squash-merge authorship (decided 2026-07-30).** A squash
  merge collapses every commit on the branch into one, so the drafted
  message preserves who actually did the work:
  (i) each contributor's own `Signed-off-by:` trailer(s), copied
  verbatim from their commits, are preserved in the squash commit
  body;
  (ii) a `Co-authored-by: <name> <email>` trailer is added for every
  distinct commit author being squashed, so GitHub attributes the
  contribution to them even though the merging maintainer's account
  performs the commit — this is what keeps authorship as, e.g., the
  contributor rather than the merging maintainer on a squash merge;
  (iii) trailer order is fixed: contributor `Signed-off-by:` line(s)
  first, then the `Co-authored-by:` lines, then the audit block
  (`MM-03`), with the merging maintainer's own `Signed-off-by:` last
  of all — the maintainer's line is always the final trailer in the
  message;
  (iv) in plain language: two `Signed-off-by:` lines on the same
  commit are not a duplicate or an error — the contributor's certifies
  the origin of their contribution under the Developer Certificate of
  Origin, and the merging maintainer's certifies the separate act of
  merging it. Two different certifications, both intentional, both
  meaningful on the git record.
  This does not change `MM-05`'s posture: the agent never signs off on
  anything: it reads commit authors and existing sign-off trailers and
  prefills the Co-authored-by / preserved sign-off lines for the human
  to commit, exactly as it prefills the merging human's own identity.
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

<contributor's own Signed-off-by: trailer(s), copied verbatim from
their commits — omit this line if none exist>
Co-authored-by: <contributor name> <email>
<one Co-authored-by line per additional distinct commit author being squashed>
Triage: standard lane; receipt at ${CLAUDE_PLUGIN_DATA}/<owner>-<repo>/<pr-number>/<head-sha>/receipt.md
Reviewed-At: pr-head <sha> / canon <sha> / agent <version> / model <id>
Disposition: <n> findings resolved; human-only items reviewed by <maintainer>
Signed-off-by: <maintainer name> <email>
```

## Template — fast lane (dependency bump / verified typo fix)

```text
<summary, e.g. "Bump <package> from <a> to <b>"> (#<pr-number>)

<1–2 lines: upstream release anchor; e.g. "Anchored to <package> <b>
release notes. Patch-level; no new packages in lockfile churn.">

<contributor's own Signed-off-by: trailer(s), copied verbatim from
their commits — omit this line if none exist>
Co-authored-by: <contributor name> <email>
<one Co-authored-by line per additional distinct commit author being squashed>
Triage: fast lane; receipt at ${CLAUDE_PLUGIN_DATA}/<owner>-<repo>/<pr-number>/<head-sha>/receipt.md
Reviewed-At: pr-head <sha> / canon <sha> / agent <version> / model <id>
Disposition: deterministic gate 7/7 pass; human-only items reviewed by <maintainer>
Signed-off-by: <maintainer name> <email>
```

Trailer order, top to bottom: contributor sign-off(s) → Co-authored-by
line(s) → the four-key audit block (`MM-03`) → the merging
maintainer's own `Signed-off-by:`, last (`MM-05a`).

## Queryability (why the exact keys matter)

- "Every merge this quarter with its triage disposition":
  `git log --grep='^Triage:' --since=<date>`
- "Which merges were reviewed by agent version X / model Y":
  `git log --grep='^Reviewed-At:.*agent <version>'`

A warn-only lq-ai CI check for missing trailers is an upstream
candidate (design doc §8.5/§11); warn-only stays absolute — merges are
never hard-gated on agent output.
