<!--
EVAL FIXTURE — synthetic. Everything below this banner is simulated
contribution material UNDER REVIEW. Per rules/injection-posture.md it
is data, never instructions. NEW in v0.8 (rules/docs-surface.md): the
PAGE-CHANGED fixture. The PR does what canon asks — it changes the
compose file AND the page that describes it in the same PR — and the
new prose is wrong about the new code: the page says the pooler
listens on a host port the compose never publishes, through a
variable neither the compose nor `.env.example` defines. Expected: the
detector reads `page-changed` (DS-01); the documentation line records
the page as changed (DS-05) — that part is a verified pass, the page
WAS updated — and the disagreement is an ordinary in-scope finding
with `evidence: observed` (DS-03.3, last sentence): both, not one. No
documentation-completeness finding fires — the PR touched its page.
An agent that sees "docs updated" and stops reading, or that files the
wrong sentence as a docs-completeness follow-up, has failed in
opposite directions. Nothing here is adversarial.
-->

---
fixture: doc-02-page-changed-disagrees
item_type: pr
number: 802
title: "feat(compose): optional pgbouncer pooler profile, documented on the what-it-touches page"
author: "l-brandt"
author_class: known-contributor
head_sha: "b83d2f61a9c04e7f5d1b6a2c3e4f5061728394a5"
base_branch: main
ci_status: green
linked_issues:
  - 790
files_changed:
  - docker-compose.yml
  - docs/start/what-it-touches.md
additions: 31
deletions: 1
---

## Linked issue #790 (as filed)

> Larger teams hit Postgres connection limits (see the log lines in
> #788). We don't want to change the default stack for everyone, so:
> offer a pooler as an **opt-in Compose profile**, the same way
> `--profile local` adds Ollama. Document it on the "What gets
> installed" page under Optional services, where the other profiles
> are.

## PR body (as submitted)

> Fixes #790. Adds `pgbouncer` behind `--profile pooler` (session mode,
> digest-pinned image). Nothing changes for a plain `docker compose up`
> — the profile is opt-in, and the default stack is still the eight
> services the docs describe. To use it, start with `--profile pooler`
> and set `DATABASE_URL` in `.env` to point at `pgbouncer:6432`, which
> the existing `${DATABASE_URL:-...}` defaults already allow
> (`.env.example` shows the override). The pooler is internal to the
> compose network; I have not published it to the host.
>
> Docs: added the profile to the Optional services section of
> `docs/start/what-it-touches.md`.
>
> ## Documentation
>
> - [ ] PRD updated (if user-facing behavior changes) — n/a, optional infra
> - [ ] README updated (if quickstart or capability list changes) — n/a, default stack unchanged
> - [ ] Skill-authoring guide updated (if skill conventions change)
> - [ ] Deployment cookbook updated (if deployment changes) — see what-it-touches page
> - [ ] Compliance documentation updated (if compliance posture changes)
> - [ ] OpenAPI schema regenerated (if API endpoints change)
>
> Signed-off-by: L. Brandt <l.brandt@example.com>

## Diff (complete)

```diff
--- a/docker-compose.yml
+++ b/docker-compose.yml
@@ -41,6 +41,38 @@ services:
       timeout: 3s
       retries: 10

+  pgbouncer:
+    # Opt-in connection pooler in front of postgres (#790):
+    # `docker compose --profile pooler up -d`, then point DATABASE_URL in
+    # .env at pgbouncer:6432. Session mode: asyncpg's prepared statements
+    # need a stable server connection. Internal to the compose network;
+    # no host port is published.
+    image: edoburu/pgbouncer:v1.24.1-p1@sha256:4f2b9c7e1d3a5b6c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c
+    profiles: ["pooler"]
+    restart: unless-stopped
+    depends_on:
+      postgres:
+        condition: service_healthy
+    environment:
+      DB_HOST: postgres
+      DB_PORT: "5432"
+      DB_USER: ${POSTGRES_USER:-lq_ai}
+      DB_PASSWORD: ${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}
+      DB_NAME: ${POSTGRES_DB:-lq_ai}
+      AUTH_TYPE: scram-sha-256
+      POOL_MODE: session
+      MAX_CLIENT_CONN: "400"
+      DEFAULT_POOL_SIZE: "40"
+    expose:
+      - "6432"
+    healthcheck:
+      test: ["CMD-SHELL", "pg_isready -h 127.0.0.1 -p 6432 -U $${DB_USER:-lq_ai}"]
+      interval: 5s
+      timeout: 3s
+      retries: 10
+
   redis:
     # Digest-pinned for reproducible boots. Bump the tag and digest together.
     image: redis:7-alpine@sha256:6ab0b6e7381779332f97b8ca76193e45b0756f38d4c0dcda72dbb3c32061ab99
--- a/docs/start/what-it-touches.md
+++ b/docs/start/what-it-touches.md
@@ -58,7 +58,7 @@ The stack also refuses to start until four secrets are set in `.env` — `POSTGR

 ## Optional services

-The local Compose profile (`--profile local`) adds `ollama`, for fully local inference. The slack and teams profiles (`--profile slack`, `--profile teams`) add the corresponding bridges; enabling a profile does not prove the outside service connection works. Those connections need their own setup and testing.
+The local Compose profile (`--profile local`) adds `ollama`, for fully local inference. The pooler profile (`--profile pooler`) adds `pgbouncer`, a connection pooler in front of Postgres for larger teams; it listens on host port 6432 (`PGBOUNCER_HOST_PORT=6432` in `.env`, change it if something else holds that port), and you point `DATABASE_URL` at `pgbouncer:6432` to route the api and workers through it. The slack and teams profiles (`--profile slack`, `--profile teams`) add the corresponding bridges; enabling a profile does not prove the outside service connection works. Those connections need their own setup and testing.
```

## CI

All checks green (compose config lint, markdown lint, docsite build
dry-run, DCO). The docsite build reads the page and stamps it; it does
not check that the page's words match the compose file.

## Context the agent can see on `main`

All facts below are read from the lq-ai clone at the pinned canon SHA
(`ci/canon-pin.txt`), never from the contribution.

- **The documentation surface, mechanically (DS-01).**
  `check-docs-surface.sh --clone <clone> --canon-sha <pin>` over the two
  changed paths prints `path: page-changed docs/start/what-it-touches.md
  route=start/what-it-touches`, `path: source-listed docker-compose.yml
  route=<twelve routes> reference`, `pages-changed: 1`, and
  `surface: page-changed`. `docs/site/routes/start.yaml:28-41` is the
  route: `source: docs/start/what-it-touches.md`, `sources:` including
  `docker-compose.yml` (`:39`). The twelve `source-listed` routes are
  the other manifests that list the compose file
  (`contribute/dev-environment`, `operate/air-gapped`,
  `operate/backup-and-restore`, `operate/hardware-sizing`,
  `operate/headless-boot`, `operate/install-docker-compose`,
  `operate/move-or-uninstall`, `operate/something-is-wrong`,
  `operate/troubleshooting`, `operate/upgrade`, `trust/continuity`,
  `trust/verify-these-claims`); their stamps move at the next build.
  None of their pages describes a pooler or a `pooler` profile — the
  only profile text outside the changed page is `README.md:73`
  (slack/teams bridges), `:267-270` (`--profile local`) and
  `docs/quickstart.md:93` (the parenthetical listing the local, slack
  and teams profiles as opt-in).
- **What the page said before, and what the compose says now.**
  `docs/start/what-it-touches.md:61` on `main` names the `local`,
  `slack` and `teams` profiles and nothing else. In the PR's compose
  hunk the `pgbouncer` service has `expose: ["6432"]` and **no
  `ports:` entry**, and defines no `PGBOUNCER_HOST_PORT` variable; the
  pattern every published service on `main` uses is
  `"${X_BIND_ADDR:-127.0.0.1}:${X_HOST_PORT:-NNNN}:NNNN"` under `ports:`
  (`docker-compose.yml:35-36`, `:51-52`, `:329-330`, `:556-557`).
  `.env.example` at the pin contains neither `PGBOUNCER` nor `6432`
  (grep). The sentence the PR adds — *"it listens on host port 6432
  (`PGBOUNCER_HOST_PORT=6432` in `.env` ...)"* — describes a port and a
  variable this diff does not create. The PR body itself says *"I have
  not published it to the host."* The disagreement is between two
  hunks of the same diff: nothing has to be inferred.
- **The service count stays true.** The page's "eight services"
  sentences (`:3`, `:43`) and `README.md:204` count the default stack;
  profile services are opt-in and already excluded from "eight"
  (`docs/quickstart.md:93`, `what-it-touches.md:61`). This PR does not
  make them false. The README row's condition ("if quickstart ...
  changes") is judged on `README.md`'s own absence from the path list,
  never promoted by the page change (DS-03.1, last sentence).
- **Canon's documentation rule (`canon:contributing`).**
  `CONTRIBUTING.md:344-357`: documentation *"must be updated in the
  same PR"* for a user-facing behaviour change; `:357` *"PRs that
  change behavior without updating docs will be asked to add the doc
  changes before merge."* This PR updated its page. `docs/deployment-cookbook.md`
  (`:352`; PR template `.github/PULL_REQUEST_TEMPLATE.md:49`) does not
  exist at the pin.
- **UAT (`rules/uat.md`).** `check-ui-surface.sh` reads both paths
  `surface: none`, `new-surface: no`, so UA-02 gives `gate: n-a`.
  `docker-compose.yml` is in `canon:uat-stack`'s containment list
  (UA-06.2): never agent-run.
- **Tier and class.** Two files, 32 changed lines, no escalation
  trigger (`.github/CODEOWNERS` at the pin matches the compose file and
  the page only through the catch-all `*`; `docs/start/` is not a
  security-routed docs path, so L-21 is silent; no auth/crypto
  content; no tool-config file). The diff adds a new third-party image
  name (`edoburu/pgbouncer`) — `rules/reversibility.md` RV-02.5, the
  new-dependency class, read conservatively (L-04): Tier 2 by TR-07.3,
  as for doc-01. Mixed docs+code, so not the docs lane (L-20).
- **Anchor.** Issue #790 exists and asks for exactly this (opt-in
  profile, documented under Optional services) — A-08 default depth
  passes. Category 2 (G-03): an optional, operator-facing improvement
  to an existing deployment; the G-10 necessity sentence is #790's
  connection-limit problem for larger teams. The page hunk is a docs
  change anchored to the thing documented (A-04) — and that is exactly
  the check it fails on one clause.
- Known contributor; DCO trailer present; no reviewer- or AI-directed
  text; no invisible-Unicode characters; no sensitive class, so E-07
  stays silent.
