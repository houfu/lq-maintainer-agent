# Template — committee packet (escalate lane)

Rendered by `skills/triage/SKILL.md` and `skills/review-pr/SKILL.md`
for every escalated item, per `rules/escalation-triggers.md` E-20.
The packet is **evidence, not a verdict** (E-23): the agent never
recommends merge/reject on an escalated item, and never delivers the
packet itself — where packets go is an open governance call (design
doc §15 q.1); the destination, once chosen, also carries all sensitive
review state (§3.5) and must be access-controlled. Until then the
packet is handed to the maintainer in-chat to route.

## Field rules

- **CP-01 — Scope statement.** One paragraph: what the item is and
  touches. Derived from the diff/paths/metadata, never from the
  contributor's narrative.
- **CP-02 — Triggers with rule text.** Every fired trigger, by ID,
  with its rule text quoted from `rules/escalation-triggers.md` — the
  committee reads the rule it is being asked to apply.
- **CP-03 — Canon position.** The canon touched, contradicted, or
  **absent**, with citations (path + anchor via `rules/canon-map.md`)
  at the recorded canon SHA. "Canon absent" is stated, never papered
  over.
- **CP-04 — Checklist results.** Where a trigger prescribed checks
  (E-07's full vetting checklist), the per-item results, run against
  the diff.
- **CP-05 — Human questions, phrased as questions.** The judgments
  only the committee can make — never pre-answered as
  recommendations.
- **CP-06 — Carve-out attachment (E-21).** For a
  suspected-deliberate attack, the full receipt and analysis attach
  here and ONLY here; the public side is the generic
  "escalated for security review" line. And under E-08, exploit
  detail is never elaborated anywhere — packet included — beyond
  identifying where it appears.
- **CP-07 — Pinned fields.** PR head SHA (or n/a for issues), canon
  SHA, agent version, served model ID.

## Template

```markdown
## Committee packet — <PR | issue> #<n>: <title>

Reviewed-at: pr-head `<sha or n/a>` · canon `<sha>` ·
agent `<x.y.z>` · model `<served model ID>`
Author: <login> (<author class, API-determined>)

### 1. Scope statement

<one paragraph: what the item is, what it touches, judged from the
diff, paths, commit metadata, CI status, and author class only.>

### 2. Triggers fired

- **<E-NN>** — "<rule text quoted from rules/escalation-triggers.md>"
  Evidence: <where in the item this fires — file/hunk/paths>.

### 3. Canon touched / contradicted / absent

| Canon | Relation | Citation |
| --- | --- | --- |
| <doc/section/ADR/DE> | <touched / contradicted / absent> | <path + anchor, at canon `<sha>`> |

### 4. Checklist results (where a trigger prescribed checks)

| Checklist item | Result |
| --- | --- |
| <item> | <pass / fail / n-a> |

### 5. Questions for the committee

1. <a question only a human can answer — e.g. "Do we accept an
   unanchored structural change to X, or require a DE/ADR first?">
2. <...>

### Attachments

- <if E-21: the full Triage Receipt for this item (public side was
  reduced to the generic escalation line).>
- <if salvage was run: the decomposition and drafted contributor
  response, for the committee's awareness — humans post everything.>
```
