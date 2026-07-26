# Deck glossary — plain-language captions

Normative content. This file is the plain-language layer of the reading deck
(`skills/triage/scripts/render-deck.sh`). Each `### <key>` section maps one
enumerated receipt value to a caption a non-technical maintainer can read, plus
an optional decision line marked with a leading `→`.

**A wrong gloss here misleads the reader about a security decision.** Treat edits
to this file like edits to `rules/` — plain wording is welcome, but the *meaning*
must stay faithful to the check it explains. Do not soften a `fail` into
reassurance or a "never checked" into "checked."

Format the renderer relies on:

- Keys are the `### key` heading text, verbatim, lowercase.
- The body is plain text (no markdown formatting is rendered — write plainly).
- A line beginning with `→` becomes the highlighted "what this means for your
  decision" line. At most one per section.
- Unknown keys fall back to showing the raw receipt value, so a missing gloss
  degrades safely rather than hiding a fact.

The `outcome:`, `undo:`, `category:`, and `tier:` sections carry the
action-first vocabulary the deck leads with from v0.7 (design doc v0.7 §7/§8,
decided 2026-07-26). The `lane:` and `burden:` sections stay exactly as they
were: records written before those fields existed still render from them, and
the burden captions still label the axes in the deck's auditor section.

Everything here is read by contributors as well as maintainers now that the
deck is the public artifact — plain words, no rule IDs, no lane or tier jargon
left unglossed (`rules/tone-gate.md` TG-03.5). The warning above binds harder
for the same reason: warm phrasing never turns a `fail`, a "never checked", or
an irreversible undo path into reassurance (TG-06).

---

## Lanes — the recommendation

### lane:fast
A routine, low-risk change that cleared every automated safety check. Safe to
fast-track — but you still make the final merge click. The agent never merges.

### lane:standard
This needs a real human review. Standard lane is where anything uncertain lands:
substantive code changes, and dependency bumps that didn't clear the automated
gate.
→ Read the findings below and make the call yourself.

### lane:docs
A documentation-only change. Light review — check that it's accurate and lands in
the right place.

### lane:escalate
Escalated. This needs more than one person — but not an open-ended
architecture debate: the packet separates what the agent found the
project's own canon already settles (each with a citation you can click
and should verify) from the named decisions still open, each drafted —
or, from a batch run, named — for ratify / amend / reject.
→ Do not decide this one alone. The drafted residual decisions are the
agenda; a "settled" row is the agent's finding, not a ruling —
challenging one is always in order, and a challenged row becomes
another open decision.

### held:true
On hold at the contributor's request — they contested a call or asked for a human.
The agent has stood down and drafted nothing further.
→ A person answers this; the agent does not adjudicate objections to itself.

---

## The seven automated safety checks (the "fast-lane gate")

Each check has a short human label, a "passed" meaning, and a "did not pass"
meaning. The label lines end in `:label`.

### check:author_identity:label
Who opened it

### check:author_identity:pass
Opened by the genuine Dependabot/Renovate bot, confirmed through GitHub's App
identity — not someone impersonating it with a matching name.

### check:author_identity:fail
Could not confirm this came from the genuine dependency bot. Treat the author as
unknown until a person verifies it.
→ Don't rely on "it says Dependabot" — the name alone proves nothing.

### check:manifest_only:label
Only touches the dependency list

### check:manifest_only:pass
The change edits only dependency manifest and lockfile files — no application code
was altered.

### check:manifest_only:fail
The change touches files beyond the dependency list, so it is not a clean
dependency bump. Something else is riding along.
→ Review the non-dependency changes before treating this as routine.

### check:semver_delta:label
Size of the version jump

### check:semver_delta:pass
A small (patch or minor) bump on an established (version 1.0 or higher) package —
the kind considered safe to fast-track.

### check:semver_delta:fail
A large version jump — a major bump, a downgrade, a pre-1.0 package, a widened
version range, or a version that couldn't be parsed. By policy these are never
auto-approved.
→ Read the dependency's changelog / release notes for breaking changes that affect
the call sites this project uses — a change this size can alter or break behaviour
on purpose. Then decide.

### check:no_new_packages:label
No new packages slipped in

### check:no_new_packages:pass
No brand-new package names were added anywhere — including deep in the lockfile.
No surprise dependency or typosquat snuck in alongside the bump.

### check:no_new_packages:fail
A new package name appears in the change. New names are how typosquats and
supply-chain attacks arrive — as *added* packages, not version bumps.
→ Look closely at any newly added package before merging.

### check:osv_lookup:label
Known-vulnerability check

### check:osv_lookup:pass
None of the changed package versions match a known vulnerability in the public OSV
advisory database.

### check:osv_lookup:fail
One of the changed versions matches a known-vulnerability advisory.
→ Investigate the advisory before merging — this may be introducing a known flaw.

### check:release_age:label
How long the version has been public

### check:release_age:pass
The new version has been published for at least 7 days — long enough that a
malicious release would likely have been reported and pulled.

### check:release_age:fail
The new version is very fresh (published less than 7 days ago). Freshly published
releases are the window compromised packages exploit.
→ Consider waiting, or verify the release independently before merging.

### check:ci_green:label
Automated tests

### check:ci_green:pass
The project's own automated checks (CI) all passed on the exact commit reviewed.

### check:ci_green:fail
The project's automated checks are not confirmed green on the reviewed commit — they
either failed or have not run yet.
→ Get CI running and green on this PR before merging; for an outside contributor that
may mean approving the workflow run first.

---

## The outcome — what the review recommends (TR-05)

Exactly one of these leads a reviewed PR's deck (`rules/tiers.md` TR-05, TR-10).
"Wait", "monitor", and a bare "escalate" are not outcomes here — an open
question is named, not left hanging. Each is a **recommendation**: a person
makes the actual call, and the agent performs no GitHub action at all.

The caption is the headline; the `→` line is the sub-line the deck reads out
under it. The named fix, the specific question, and the undo sentence are free
text and live in the review body — never in these captions.

### outcome:merge
Ready to merge
→ Nothing found in this review blocks it. A maintainer makes the merge click;
the agent never merges, approves, or closes.

### outcome:merge-after
Ready to merge after one named change
→ One change is asked for first, named in plain words in the review and in the
note on the item. Once it lands, this can go in.

### outcome:discuss
One specific question to settle first
→ A conversation, not a decline — the question is named, and answering it is
what unblocks this. Nothing is being rejected.

### outcome:route-to-design
Bigger than a code review — this needs a design plan
→ It adds capability the project hasn't decided on yet. Run
/lq-maintainer:design-plan pr N for the decisions it needs, the obstacles it
would hit, and the smaller changes that would build it.

### outcome:hold
On hold — a person answers this
→ The agent has stood down and drafted nothing further. A maintainer picks it
up from here.

### outcome:security-escalate
Routed for security review
→ This is about the surface the change touches, not about the person who sent
it. It is not decided by one reviewer, and anything vulnerability-shaped is
handled privately, never in the open.

---

## If it turns out wrong — the undo path (RV-04/RV-05)

The claim a review makes is never "this is certainly correct". It is "here is
what being wrong would cost, and here is the bound". That is the line the deck
highlights under the outcome (`rules/reversibility.md` RV-05).

### undo:revert-clean
One revert puts this back: no data was migrated or written, no published
interface changed, no new dependency was adopted.
→ Cheap to undo. That is what makes going ahead reasonable — not a claim that
the change is certainly right.

### undo:residue
A revert takes the code back, but something the change already did stays behind
— rows it wrote, a file it moved, a message it sent. The review says what.
→ Undoable, with a leftover. Read what the leftover is, and decide whether it
is acceptable, before merging.

### undo:irreversible-class
This touches something that cannot be cleanly undone: credentials or access
checks, stored data or migrations, a public interface, CI configuration, a new
dependency, or a release.
→ Never eligible for a quick pass. It takes the deep review and the cautious
grading whatever its size, and unknowns here are treated as risks, not as
"probably fine".

---

## Change categories — what kind of change this is (G-NN)

Judged from the diff, never from the description (`rules/change-categories.md`
G-01). The category decides which path reviews the change; it is a
recommendation like every other call here, and a maintainer can reassign it.

### category:1
New feature
→ New capability the project doesn't have yet. This needs a plan before it
needs a code review: what would the project have to decide for this to exist?

### category:2
Behaviour change
→ Something that already exists now works differently or better. Reviewed on
its merits, plus one plain question: what does this make better for someone
using it?

### category:3
Bug fix or rollback
→ Reviewed on whether it actually fixes the thing, and whether a test would
catch the problem coming back. Rolling a change back is a normal, healthy move
here — never an embarrassment.

### category:4
Refactor or large-scale change
→ The project hasn't finished writing its process for changes this size. Until
it has, the honest answer is a holding response plus an offer to split the work
into smaller, reviewable pieces — not a decline.

---

## Depth of review — how much process this got (TR-NN)

The lightest depth that fits is the default (`rules/tiers.md`). Depth is
entered by a named condition, never by habit — and nothing inside a
contribution can buy it a lighter one.

### tier:0
Decided by automated checks
→ Dependency bumps and hunk-verified typo fixes: mechanical checks decide, and
the reviewer's job is to confirm the anchor and flag anything odd. The gate
results are below.

### tier:1
One focused pass
→ Small (under ~400 changed lines and 10 files), nothing irreversible touched,
no trigger fired. The pass is deliberately time-boxed, so read "what was not
checked" for what that leaves open — each open item names the check that
closes it.

### tier:2
Deep review
→ Several passes over the change, entered because something named it: a trigger
fired, the change is large, or it touches something that cannot be cleanly
undone. The condition that earned the depth is recorded with the review.

### tier:3
Committee or design path
→ Bigger than one reviewer: a genuine conflict with the project's own
decisions, or a new feature that needs a design first. The packet or plan
arrives with a drafted recommendation; people still decide it.

---

## Coverage — what was and wasn't looked at

### coverage:deterministic-gate
The seven automated safety checks above.

### coverage:anchor
Whether the change is tied to a real, verifiable source — an upstream release for
a dependency, an accepted design note for a feature.

### coverage:vetting-checklist
A security pass over the diff: typosquats, known-bad versions, suspicious install
scripts, hidden instructions aimed at a reviewer or an AI.

### coverage:code-quality
A read of the changed code for correctness and clarity.

### coverage:test-adequacy
Whether the change is covered by tests.

### coverage:salvage
Whether an overreaching change was broken into parts that could be accepted
separately.

### coverage:runtime-behavior
Whether the code actually runs and behaves correctly.
→ The agent never runs contributed code, so it did not confirm this actually works at
runtime. Exercise the affected feature yourself before merging.

### coverage:package-contents
What is actually inside the dependency package.
→ NOT checked for dependency bumps. The agent sees only names, versions, and
hashes — never the code inside the package. Whether the published package matches
its stated source is a human trust judgment.

---

## Human-only judgments — permanently open

These can never be marked "done" by the agent.

### human:contributor-trust
Whether you trust this contributor. The agent scores changes, never people.

### human:supply-chain-hygiene
The residual "do we trust this dependency and its maintainers" judgment that no
automated check can settle.

### human:roadmap-worth
Whether this is worth building — a product-roadmap call, not a code call.

### human:engagement-tone
How warmly or firmly to engage this contributor.

---

## Finding severity

### severity:blocking
Must be fixed before this can merge.

### severity:major
A significant problem worth resolving before merging.

### severity:minor
A small issue — worth noting, not necessarily blocking.

---

## Maintainer burden — the deck verdict

Overall burden is the **worst single axis** (blockers gate above it). Headlines below.

### burden:blocked
Blocked — resolve first

### burden:high
High burden — real work to accept

### burden:medium
Medium burden — some follow-up expected

### burden:low
Low burden — a quick accept

### burden:scope:label
Scope
### burden:scope:concern
stays within what was discussed
### burden:review:label
Review effort
### burden:review:concern
effort to review right now
### burden:tests:label
Tests
### burden:tests:concern
is the new behaviour tested
### burden:carry:label
Carry cost
### burden:carry:concern
what you maintain afterward
### burden:safety:label
Safety / risk
### burden:safety:concern
residual risk short of a blocker

### blocker:ci-red
Automated checks (CI) are not confirmed green on the reviewed commit — they failed
or have not run.
### blocker:known-vuln
A changed dependency matches a known published vulnerability.
### blocker:data-harm
A blocking-severity security or data-harm issue is present.
### blocker:missing-dco
The contributor has not signed off on their contribution (DCO/CLA).
### blocker:incompatible-license
The change, or a newly added dependency, carries a license incompatible with the project.
### blocker:attack-escalation
Fired an escalation trigger a human must handle directly — the change touches the agent's own instruction/config files, or was routed for security review. Not a judgment on the contributor; just not a routine, agent-assisted decision.
### blocker:vuln-suspect
The item may describe a vulnerability — handled privately, never in the open.

---

## Next steps per burden axis

Actionable follow-ups the reviewer takes when an axis grades medium or high.

### burden:scope:next
Confirm the change maps to an accepted requirement, decision, roadmap item, or
deferred-enhancement entry — or decide it is out of scope and say so.

### burden:review:next
Budget real review time and read the touched subsystems on main — this spans
significant ground.

### burden:tests:next
Request the tests the project's contributing guide requires for this change class
(for a bug fix, a regression test) before accepting.

### burden:carry:next
Weigh the dependency or surface you would maintain from here on; ask whether it can
reuse existing code instead.

### burden:safety:next
Resolve the residual risk: pin or narrow the dependency range, or add a lockfile so
a concrete version is vetted; check the affected area against the vetting playbook.

---

## The issue deck — recommendation & references

An issue is not graded on the burden axes (there is no code diff). Its deck
headlines one **recommendation** — is this ready to act on? — over a
rule-grounded preview of the PR it would become. Headlines and their decision
lines below (`rules/issues.md` IV-NN).

### recommendation:proceed
Ready to proceed — clear, in scope, and grounded
→ A single, anchored ask a contributor could pick up. Decide whether it is worth
doing; nothing blocks acting on it.

### recommendation:needs-info
Needs more information before it can be acted on
→ A key piece is missing — reproduction steps for a bug, or a design anchor for a
feature. Post the drafted request to the reporter; you cannot act until it is
answered.

### recommendation:decompose
Decompose into smaller issues first
→ This sprawls across several concerns. Split it into the drafted sub-issues so each
piece can move on its own — a decomposed idea means the oversized PR never gets
written.

### recommendation:escalate
Escalate — a named set of decisions needs more than one person
→ A trigger fired that puts this beyond a single maintainer. The packet
lists what the agent found canon already settles (verify the citations)
and states each open decision for ratify / amend / reject.

### recommendation:design
This is a feature idea that deserves a design plan
→ It asks for capability the project hasn't decided on yet, so it takes the
design path rather than a code review — not a decline, a plan. Run
/lq-maintainer:design-plan issue N for the decisions it needs, the obstacles it
would hit, and the smaller changes that would build it.

### recommendation:proceed:next
Decide whether it is worth doing; if so, mark it ready (or good-first-issue) so a
contributor can pick it up. Nothing blocks acting on it.

### recommendation:needs-info:next
Post the drafted request for the missing pieces — reproduction steps for a bug, a
design anchor for a feature. The issue is parked until the reporter answers.

### recommendation:decompose:next
File the drafted sub-issues (crediting the reporter) and cross-link them, so each
part can move on its own.

### recommendation:escalate:next
Put the drafted residual decisions on the committee / roadmap agenda —
the meeting's job is to ratify, amend, or reject each one (drafted in
full by the single-item review; a batch run names them and defers the
drafts), not to "discuss architecture." The settled ledger is the
pre-read — verify it, don't just defer to it. Do not accept or decline
the item solo.

### recommendation:design:next
Run /lq-maintainer:design-plan issue N, then take the drafted decisions to the
committee or roadmap — the plan is the pre-read, not the ruling. The reporter is
credited in whatever the plan produces, and the atomic decomposition is what a
contributor can pick up once the design is agreed.

### issue:obstacles
A preview of what a PR built from this issue would run into. Each line is a fact
about what the project's own rules would do — not a guess about unwritten code.

### issue:references
Where this issue already touches the project: existing duplicates, open PRs in
flight, and the roadmap or deferred-enhancement entry the ask maps to.

---

## Decision scoping — the escalation ledger

Rendered for escalated items from the receipt's decision_scoping footer
block (rules/decision-scoping.md). The counts headline reads
"<r> decisions to make · <s> found settled".

### scoping:settled
Sub-questions the agent found already answered by the project's
existing decisions — each with its citation, pinned to the exact canon
version reviewed. Click it to verify: settled is the agent's finding,
not a ruling. If the quote doesn't cover the question, or canon has
moved since the pin, treat the row as open.

### scoping:residual
A decision no canon makes yet, stated in one sentence. The agent
drafted the decision text for you to ratify, amend, or reject (batch
runs name the decision and leave the draft to the single-item review).
→ The agent drafted; a human decides. Always.

### scoping:reserved
Permanently a human call by the project's own rules — contributor
trust, roadmap worth, the merge click. Never narrowed, never resolvable
by the agent.

### scoping:none-residual
Everything this escalation raised is, on the agent's search, already
settled by the cited canon. The committee's act is verifying that —
confirm the citations cover their questions, anchor the item where the
agent found uncited coverage, and contest any row that doesn't hold up
(a contested row becomes an open decision).
→ The item stays escalated: a fired trigger is never un-fired.

### artifact:draft-adr
An agent-drafted, watermarked, unadopted decision record with a
placeholder number. It anchors nothing and decides nothing until a
maintainer adopts, numbers, and merges it.

### artifact:de-stub
An agent-drafted deferred-enhancement / mini-PRD stub (sometimes
annotated as amending an existing entry or proposing a workflow
convention), crediting the contributor. A human files it — or doesn't.
