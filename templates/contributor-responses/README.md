# Contributor responses — scenario index

Drafted reply patterns for contributor-facing comments. Skills pick
the scenario-matching pattern and fill it; **a human posts every
reply** — the agent never posts, closes, or labels (design doc §2.1,
§10). Shared rules across all patterns:

- **CR-01 — Lead with what is kept.** Wherever anything survives,
  the reply opens with it (`rules/salvage.md` S-12).
- **CR-02 — Warm to the person, precise about the work.** Calibrated
  for a possibly non-engineer contributor; never an insult, never
  sarcasm, never "your AI wrote this" as an accusation.
- **CR-03 — Declines cite canon.** Path + anchor via
  `rules/canon-map.md`; "we don't want this" is never sufficient.
- **CR-04 — Attribution line.** Each pattern ends with the same
  attribution line receipts carry (agent version + posting
  maintainer, linked to the bot-behavior page). The maintainer may
  reword the reply freely; the attribution line stays.
- **CR-05 — No exploit detail, ever,** in any reply
  (`rules/issues.md` C-40 / `rules/escalation-triggers.md` E-08).
- **CR-06 — Bound by the conduct standard.** Every pattern is the
  contributor-facing expression of `rules/conduct.md` (`CD-NN`): it
  meets `canon:code-of-conduct` (the project's Contributor Covenant) and
  respects the contributor — critique the change never the person,
  assume good faith, acknowledge genuine effort, and phrase next-step
  asks as courteous requests that explain why (`CD-06`). CR-02 is the
  register rule; CR-06 is its normative source.

| Scenario | Pattern |
| --- | --- |
| Bug report missing repro pieces | `repro-request.md` |
| Overreaching PR/issue, parts survive (salvage) | `salvage-partial-accept.md` |
| Vulnerability filed publicly | `vulnerability-redirect.md` |
| Obvious slop — close with pointer (§6.1) | `slop-close.md` |
| Contributor contests a lane call / asks human-only (§7.1) | `contest-acknowledgement.md` |

The attribution line, verbatim (fill version and maintainer):

```markdown
*Drafted by [lq-maintainer-agent](https://github.com/legalquants/lq-maintainer-agent/blob/main/docs/bot-behavior.md)
v<x.y.z>; reviewed and posted by @<maintainer>.*
```
