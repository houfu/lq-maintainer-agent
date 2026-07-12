# Pattern — repro request (bug reports missing pieces)

Used by `rules/issues.md` C-10 when a bug's repro is partial or
absent. Each ask is phrased so a **non-engineer filer** can supply it:
say what to paste and where to find it, not just its name. Never
imply the report is unwelcome — an incomplete bug report is a
contribution in progress, and an unanchored bug report is a repro
request, never an escalation (`rules/anchoring.md` A-07).

Include only the rows for pieces actually missing; delete the rest.

## Template

```markdown
Thanks for reporting this, @<filer> — this looks like something we
want to fix, and your report already gives us <what is present, e.g.
"a clear description of the wrong output">.

To pin it down we need a little more. Could you add:

- **Which version you're running** — <plain-language pointer, e.g.
  "the version number shown by `<project's version command>`, or the
  date you installed/updated">.
- **The exact steps you took** — a numbered list, starting from a
  fresh start, so we can follow along and see what you saw.
- **What you expected vs. what actually happened** — one sentence
  each is plenty.
- **Any output or error text** — copy and paste it as-is (please skim
  it first and remove anything private, like file paths with your
  name or any keys/tokens).

No need to know what's wrong internally — the four items above are
enough for us to reproduce it on our side. Once we can reproduce it,
we'll take it from there and keep you posted on this issue.

<if a likely subsystem was identified: For what it's worth, this
looks related to <plain-language area>, but we'll confirm once we can
reproduce it.>

*Drafted by [lq-maintainer-agent](https://github.com/legalquants/lq-maintainer-agent/blob/main/docs/bot-behavior.md)
v<x.y.z>; reviewed and posted by @<maintainer>.*
```
