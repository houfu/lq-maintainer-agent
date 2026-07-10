<!--
TEMPLATE: contributor-responses/repro-request.md — drafted request for
missing repro pieces on a bug report, calibrated for NON-ENGINEER
filers (design §7). lq-ai's filers are often lawyers and legal-ops
people, not developers.

Fill conventions (remove this comment block from rendered output):
- {{placeholders}} filled at render time.
- Calibration rules: no jargon without a plain-language gloss; every
  ask is a concrete, checkable action ("copy the exact text of the
  message", not "provide stderr"); acknowledge what they ALREADY gave
  us first; number the asks so partial answers are easy; never imply
  the filer did something wrong; keep the total ask small — request
  only the pieces actually missing per the receipt's repro assessment.
- If the filer is evidently an engineer (stack traces, version pins in
  the report), the skill may tighten the register — but this template's
  default is the non-engineer.
- This is a DRAFT: a human maintainer edits and posts it.
-->

Hi @{{filer}} — thanks for reporting this. What you've described
({{one-line restatement of the symptom in the filer's own terms}}) is
exactly the kind of report we want, and you've already given us
{{what they provided: "the screenshot", "the steps you took", "the
document that triggered it"}} — that helps a lot.

To track it down we need {{count}} more thing{{s}}. Numbered so you can
answer whichever you can — partial answers are still useful:

1. **{{plain-language ask, e.g. "The exact wording of any error
   message."}}** {{how to get it, concretely: "If a red or grey box
   appeared, copy its full text here (or a screenshot works). The exact
   wording matters more than it looks — it tells us which part of the
   system spoke."}}
2. **{{e.g. "What you did right before it happened."}}** {{"A simple
   list is perfect: 'I opened X, clicked Y, typed Z, then the error
   appeared.' No need for technical terms — describe it the way you'd
   tell a colleague."}}
3. **{{e.g. "Whether it happens every time."}}** {{"If you can safely
   try the same steps once more: does it fail again, or was it a
   one-off? Either answer is informative. If trying again feels risky
   with your real documents, say so and skip this one."}}
4. **{{e.g. "An example input we can use", only if applicable:}}**
   {{"If the problem involves a specific document, a stripped-down
   example with any confidential content removed or replaced is ideal.
   Please don't post anything confidential in this public thread — if
   the example can't be sanitized, tell us and we'll arrange another
   way."}}

Once we have {{the most important item}}, we can usually pinpoint the
problem quickly — we suspect it's in {{plain-language subsystem
description, e.g. "the part that reads uploaded documents"}}, and a
fix would come with a test so it stays fixed.

Thanks again for taking the time to report it.
