<!--
TEMPLATE: contributor-responses/salvage-partial-accept.md — the drafted
contributor reply when the salvage protocol keeps some parts and
redirects or declines others (design §6).

Fill conventions (remove this comment block from rendered output):
- {{placeholders}} filled at render time.
- LEAD WITH WHAT IS KEPT. The first substantive sentence names the
  parts we want. Never open with the problem ("this PR is too big").
- Every decline carries a canon citation; every preserved idea names
  where it now lives (drafted DE-XXX / mini-PRD stub crediting the
  contributor). No part is dismissed without a stated path.
- This is a DRAFT: a human maintainer edits the tone and posts it. The
  contributor-engagement-tone judgment on the receipt stays open until
  they do.
- The contributor population often works with AI assistants and tends
  to overdeliver; the tone target is "your ideas are landing — here is
  the path for each," never "you did it wrong."
-->

Hi @{{contributor}} — thanks for this. There's real value here, and we
want to take it: **we want {{kept_count}} of your {{total_count}}
ideas** — here's the path for each.

**What we're keeping:**

- **{{part title}}** — {{one sentence on why it fits, with anchor
  citation if it has one}}. Path: {{e.g. "if you can split just this
  part ({{the specific hunks/files}}) into its own PR, it's ready to
  review as-is — happy to talk you or your tooling through the split if
  useful."}}
- **{{part title}}** — {{…}}. Path: {{e.g. "we've drafted this as
  {{DE-XXX / a mini-PRD stub}} crediting you, so the idea enters the
  project's canon and can be built when it's scheduled — you'd be the
  natural person to pick it up."}}

**What we're routing elsewhere:**

- **{{part title}}** — this one works better as documentation than as
  shipped code: {{one sentence — the project's default is that an
  operator recipe beats shipped code when both would work}}. Path:
  {{where the doc would live}}.
- **{{part title}}** — this overlaps {{#NNN / DE-NNN}}, which already
  tracks it; we've cross-referenced your version there so the overlap
  is recorded.

**What we're declining, and why:**

- **{{part title}}** — {{one sentence, citing the specific canon:
  "conflicts with {{ADR-NNNN}}, which decided {{one clause}}" / "out of
  scope per {{PRD section}}"}}. If you think the canon itself should
  change, that's a legitimate conversation — the place to raise it is
  {{an issue proposing the change}}, not this PR.

**Practical next step:** {{one line — usually: "close this PR in favor
of the split above; we've drafted the follow-up titles so filing them
is a copy-paste."}} One change per PR keeps each piece reviewable in
minutes instead of weeks — which gets your work merged faster.

Thanks again — decomposed like this, most of what you built survives.
