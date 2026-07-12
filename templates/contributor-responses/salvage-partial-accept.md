# Pattern — salvage: partial accept ("we want two of your three ideas")

Used by `rules/salvage.md` S-12 whenever salvage decomposed an
overreaching PR or issue and at least one part survives. **Leads with
what is kept** (CR-01); then a path per part; declines cite canon
(CR-03). The default offer for any PR split is **maintainer-
performed** — handing a novice contributor unverified rework is a
documented way contributions die (design doc §6). If the hunk map is
shared with the contributor, the unverified caveat travels with it.

## Template

```markdown
Thanks @<contributor> — there's real value in here, and we want to
keep <count-kept> of your <count-total> ideas. Here's the path for
each:

**1. <part statement — the strongest kept part first>** — yes.
<disposition path, e.g. "This stands on its own; we'd like it as a
focused follow-up PR" / "We've drafted a DE entry crediting you, so
the idea enters the project's backlog with your name on it".>

**2. <part statement>** — yes, as documentation.
<e.g. "This works today as an operator recipe; a docs page serves the
goal without new code to maintain — we've sketched where it would
live.">

**3. <part statement>** — not this one.
<canon-cited reason, e.g. "This contradicts <ADR-NNN>: <one-line gist
of the decision>" / "It duplicates #<n>, where we've noted your
interest.">

**On the mechanics:** rather than ask you to re-cut the branch, we're
happy to perform the split ourselves — part 1 as its own PR crediting
you, part 2 as a docs change. If you'd prefer to do it, the hunks we'd
move are listed below; note this mapping is a suggestion we have
**not verified to compile or pass tests**, so treat it as a starting
point.

<optional hunk map: - follow-up 1: <files/hunks> ...>

Either way: one change per PR keeps each idea reviewable on its own
merits — and it means the good parts land instead of waiting on the
contested ones. Thanks again for the energy here.

*Drafted by [lq-maintainer-agent](https://github.com/legalquants/lq-maintainer-agent/blob/main/docs/bot-behavior.md)
v<x.y.z>; reviewed and posted by @<maintainer>.*
```

## Issue variant notes

For a decomposed **issue**, replace the mechanics paragraph: the
maintainer files the drafted split issues as sub-issues of the
original ("we'll open one issue per idea, each crediting you, so each
can be discussed on its own"). No compile caveat applies — there is
no diff.
