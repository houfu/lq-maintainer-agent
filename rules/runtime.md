# Runtime — one agent, two hosts (RT-NN)

Normative data for the LQ Maintainer Agent (design delta v0.7.5 §1).
Loaded **first, whole**, by every skill, at Step 0 — before
`rules/loading.md` and before any content is read. Every rule carries a
stable ID (`RT-NN`). Companion rule sets: `rules/loading.md` (`LD-NN` —
LD-11's fan-out, which RT-06 conditions), `rules/escalation-triggers.md`
(E-10 — the agent-instruction files of both hosts), and
`settings/README.md` (the hook these rules read their facts from).

The agent runs as a **Claude Code plugin** and as a **Codex plugin**
from the same tree. Codex reads this repo's `.claude-plugin/` layout,
`skills/*/SKILL.md` and `hooks/hooks.json` as they stand. What it does
**not** do is honor three of the mechanisms the design's guarantees were
written against: `allowed-tools` (not enforced), `disable-model-invocation`
(ignored), and `agents/*.md` (not loaded). It also substitutes no plugin
path into skill text or model-run shells.

The ruling this file encodes (2026-09-29): **the guarantees are the
design; the mechanisms are per host.** Nothing below relaxes a
guarantee to fit a host. Where a host cannot supply the mechanism a
guarantee needs, the guarantee is met a stricter way, or the capability
it protected does not run on that host.

| Guarantee | Claude Code | Codex |
| --- | --- | --- |
| §2.1 blocks (merge, push, PR refs, …) | `hooks/hooks.json` PreToolUse | the same hook, once trusted in `/hooks` |
| Every GitHub write reaches a human | `allowed-tools` omits writes, so they prompt | the hook hands them over (RT-04) |
| Skills fire only when named | `disable-model-invocation: true` | `skills/<skill>/agents/openai.yaml` `allow_implicit_invocation: false` (RT-05) |
| Fan-out members are read-only | `agents/*.md` `tools:` | `agents/codex/*.toml` `sandbox_mode = "read-only"`, or no fan-out (RT-06) |
| A review run gets the full floor (RT-09) | the canary arms the session by `session_id` | the same, by Codex's `session_id` |
| Plugin paths resolve | `${CLAUDE_PLUGIN_ROOT}` substituted | bound from the canary (RT-01) |

## Binding

- **RT-01 — The plugin root is bound once, from the host's own report,
  and every command uses the bound absolute path.** Throughout this
  repo, `${CLAUDE_PLUGIN_ROOT}` is the **plugin-root token**. Where the
  host substituted it (Claude Code), the text already carries the path.
  Where it reads literally (Codex), bind it from the canary's `root=`
  field (RT-03); if that reads `not-reported`, bind it as the directory
  two levels above the `SKILL.md` the host listed for this skill, and
  confirm `<root>/.claude-plugin/plugin.json` names `lq-maintainer`
  before trusting it. **Never run a shell command containing the
  literal token**: an unset variable expands to empty and the command
  runs `/skills/...` — a wrong file at best. Every rule, template,
  and script path the run then reads or runs is `<root>/…`.
- **RT-02 — The data directory is bound the same way.**
  `${CLAUDE_PLUGIN_DATA}` is the data token (the deck, receipt and
  cache store, design §3.1). Bind it from the canary's `data=` field.
  If that reads `not-reported`, ask the maintainer where to store the
  run's files — the standing fallback — and never invent a path. A
  store outside the session's writable roots makes each write prompt on
  Codex; that is the host working as intended, not a fault to route
  around.

## The safety floor, checked rather than assumed

- **RT-03 — The canary runs first, and its answer is recorded.** Before
  any other command, run exactly `lq-maintainer-safety-canary`. The
  safety hook always blocks it with one status line beginning
  `LQ-MAINTAINER SAFETY FLOOR ACTIVE` and carrying `runtime=`,
  `writes=`, `model=`, `root=`, `data=` and, last, `armed=`. Record the
  line in the work log (`RP-21` / `RI-15`, act `script`) and bind RT-01,
  RT-02, RT-04 and RT-07 from it.

  **The canary also arms the session (RT-09).** `armed=yes` means the
  hook has recorded this session as a review run, and every later Bash
  call in it meets the full review floor. `armed=failed` means the hook
  could not record it: the session would fall back to the coder floor
  on its next call, so **the run stops** exactly as it does without the
  marker, and the maintainer is told the fix (the hook could not write
  the armed-marker directory under their home, named in `settings/README.md`; make it a writable directory of their own).
  A line with no `armed=` field is an older hook than these rules: stop
  and update the plugin. `armed=no` is never printed.

  **Any other answer — "command not found", an approval prompt, exit
  0, or a block without the marker — means the §2.1 hook is not loaded,
  and the run stops before reading anything.** Tell the maintainer the
  one-line fix and draft nothing: on Codex, open `/hooks` and trust the
  `lq-maintainer` hook (a plugin hook is skipped until trusted, and
  every plugin update changes its hash); on Claude Code, restart the
  session after installing or updating, and never run under
  `--dangerously-skip-permissions`, where no hook runs at all. If asked
  to approve the canary, the maintainer should decline: the prompt is
  itself the evidence that the hook is missing. A run without its
  floor is not a degraded run; it is not a run (the posture `LD-09`
  takes toward the security rule files).

- **RT-04 — Gated writes follow the write mode the hook reports.** The
  gated writes are the ones design §8.4 routes through a human prompt:
  `gh pr comment`, `gh issue comment`, and `gh api` POST/PATCH on a
  comments endpoint. The hook passes them only where the host
  guarantees that prompt — Claude Code in the `default`, `acceptEdits`
  or `plan` permission mode (`writes=prompt`). Everywhere else
  (`writes=hand-over`: every Codex session, Claude Code in `auto`,
  `dontAsk` or `bypassPermissions`, and any host or mode the hook does
  not recognize) the hook blocks them, and the skill **hands the write
  over**: the exact command, the path of the body file it posts, and
  one line on what it does — the form every milestone write already
  takes (`MS-10`). The maintainer runs it or does not. Never attempt a
  gated write in `hand-over` mode to see whether it passes, never
  rephrase one after a hand-over block, and record each hand-over in
  the work log with the result `n-a`. Everything the §2.1 hook blocks
  outright stays blocked in both modes.

- **RT-09 — Two floors: a review run is always armed, and the coder
  floor never weakens the human-only invariants.** The plugin is enabled
  per host, not per project, so its hook runs in every session the
  maintainer opens — including the ones where they are simply a coder
  on the repo. The hook therefore keys its floor on the host's session
  identity (`session_id`, sent with every hook event by Claude Code and,
  per Codex's hooks documentation, by Codex command hooks too):

  - **Review floor (armed).** A session in which the canary has run.
    Everything §2.1 and RT-04 describe, unchanged: the `gh` allow-list,
    `git push` blocked, gated writes prompted or handed over. Because
    RT-03 runs the canary before any other command, **a review run is
    always armed before it reads anything** — no PR, issue or canon
    text is in context while it is on any other floor.
    The review floor also refuses the other roads to contributed
    code: fetching, pulling or listing a repository by URL, adding or
    repointing a remote, and cloning a URL — a review run's clone
    fetches named remotes only.
  - **Coder floor (unarmed).** A session that never ran the canary.
    `git push`, `gh pr create` / `edit` / `ready`, `gh issue create` /
    `edit`, label and release edits, and non-`DELETE`, non-GraphQL
    `gh api` writes pass the hook and meet the host's own permission
    evaluation. What stays blocked is the set lq-ai's vetting policy
    reserves for a human regardless of purpose — the **five human-only
    invariants**: (1) merging (`gh pr merge`, the REST merge endpoint);
    (2) reviewing or approving (`gh pr review` in every form, the REST
    reviews endpoint); (3) closing (`gh pr close`, `gh issue close`, a
    `state` other than open); (4) deleting (`gh repo delete`, every `gh`
    `delete` subcommand, every `gh api` `DELETE`); and (5) contributed
    code never entering an agent session (any fetch or checkout of
    `refs/pull/*` or `pull/<n>/{head,merge}`, and `gh pr checkout` in
    every form). The routes that could launder those five stay blocked
    with them: `gh api graphql`, alias definition on either tool,
    `gh extension install` / `create` / `exec` / `upgrade`, and the
    `git-push` / `git-send-pack` / `git-receive-pack` plumbing binaries.
    The coder floor is not a review floor with holes: no skill runs on
    it, and nothing on it is ever recorded as a review.

  **Arming is one-way.** There is no disarm command, because a
  prompt-injected agent would run it, and the hook blocks, in both
  floors, any Bash command naming the armed-marker directory or writing or
  deleting under `.lq-maintainer` (plain reads of the publishing
  config, logs and site build pass). That is a floor, not a
  boundary: the marker is a hook-bypass surface of the same class as
  hook-file self-modification (`settings/README.md`), and an agent that
  deletes or backdates it by another tool is actively evading — which
  is itself the finding. A marker older than 24 hours is
  ignored, so an abandoned session lapses rather than lingering. A
  maintainer who wants to code after a review opens a new session.
  **A host without session identity gets the review floor**: a payload
  with no usable `session_id` string, a marker directory the hook cannot
  read, or a marker it cannot parse all count as armed — the floor only
  ever fails toward the stricter one. And where no hook runs at all
  (`--dangerously-skip-permissions`, an untrusted or disabled Codex hook)
  there is no floor of either kind; RT-03's canary is what makes that
  visible. The hook screens the Bash tool only, so **a review run uses
  `gh` through Bash for every GitHub read and never a connector (MCP)
  tool** — the hook sees what it does.

## Invocation

- **RT-05 — Skills fire only when named, on both hosts, and render the
  host's own spelling.** Every skill ships both switches:
  `disable-model-invocation: true` in its `SKILL.md` frontmatter and
  `skills/<skill>/agents/openai.yaml` with `policy.allow_implicit_invocation: false`
  beside it (`ci/scripts/test-runtime-compat.sh` fails a skill missing
  either). The repo's text spells commands the Claude Code way,
  `/lq-maintainer:<skill>`; the same skill on Codex is
  `$lq-maintainer:<skill>`. Every command a run **renders for the
  maintainer** (a deck's next step, a handed-over re-run) uses the
  spelling of the host named by the canary's `runtime=` field.

## Fan-out

- **RT-06 — A fan-out runs only on an agent the host pins read-only.**
  A subagent that judges contributed content gets no write surface
  (design §9). On Claude Code that is the plugin's `agents/*.md` with
  their `tools:` lists. On Codex it is an installed custom agent from
  `agents/codex/` whose `sandbox_mode` is `read-only`; a built-in or
  general-purpose agent never stands in for one. Where no such agent
  is available — including `triage-item` on Codex, which needs `gh` and
  therefore network a read-only sandbox does not have — the run takes
  the single-context path each skill already carries (`LD-11`'s
  re-read; the Tier-2 passes run in sequence), and the work log records
  the fan-out as `not-run` with the reason. The path taken never
  changes a call (the same bar `LD-10` holds loading to).

## Pinned fields

- **RT-07 — The served model ID is the host's report, never a name the
  model gives itself.** Use the canary's `model=` field where it is
  not `not-reported` (Codex sends its model slug to hooks); otherwise
  the platform's own report as the skills already require, and
  otherwise "not-recorded — session did not expose a model ID". The
  **agent version** is read from `<root>/.claude-plugin/plugin.json`
  on both hosts. The runtime (`claude-code` / `codex`) is recorded in
  the work log beside the four pinned fields; it is not a fifth one,
  and the `receipt:v2` footer is unchanged.

## What this file never does

- **RT-08 — A host is never a reason for a lighter touch.** No lane,
  category, tier, trigger, finding, or outcome reads the runtime. Two
  hosts running the same skill on the same head SHA and canon SHA owe
  the same calls; where they cannot do the same work (RT-04, RT-06),
  the difference is in who presses the button and how many windows ran
  — never in what was judged.
