# publish/ — the scheduled refresh of the public reviews site

This directory is **not** part of any skill. It holds the one piece of
the publishing design (`rules/publishing.md`, `PB-10`–`PB-12`) that
runs outside an agent session: a plain shell script a maintainer
schedules on their own machine to regenerate the public site from
their local review records and, once the committee has said so, push
it to the branch GitHub Pages serves from on
`LegalQuants/lq-ai-community`.

Why it lives outside the skills: the agent never pushes, holds no
credential for the community repository, and every armed session
blocks `git push` at the hook (`rules/runtime.md` RT-09). A site that
stays current needs *someone* to push on a schedule, and that someone
is the maintainer's own automation, running as them, with their
credential, with no model in the loop. The script refuses to run when
it detects an agent session's environment, so a prompt-injected run
cannot borrow it.

| File | What it is |
| --- | --- |
| `site-refresh.sh` | The job: generate → scan → (if enabled) clone, replace, commit, push. Also installs and removes its own LaunchAgent. |
| `com.legalquants.lq-ai-reviews-site.plist` | The launchd template `--install-launchd` fills in for this machine (script path, log dir, hour). |

The generator it calls is `skills/triage/scripts/publish-site.sh` — the
whitelist publisher with the sanitization gate — and every refusal or
scan hit there stops this job before any push.

## First run (nothing is pushed)

```sh
sh publish/site-refresh.sh --plan
```

prints the steps and runs nothing. Then

```sh
sh publish/site-refresh.sh
```

writes a default configuration to `~/.lq-maintainer/site.conf` with
`PUBLISH=no`, generates the site into `~/.lq-maintainer/site/build/`,
and stops. Open `~/.lq-maintainer/site/build/index.html` in a browser
to read what would be published. The log is
`~/.lq-maintainer/logs/site-refresh.log`, one line per run; the
generator's full output from the last run is
`~/.lq-maintainer/logs/generate.last`.

## Scheduling it

```sh
sh publish/site-refresh.sh --install-launchd
```

installs a LaunchAgent that runs the script daily at `SCHEDULE_HOUR`
(default 06:15 local time) as the logged-in user. It is safe to install
before publishing is enabled: with `PUBLISH=no` every run regenerates
the local build and pushes nothing. `--uninstall-launchd` removes it.
The job needs `gh` logged in for the account that holds push rights on
the community repository (`gh auth status`), and `git` configured to
use `gh` as its credential helper (`gh auth setup-git`); it inherits
neither from a terminal, so check both once from a fresh shell.

## Enabling publication — after the committee decides

Three things are the committee's, not this plugin's (proposal R1, R9,
R10 in `docs/proposals/public-receipts-on-lq-ai-community.md`):
enabling Pages on lq-ai-community, naming the branch it serves from,
and accepting that a maintainer's scheduled job pushes generated output
to that branch. When those are decided and the branch exists on the
remote:

1. Set `PAGES_BRANCH` in `site.conf` to the designated branch (default
   `gh-pages`) and `PUBLISH="yes"`.
2. Run `sh publish/site-refresh.sh --dry-run` once more and read the
   build.
3. Run `sh publish/site-refresh.sh`. The first push replaces the
   branch's tree with the generated site, a `.nojekyll` marker, and a
   root `README.md` that says what the branch is.

The script never pushes to `main`, never creates the branch, and stops
with a reason if the branch is missing, the generator refuses an item,
the scan hits, or `gh`/`git` fail. `SELECT` picks which items are
generated (`merged` is the pilot slice; `closed` adds closed-unmerged
items; `all` adds open ones, which the committee may not want public
while a review is live). `ALLOW_SECURITY` lists the item numbers a
maintainer has ruled publishable despite an `E-08` trigger or a
security-tagged finding (`PB-03`), one ruling per item, in their own
name.

## What it is not

- Not a skill, not a hook, not run by a model. If you ask an agent
  session to run it, it exits with a refusal.
- Not a second copy of the committee's record. `main` on
  lq-ai-community stays the committee's, changed through its own
  publication process; this job only ever writes to the Pages branch.
- Not a substitute for reading. Before `PUBLISH=yes` is set, the
  maintainer reads the local build. The scan is the floor, not the
  reviewer.
