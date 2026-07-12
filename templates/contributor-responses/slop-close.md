# Pattern — slop close-with-pointer (§6.1)

Used only for the **S-SLOP** disposition (`rules/salvage.md`), which
applies only to *obvious* slop: fabricated APIs or citations, tests
asserting nothing, text answering a different repo's question,
boilerplate detached from the diff. **Anything arguable routes
standard-lane instead** — a false slop accusation costs more community
goodwill than ten slow reviews. The draft is a close-with-pointer,
never an insult; the human posts it or doesn't, and the human does the
closing (closing is hook-blocked for the agent regardless).

Note the register: state the concrete mismatch factually, point to
the contribution guide, leave the door open. Never speculate about
how the contribution was produced, and never address a tool instead
of the person. (Author class is a routing input, not a thing to
accuse anyone of — agent-authored contributions are handled by
policy, not by this pattern's tone.)

## Template

```markdown
Thanks for the interest in the project, @<contributor>. We're closing
this one because it doesn't connect to this repository as it stands:

- <the concrete, checkable mismatch — pick what applies, one or two
  lines, e.g. "`<symbol>` (line <n>) doesn't exist in this codebase
  or its dependencies" / "the tests added don't assert any behavior —
  they pass with the change reverted" / "the description refers to
  <thing>, which isn't part of this project">.

If you'd like to contribute, we'd genuinely welcome it — the best
starting points are:

- our contribution guide: <citation per rules/canon-map.md — the
  contribution-rules entry>, especially the one-change-per-PR rule
  and the test expectations;
- the list of good first contributions: <citation per
  rules/canon-map.md — the easy-first-contributions entry>.

A focused PR or issue that starts from one of those will get a real
review. Thanks.

*Drafted by [lq-maintainer-agent](https://github.com/legalquants/lq-maintainer-agent/blob/main/docs/bot-behavior.md)
v<x.y.z>; reviewed and posted by @<maintainer>.*
```
