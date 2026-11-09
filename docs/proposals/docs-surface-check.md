# Does this change need a docsite update? — the docs-surface check (PROPOSED 2026-11-09; INCORPORATED into design delta v0.8 §5 the same day, shipping in v0.8.0)

Field request from the maintainer, in their words, the day after
v0.8.0 was cut:

> the task is to evaluate whether PR review needs a check on whether
> docsite update is needed

The answer is **yes, a narrow one: a mechanical detector that says
which published pages a change touches or is listed under, feeding one
Next-steps line and the self-attestation docs row — never a gate.**
This document is the plan it was built from, written against a
read-only look at lq-ai's documentation site on 2026-11-09. The
maintainer ruled the same day that it ships in v0.8.0 rather than
after it; the normative result is `rules/docs-surface.md` (`DS-NN`),
and the sequencing section below records what that ruling pulled into
the release.

## What the docsite is, in the terms this plan depends on

The site at `https://legalquants.github.io/lq-ai/` is built from
`LegalQuants/lq-ai` `main` (ADR 0028; launched by lq-ai #754 on
2026-10-25 as v0.9.1's headline). Three layers matter here:

1. **Route manifests** — `docs/site/routes/*.yaml`, six files. Each
   entry maps one published route to exactly **one** canonical
   `source:` file elsewhere in the repository (a doc under `docs/`,
   `README.md`, `CONTRIBUTING.md`, …) and optionally lists further
   `sources:` — and those lists include **code**: `api/app/api/auth.py`
   and `web/backend/open_webui/config.py` under *Is LQ.AI right for
   your team?*, `web/src/lib/lq-ai/tabs.ts` under *Where to find help*,
   `docker-compose.yml` under *What gets installed*. The build stamps
   every page "checked against `<sha>`" from git history over the page
   and its `sources:`, so a change to a listed file **moves the stamp
   without anyone checking the words**.
2. **Generated reference pages** — `/reference/` is parsed at build
   time out of `api/app/config.py`, `gateway/app/config.py`,
   `api/app/skills/schema.py`, `gateway.yaml.example`,
   `mcp.yaml.example` and `docker-compose.yml` (the docs-site
   workflow's own path list names them, with the comment that without
   them "a settings change ships while the published reference still
   describes the previous release"). Only the hand-written
   `docs/site/reference/*.intro.md` prose around those tables can go
   stale.
3. **The workflow** — `.github/workflows/docs-site.yml` builds and
   gates (single-source, orphans, links, rules, explore, e2e, pa11y)
   any PR touching a page source or a reference source, and deploys on
   push to `main` and after a Release. It cannot know a page's prose
   is now wrong.

lq-ai's own canon on the question (`canon:contributing`,
"Documentation expectations"): *"If your change affects user-facing
behavior, the documentation must be updated in the same PR … PRs that
change behavior without updating docs will be asked to add the doc
changes before merge."* The PR template's "Documentation" section asks
the contributor to tick which docs they updated; the plugin's
self-attestation cross-check (`T-02`) can today only answer
`cannot-verify` on those rows, because nothing maps a changed path to
a page.

> This supersedes the narrower framing in the session's hand-over note
> (`docsite-look-2026-11-09.md`), which located the canon requirement
> in the P10 "Contract is truth" invariant alone. CONTRIBUTING's
> documentation section is the wider and the governing text.

## What the v0.9.1 window showed

Sixty-four PRs merged between 2026-10-08 and 2026-10-28:

| Shape | PRs |
| --- | --- |
| code and docs changed together | 30 |
| docs only | 16 |
| code only | 14 — of which 9 are dependency or test-only |
| touched a generated-reference source | 9 — the reference regenerates on its own |

Of the five code-only behaviour PRs, one (#720, playbook keyword
matching) changed user-visible behaviour with no page touched, and one
(#772, the TLS trust store) changed a security posture the trust pages
state claims about. The second is a *claims* problem that lq-ai is
designing as #683 (a shared claims registry with release-time checks);
a per-PR nudge should feed that work, not duplicate it. So the
frequency is one or two in sixty-four — low, but each one is exactly
the case the stamp hides, and the PR-template row that would catch it
is the one the agent cannot verify.

## Why narrow, and why no gate

- Documentation completeness is the finding class the v0.8.0
  calibration found the maintainer removing from the merge gate most
  consistently: the 2026-08-05 ruling on #401 ("i would like to limit
  reviews") made documentation-completeness findings default to
  follow-up issues, and the same line was applied to #442, #443 and
  #488. `CF-13` exists for precisely this shape — canon asks,
  maintainer chose the gate — so the check must produce a finding that
  stays canon-required **and** takes `scope: follow-up`, never a merge
  condition the maintainer then has to remove again.
- Same posture as `UA-01`: a surface, not a verdict. The check reports
  where a change lands on the published site; it changes no lane,
  category, tier, trigger or outcome.
- A path map cannot see a semantic change under an unchanged file, and
  it cannot read prose. It gets the review to the right page; the
  review (or the maintainer) reads the sentence.

## The design (DS-NN, to become `rules/docs-surface.md` or a section of `rules/self-attestation.md`)

- **DS-01 — The docs surface is detected from paths, mechanically,
  never from the PR's words.** A new
  `skills/triage/scripts/check-docs-surface.sh` (sh/python3 polyglot,
  stdlib only, same stdin shape as `check-ui-surface.sh`: `git diff
  --name-status` lines or bare paths) classifies every changed path
  against the route manifests and the reference-source list and prints
  the strongest class:
  - **`page-changed`** — the path is some route's `source:`. The page
    itself changed; the review confirms the page's words and the
    diff's words agree. Each hit names its route.
  - **`source-listed`** — the path is in some route's `sources:` and
    that route's `source:` is **not** in the diff. The stamp will move,
    the words were not touched: the #720 shape. Each hit names the
    route(s) and the listed path.
  - **`reference-source`** — the path is a generated-reference input.
    The table regenerates; the review checks the matching `.intro.md`
    prose and any setting a page quotes by name.
  - **`none`**.
  - **`unknown`** — fail-closed: the row is missing, the manifests
    could not be read at the canon SHA, or a manifest uses YAML the
    parser does not accept. `unknown` renders as `cannot-verify` on
    the docs rows and one Next-steps line; it never gates anything, so
    failing closed costs a line, not a merge.

  The model may **raise** a surface the script missed — a module whose
  public name, route, environment variable or CLI word appears in a
  page's text (`llms-full.txt` is the one-file grep) — recorded as
  **`described`** with the reason, and may never lower one.
  Test-only and dependency-manifest paths are excluded by the row,
  which is what keeps nine of fourteen code-only PRs silent.

- **DS-02 — What it reads, and from where.** Two inputs, nothing else:
  the `canon:docs-routes` row of `rules/canon-map.md` (the manifest
  directory, the reference-source list, the intro directory, the
  exclusions), and the manifest files themselves **from the
  maintainer's lq-ai clone at the pinned canon SHA** (`git show
  <canon-sha>:docs/site/routes/<file>`), never from the contribution.
  Python's standard library has no YAML parser, so the script carries a
  parser for the subset the manifests use — `- route:` entries, scalar
  `source:`, inline `[a, b]` and block `- x` lists under `sources:` —
  and anything outside that subset makes the whole run `unknown`
  (DS-01). No network, no execution, no clone write.

- **DS-03 — What it drives.** Three places, and only these:
  1. **The self-attestation docs rows** (`T-02`, `T-05` code-quality
     pass). Two different lists meet here and the check must not
     conflate them. The PR template's rows name **specific files**
     (PRD, README, the skill-authoring guide, the deployment cookbook,
     `docs/compliance/`, the OpenAPI schema); the route manifests name
     **pages**, and the two sets differ — `docs/PRD.md` is no route's
     `source:` at all, only a `sources:` entry, while `README.md` and
     `docs/skill-authoring-guide.md` are route sources. So the split
     is: the **detector decides whether a row's condition applies** —
     "if user-facing behaviour changes" is met when `source-listed`,
     `described` or `reference-source` fires on behaviour code, and
     unmet (`n-a`, reason "no documented surface touched") on `none`;
     the **diff's own path list decides whether the row's named file
     was touched**, which is mechanical today and needs no manifest.
     Condition met and file touched → `verified-pass`; condition met
     and file untouched → `verified-fail`; condition unmet → `n-a`.
     The route names the detector prints go into the row's evidence
     cell, so the maintainer sees *which page* the untouched file
     feeds. `page-changed` on a route source is evidence that *that*
     page changed, never that a template row's file did.
  2. **One Next-steps line** (`B-14`) naming the route(s) and the one
     sentence to check or change, with its cost (minutes). For
     `source-listed` it reads: *the stamp on `<route>` will move at the
     next build; check that its sentence about `<listed path>` is still
     true.*
  3. **The finding, where canon requires one.** A user-facing behaviour
     change with `source-listed`/`described` and no `page-changed` is a
     finding under `canon:contributing` "Documentation expectations":
     `severity: major` (not `blocking` — `CF-11` reserves that word
     for defects), `evidence: canon-gap`, `fairness: own-burden`, and
     **`scope: follow-up` citing the 2026-08-05 limit-reviews ruling
     by date** (`CF-13`). It never counts toward `TR-06`, never names a
     `merge-after` fix, and reaches the contributor as at most one
     courteous sentence that the page will be updated (`CF-07`'s
     wording). A `page-changed` whose words **disagree** with the code
     in the same diff is an ordinary in-scope finding
     (`evidence: observed`, `fairness: own-burden`) at whatever
     severity the disagreement earns — that one the PR did to itself.

- **DS-04 — What it never does.** No lane, category, tier, trigger,
  outcome or `uat.gate` reads the docs surface. Nothing
  contributor-facing tabulates it (`TG-02.2`). It is not a blocker
  slug, not a label, not an escalation trigger, and `unknown` never
  escalates.

- **DS-05 — The record.** One line in the receipt's self-attestation
  section (`### Documentation surface: <class> — <routes>`), the
  Next-steps entry, and an **optional additive footer block**:

  ```yaml
  docs:
    surface: <page-changed|source-listed|reference-source|described|none|unknown>
    routes: [<route>, …]        # the routes the hits named; [] for none/unknown
    pages_changed: <integer>    # routes whose source: is in the diff
  ```

  Absent on every earlier footer, like `uat:`. The deck gets **no new
  card**: the Next-steps line is the whole public rendering, and the
  `docs` chip appears only on a finding the check produced. The
  `unknown` reading adds the `canon:docs-routes` dangling-key note to
  the coverage statement, as any unresolved row does.

## Sequencing — what the v0.8.0 ruling pulled into the release

1. **The canon pin — advanced in v0.8.0.** `ci/canon-pin.txt` is at
   `fdeced2e` (lq-ai, 2026-07-10). `docs/site/` does not exist there,
   so a `canon:docs-routes` row fails the drift check at the pin, and
   new goldens cannot be `adjudicated_under` it. Twenty-five scheduled
   pin-advance PRs are open (#17 through #44 — one for each night the
   head moved since the pin was last advanced); the newest, #44, moves
   the pin
   to `e548ad429` (2026-11-08) and its body reports the drift check
   passing against the new canon — but its own checks never ran
   (`action_required`: the default token does not trigger workflows,
   as the workflow's token note says). **Step zero is to approve its
   runs, merge it, and re-adjudicate whatever goldens eval-run
   re-flags.** Shipping the check in v0.8.0 made that step part of the
   release: `ci/canon-pin.txt` moves to `e548ad429` in the same
   change, the drift check passes against it with no canon-map edit,
   and every existing fixture's canon claims were re-checked against
   the new tree — eighteen pairs needed repair or re-wording, one
   golden's graded fields moved (the changelog records the result). The open
   pin-advance PRs are superseded by this and can be closed.
2. **The base.** Built on the v0.8.0 release branch, as part of its
   PR.
3. **The canon remote, by URL — `RT-10`.** Before this, `review-pr`
   Step 1 pinned canon to `origin/main` after a fetch. On the maintainer's own machine the
   lq-ai clone's `origin` is the `houfu` fork — behind, and without
   `site/` at all; the LegalQuants remote there is named
   `legalquants`. This detector reads manifests from that clone, so it
   would read nothing. Amend the pin rule to **the remote whose URL
   matches `canon:repo`**, falling back to `origin` only when it does,
   and warn when no remote matches. Small, and in the same release
   because the check is useless without it — now `rules/runtime.md`
   RT-10, applied in every skill's pin step.

## The canon-map row (draft)

Same `class: value, value; …` shape as `canon:ui-surface`, so the
existing `canon_row` parser reads it:

| Key | Question class | lq-ai path | Notes |
| --- | --- | --- | --- |
| `canon:docs-routes` | Documentation surface — "which published pages does this change touch, or sit under?" | routes: `docs/site/routes/`; reference-sources: `api/app/config.py`, `gateway/app/config.py`, `api/app/skills/schema.py`, `gateway.yaml.example`, `mcp.yaml.example`, `docker-compose.yml`; intros: `docs/site/reference/`; exclude: `site/`, `docs/site/_data/`; exclude-names: __tests__, .test., .spec., uv.lock, package-lock.json | Consumed by `skills/triage/scripts/check-docs-surface.sh` (DS-01/DS-02), mechanically: the manifests under `routes` are read from the clone at the canon SHA; a changed path that is a route's `source:` is `page-changed`, one in a route's `sources:` (with that route's `source:` untouched) is `source-listed`, one in `reference-sources` is `reference-source`. `exclude` first. The row is the **only** place the target's site layout is written; another project rewrites this one row, or deletes it — a missing row is `unknown`, never a failure of the review. Resolvable only at a canon pin ≥ lq-ai 2026-10-25. |

## The script (interface draft)

```
check-docs-surface.sh [--canon-map PATH] [--clone DIR] [--canon-sha SHA] < changed-paths

surface: page-changed|source-listed|reference-source|none|unknown
path: <class> <path> [route=<route>[,<route>]]      one line per changed path
route: <route> <page-changed|source-listed> <source path>   one line per route hit
pages-changed: <integer>
error: <reason>                                     unknown only; exit 1
```

Same `--self-test` discipline as the publisher: a fixture manifest set
under `ci/fixtures/docs-surface/` and `ci/scripts/test-docs-surface.sh`
covering the five classes, the fail-closed parse, the exclusion order,
and a rename (`R100`) that moves a page source.

## Evals (three, graded through `footer_must_satisfy`)

The grader does not read the `uat:` block today, and will not read
`docs:` either until the agent-run harness (M1) exists; these goldens
are structurally linted, and the `docs.surface` vocabulary joins the
grader's enumerated-value lint beside `evidence`/`fairness`.

- **`doc-01-source-listed-no-page`** — the #720 shape: a behaviour
  change in a file a route lists under `sources:`, no doc touched, PR
  body ticks "Documentation update: n/a". Expect `docs.surface ==
  source-listed`, the Next-steps line naming the route, one `major`
  finding with `evidence: canon-gap`, `fairness: own-burden`,
  `scope: follow-up` citing 2026-08-05; `outcome: merge` unchanged;
  `must_not`: any "merge — after docs" rendering, any contributor ask
  beyond one sentence, any public claimed-versus-verified table.
- **`doc-02-page-changed-disagrees`** — a PR that updates
  `docs/quickstart.md` and `docker-compose.yml` together, and the new
  prose names a port the compose change no longer exposes. Expect
  `docs.surface == page-changed`, `pages_changed >= 1`, one in-scope
  finding with `evidence: observed` pointing at the sentence; the docs
  row `verified-pass` (the page was updated) **and** the finding (it
  was updated wrong) — both, not one.
- **`doc-03-tests-only-silence`** — the over-reaction guard, the
  `uat-03` of this strand: a PR that adds test cases and nothing else.
  Expect `docs.surface == none`, no Next-steps docs line, no finding,
  nothing in the receipt but the one `n-a` row. Nine of fourteen
  code-only PRs in the window were dependency or test changes; a check
  that speaks on them has become a tax (dependency bumps already have
  their own fast-lane goldens, so the guard is written on the test
  shape).

## What shipped (v0.8.0)

`skills/triage/scripts/check-docs-surface.sh` and
`ci/scripts/test-docs-surface.sh` with fixtures under
`ci/fixtures/docs-surface/` (in the `uat-test` workflow); the
`canon:docs-routes` row and the canon pin at `e548ad429`;
`rules/docs-surface.md` (`DS-01`–`DS-05`, registered **whole** in
`LD-02`); Step 5b in `skills/review-pr/SKILL.md` beside the UA-01 step,
with the script in `allowed-tools`; `RP-23`, the visible section and the
`docs:` footer block in `templates/receipt-pr.md`; one decision-card
line and five glossary captions in the deck, with six renderer tests;
`RT-10` and the pin step of every skill; the `docs_surface` golden key,
its vocabulary lint and the `footer_must_satisfy` parse lint in the
grader; three fixtures and goldens; the design delta's §5 and the
changelog strand. No chip: the one finding renders like any other.

## Honest bounds

- A path map sees files, not meaning: a behaviour change in a file no
  manifest lists, and no page names, is invisible to the script and is
  the model's `described` raise or nothing.
- The manifests live in lq-ai and will move; the dangling-key rule
  (`canon-map.md` usage rules) applies, and `unknown` is the safe
  reading on the way.
- Claims drift across releases — the #772 shape — is lq-ai #683's
  design, not this check's. This check can hand #683 one line per PR;
  it should not grow a registry of its own.
- The evidence base is one twenty-day window of sixty-four PRs, read
  from file lists, not diffs. The 1–2 figure is a floor on what the
  stamp hid, not a measurement of what readers noticed.
