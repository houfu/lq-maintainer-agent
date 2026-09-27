# Tier 2 — the deep dive (`review-pr` Step 5)

Reference file, loaded **on demand** by
`skills/review-pr/SKILL.md` Step 5 and by nothing else. A Tier-1 quick
pass — the default, and the majority of runs — never reads this file.
It is the v0.6 four-pass machinery, unchanged in substance: same
passes, same member prompts, same filter stage, same budget gate.

You are reading this because a `TR-07` condition fired. **Name that
condition in every output of this step.**

Step numbers here (Step 2's cache, Step 3's fetch, Step 7's packet)
refer to `skills/review-pr/SKILL.md`; `${CLAUDE_PLUGIN_ROOT}` resolves
as it does there. Rule IDs are normative data in `rules/` and are read
there, never recalled.

### 5.1 — Estimate the budget, then dispatch the four-member team

Stage the diff and PR metadata already fetched in Step 3 for the team.
**Run `check-breaking.sh` yourself before dispatching** and stage its
output alongside the diff: members hold Read/Grep/Glob only and cannot
run it, and both the security-vetting and code-quality passes reason
about the same surface it reports — a `FAIL` is already the entering
condition for this deep dive where BC-01 is why you are here, and its
`break:` lines tell those two passes exactly which hunks carry a
contract change. Its `PASS` is staged with the same caveat it prints:
"no textual break detected", never "non-breaking" (`BC-03`), and the
semantic breaks it cannot see remain the passes' own job (`BC-02`).

**Budget gate first (design §9).** Estimate the cost of the dispatch
from the diff size, file count, and the subsystem surface the
code-quality pass will walk. Deep dives are opt-in above a per-PR
ceiling in the **$1–5 band** — default ceiling **$5** unless the
maintainer has set a different ceiling within the band. Report the
estimate; if it exceeds the ceiling, **ask before dispatching** and
proceed only on explicit opt-in. Either way the user may trim passes
for a cheaper subset run — a partial record with an honest coverage
statement is legitimate. Digest-level triage stays single-session, and
the Tier-1 quick pass rides no budget gate at all (`TR-04`); the team
is for depth, not breadth.

Launch **four parallel subagents via the Task tool**, one per pass,
each with a fresh context and a fully self-contained prompt. **Every
member is dispatched as the plugin's `review-pass` agent**
(`agents/review-pass.md`) — never as a general-purpose agent. That
agent's `tools` frontmatter grants **Read/Grep/Glob only**: no Bash
(so no execution of anything, and no `git`), no `gh`, no network, no
write tools. This is the programmatic layer of the read-only posture
(design §9/§10); the session-wide PreToolUse hook
(`hooks/hooks.json` → `settings/hooks/block-writes.sh`) is a second
programmatic layer behind it. Members therefore cannot run
`git log`/`git show`; when a pass's coverage note says it needed
history, you (the lead) run the read-only git command yourself and
fold the answer into the merge step. Do not reuse a member for a
second pass. The shared constraints in
`${CLAUDE_PLUGIN_ROOT}/skills/review-pr/references/member-constraints.md` additionally go verbatim into
every member's prompt — belt and braces, since any single layer is
assumed to fail, §10.

**Assembling each member's prompt.** The member prompts are data,
like the rules files — they live in
`${CLAUDE_PLUGIN_ROOT}/skills/review-pr/references/` and are included
**verbatim, never paraphrased from memory**. Build each prompt by
concatenating, in order:

1. `${CLAUDE_PLUGIN_ROOT}/skills/review-pr/references/member-constraints.md` — the shared constraints that
   open every member's prompt: the injection posture, the read-only /
   never-execute rules, the pinned-context requirement, and the
   structured-findings output format (file/line, severity, confidence,
   canon citation, suggested comment, disposition hint, coverage
   note).
2. The member's pass brief — exactly one of
   `${CLAUDE_PLUGIN_ROOT}/skills/review-pr/references/pass-anchor.md`, `${CLAUDE_PLUGIN_ROOT}/skills/review-pr/references/pass-security.md`,
   `${CLAUDE_PLUGIN_ROOT}/skills/review-pr/references/pass-quality.md`, `${CLAUDE_PLUGIN_ROOT}/skills/review-pr/references/pass-tests.md`.
3. Resolve every `{{INSERT: <path>}}` token in the concatenation by
   substituting the named file's **full contents** (these pull in
   `rules/injection-posture.md`, `rules/canon-map.md`, and the pass's
   own rule files). Never summarize an inserted file; an unresolved
   token is an assembly error — stop and fix it.
4. Append the staged diff, the PR metadata, and the four pinned
   fields.
5. **If any escalation trigger fired on the card**, additionally
   append `${CLAUDE_PLUGIN_ROOT}/skills/review-pr/references/pass-anchor-scoping.md` to the anchor/scope
   analyst's prompt (resolving its `{{INSERT: …}}` tokens like any
   other): the member then returns the decision-scoping raw material
   alongside its anchor/salvage output — settled entries verified
   against the clone at the pinned canon SHA (decision content
   quoted, citation attached), residual atomic sentences with
   nearest-canon bounds, and the drafted artifacts (`D-02`–`D-07`).
   **Members stay recommendation-free** (decided 2026-07-26): the
   labeled recommended resolution E-23 now requires is assembled by
   **you**, the lead, in Step 7, over the members' evidence — so the
   pass brief's "never recommend" instruction stands exactly as
   written for the member's own output. This rides the same budget
   gate; if the maintainer trims it, the coverage statement and packet
   record "decision scoping: not covered — resumable" (`D-11`) —
   honest-partial is legitimate, a fake-complete ledger is not.

**The four passes** (the brief files govern; this list is only the
dispatch roster):

1. **Anchor/scope analyst** (`pass-anchor.md`) — lane-relative anchor
   with citations, scope legibility, and the salvage decomposition
   (as an explicitly-unverified advisory) when the PR overreaches.
2. **Security-vetting pass** (`pass-security.md`) — the vetting
   playbook checklist against the diff, sensitive paths, escalation
   triggers, agent-instruction/tool-config files, attack signals.
3. **Code-quality pass** (`pass-quality.md`) — walks the surrounding
   subsystem on `main`; the AI-generated-contribution failure modes.
4. **Test-adequacy pass** (`pass-tests.md`) — would the tests fail
   without the change; required regression tests; assertion strength.
   Reads tests, never runs them.

Write each member's raw structured findings to the Step 2 cache
directory as it returns (`findings-anchor.md`, `findings-security.md`,
`findings-quality.md`, `findings-tests.md`). These local cache writes
are not pre-approved and will prompt; if the maintainer declines them,
carry the findings in-session — the internal evidence record, not the
cache, is the record either way.

### 5.2 — Merge into the long-form report

**Each member's pass is a work-log row** (`RP-21`), written when the
member returns: the pass name, what it covered (the subsystem it
walked, the surface it read), and what it produced (its finding IDs) —
plus a `not-run` row, with its reason, for every pass the maintainer
trimmed at the budget gate. Four members and four rows: the deck's
"What I checked" card is where a maintainer sees that the deep dive
was actually deep, and which quarter of it was skipped.

As lead, merge the four findings sets: deduplicate overlapping
findings (keep the higher severity, union the citations), order by
severity, resolve conflicts by re-reading the relevant code yourself,
and assemble the **complete, unfiltered** long-form report at
`${CLAUDE_PLUGIN_DATA}/<owner>-<repo>/<pr-number>/<head-sha>/report.md`:
the four pinned fields, the category and tier with their entering
condition, per-pass coverage notes, the full merged findings table,
salvage decomposition if produced, and the vetting-checklist
rendering. This cache write is local and rebuildable — it backs the
internal evidence record; it is never the record.

### 5.3 — The filter stage (design §9)

Between the members and the record sits a filter. The field's #1
complaint about AI review is noise; nothing reaches the evidence
record — or, through it, the deck — unfiltered:

1. **Dedup** — already done in 5.2; a finding appears once.
2. **Evidence check** — drop any finding that cannot cite the specific
   code it is about, and drop any finding missing its required
   `impact` or `ask` (`rules/lanes.md` L-33 — an evidence-grounded
   finding with no stated impact or ask is still incomplete). A
   finding about the PR's narrative does not qualify (it may survive
   as a coverage note or an escalation flag, not a finding). A finding
   about code the diff does not touch is **no longer dropped to a
   coverage note** (decided 2026-07-30, superseding the prior rule): it
   may survive as a finding scoped `pre-existing` or `follow-up`
   (`rules/lanes.md` L-33), provided it still cites the specific code
   it is about — the evidence bar is unchanged, only the disposition
   changes; a `follow-up`-scoped finding also carries its drafted
   follow-up issue stub.
3. **Confidence threshold** — findings the member marked
   low-confidence do not reach the record unless they are
   security-relevant (those render as flags for human attention,
   clearly marked low-confidence). Dropped findings are not
   cache-only (decided 2026-07): write them into the 5.2 cached
   report under a `### Below threshold` heading, one `- ` bullet per
   finding (`` `file:line` `` — one-line summary — originating pass,
   low confidence). The deck renders that section as a collapsed
   deck-only card (Step 9), so the maintainer sees everything.
4. **Severity-shaped rendering, not a fixed cap** (decided 2026-07,
   replacing the cap of 10): **every blocking and major finding
   renders in the evidence record**, however many there are; **minor
   findings always collapse** to a single count line ("N minor
   findings — in the deck"). A PR with twelve majors shows all twelve;
   a PR with one major and nine minors shows one.

Nothing is hidden: the full unfiltered set lives in the 5.2 cached
report, and the evidence record states how many findings were filtered
at each stage and where the full set lives.

### 5.4 — The Tier-2 outcome

A deep dive earns its cost by **settling** questions, not by
re-opening them: Tier 2 ends in the same `TR-05` vocabulary as
Tier 1 — one outcome, with its `RV-05` undo-path line and, for
category 2, the `G-10` necessity sentence. The exception is an item
under active security escalation, which follows the E-NN output rules
instead (`TR-07`, Step 7): under `E-21` no public output is drafted
until the maintainer rules, and under `E-08` the only output is the
private-advisory redirect. Where the deep dive could not settle
something, that is an `RV-06` named check with its cost — inside the
irreversible classes, it stays fail-closed (`RV-03`, `B-11`).
