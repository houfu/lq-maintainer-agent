# One agent, two hosts — Claude Code and Codex (PROPOSED 2026-09-29; INCORPORATED into design delta v0.7.5, 2026-10-03)

Field request from the maintainer, in their words:

> i need to improve claude/codex compatibility. for example the claude
> plugin thing needs to be more generalised.

## What we found

Codex already runs this plugin. A maintainer's `~/.codex/config.toml`
had `lq-maintainer@lq-maintainer-agent` enabled at v0.6.0, installed
from the `.claude-plugin/` layout with no Codex-specific file in the
repo, and the PreToolUse hook had been trust-reviewed and was firing.
Codex 0.153 falls back to `.claude-plugin/plugin.json` and
`marketplace.json` (undocumented), discovers `skills/*/SKILL.md`, loads
`hooks/hooks.json`, and names the skills exactly as Claude Code does
(`lq-maintainer:review-pr`), invoked with `$` instead of `/`.

So the problem was never "Codex cannot load it". It is that Codex
loads it **and silently drops three of the mechanisms the design's
guarantees were written against**, plus a fourth mechanical gap:

| Gap | Consequence on Codex before this change |
| --- | --- |
| `disable-model-invocation` is ignored (Codex reads only `name` and `description`) | Every skill, including `review-pr` and `label`, is implicitly invocable. §3.3's "explicit invocation is enforced" was false on Codex. |
| `allowed-tools` is not enforced | "Writes are omitted from the allow-list, so they prompt" no longer held. With network access, `gh pr comment` could run with no human approval — **the §8.4 gate did not exist on Codex.** |
| `agents/*.md` are not loaded from a plugin | `triage-item` and `review-pass` have no Codex counterpart. A skill told to dispatch one gets a general-purpose agent with write tools, or nothing. |
| `${CLAUDE_PLUGIN_ROOT}` is substituted neither into skill text nor into model-run shells (verified: it is set only for hook commands) | Every `${CLAUDE_PLUGIN_ROOT}/skills/triage/scripts/render-deck.sh` command resolves to `/skills/...`. |

And one Codex behavior with no Claude Code analogue: **a plugin hook
runs only after a human trusts it in `/hooks`, every update re-arms
that review, and an untrusted hook is skipped silently.** A maintainer
who updates and does not re-trust has no §2.1 floor, and nothing says
so.

## The rulings

### R1 — The guarantees are the design; the mechanisms are per host

Nothing is relaxed to fit a host. Where a host cannot supply the
mechanism a guarantee needs, the guarantee is met a stricter way, or
the capability it protected does not run on that host. The table in
`rules/runtime.md` names, per guarantee, the mechanism on each host.

### R2 — The safety floor is checked, not assumed (`RT-03`)

Every skill's first command is `lq-maintainer-safety-canary`, a
non-existent command the hook always blocks with a status line. No
marker, no run. This single check covers Codex's untrusted-hook skip,
`[features] hooks = false`, and Claude Code's
`--dangerously-skip-permissions` — the three ways a session ends up
with no floor — and turns each into a refused run that names its fix.
Unhooked, the command is "not found": inert by construction.

The canary also carries the host's own facts back to the skill —
runtime, write mode, the model slug Codex sends hooks, and the plugin
root and data directory Codex exports to hooks but not to model shells
— so `RT-01`, `RT-02` and `RT-07` bind from a report, never a guess.

### R3 — Gated writes follow the host's guarantee, fail-closed (`RT-04`)

Codex hooks cannot request an approval prompt
(`permissionDecision: "ask"` is parsed but unsupported) and Codex does
not enforce `allowed-tools`. There is therefore no way, on Codex, to
make `gh pr comment` *prompt*. The two options were a best-effort
prompt through execpolicy rules the plugin cannot ship, or a block. We
take the block: on Codex the hook **hands the write over** — the agent
prints the exact command, the maintainer runs it — which is the form
every milestone and label write already takes. The same logic applies
to Claude Code's `auto`, `dontAsk` and `bypassPermissions` modes, where
no prompt is guaranteed either; the hook reads `permission_mode` and
hands over there too. Any host or mode the hook does not recognize is
treated as having no prompt.

This is the one behavior change Claude Code users will notice: a
maintainer running triage in `auto` mode now gets hand-overs instead
of auto-approved posts. That is the design's intent restated
mechanically, not a new restriction — §3.3 always said a human
approves each post.

### R4 — Both switches, always (`RT-05`)

Each skill ships `disable-model-invocation: true` **and**
`agents/openai.yaml` with `policy.allow_implicit_invocation: false`.
A CI lint fails any skill missing either, because the failure mode is
invisible from the host that has its switch set.

### R5 — Read-only fan-out or no fan-out (`RT-06`)

Codex has no per-tool allow-list for custom agents; its pin is the
sandbox. `review-pass` needs only reads, so it gets a Codex custom
agent (`agents/codex/lq-maintainer-review-pass.toml`,
`sandbox_mode = "read-only"`) that maintainers install. `triage-item`
needs `gh`, and so network, which a read-only sandbox does not have,
so it gets no Codex counterpart: batch triage on Codex takes the
single-context path `LD-11` already specifies. A general-purpose agent
never stands in for a pinned one on either host.

### R5a — The instruction files of both hosts are E-10 data

`AGENTS.override.md`, `.codex/**` and `.agents/**` join `CLAUDE.md`,
`AGENTS.md` and `.claude/**` in E-10 / I-11: flagged, never loaded.

### R6 — No build step

Unlike `lq-codex-for-legal`, which packs a source tree into
per-provider bundles, this plugin stays one tree. Codex reads the
Claude layout already; the Codex-native files
(`.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`) are
added so nothing depends on an undocumented fallback, and a lint keeps
the two manifests' name and version in lockstep. A build step would add
a release artifact to audit and a second place for the permission
surfaces to drift, for no guarantee this layout cannot already carry.

## What ships

| Surface | File | Note |
| --- | --- | --- |
| Rule set (`RT-NN`) | `rules/runtime.md` | New. Loaded first, whole, by every skill. |
| Hook: host + mode detection, hand-over, canary, fail-closed input | `settings/hooks/block-writes.sh` | Permission-bearing. |
| Codex command rules | `settings/codex/lq-maintainer.rules` | Second layer; installed by the maintainer. |
| Explicit-invocation switch | `skills/*/agents/openai.yaml` | One per skill. |
| Step 0 binding + canary grant | `skills/*/SKILL.md` | Frontmatter grants only the canary. |
| Codex read-only review member | `agents/codex/lq-maintainer-review-pass.toml` | Installed by the maintainer. |
| Codex manifests | `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json` | |
| Host spelling in decks | `skills/triage/scripts/render-deck.sh` | `LQ_RUNTIME=codex` → `$lq-maintainer:…`. |
| E-10 / I-11 widened | `rules/escalation-triggers.md`, `rules/injection-posture.md` | |
| Tests | `ci/scripts/test-block-writes.sh`, `ci/scripts/test-runtime-compat.sh`, `ci/runtime-compat-test.yml` | The hook had no direct test before. |
| Docs | `docs/onboarding.md`, `settings/README.md`, `CONTRIBUTING.md`, `README.md` | |

## Considered and left out

- **Renaming `${CLAUDE_PLUGIN_ROOT}` across ~140 sites** to a neutral
  token. Declined: Claude Code substitutes the literal, Codex sets it
  for hooks under that name too, and `RT-01` binds it on Codex. A
  rename would ripple into the drift check, the `allowed-tools`
  patterns and the merge-message trailers for no behavioral gain.
- **A PermissionRequest hook** to recreate prompting on Codex. It runs
  only when Codex was already going to ask, so it cannot create a
  prompt that the sandbox would not have raised.
- **An eval runner for Codex.** The eval runner does not exist yet for
  either host (M1); it will be written host-neutral from the start.
- **Converting `triage-item`** into a Codex agent that reads
  pre-fetched item data instead of calling `gh`. Possible; deferred
  until single-context batch triage on Codex proves too slow in use.
