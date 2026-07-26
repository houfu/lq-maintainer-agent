# Template — cross-item feedback log (maintainer → agent)

The append-only record of what maintainers actually decided when it
diverged from — or commented on — what the agent recommended. One log
per target repository, **maintainer-internal**: it lives at
`${CLAUDE_PLUGIN_DATA}/<owner>-<repo>/feedback-log.md`, never in the
community repo's per-item directories and never on any public surface
— the per-item `### Maintainer decision` receipt section (RP-18)
carries the item's ruling; this log aggregates the
**agent-performance signal across items**, which is exactly the raw
material new golden evals (`evals/`) and rule amendments are built
from. Written behind the same human-gate discipline as every internal
artifact.

## Field rules

- **FL-01 — When to append.** An entry is appended when (a) the
  maintainer's final decision differs from the agent's recommendation
  (`decision.alignment` is `adjusted` or `overridden`, RP-18), or
  (b) the maintainer gives explicit feedback on the agent's handling,
  whatever the alignment. Routine full agreement gets **no entry** —
  the log stays high-signal; the receipt already records the ruling.
  A session with no recorded ruling (RP-18 is optional — e.g. a
  contributor running a review skill to check their own work) appends
  nothing: this log records maintainer rulings and maintainer
  feedback only.
- **FL-02 — Entry format.** Exactly the block in the template below:
  date, item, the agent's recommendation with its assigning rule, the
  maintainer's decision, and the why **in the maintainer's words,
  quoted** — never paraphrased into agreement. Newest entry last
  (append-only; entries are never edited or removed — a correction is
  a new entry referencing the old one).
- **FL-03 — Feedback is about the agent, never the contributor.** An
  entry critiques the agent's routing, depth, tone, or judgment. No
  contributor-directed commentary, no quoted contribution content
  beyond what identifies the divergence — the same posture as the
  receipt footer (`templates/receipt-pr.md`).
- **FL-04 — The eval loop.** When authoring or revising golden evals,
  read this log first: a recurring divergence ("the agent keeps
  routing X too heavy") is a golden-file candidate and possibly a
  rule amendment. An entry that has been converted notes the golden
  ID on a follow-up line, so the loop is auditable.
- **FL-05 — Mirror flag in the receipt.** Whenever an entry is
  appended, the item's receipt footer sets
  `decision.feedback_logged: true` (RP-18) — so a resuming session
  knows the signal was captured without re-asking the maintainer.

## Template — one entry

```markdown
## <YYYY-MM-DD> — <pr|issue> #<n>

- Agent recommended: <outcome/recommendation enum> (<assigning rule id>)
- Maintainer decided: <what they did, plain language>
  (alignment: <adjusted | overridden | accepted-with-feedback>)
- In their words: "<the maintainer's why / feedback, quoted verbatim>"
- Rule(s) implicated: <rule id(s), if the maintainer or agent named one | none identified>
- Golden candidate: <yes — <what the fixture would test> | no>
<if later converted: - Converted to golden: <golden file id>, <date>>
```
