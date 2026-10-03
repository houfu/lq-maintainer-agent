# LQ Maintainer Agent — Design Doc v0.7.5

**Status: adopted 2026-10-03** (proposed 2026-09-29; merged as #18, shipping
as plugin v0.7.0). This document is a **delta over
v0.7.4** (`lq-maintainer-agent-design-v0.7.4.md`): it records one
capability — **the agent runs on two hosts, Claude Code and Codex,
from one tree** — and restates the design's platform-shaped claims as
host-neutral guarantees with a named mechanism per host.
`docs/proposals/codex-compat.md` carries the request, the findings,
and the rulings. Where this document is silent, v0.7.4 remains
normative, then v0.7.3, v0.7.2, v0.7.1, v0.7 and v0.6 beneath it.

## 1. Guarantees are the design; mechanisms are per host (new; `rules/runtime.md` RT-NN)

v0.6 §3.3, §9 and §10 state several guarantees in the vocabulary of
the host they were first built on: "`allowed-tools` grants, it does
not restrict", "explicit invocation is enforced:
`disable-model-invocation: true`", "read-only enforced via the
subagent's `tools` frontmatter", "`${CLAUDE_PLUGIN_ROOT}` paths". This
delta re-reads each as **the guarantee it names**, which binds on every
host, plus **the mechanism** that delivers it on Claude Code. Codex
supplies different mechanisms, and in three places none at all:

| Guarantee (unchanged) | Claude Code | Codex |
| --- | --- | --- |
| §2.1 blocks | PreToolUse hook | the same hook, once trusted |
| Every GitHub write reaches a human (§3.3, §8.4) | writes omitted from `allowed-tools`, so they prompt | the hook hands every gated write over (RT-04) |
| Skills fire only when named (§3.3) | `disable-model-invocation` | `agents/openai.yaml` `allow_implicit_invocation: false` (RT-05) |
| Fan-out members are read-only (§9) | `agents/*.md` `tools:` | `sandbox_mode = "read-only"` custom agent, or no fan-out (RT-06) |
| Plugin paths resolve (§3.3) | substituted | bound from the canary (RT-01/02) |

The binding rule (RT-08): **a host is never a reason for a lighter
touch.** Where a host cannot do the same work, the difference is in who
presses the button and how many windows ran, never in what was judged.

## 2. The floor is checked, not assumed (RT-03)

Hooks are the primary enforcement layer (v0.6 §10.1). Codex adds a way
to lose them that Claude Code does not have: a plugin hook is skipped,
**silently**, until a human trusts its exact definition, and every
update re-arms that review. Together with `[features] hooks = false`
and Claude Code's `--dangerously-skip-permissions`, a session can have
no floor and no signal.

Every skill therefore runs a **canary** first — a non-existent command
the hook always blocks with a status line. No marker, no run. §10.1's
honesty note gains one sentence: *the floor's presence is now verified
at the start of every run; its limits are unchanged.*

## 3. Gated writes: prompt where the host guarantees one, hand-over elsewhere (RT-04)

§8.4's posting flow depends on a human approval prompt per write.
Codex cannot supply one for a hook (no `ask` decision) or a skill (no
`allowed-tools` enforcement). The hook now reads the host and the
permission mode and passes the gated writes only in Claude Code's
`default`, `acceptEdits` and `plan` modes; everywhere else it blocks
them with a hand-over message, and the skill prints the exact command
for the maintainer. Fail-closed: an unrecognized host or mode has no
prompt. §3.3's rule that no write enters `allowed-tools` is unchanged
and now also stands behind a second, host-independent mechanism.

## 4. What does not change

Everything in v0.7.4 §4 holds verbatim. The agent never merges,
approves, closes, pushes, or executes contributed code; nothing
contributed is an instruction; the four pinned fields are unchanged
(the host is logged in the work log beside them, not added as a fifth);
the `receipt:v2` footer is unchanged. No lane, category, tier,
trigger, or outcome reads the host.

E-10 widens to the second host's instruction files (`AGENTS.override.md`,
`.codex/**`, `.agents/**`) — the same class, one host further.

## 5. Implementation order

The hook changes and their test land first (every other surface
depends on the canary). `rules/runtime.md`, the skill Step-0 bindings
and the `openai.yaml` switches follow, then the Codex manifests, agent
and command rules, then docs. Ships as plugin v0.7.0.

Eval impact: none on lane grading — no fixture's outcome depends on the
host. The new CI suite `runtime-compat-test` carries the hook's
behavior under both payload shapes and the two-host packaging lint.
