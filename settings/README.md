# settings/ — the §2.1 safety floor (reference copy)

This directory is the plugin's **permission-bearing surface**: the
hard-block layer that keeps any Claude Code session with the plugin
active from performing repository actions reserved for humans.

The policy it enforces is lq-ai's own
(`docs/security/external-contribution-vetting.md`, restated as design
doc §2.1): automated assistants **"may review and report, but the merge
button is a human maintainer's"** — and that does not relax with trust.
The agent recommends, drafts, and reports; a human decides, every time.
These files make that policy mechanical rather than aspirational.

Two homes for the same block (design §3.3):

- **The plugin path** ships the hook via `hooks/hooks.json` at the
  plugin root — a plugin's bundled settings file **cannot** carry
  permission rules, so the hook is the whole plugin-side enforcement.
- **`settings/claude-settings.json` is the reference copy** that M0
  vendors into lq-ai's own `.claude/settings.json`, covering Claude
  Code sessions in the product repo that do *not* have this plugin
  installed. It carries the deny rules *and* the hook registration.

## Structured as an allow-list *(v0.6, research 2026-07)*

Naive deny-lists miss write spellings nobody anticipated — above all
`gh api`/GraphQL mutations. The hook
(`settings/hooks/block-writes.sh`) therefore does not enumerate
known-bad strings; for `gh` it enumerates **what is permitted** and
denies the rest by default:

| Allowed through the hook | Notes |
| --- | --- |
| `gh pr list / view / diff / checks / status` | the read surface |
| `gh issue list / view / status` | |
| `gh repo view`, `gh release list/view`, `gh run list/view`, `gh workflow list/view`, `gh label list`, `gh search *`, `gh auth status`, `gh status`, `gh help` | read-only |
| `gh api` with method GET or HEAD | the default method; `-f`/`-F` fields imply POST and are screened as POST |
| `gh api` POST/PATCH on `…/comments` endpoints only | the **permission-gated** receipt post and update-in-place flow (design §8.4) |
| `gh pr comment`, `gh issue comment` | same gated flow |
| local `git` (log, diff, show, status, fetch of branch refs, …) | except the blocked classes below |

Everything `gh` outside that table is **blocked**: merge, review (all
forms — use `gh pr comment`), close, checkout, edit, ready, alias,
extension, repo administration, `gh api graphql` (always POST; cannot
be method-screened; REST GETs cover every read the agent needs,
including author-class checks), and every non-GET `gh api` call except
the comment flow. `DELETE` is never allowed, anywhere.

The git side keeps a targeted deny: `git push` and `git send-pack` in
any form (force flags, `-C`/`--git-dir` rearrangements, compound
commands, quoted and `sh -c`-wrapped spellings, line continuations),
any fetch/checkout touching `refs/pull/*` or `pull/<n>/{head,merge}`
(contributed code is never brought into an agent session — design
§10), and alias definition on either tool (`gh alias set/import`,
`git config … alias.*`), which can launder a blocked verb under an
arbitrary name.

**Passing the hook is not "promptless."** Everything the hook allows
still goes through normal permission evaluation; only what a skill's
`allowed-tools` frontmatter grants runs without asking, and nothing
that writes to GitHub is ever in that frontmatter (design §3.3).
Posting a Triage Receipt still requires a human to approve the write —
it is gated, not banned.

## Two enforcement layers

`claude-settings.json` carries both:

1. **`permissions.deny` rules** — e.g. `"Bash(gh pr merge:*)"`. Cheap,
   declarative, evaluated before anything runs — but they are *prefix*
   matches and structurally cannot express an allow-list: a deny on
   `Bash(gh:*)` would also kill the read surface, because deny rules
   take precedence over allow rules. The deny entries are therefore
   the coarse first-chance layer for the named §2.1 classes, no more.
2. **A `PreToolUse` hook** (`hooks/block-writes.sh`, matcher `Bash`) —
   the layer that actually carries the §2.1 allow-list structure. It
   parses the full command text (env-var prefixes, wrappers like
   `env`/`sudo`/`timeout`/`xargs`, shell `-c` strings, `eval`,
   command substitution, quoted subcommand words), resolves each `gh`
   and `git` invocation, and exits `2` (block, with an explanation fed
   back to Claude) on anything not permitted. The hook is deliberately
   **complete on its own**: when the plugin loads only the hook
   (plugins cannot inject permission rules), every §2.1 class is still
   blocked.

Design bias: **false positives over false negatives.** The hook will
occasionally block an innocent command — a Bash heredoc whose body
mentions `gh pr merge`, a wrapper it cannot vouch for. That costs a
maintainer a moment; an under-block costs the policy. Draft file
content with the Write tool rather than Bash heredocs, and run `gh`
directly rather than through wrappers. Do not "fix" an over-block by
loosening a rule without checking what evasion the rule exists to
catch.

Two deliberate over-blocks to know about: **all** `gh pr review` forms
are blocked, not just `--approve` (prefix deny rules cannot see flags,
and the allow-list simply omits review) — use `gh pr comment`, which
is the receipt flow's path anyway; and `gh repo clone` is blocked
(cloning a contributor fork is checkout-of-contributed-code by another
road; the maintainer's own clone is where sessions run).

## How it loads

**Via the plugin (the normal path).** The plugin ships
`hooks/hooks.json` at the plugin root — the auto-discovered hooks
manifest — carrying just the `PreToolUse` registration (and nothing
else: a stray `permissions` key does not belong in a hooks manifest
and would do nothing). The hook registers in every session where the
plugin is active, and `${CLAUDE_PLUGIN_ROOT}` in the hook command
resolves to the installed plugin directory. Hooks load at session
start — after installing or updating the plugin, restart Claude Code,
then verify registration with `claude --debug` or `/hooks`. Keep
`hooks/hooks.json` and the `hooks` block in
`settings/claude-settings.json` in sync: same script, same matcher.

**As a settings file (lq-ai's M0 copy, or `claude --settings`).** The
file is also a valid Claude Code settings document: merge the
`permissions.deny` array and the `hooks` block into the target repo's
`.claude/settings.json`, copy `hooks/block-writes.sh` to
`.claude/hooks/block-writes.sh`, and change the hook command to

```json
"command": "sh \"$CLAUDE_PROJECT_DIR/.claude/hooks/block-writes.sh\""
```

because `${CLAUDE_PLUGIN_ROOT}` only resolves for plugin-provided
hooks. In this path both layers apply, including the deny rules. The
script needs `python3` on PATH (universal on dev machines); if it is
missing, the hook **blocks everything** rather than allowing anything
(fail-closed).

## Verifying

The hook is a plain filter — test it directly:

```sh
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' \
  | sh settings/hooks/block-writes.sh
echo "exit: $?"   # expect 2 and a policy message on stderr
```

Swap in any blocked class (expect exit 2), any allow-listed read
(expect exit 0, no output), or a default-deny probe like
`gh api -X PUT repos/o/r/pulls/1/merge` (expect 2 — no pattern names
that endpoint; the allow-list structure catches it). In a live
session, `claude --debug` shows hook registration and per-call
results; `/hooks` lists what loaded. The M0 spike test installs the
plugin into a scratch clone and verifies the hooks actually fire
(design §14); the eval harness's adversarial fixtures include
command-evasion cases exercised against this script in CI.

## What the hooks do — and do not — guarantee *(design §10.1)*

Hooks are the chosen primary enforcement layer (maintainer decision,
2026-07, over requiring GitHub-side rulesets). State the limits
plainly so nobody believes a stronger claim than the mechanism
supports. Hooks can be bypassed by:

- **settings/hook-file self-modification** — a session that edits
  `.claude/settings.json`, `hooks/hooks.json`, or the hook script can
  disarm them; that is why these paths are CODEOWNERS-routed and
  two-review in this repo (§3.6) and security-routed in lq-ai (§2.1),
  and why an agent *actively evading* its hooks is itself detectable
  behavior in a human-supervised session;
- **write operations phrased as `gh api`/GraphQL mutations** —
  mitigated by the allow-list structure above (non-GET denied by
  default, GraphQL blocked outright), which is exactly why v0.6
  abandoned the deny-list structure;
- **environment-variable prefixing and wrapper tricks** — the hook
  resolves the common forms (`FOO=bar gh …`, `env`, `sudo`,
  `timeout`, `sh -c`, `eval`, command substitution) and fails closed
  on what it cannot parse, but no text filter is a security boundary
  against a determined evader;
- **`--dangerously-skip-permissions`** — hooks do not run at all under
  it. **`docs/onboarding.md` therefore forbids running triage sessions
  with permission checks disabled**; there is no legitimate triage
  reason to do so.

Accordingly the M0 exit criterion claims "merge, approve, close, push,
and PR-ref checkout are **blocked at the hook layer**" — not
"impossible" (design §14). Also not caught here: shell aliases or
wrapper scripts that themselves push/merge, git commands issued by
tools other than the Bash tool, and actions taken entirely outside
Claude Code. Those are backstopped by the rest of the system: lq-ai's
branch protection, required human review, and the read-only
`allowed-tools` posture (design §10). Server-side enforcement (branch
protection, rulesets) remains available to lq-ai's admins as an
independent layer, but this project does not require it.

This is a floor, not the ceiling: everything not blocked still goes
through normal permission prompting, and the agent's skills request
only read tools, the §5.1 check scripts, and the gated comment flow.

## Changing these files

`settings/` and `hooks/` are the repo's permission-bearing surfaces:
changes require **two maintainer reviews** and are CODEOWNERS-routed
(design §3.6). The agent must never be easier to poison than the repo
it guards. Every release tags the plugin version; receipts record the
agent version that produced them, so a change here is traceable to the
reviews it influenced.
