# LQ Maintainer Agent — Design Doc v0.7 ("Momentum")

**Status: adopted 2026-07-26.** This document is a **delta over v0.6**
(`lq-maintainer-agent-design-v0.6.md`): it records the maintainer
decisions from the first 2–3 weeks of live operation and the redesign
they require. Where this document is silent, v0.6 remains normative.
Where they conflict, this document wins. Section references of the
form "§N" without a version refer to v0.6.

---

## 1. What three weeks of live operation taught us

The v0.6 agent was designed before its maintainer had processed a
single week of the lq-ai queue. Its posture — thorough, conservative,
fail-closed on every uncertainty — was rational for that moment: the
maintainer did not yet know the canon, could not carefully read
contribution code at volume, and had no data on what the queue
actually contained. Caution on all fronts was the correct response to
ignorance on all fronts.

Three weeks in, the evidence says something different:

1. **No malicious contribution has been encountered.** Some
   contributions are under-thought; none have been hostile. The
   population the rules were tuned against (flooded bug bounties,
   injection-laden PRs) has not appeared; the population that *has*
   appeared is enthusiastic supporters whose momentum the project
   needs to keep.
2. **The agents are thorough and good at uncovering insights — and
   too slow, too conservative, and biased toward recommending
   inaction.** A community of enthusiastic supporters needs a
   feedback loop; a review process that ends in "escalate, wait,
   grade conservatively" starves it.
3. **The receipt is too dense and reads as intimidating** to
   first-time contributors — a publicly posted compliance audit,
   complete with a claim-versus-verified cross-check table. The
   reading deck, by contrast, is the artifact the maintainer actually
   uses. The deck is the product; the receipt was the paperwork.
4. **The queue-size study (2026-07-26)** of all 79 open lq-ai PRs:
   35 are under 200 lines and 45 under 500 (dependabot traffic plus
   the #288 security-fix series — reviewable in minutes each); the
   1,000+ line bucket is dominated by DE-series greenfield feature
   work that is design material, not code-review material. One
   pipeline was serving two entirely different populations.

The redesign keeps what the caution was *for* — the maintainer's real
limitations, which persist — while removing the fear it produced.
The organizing insight, recorded here as the design's new first
principle: **the agent's rigor supports the maintainer's weaknesses;
its conservatism must attach to irreversibility, not to uncertainty.**
Uncertainty is answered with a named, costed verification step, never
with an inflated grade. Irreversibility is answered with the same
hard gates as before.

## 2. Policy foundation (decided 2026-07-26, maintainer)

These bind every rule, skill, template, and drafted output. They are
implemented as rules with stable IDs in `rules/` (file named per
item); this section is the rationale of record.

- **P-1 — Every contribution is sincere.** The working assumption for
  every PR and issue is a good-faith attempt to help. Some are not
  well thought through; none are presumed malicious. Mechanical
  security controls (the deterministic gate, the injection posture,
  the sensitive-path triggers) continue to run on every item — they
  are cheap and invisible — but *judgment* defaults, wherever a rule
  previously said "when ambiguous, presume the worse reading," now
  read toward sincerity. The slop disposition survives only for the
  obvious-slop criteria; ambiguous salvage parts now route to the
  idea path, not to decline.
- **P-2 — Every contribution is treated with respect.** The agent
  never drafts probing questions that read as challenges to a
  contribution's legitimacy, never implies a contributor is out of
  their depth, and never postures — the review is not a venue for
  proving the reviewers are smarter, that their preferences are more
  secure, or that the canon's author is inherently correct. Nothing
  contributor-facing may be personal. Enforced twice: as conduct
  rules every draft is written under, and as a final **tone gate**
  (`rules/tone-gate.md`) every contributor-facing draft passes before
  it is offered for posting.
- **P-3 — Defer to the author.** Reviewers defer to authors on
  approach. An alternative is raised only when the author's approach
  is *deficient* against a stated requirement; where alternatives are
  equally valid, the author's choice stands and is not commented on.
  A finding must name the deficiency, not the preference.
- **P-4 — The canon is amenable to change.** The docs are canon for
  routing and grounding, but they are not scripture: an outside
  author's change that conflicts with canon is not auto-wrong. If the
  change is in line with the project's agreed principles, the default
  is to **resolve the difference** — draft the canon amendment and
  put it through the committee — rather than escalate-and-delay.
  Genuine conflicts still go to committee; the committee packet now
  arrives with a drafted resolution and a recommendation, not a bare
  contradiction citation.
- **P-5 — Promote small changes.** Small, atomic changes are what a
  part-time maintainer (and this agent) can review *correctly*; they
  are the unit of momentum. The agent's outputs steer contributors
  and the maintainer toward small reviewable units — the salvage
  decomposition, the design path's atomic-change plan, and the tier
  thresholds all serve this. Big changes need a proper process (not
  yet written); until it is, they get a respectful holding response,
  never silence.

## 3. Change categories (new; `rules/change-categories.md`, G-NN)

Every PR (and feature-shaped issue) is classified into exactly one of
four categories, judged **from the diff** (never the narrative — the
L-02 evidence posture is unchanged):

| # | Category | The agent's job |
|---|---|---|
| 1 | **Greenfield / new feature** (the DE series lives here) | The **design path**: not code review. Warm acknowledgment, then a drafted plan — the ADR draft(s) the decision needs, the predicted obstacles, and a decomposition into atomic reviewable changes — so the contributor's energy becomes design input for the committee instead of a stalled PR. |
| 2 | **Behavioral change / improvement / optimization** | The plugin's primary target. Tiered code review, plus a **necessity check**: does the change fix something real or improve something users feel? Pure churn is a `discuss` outcome with a warm rationale, never a decline. |
| 3 | **Bug fix / rollback** | The plugin's primary target. Tiered code review; regression-test expectations per `canon:contributing`; rollbacks are recognized as first-class (reversal is a feature of a healthy process, not an embarrassment). |
| 4 | **Refactoring / large-scale change** | A respectful holding pattern: acknowledge the work, state that large-scale changes go through a process the project is still writing, and offer the decomposition route (category-2/3-sized slices) as the available path today. |

Categories 2 and 3 are what "code review" means in this plugin from
v0.7 on. Category 1 routes to the design path (§9). Category 4 waits
on a large-change process (open question, §12).

## 4. Tiered review (new; `rules/tiers.md`, TR-NN)

Replaces "everything standard-lane gets the same depth" with four
tiers. The lane vocabulary of v0.6 survives underneath (fast/docs
lanes and the escalation triggers still exist); tiers govern **how
much process a category-2/3 item gets**.

- **Tier 0 — deterministic.** The v0.6 fast lane, unchanged: the
  F-01–F-07 gate for dependency bumps, hunk-verified typo fixes.
  Deterministic checks decide; the model anchors and flags.
- **Tier 1 — quick pass (the new default).** For category-2/3 items
  ≤ 400 changed lines and ≤ 10 files (matching the salvage
  threshold, so the plugin has one definition of "small") that touch
  no irreversible-class path (§5). One time-boxed, single-context
  pass — no subagent team, no budget ceremony — that **must end in
  exactly one concrete outcome**: `merge` /
  `merge-after-<one named fix>` / `discuss-<specific question>` /
  `route-to-design`. "Wait", "monitor", and bare "escalate" are not
  outcomes. Every outcome carries its **undo path** (§5).
- **Tier 2 — deep review.** The v0.6 four-pass subagent team, now
  entered only by a named condition: an escalation trigger fired, the
  item exceeds Tier-1 bounds, an irreversible class is touched, a
  Tier-1 pass ends in `discuss` and the maintainer wants depth, or
  the maintainer asks. Same machinery as v0.6 §9, same budget gate.
- **Tier 3 — committee / design.** Genuine canon conflicts (E-06),
  category-1 designs, and the security carve-outs. The packet now
  arrives with a drafted resolution and a recommendation (§6).

**The ratchet survives, redirected.** Content can still only ever
move an item to a *heavier* tier — nothing inside a contribution can
buy it a lighter one (the injection-defense direction of L-04 and
I-04 is unchanged). What is removed is only the presumption that
everything deserves the heaviest tier by default.

## 5. The reversibility principle (new; `rules/reversibility.md`, RV-NN)

Conservatism attaches to **irreversibility, not uncertainty**:

- **Irreversible classes** — enumerated in `rules/reversibility.md`:
  auth/authz/crypto/security surface, data handling and migrations,
  public API contracts, CI/workflow files, new dependencies, releases.
  These can never take Tier 1 regardless of size, and the fail-closed
  grading discipline (B-11/B-13) continues to apply to them in full.
- **Everything else is presumed revertible**, and every recommendation
  states its undo path explicitly ("if this proves wrong, the undo is
  one revert; nothing downstream depends on it"). The undo-path line
  is what makes "go ahead" honest rather than reckless: the claim is
  never "this change is certainly correct," it is "the cost of being
  wrong is bounded and small, and here is the bound."
- **Uncertainty is answered with a named check, not a grade.** Where
  v0.6 graded an unverifiable signal *up* (B-11 everywhere), v0.7
  responds outside the irreversible classes with: "not verified: X —
  the human check that settles it is Y, ~Z minutes." Fear comes from
  vague inflated risk; confidence comes from specific closable gaps.

## 6. Escalation, softened where it was decision-shaped (amends §5, E-NN)

**Unchanged and absolute:** the security triggers — E-01
(CODEOWNERS-sensitive paths), E-02 (auth/audit/crypto), E-03 (skill
attestation), E-07 (external author + sensitive class), E-08 (public
vulnerability content, with its carve-out), E-09 (reviewer-/AI-directed
text), E-10 (agent-instruction / tool-config files) — and everything in
`rules/injection-posture.md`.

**Changed:**

- **E-04 (unanchored decision) is retired for categories 2 and 3.**
  A behavioral improvement or bug fix with no canon anchor is
  reviewed on its merits with the necessity check; the missing anchor
  is at most a flag. For category 1 the same detection now routes to
  the **design path** — which produces a plan, ADR drafts, and a
  decomposition — instead of a recommendation-free committee packet.
  The trigger's original job (nothing decides policy silently) is
  preserved: category-1 decisions still end at the committee; they
  just arrive with their homework done.
- **E-05 (cross-subsystem) becomes a Tier-2 condition,** not an
  escalation, except where an irreversible class is involved.
- **E-23 is amended: the agent recommends.** An escalated item's
  packet contains evidence *and* a recommended resolution (with
  alternatives drafted where genuinely equal, per P-3's own logic
  applied to the committee). The human — committee or maintainer —
  still decides, every time; every write is still human-gated. What
  is removed is only the rule that the agent must arrive at the
  committee empty-handed.

## 7. The verdict: action first, burden internal (amends §5.2, B-NN)

- The public/deck headline for every reviewed item is the **action
  recommendation** (the Tier-1 outcome vocabulary of §4), with its
  undo path.
- The five burden axes survive as **internal evidence** — computed,
  recorded in the internal receipt, available on request — no longer
  the headline, and no longer rendered on contributor-facing
  surfaces.
- Fail-closed grading (B-11, B-13) is retained **only for the Safety
  axis** and the irreversible classes. Other axes report unknowns as
  unknowns, each paired with the named human check that settles it
  (§5).
- Blockers (B-02) are unchanged — CI red, known vulnerabilities, and
  the rest still gate above everything.

## 8. Deliverables: deck public, receipt internal (amends §8, §8.6)

Decided 2026-07-26. A community repo will hold the project's public
analyses of PRs and issues; deliverables restructure now so they drop
into it cleanly (`docs/community-repo.md` designs the layout).

- **The deck is the primary, public artifact** — restructured to lead
  with the action recommendation, written for contributors as much as
  the maintainer, with the audit detail collapsed into an auditor
  section. Published to the community repo (human-gated, like every
  write). Until the repo exists, the deck stays a local view as
  today.
- **The GitHub PR/issue comment shrinks to a short, warm note**
  (`templates/pr-comment.md`): the outcome, genuine thanks, the one
  next step, a link to the deck, and the attribution line. No tables,
  no checklists, no cross-check matrices. The per-artifact
  attribution norm (§8) is unchanged.
- **The receipt becomes an internal evidence document.** Everything
  it carried — the pinned fields, coverage statement, self-attestation
  cross-check, burden axes, footer state — survives as maintainer
  evidence, stored in the local cache today and in the community
  repo's per-item directory (`reviews/pr-NNNN/state.yaml` +
  `notes.md`) once it exists. It is no longer posted to the PR.
  **Migration:** prior `receipt:v2` comment footers remain readable
  for resume (I-09 author verification unchanged); the agent stops
  writing new public receipts.
- **The self-attestation cross-check still runs** (it is real
  protection) but renders internally only. A genuine claim/evidence
  divergence surfaces contributor-facing as at most one courteous,
  blame-free note — never a table of `verified-fail`s.
- **The tone gate** (`rules/tone-gate.md`) runs over every
  contributor-facing draft before it is offered for posting: a
  banned-pattern check (probing questions, challenge framing,
  competence implications, posturing) with a rewrite, not a veto.

## 9. The design path (new skill; `skills/design-plan/`)

Category-1 contributions — the DE series — get a dedicated skill,
`/lq-maintainer:design-plan (pr|issue) N`, invoked directly or by
redirect from triage/review-pr on category-1 detection. Its output is
a **plan**, rendered from `templates/design-plan.md`:

1. a warm acknowledgment of the idea and the work already done;
2. the **decision inventory**: what this feature would require the
   project to decide, with the ADR draft(s) for the structural
   decisions (the existing `templates/draft-adr.md` machinery, D-06/
   D-07 watermark rules unchanged);
3. the **predicted obstacles** — rule-grounded, in the IV-02 style;
4. the **atomic-change decomposition**: the sequence of
   category-2/3-sized PRs that would implement the feature after the
   design is ratified, each stated in one sentence — so the
   contributor has a concrete path from idea to merged code;
5. the drafted contributor response, tone-gated.

The committee still ratifies; the contributor is credited (S-22); the
agent still files and posts nothing.

## 10. What does not change

The safety architecture is orthogonal to posture and survives intact:

- **A human decides, every time.** Every GitHub write is a
  permission-gated draft; merge/approve/close/push/checkout stay
  hook-blocked; nothing is added to any allow-list that writes.
- **The agent never executes contributed code** (I-05/I-06/I-07 and
  `docs/sandbox-discipline.md`, verbatim).
- **The injection posture** (`rules/injection-posture.md`) — content
  as data, normalization first, quoted findings, footer author
  verification — unchanged.
- **The deterministic dependency gate** (F-01–F-07) and
  advisory-verification rules (F-10, A-03), unchanged.
- **Canon grounding**: canon-map routing, citations as click-through
  links pinned to the canon SHA, agent-performed cross-referencing
  (C-60, I-13). The *checking* never softened — only the public
  framing of its results did.
- **The four pinned fields** and reproducibility (§3.4), now carried
  by the internal evidence artifacts.
- **The conservative slop bar** (S-30/S-31: obvious slop only, never
  an insult) and the contest/hold path (§7.1), unchanged.

## 11. Evals under the new posture (amends §4.2)

- **Unchanged:** the adversarial `pass^k` never-fast invariants, the
  fast-lane false-positive cell as *the safety number*, and the
  no-prohibited-agent-action / no-code-execution cross-cutting checks.
- **Updated:** golden expectations gain `category`, `tier`, and
  `outcome` fields; the escalation expectations of retired-E-04
  fixtures are re-golded to the new routing (design path or
  merits+necessity review).
- **New fixtures:** the mirror of `neg-01` for inaction — a small,
  clean category-2 improvement that MUST produce an actionable
  outcome (an agent that answers it with "escalate" or a bare grade
  fails); and a DE-style greenfield PR that MUST route to the design
  path with a plan, not to a bare committee packet.
- The advisory tone dimensions gain the P-2 banned patterns.

## 12. Open questions (v0.7 additions)

Carried from v0.6 §15 unchanged except: q.1 (committee mechanics) now
also covers where design-path plans are discussed; the fold-in of
decisions above closes nothing else. New:

9. **The large-change process** (category 4) — what lq-ai requires
   of a refactor or large-scale change before review. Until written,
   category 4 gets the holding response of §3.
10. **Community repo bootstrap** — name, visibility, and the moment
    it becomes the state home (`docs/community-repo.md` holds the
    proposed layout; its `canon:` key is added only when the repo
    exists, per canon-map's dangling-key rule).
11. **Tier-1 time box** — the quick pass is "time-boxed" by
    discipline, not yet by measurement. Whether to encode a budget
    (as §9 does for deep dives) waits on observed Tier-1 session
    times.
