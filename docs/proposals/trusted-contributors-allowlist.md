# Proposal — the trusted-contributors allowlist (E-07's second leg)

**Status:** drafted 2026-07-19, waiting on lq-ai. Blocked only on the
upstream file existing.

## Why

`rules/escalation-triggers.md` E-07 defines "known contributor"
(decided 2026-07, closing design doc §15 q.2) as: **verified GitHub
org membership via the API, plus a maintainer-curated allowlist for
trusted outsiders.** The org-membership leg works today (L-07, API
author class). The allowlist leg needs a file in lq-ai that does not
exist yet — and `rules/canon-map.md` cannot grow a key for a file
that fails to resolve at the pin (the drift check fails closed on
dangling keys, by design).

This proposal carries the drafted upstream file so the lq-ai PR is a
copy-paste, and records the exact canon-map row to add here once it
merges and the pin advances past it.

## Step 1 — PR against lq-ai: `.github/MAINTAINERS/trusted-contributors.md`

The `.github/MAINTAINERS/` directory already exists in lq-ai. Drafted
file content:

```markdown
# Trusted contributors (maintainer-curated allowlist)

This list extends "known contributor" for external-contribution
vetting (see docs/security/external-contribution-vetting.md and the
lq-maintainer-agent's escalation rules): a GitHub account listed here
is treated as a known contributor for review-routing purposes even
though it is not a LegalQuants org member.

Being listed here NEVER waives review, anchors, or the vetting
policy's human merge gate — it only changes whether the *full*
external-author checklist auto-runs on sensitive-class changes.

Rules for this file:

- One account per line, with the date added and the sponsoring
  maintainer. Remove liberally; re-adding is cheap.
- Changes to this file are security-relevant: CODEOWNERS-route it to
  the security reviewers, two-maintainer review.
- Identity is the GitHub account, verified via the API — never a
  display name or an email claimed in a commit.

| GitHub account | Added | Sponsoring maintainer | Note |
| --- | --- | --- | --- |
| _(none yet)_ | | | |
```

The lq-ai PR should also add a CODEOWNERS line routing
`.github/MAINTAINERS/trusted-contributors.md` to the security
reviewers (consistent with the file's own rules, and with E-01
picking up changes to it automatically on the agent side).

## Step 2 — after the lq-ai pin advances past that merge, in THIS repo

Add to the `rules/canon-map.md` routing table:

```markdown
| `canon:trusted-contributors` | Known-contributor allowlist — "is this external author trusted for E-07 purposes?" | `.github/MAINTAINERS/trusted-contributors.md` | The curated second leg of E-07's known-contributor definition (decided 2026-07). Read from the clone's `main` at the pinned canon SHA; account identity is still verified via the API (L-07) — the list names who is trusted, the API proves who is asking. |
```

And update E-07's interim clause ("Until the allowlist exists, org
membership alone") to cite `canon:trusted-contributors`.

## Non-goals

- No trust *scoring* — the list is binary and human-curated (the
  agent never scores people; receipt rule RP-09 keeps contributor
  trust permanently human).
- No effect on anchors, lanes, or the merge gate — E-07 controls
  only whether the full external-author checklist auto-runs.
