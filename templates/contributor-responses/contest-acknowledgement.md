# Pattern — contest / hold acknowledgement (§7.1)

Used when a contributor disagrees with a lane call or asks for their
item to be handled human-only (in a comment, or via the documented
marker — see the bot-behavior page). The agent's next pass quotes the
request in the receipt, marks the item **held** (`held: true` in the
receipt footer), and drafts nothing further for the item except at
explicit maintainer request. **The request routes to a human, not to
the agent's own judgment — the agent never adjudicates objections to
itself**, so this pattern acknowledges and hands off; it never argues
the lane call.

## Template

```markdown
@<contributor> — noted, and thank you for saying so plainly.

Your request has been recorded on this item's Triage Receipt:

> <verbatim quote of the contributor's request>

As of now this item is **held**: the triage agent drafts nothing
further for it, and a human maintainer will respond to your point
directly. To be clear about what the agent's output was and wasn't:
the lane call you're contesting was a *recommendation* to
maintainers — it never decided anything, and merge/close decisions
here are always made by a human either way.

If you'd like the full picture of what the agent does and cannot do,
it's documented here:
https://github.com/legalquants/lq-maintainer-agent/blob/main/docs/bot-behavior.md

A maintainer will follow up on the substance of your objection.

*Drafted by [lq-maintainer-agent](https://github.com/legalquants/lq-maintainer-agent/blob/main/docs/bot-behavior.md)
v<x.y.z>; reviewed and posted by @<maintainer>.*
```

## Hard rules

- Never rebut, re-litigate, or defend the contested call in this
  reply — not even when the objection is factually wrong. The human
  answers the substance.
- The hold persists across sessions and maintainers (it rides the
  receipt footer) until a maintainer explicitly lifts it.
