# LQ Maintainer Agent — Design Doc v0.7.6

**Status: proposed 2026-09-29.** A **delta over v0.7.5**
(`lq-maintainer-agent-design-v0.7.5.md`, itself proposed the same
day): one capability — **a user-facing change is seen running before it
merges** — and the one amendment to a standing prohibition it needs.
`docs/proposals/uat-for-user-facing-changes.md` carries the request,
the rulings, and the honest status. Where this document is silent,
v0.7.5 remains normative, then v0.7.4 and the chain beneath it.

## 1. User acceptance becomes part of review (new; `rules/uat.md` UA-NN)

- **Detection is mechanical** (UA-01): a path classifier over one
  canon-map row (`canon:ui-surface`) — rendered / indirect / none, plus
  an added-page flag. Words in the PR are not evidence.
- **The gate is split by surface** (UA-02): required for a rendered
  surface, an added page or component, or a new user-facing feature
  (category 1 with any surface); recommended for an indirect surface.
- **A required UAT holds the merge, not the review** (UA-03): `merge`
  renders "merge — after UAT" until a pass is recorded at the reviewed
  head SHA; the outcome vocabulary (v0.7 §4, TR-05) is unchanged.
- **Expectations first** (UA-04), sourced and maintainer-confirmed;
  the design path writes them into each user-facing atomic change
  (DP-06a).
- **One verdict per expectation** (UA-09) — matches / differs /
  not-reached — recorded in an optional additive `uat:` footer block;
  the `receipt:v2` version does not change.

## 2. I-05 amended: one contained runner (maintainer ruling 2026-09-29)

v0.6 §10 and I-05: "the agent never executes contributed code". This
delta adds exactly one exception: **`uat-run.sh`, for an eligible
item, one human-approved run per head SHA.** The runner is the
sandbox-discipline page turned into code — sequence (it refuses any PR
touching manifests, lockfiles, the Dockerfile, compose, workflows, or
anything outside the web context) and containment (trusted recipe from
`main`; contributed source built with `--network=none`; an internal
network with no published ports; `env -i` and a throwaway `.env`; no
Docker socket; full teardown). It is a gated action under v0.7.5 RT-04,
never in any `allowed-tools`, and the hook passes only its `--plan`
form ungated. Every other statement of I-05 stands, including every
reason it gives for "never" — those reasons are why the runner is
shaped as it is.

The coverage statement changes by one clause: runtime behavior is
never checked **outside the screens a UAT card lists**.

## 3. What does not change

v0.7.5 §4 holds. No surface, gate, or verdict moves an item lighter
(UA-11); a passed UAT satisfies its gate and is evidence of nothing
else. I-06 (never run a workflow PR) is untouched and additionally
enforced by the runner's refusals. Triage never runs a UAT.

## 4. Implementation order and status

Rules and canon rows; the detector; the runner in `--plan` form with
its offline test suite; hook gating; skill wiring; templates and deck;
evals (`uat-01`–`uat-03`, `adv-11`). Ships with v0.7.5 as plugin
v0.7.0.

**The runner's first real run is the field spike** (Docker, ~25 GB
cold build). Until it has completed on lq-ai, the agent-run path is
available but unproven, and receipts say so in the UAT card's
containment line.
