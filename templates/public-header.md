# Template — public header (the block every published record opens with)

Rendered by `skills/triage/scripts/publish-site.sh` at the top of every
published item page (`pr-<n>/index.html`), every published deck
(`pr-<n>/<head>/deck.html`, through `render-deck.sh --public-header`)
and every published receipt (`pr-<n>/<head>/receipt.md`), and in its
long form as the site's `about.html`. Adopted from
`docs/proposals/public-receipts-on-lq-ai-community.md` R3 (the fixed
header) and R4 (GitHub's state travels with the record). **Render,
never freehand**: the generator reads its words from this file and
from nowhere else, and fills only the `{{field}}` slots below. The
field rules (`PH-NN`) are normative.

The blocks are fenced and introduced by an HTML comment marker
(`<!-- public-header:<name> -->`); the generator reads the first fenced
block after each marker. The prose around them is for people editing
this file and is never published.

## Field rules

- **PH-01 — Fixed text, filled slots.** Only the `{{field}}` slots
  vary between records. Every other word of the block is the same on
  every published record, so a reader who has read one header has read
  them all. A record the generator cannot fill a slot for gets the
  slot's stated fallback, never an omission of the sentence.
- **PH-02 — What this is.** Names the item (`{{kind_label}} #{{number}}`
  on `{{repo}}`), the agent version, the host it ran under
  (`Claude Code` / `Codex`), the model as the record pinned it, the
  head reviewed (PRs) and the canon SHA it was read against, and links
  the rules at that version's tag. Fallbacks: model `not recorded`;
  host `not recorded`.
- **PH-03 — What it is not.** Always present, never shortened. "A human
  maintainer decides whether and how a change merges" is in bold on
  every record. The record is not a GitHub approval, not a review
  requirement and not a statement about the contributor.
- **PH-04 — Where the decision stands.** Three fields, in this order,
  each from its own source and never merged into one: the agent's
  recommendation (the newest reviewed head's `outcome`, or the issue
  `recommendation`, from `state.yaml`); the maintainer's recorded
  decision (the RP-18 block — `accepted` / `adjusted` / `overridden` —
  or "none recorded — absence is not agreement"); and GitHub's state
  today (`status.yaml`, with the date it was checked). Then always:
  "If these three disagree, GitHub is right."
- **PH-05 — Disagreement is said, not smoothed (R4).** When the three
  fields of PH-04 disagree, one sentence from the `discrepancy` table
  below is appended to the same paragraph. The generator picks every
  row that applies, in table order. A discrepancy is never rewritten
  into agreement.
- **PH-06 — What was and was not checked.** Always present. The code
  was read, not run; mechanical breaking-change checks are textual;
  contributor trust and supply-chain hygiene are human judgments; the
  head may have moved since.
- **PH-07 — If you disagree.** Links the item on GitHub and the site's
  FOR-AGENTS page. A maintainer answers, never the agent.
- **PH-08 — Self-review line (conditional).** Rendered when the item's
  GitHub author login is the same login as the maintainer named in the
  record's attribution line (`templates/pr-comment.md` PC-05, "reviewed
  and posted by @<login>").
- **PH-09 — Older-rules line (conditional).** Rendered when the
  record's agent version differs from the version publishing it
  (`--agent-version-tag`, default the plugin manifest's version), with
  a link to the changelog between the two tags.
- **PH-10 — Escalate-lane gloss (conditional).** Rendered whenever the
  lane is `escalate`, every time, so "escalated" is never read as "a
  problem was found".
- **PH-11 — Draft status line (conditional).** Rendered when the record
  carries a drafted public comment or a drafted merge message
  (RP-19): each draft is labelled *posted as drafted* / *posted with
  edits* / *not posted* / *unknown*, as matched against the item's
  actual GitHub comments and merge commit. A draft is never presented
  as something that was said.
- **PH-12 — Review time is approximate.** The receipt carries no
  timestamp of its own, and the generator reads nothing else from the
  cache, so the date shown for a review is the record's file time,
  always labelled "about <date>, from the record's file time".

## Template

### The short header (item pages, decks, receipts)

<!-- public-header:short -->
```markdown
**What this is.** An AI-assisted review of {{repo}} {{kind_label}} #{{number}}, drafted by lq-maintainer-agent v{{agent_version}} (running under {{host}}, model {{model}}) {{head_phrase}} against {{repo_name}} main `{{canon_short}}`, about {{reviewed_on}} (from the record's file time), and published by a maintainer. The rules it applied are public: [the rules at v{{agent_version}}]({{rules_url}}).

**What it is not.** It is advice to the maintainers, not a decision. **A human maintainer decides whether and how a change merges**, by lq-ai's governance ([GOVERNANCE.md]({{governance_url}})). This record is not a GitHub approval, not a review requirement, and not a statement about the contributor. The agent cannot merge, approve, close or label anything, and did not.

**Where the decision stands.** Agent recommendation: {{recommendation}}. Maintainer's recorded decision: {{decision}}. GitHub today (checked {{checked_on}}): {{github}}. If these three disagree, GitHub is right.{{discrepancy}}

**What was and was not checked.** The code was read, not run — the agent never executes contributed code except in the sealed acceptance box described in bot-behavior.md, and a record says so when it did. Mechanical checks only for breaking changes (textual). Contributor trust and supply-chain hygiene are human judgments and were not assessed. The head may have moved since this review; the findings describe the head named above and nothing later.

**If you disagree**, say so on [the {{kind_label}} on GitHub]({{item_url}}); a maintainer answers, never the agent. If you are a machine reading this, see [FOR-AGENTS]({{for_agents_url}}).
```

### Conditional lines (appended inside the same block when they apply)

<!-- public-header:if-self-review -->
```markdown
**Self-review.** The {{kind_label}}'s author is the maintainer who ran and published this review.
```

<!-- public-header:if-older-rules -->
```markdown
**Older rules.** Produced under v{{agent_version}} of the rules, which differ from the current rules (v{{current_version}}) in [the changelog between those tags]({{compare_url}}).
```

<!-- public-header:if-escalate -->
```markdown
**Escalate lane.** A security-sensitive path was touched, so a human reviewer was required — this is routing, not a finding.
```

<!-- public-header:if-drafts -->
```markdown
**Drafts in this record.** {{drafts}} A draft is text prepared for a maintainer; only what GitHub shows was said.
```

### Discrepancy sentences (PH-05)

One row per case; the key is what the generator tests, the sentence is
what it appends. Rows apply in table order.

<!-- public-header:discrepancy -->
```markdown
- merged-no-decision: These do not line up: GitHub shows the {{kind_label}} merged, and no maintainer decision was recorded in the review.
- closed-no-decision: These do not line up: GitHub shows the {{kind_label}} closed, and no maintainer decision was recorded in the review.
- merged-not-recommended: These do not line up: the agent's newest recommendation was "{{recommendation}}", and GitHub shows the {{kind_label}} merged.
- closed-merge-recommended: These do not line up: the agent's newest recommendation was to merge, and GitHub shows the {{kind_label}} closed without merging.
- open-merge-recommended: These do not line up: the agent's newest recommendation was to merge, and GitHub shows the {{kind_label}} still open.
- decision-overridden: The maintainer's recorded decision overrode the agent's recommendation.
- decision-adjusted: The maintainer's recorded decision adjusted the agent's recommendation.
- head-moved: The {{kind_label}}'s head on GitHub is now `{{github_head_short}}`, not the head this review read.
```

### The long form (about.html)

<!-- public-header:long -->
```markdown
# About this site

This site publishes the records lq-maintainer-agent made when it reviewed pull requests and issues on {{repo}}. It is generated from the agent's records by a script, on a maintainer's machine, and served by GitHub Pages from {{site_repo}}. Nothing on it is written by hand, and nothing on it runs in your browser: there is no JavaScript, no external font, script or image, and no tracking.

## What a record is

Each record is an AI-assisted review, drafted by lq-maintainer-agent for the project's maintainers. It says which version of the agent wrote it, which host it ran under (Claude Code or Codex), which model, which head of the pull request it read, and which commit of lq-ai's `main` it read the project's rules and documents at. The rules it applied are public, at that version's tag in [lq-maintainer-agent]({{agent_repo_url}}).

## What a record is not

It is advice to the maintainers, not a decision. **A human maintainer decides whether and how a change merges**, by lq-ai's governance ([GOVERNANCE.md]({{governance_url}})). A record is not a GitHub approval, not a review requirement, and not a statement about the contributor. The agent cannot merge, approve, close or label anything. It never posts on its own: everything it drafts is read, and posted or dropped, by a maintainer.

## Three things that are never the same thing

Every item page and every deck states three things side by side, from three sources:

- **The agent's recommendation** — what the newest review advised.
- **The maintainer's recorded decision** — accepted, adjusted or overridden, when a maintainer recorded one. Most records carry none. The absence of a recorded decision is not agreement.
- **What GitHub shows today** — open, merged or closed, by whom and when, checked when the site was generated.

If these three disagree, GitHub is right, and the page says that they disagree rather than smoothing it over.

## What was and was not checked

The code was read, not run — the agent never executes contributed code except in the sealed acceptance box described in bot-behavior.md, and a record says so when it did. Mechanical checks for breaking changes are textual only. Contributor trust and supply-chain hygiene are human judgments and are never assessed by the agent. A review describes the head it names and nothing later.

## Words you will see

- **Escalate lane.** A security-sensitive path was touched, so a human reviewer was required — this is routing, not a finding. Most records on this site are in the escalate lane because lq-ai's sensitive surface is large.
- **Older rules.** A record made under an earlier version of the agent says so, and links the changelog between that version and the current one. A record is what it was; old records are never rewritten to today's rules.
- **Self-review.** When the author of a pull request is the maintainer who ran the review, the record says so.
- **Drafts.** A record may carry a drafted public comment or merge message. Each is labelled with what GitHub shows: posted as drafted, posted with edits, not posted, or unknown.
- **Review dates.** A record has no timestamp of its own; the date shown is the record's file time, which can be later than the review itself when the record was updated at merge.

## What is never published here

Reviews of deliberate attacks, reports that look like a security vulnerability, items a contributor asked to be held, and anything security-tagged until a maintainer has ruled on it item by item. Local file paths, email addresses and the mechanics of permission checks are removed before publication, and every generated file is scanned for them; one hit stops the whole run.

## If you disagree

Say so on the pull request or issue on GitHub. A maintainer answers, never the agent. If you are a machine reading this site, read [FOR-AGENTS]({{for_agents_url}}) first.
```
