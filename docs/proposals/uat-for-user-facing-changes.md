# Seeing a user-facing change before it merges (PROPOSED 2026-09-29)

Field request from the maintainer, in their words:

> check whether a PR affects the layout or frontend or user facing
> situation, and if yes, recommend or require a UAT check. the agent
> may run the stack and take screenshots of the new feature, but we
> need to figure out if it is coming about as we expected

and, the same session:

> the agent should also require it for new user facing features

## The problem

A diff says what changed. It cannot say what a person now sees. lq-ai's
web UI (a SvelteKit fork under `web/`) changes about once or twice a
week, and nothing between the PR and the merge button looks at it
running: there are no preview deployments, the Cypress suite runs
nightly and mostly against stubs, and the PR template asks for no
screenshots. The review reads the diff and says, honestly, "runtime
behavior — never checked". For a layout change that is the whole
question.

## The rulings

### R1 — Detection is mechanical, from paths (`UA-01`)

`check-ui-surface.sh` classifies the changed paths against one
canon-map row (`canon:ui-surface`) into **rendered** (markup, styles,
static assets, client code), **indirect** (copy and translations, API
shapes and error strings the UI renders), or **none**, and flags an
**added** page or top-level component as a new surface. A PR's own
"no UI change" is not evidence. The model may raise the surface with a
reason, never lower it.

### R2 — Required or recommended, split by surface (`UA-02`)

- **Required** — a rendered surface; an added page or component; or a
  **new user-facing feature** (a category-1 item whose surface is not
  `none` — the maintainer's follow-up ruling).
- **Recommended** — an indirect surface only: a named next step, never
  a gate.

A required UAT holds `merge` ("merge — after UAT") until it passes **at
the reviewed head SHA**; it does not add a fifth outcome or change the
review's reasons (`UA-03`).

### R3 — Expectations before pictures (`UA-04`)

"Coming about as we expected" needs the expectation written down
first: screen, state, what a person should see — each with its source
(the linked issue, the design plan, the PRD, or the PR body marked as
contributor text). The maintainer confirms the list before any run.
No source saying what a person should see is itself the finding.
The design path writes these expectations into each user-facing
atomic change (`DP-06a`), so "what should this look like?" is answered
in the design conversation rather than discovered at review.

### R4 — The agent may run it: I-05 amended, with one runner (`UA-05`–`UA-07`)

The maintainer chose this over "human runs, agent observes" and
"checklist only", knowing it amends a standing prohibition. The
amendment is shaped so that every reason I-05 gave for "never" is
answered by construction rather than waived:

| I-05's reason | How the runner answers it |
| --- | --- |
| Installs run lifecycle scripts | Dependencies install only from **trusted `main`'s** manifests; a PR touching a manifest or lockfile is refused (UA-06.2). |
| `docker build` runs the contributor's Dockerfile | The Dockerfile and compose file come from `main`; a PR touching either is refused. The PR supplies only the web source tree. |
| Ambient credentials are the prize | Every docker/git call runs under `env -i`; the `.env` holds fresh random values and no provider keys; no Docker socket; no host mounts outside a scratch dir; the PR is fetched anonymously into a scratch bare repo, never the clone. |
| Exfiltration needs egress | Contributed source **builds with `--network=none`** (a layer missing the trusted cache fails closed) and **runs on an internal network** with every published port reset. |
| The agent is instructable by the PR | The runner is a fixed script whose eligibility checks run inside it, not in the model's judgment; screenshots are material under review (UA-08); and a real run is a **gated action** — a human approves each run for one head SHA, or it is handed over (`RT-04`). |

Eligibility (`UA-06`) is web-only in v1: anything outside `web/`, any
containment-bearing file, a head SHA other than the approved one, a
fired security trigger, or a held item → refused, and the human-run
path under sandbox discipline applies with the same expectation list.

### R5 — One verdict per expectation, recorded without inventing anything (`UA-09`, `UA-10`)

`matches` / `differs` / `not-reached`. A `differs` is an ordinary
finding in the L-33 slots; `not-reached` never counts as a pass. The
evidence record gains an optional, additive `uat:` footer block
(enumerated fields only; `receipt:v2` unchanged), the deck a UAT card,
and the coverage line becomes "runtime behavior — never checked,
except the screens the UAT card lists". Screenshots stay internal;
attaching one to the PR is the maintainer's call.

## What ships

| Surface | File |
| --- | --- |
| Rule set (`UA-NN`) | `rules/uat.md` (new) |
| I-05 / I-07 amended; E-10 unchanged | `rules/injection-posture.md` |
| Canon rows | `rules/canon-map.md` — `canon:ui-surface`, `canon:uat-stack` |
| Detector | `skills/triage/scripts/check-ui-surface.sh` (new) |
| Runner + camera | `skills/triage/scripts/uat-run.sh`, `uat-shoot.py` (new) |
| Hook: the runner is a gated action; `--plan` passes | `settings/hooks/block-writes.sh` |
| Skill wiring | `review-pr` (Step 4 item 5a, Step 9), `triage` (Step 6b card flag), `design-plan` (Step 8) |
| Templates | `receipt-pr.md` RP-22 + `uat:` footer; `triage-card.md`; `pr-comment.md`; `design-plan.md` DP-06a; deck glossary |
| Deck | `render-deck.sh` UAT card, the hold line, merge message "not ready" |
| Docs | `docs/sandbox-discipline.md`, `docs/bot-behavior.md`, `docs/onboarding.md`, `README.md`, `CONTRIBUTING.md` |
| Tests | `ci/scripts/test-uat.sh` + `ci/uat-test.yml`; hook cases in `test-block-writes.sh`; compat lint forbids granting a real run |
| Evals | `uat-01`…`uat-03`, `adv-11` |

## Honest status

The detector, the gate, the eligibility checks, the containment plan
and the hook gating are implemented and tested offline. **The runner
has not yet completed a real run against lq-ai** — the first one is a
field spike: it needs Docker, a ~25 GB cold build of the stack from
`main` (20–30 minutes; later runs reuse the cache), and it will find
the recipe details that only a real boot can (whether the web build
completes offline from cache, whether sign-in works with the generic
form selectors, whether Chromium is content with `--cap-drop ALL`).
Each is a fail-closed failure — a refused or failed run, torn down —
never a silent pass.

## Considered and left out

- **Human runs the stack, agent observes a URL.** Kept I-05 intact;
  declined by the maintainer in favour of the agent running it, with
  the containment above.
- **Preview deployments.** lq-ai has none, and adding one is a lq-ai
  infrastructure decision, not this agent's.
- **Agent-run UAT for api/, word-addin/, desktop/.** v1 rebuilds only
  the web service from contributed code; the others are human-run
  until a field run shows the web path is sound.
- **Interaction scripts (click, type, submit).** v1 photographs routes
  in named states. Interactions need a trusted step language the
  expectations can use without becoming code; deferred.
- **Visual diffing against `main`.** Useful for "nothing else moved",
  but it doubles the build; deferred until the single-build path is
  proven.
