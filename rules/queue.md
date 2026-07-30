# Queue — merge-order groups and mergeability (batch mode)

Normative data for the batch-mode queue router (decided 2026-07-30,
motivated by field feedback: a maintainer running a full dependabot
sweep needs to know which open PRs collide with each other before they
start clicking merge, not after the second rebase). Loaded at runtime
by `skills/triage/SKILL.md` in batch mode only. Every rule carries a
stable ID (`Q-NN`); every merge-order line in the digest cites the rule
that produced it. Companion rule sets: `rules/lanes.md` (`L-NN`/`F-NN`
— the deterministic gate whose OSV signal and CI-green result feed
Q-02's ordering), `rules/anchoring.md` (`A-NN` — the upstream-release
anchor a security-relevant bump is checked against),
`rules/stale-sweep.md` (the other batch-only guardrail file, same
"drafts and reports, never acts" posture), `rules/canon-map.md` (routes
`canon:codeowners` for the security-boundary check below).

## Merge-order groups

- **Q-01 — Groups are computed from evidence, never from labels or
  titles.** In batch mode, two or more open PRs whose `files` (already
  fetched at Step 3) touch the **same dependency manifest and/or
  lockfile** form a **merge-order group**. Membership is decided
  strictly from the fetched file paths — never from a `dependencies`
  label, a title's package name, or the "Dependabot commands" body
  boilerplate — the same evidence-only posture `rules/lanes.md` L-02
  holds for lane assignment and `rules/salvage.md` holds for
  decomposition. A group exists **iff at least two** open PRs share a
  manifest/lockfile path; a PR that shares no manifest with anything
  else in the queue simply carries no `merge_order_group` — it is not
  a group of one.
- **Q-01a — Why a group matters.** Merging any one member changes the
  shared manifest/lockfile on the base branch, so every *other*
  member's `mergeStateStatus` and CI-green (F-07) go stale the moment
  that merge lands — even though nothing in the other PR's own diff
  changed. Reporting each member as an independent merge candidate,
  with no word about this, is what turns "click merge" into "babysit
  the rebase of everything else in the group": the collision was
  already visible in the fetched data and the digest said nothing.

## Ordering within a group

- **Q-02 — Security-relevant first, then whatever minimizes the
  rebase cascade.** Within a merge-order group, the recommended order
  is: **(1) the advisory-backed / security-relevant member(s) first**
  — a bump anchored to a fixed CVE/GHSA in its upstream release
  (`rules/anchoring.md` A-03), or one whose changed path also matches a
  CODEOWNERS security-boundary pattern (`canon:codeowners`) — **then
  (2)** an order for the remaining members that leaves the fewest
  files/hunks in conflict for whoever rebases next. Security relevance
  is read off signals the deterministic gate already computed (the F-05
  OSV/advisory lookup and the anchor) — never off a PR body's "urgent"
  or "security fix" framing, the same social-engineering guard F-10
  applies to majors. Where no member is advisory-backed, the ordering
  is a stated judgment call, not a second deterministic gate, and the
  digest says so.
- **Q-02a — The cost is stated per PR left in the group.** For every
  group, the digest names what merging the recommended-first PR
  **invalidates**: which other members lose their clean
  `mergeStateStatus` and/or CI-green and now need a rebase and a CI
  re-run. State it per remaining PR — "merge #441 first; #454 and #462
  need rebase + CI re-run after" — never as one vague "the group needs
  rework" line that leaves the maintainer to work out who.

## Report-only

- **Q-03 — Mergeability and merge order are reported, never acted
  on.** The agent never merges, rebases, or re-triggers CI for any
  member of a group — one human click per write stands here exactly as
  everywhere else in this skill (`skills/triage/SKILL.md`'s "never
  batch-post, never post unprompted"; `skills/review-pr/SKILL.md`'s
  "never batch approvals implicitly"). This is worth restating for the
  queue specifically because a merge-order *recommendation* can read,
  to an unwary maintainer, like a worklist the tool might start
  clearing on its own. It never does: every member still gets its own
  individual triage/review output and its own individual human click,
  in whatever order the human actually merges them.
