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
Escalated. This needs more than one person — a committee or a security review.
→ Do not decide this one alone; route it to the right people.

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
Escalate — take this to a meeting, don't decide it alone
→ A trigger fired that puts this beyond a single maintainer (an unanchored
direction call, or a sensitive area). Route it to the committee/security review.

### issue:obstacles
A preview of what a PR built from this issue would run into. Each line is a fact
about what the project's own rules would do — not a guess about unwritten code.

### issue:references
Where this issue already touches the project: existing duplicates, open PRs in
flight, and the roadmap or deferred-enhancement entry the ask maps to.
