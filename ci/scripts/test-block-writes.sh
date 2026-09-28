#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "test-block-writes: python3 missing"; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
"""Tests for settings/hooks/block-writes.sh (design 2.1; rules/runtime.md RT-NN).

The hook is the one enforcement layer both runtimes share, so it is
tested under both payload shapes: Claude Code's (no turn_id,
CLAUDE_PROJECT_DIR / CLAUDE_PLUGIN_ROOT in the environment, a
permission_mode) and Codex's (turn_id and model in the payload,
PLUGIN_ROOT in the environment). The properties under test:

  - the section 2.1 classes are blocked under every runtime and mode;
  - the read surface passes under every runtime and mode;
  - the gated-write class (gh pr/issue comment, gh api POST/PATCH on
    .../comments) passes ONLY in Claude Code's prompting modes, and is
    handed over everywhere else -- including any runtime or mode the
    hook does not recognize (RT-04, fail-closed);
  - the canary is always blocked with its marker and reports the
    runtime and write mode it detected (RT-03);
  - an unreadable Bash command is blocked, never waved through.

Run from the repo root: sh ci/scripts/test-block-writes.sh
"""

import json
import os
import subprocess
import sys

HOOK = "settings/hooks/block-writes.sh"
checks = 0
failed = 0

CLAUDE_ENV = {"CLAUDE_PROJECT_DIR": "/tmp/lq-ai", "CLAUDE_PLUGIN_ROOT": "/tmp/plugin"}
CODEX_ENV = {"PLUGIN_ROOT": "/tmp/plugin", "CLAUDE_PLUGIN_ROOT": "/tmp/plugin",
             "PLUGIN_DATA": "/tmp/data"}


def run(command, env_extra, payload_extra=None, raw=None):
    env = {k: v for k, v in os.environ.items()
           if k not in ("CLAUDE_PROJECT_DIR", "CLAUDE_PLUGIN_ROOT",
                        "PLUGIN_ROOT", "PLUGIN_DATA")}
    env.update(env_extra)
    if raw is None:
        payload = {"tool_name": "Bash", "tool_input": {"command": command}}
        payload.update(payload_extra or {})
        raw = json.dumps(payload)
    p = subprocess.run(["sh", HOOK], input=raw, capture_output=True,
                       text=True, env=env)
    return p.returncode, p.stderr


def ok(cond, label):
    global checks, failed
    checks += 1
    if cond:
        print("  ok   %s" % label)
    else:
        failed += 1
        print("  FAIL %s" % label)


def claude(mode):
    return CLAUDE_ENV, {"permission_mode": mode, "session_id": "s"}


def codex(mode="default"):
    return CODEX_ENV, {"permission_mode": mode, "turn_id": "t1",
                       "model": "codex-test-model", "session_id": "s"}


RUNTIMES = {
    "claude/default": claude("default"),
    "claude/acceptEdits": claude("acceptEdits"),
    "claude/plan": claude("plan"),
    "claude/auto": claude("auto"),
    "claude/dontAsk": claude("dontAsk"),
    "claude/bypassPermissions": claude("bypassPermissions"),
    "claude/no-mode": (CLAUDE_ENV, {}),
    "codex/default": codex("default"),
    "codex/bypassPermissions": codex("bypassPermissions"),
    "unknown-runtime": ({}, {"permission_mode": "default"}),
}
PROMPTING = {"claude/default", "claude/acceptEdits", "claude/plan"}

ALWAYS_BLOCKED = [
    "git push origin main",
    "git push --force origin HEAD:main",
    "git -C /tmp/x push",
    "sh -c 'git push'",
    "gh pr merge 12 --squash",
    "gh pr review 12 --approve",
    "gh pr close 12",
    "gh pr checkout 12",
    "gh issue close 3",
    "gh api -X PUT repos/o/r/pulls/1/merge",
    "gh api graphql -f query='mutation{x}'",
    "gh api -X DELETE repos/o/r/issues/comments/9",
    "git fetch origin pull/12/head:pr-12",
    "gh alias set m 'pr merge'",
    "gh pr edit 12 --add-label bug",
]
ALWAYS_ALLOWED = [
    "sh /plugins/lq/skills/triage/scripts/uat-run.sh --plan --pr 42 --sha abc --expectations e.json --changed c.txt",
    "gh pr view 12 --json title",
    "gh pr diff 12",
    "gh issue list --state open",
    "gh api repos/o/r/pulls/12",
    "git log --oneline -5",
    "git fetch origin main",
]
GATED = [
    "sh /plugins/lq/skills/triage/scripts/uat-run.sh --pr 42 --sha abc --expectations e.json",
    "/plugins/lq/skills/triage/scripts/uat-run.sh --pr 42 --sha abc --expectations e.json",
    "LQ_RUNTIME=codex bash uat-run.sh --out --plan --pr 1",
    "gh pr comment 12 --body-file /tmp/receipt.md",
    "gh issue comment 3 --body-file /tmp/r.md",
    "gh api -X POST repos/o/r/issues/12/comments -F body=@/tmp/r.md",
    "gh api -X PATCH repos/o/r/issues/comments/99 -F body=@/tmp/r.md",
]


def main():
    print("block-writes hook tests (%s)" % HOOK)
    for name, (env, extra) in RUNTIMES.items():
        for cmd in ALWAYS_BLOCKED:
            rc, err = run(cmd, env, extra)
            ok(rc == 2 and "BLOCKED" in err, "%s blocks: %s" % (name, cmd))
        for cmd in ALWAYS_ALLOWED:
            rc, err = run(cmd, env, extra)
            ok(rc == 0, "%s allows: %s" % (name, cmd))
        for cmd in GATED:
            rc, err = run(cmd, env, extra)
            if name in PROMPTING:
                ok(rc == 0, "%s passes gated write to the prompt: %s" % (name, cmd))
            else:
                ok(rc == 2 and "HANDED OVER" in err,
                   "%s hands over gated write: %s" % (name, cmd))

    # Canary (RT-03): always blocked, marker present, runtime + mode reported.
    rc, err = run("lq-maintainer-safety-canary", *claude("default"))
    ok(rc == 2 and "SAFETY FLOOR ACTIVE" in err and "runtime=claude-code" in err
       and "writes=prompt" in err, "canary under claude/default reports prompt mode")
    rc, err = run("lq-maintainer-safety-canary", *claude("auto"))
    ok(rc == 2 and "writes=hand-over" in err, "canary under claude/auto reports hand-over")
    rc, err = run("lq-maintainer-safety-canary", *codex())
    ok(rc == 2 and "runtime=codex" in err and "writes=hand-over" in err
       and "model=codex-test-model" in err and "root=/tmp/plugin" in err
       and "data=/tmp/data" in err, "canary under codex reports runtime, mode, model, root, data")
    rc, err = run("lq-maintainer-safety-canary", {}, {})
    ok(rc == 2 and "runtime=unknown" in err and "writes=hand-over" in err,
       "canary with no runtime signal fails closed to hand-over")

    # Unreadable input fails closed.
    rc, _ = run(None, *claude("default"), raw="not json")
    ok(rc == 2, "malformed JSON is blocked")
    rc, _ = run(None, *claude("default"),
                raw=json.dumps({"tool_name": "Bash", "tool_input": {}}))
    ok(rc == 2, "Bash call with no command string is blocked")
    rc, _ = run(None, *codex(),
                raw=json.dumps({"tool_name": "Bash", "turn_id": "t",
                                "tool_input": {"command": ["git", "push", "origin"]}}))
    ok(rc == 2, "argv-shaped command is screened (git push blocked)")
    rc, _ = run(None, *codex(),
                raw=json.dumps({"tool_name": "apply_patch", "turn_id": "t",
                                "tool_input": {"patch": "x"}}))
    ok(rc == 0, "a non-Bash tool with no command passes (matcher's job)")

    print("\n%d checks, %d failed" % (checks, failed))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
