# settings/ — the §2.1 safety mirror

This directory is the plugin's **permission-bearing surface**: the
hard-block list that makes it impossible for any Claude Code session
with the plugin active to perform repository actions reserved for
humans.

The policy it enforces is lq-ai's own
(`docs/security/external-contribution-vetting.md`, restated as design
doc §2.1): automated assistants **"may review and report, but the merge
button is a human maintainer's"** — and that does not relax with trust.
The agent recommends, drafts, and reports; a human decides, every time.
These files make that policy mechanical rather than aspirational.

lq-ai ships its own copy of this block-list in its
`.claude/settings.json` (the M0 deliverable), which covers Claude Code
sessions in the product repo that do *not* have this plugin installed.
This mirror exists so protection also travels with the plugin — into an
unhardened clone, a fresh machine, or any other checkout a maintainer
happens to run `/triage` from.

## What is blocked

| Command class | Why |
| --- | --- |
| `gh pr merge` (any flags, incl. `--admin`, `--auto`) | Merging is the human maintainer's click, always. |
| `gh pr review --approve` / `-a` | Approval is a human judgment; the agent only drafts findings. |
| `gh pr close`, `gh issue close` | Closing is a disposition decision; the agent drafts the close rationale, a human posts it. |
| `git push` — all remotes, all forms (`--force`, `--force-with-lease`, `-f`, `+refspec`, `git -C <dir> push`, `git --git-dir=… push`, compound commands, quoted/`sh -c`-wrapped spellings, line continuations) — plus `git send-pack`, push's plumbing | The agent never writes to any remote. |
| `gh alias set` / `gh alias import` | An alias can launder a blocked subcommand under an arbitrary name (`gh alias set m 'pr merge'`); the agent has no legitimate use for defining aliases. |
| `gh pr checkout`, and any fetch/checkout of `refs/pull/*` or `pull/<n>/head\|merge` refs | Contributed code is never brought into an agent session (design §10): everything downstream of checkout — test collection, install scripts, builds — executes contributor code with the session's ambient credentials. |
| `gh repo delete` | Destructive; never the agent's call. |
| `gh api` / `gh api graphql` write-equivalents of all of the above | Merge endpoints (`pulls/<n>/merge`, `repos/*/merges`), review `event=APPROVE`, `state=closed`, method `DELETE`, writes to `git/refs` or `/contents/` (push-equivalents), and the corresponding GraphQL mutations (`mergePullRequest`, `closePullRequest`, `closeIssue`, `updateRef`, `createCommitOnBranch`, …). |

Not blocked — deliberately: the read surface (`gh pr list/view/diff/checks`,
`gh issue list/view`, `gh api` GETs, local `git log/diff/status/fetch <branch>`)
and the **permission-gated draft-posting flow** (`gh pr comment`,
`gh api …/comments -f body=…`). Posting a Triage Receipt still requires a
human to approve the write in the permission prompt (design §8); it is
gated, not banned.

## Two enforcement layers

`claude-settings.json` carries both:

1. **`permissions.deny` rules** — e.g. `"Bash(gh pr merge:*)"`. Cheap,
   declarative, evaluated before anything runs. But they are *prefix*
   matches: they cannot see `git -C /some/dir push`, `cd x && git push`,
   a force-push flag, a `refs/pull/*` fetch, or a `gh api` call to a
   merge endpoint.
2. **A `PreToolUse` hook** (`hooks/block-writes.sh`, matcher `Bash`) —
   the second layer that pattern-matches the full command text and
   exits `2` (block, with an explanation fed back to Claude) on any
   §2.1 class. The hook is deliberately **complete on its own**: every
   blocked class above is caught by the hook even where no deny rule
   fires, because plugin loading may carry only the hook (plugins
   cannot inject permission rules into a user's settings).

Design bias: **false positives over false negatives.** The hook will
occasionally block an innocent command whose text resembles a push
(e.g. `git log` output piped through a filter mentioning ` push `).
That costs a maintainer a moment; an under-block costs the policy. Do
not "fix" an over-block by loosening a pattern without checking what
evasion the pattern exists to catch.

One deliberate over-block to know about: the deny rules block **all**
`gh pr review` forms, not just `--approve`, because prefix rules cannot
see flags. Use `gh pr comment` for comment posting — that is the
receipt flow's path anyway. (The hook itself only blocks the
approve forms.)

## How it loads

**Via the plugin (the normal path).** The plugin ships
`hooks/hooks.json` at the plugin root — the auto-discovered hooks
manifest — carrying just the `PreToolUse` registration (and nothing
else: plugins cannot inject `permissions.deny` rules, and a stray
`permissions` key does not belong in a hooks manifest). The hook
registers in every session where the plugin is active, and
`${CLAUDE_PLUGIN_ROOT}` in the hook command resolves to the installed
plugin directory. Hooks load at session start — after installing or
updating the plugin, restart Claude Code, then verify registration
with `claude --debug` or `/hooks`. Keep `hooks/hooks.json` and the
`hooks` block in `settings/claude-settings.json` in sync: they must
name the same script with the same matcher.

**As a settings file (lq-ai's M0 copy, or `claude --settings`).** The
file is also a valid Claude Code settings document: merge the
`permissions.deny` array and the `hooks` block into the target repo's
`.claude/settings.json`, copy `hooks/block-writes.sh` to
`.claude/hooks/block-writes.sh`, and change the hook command to

```json
"command": "sh \"$CLAUDE_PROJECT_DIR/.claude/hooks/block-writes.sh\""
```

because `${CLAUDE_PLUGIN_ROOT}` only resolves for plugin-provided
hooks. In this path both layers apply, including the deny rules.

## Verifying

The hook is a plain filter — test it directly:

```sh
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' \
  | sh settings/hooks/block-writes.sh
echo "exit: $?"   # expect 2 and a policy message on stderr
```

Swap in any command from the table above (expect exit 2) or from the
read surface (expect exit 0, no output). In a live session, `claude
--debug` shows hook registration and per-call results; `/hooks` lists
what loaded. The eval harness's adversarial fixtures (`evals/fixtures/`)
include command-evasion cases exercised against this script in CI.

## Failure behavior and known gaps

- **Fail-closed where it matters.** If `grep` is missing the hook
  blocks everything with an explanation. If `jq` is missing it falls
  back to pattern-matching the raw hook JSON with widened boundaries —
  which can only over-block, never under-block. Keep `jq` installed
  for precise matching.
- **Not caught here:** shell aliases or wrapper scripts that
  themselves push/merge, git commands issued by tools other than the
  Bash tool, and actions taken entirely outside Claude Code. Those are
  backstopped by the rest of the system: lq-ai's branch protection,
  required human review, and the read-only `allowed-tools` posture
  (design §10).
- **This is a floor, not the ceiling.** Everything not denied still
  goes through normal permission prompting; the agent's skills request
  only read tools plus the gated comment-posting writes.

## Changing these files

`settings/` is one of the repo's judgment/permission-bearing surfaces:
changes require **two maintainer reviews** and are CODEOWNERS-routed
(design §3.6). The agent must never be easier to poison than the repo
it guards. Every release tags the plugin version; receipts record the
agent version that produced them, so a change here is traceable to the
reviews it influenced.
