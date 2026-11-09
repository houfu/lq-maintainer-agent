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
  - an unreadable Bash command is blocked, never waved through;
  - two floors (v0.8.0, RT-09): every case above runs ARMED (the canary
    has armed the session first), and a session that never ran the
    canary gets the coder floor -- git push, gh pr create and ordinary
    gh api writes pass, while merge, review, close, delete, PR-ref
    fetch/checkout (gh pr checkout in every form), GraphQL and alias
    definition stay blocked. Missing session_id and an unreadable
    marker directory fail closed to armed; a stale marker does not arm.

Every run gets a throwaway HOME, so no case reads or writes the real
~/.lq-maintainer. The hook has no environment override for the marker
directory on purpose (one would be a disarm switch); HOME is the seam.

Run from the repo root: sh ci/scripts/test-block-writes.sh
"""

import datetime
import hashlib
import json
import os
import subprocess
import sys
import tempfile

HOOK = "settings/hooks/block-writes.sh"
checks = 0
failed = 0
HOME = tempfile.mkdtemp(prefix="lq-hook-test-home-")

CLAUDE_ENV = {"CLAUDE_PROJECT_DIR": "/tmp/lq-ai", "CLAUDE_PLUGIN_ROOT": "/tmp/plugin"}
CODEX_ENV = {"PLUGIN_ROOT": "/tmp/plugin", "CLAUDE_PLUGIN_ROOT": "/tmp/plugin",
             "PLUGIN_DATA": "/tmp/data"}


def run(command, env_extra, payload_extra=None, raw=None, home=None):
    env = {k: v for k, v in os.environ.items()
           if k not in ("CLAUDE_PROJECT_DIR", "CLAUDE_PLUGIN_ROOT",
                        "PLUGIN_ROOT", "PLUGIN_DATA")}
    env.update(env_extra)
    env["HOME"] = home or HOME
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


def coder(sid, base=None):
    """A Claude Code default-mode session with its own session_id."""
    env, extra = base or claude("default")
    extra = dict(extra)
    extra["session_id"] = sid
    return env, extra


def marker(home, sid):
    return os.path.join(home, ".lq-maintainer", "armed",
                        hashlib.sha256(sid.encode("utf-8")).hexdigest())


def two_floors():
    """v0.8.0 (RT-09): the canary arms; an unarmed session gets the coder floor."""
    home = tempfile.mkdtemp(prefix="lq-hook-floors-")
    CANARY = "lq-maintainer-safety-canary"

    # Arming.
    env, extra = coder("review-1")
    rc, err = run(CANARY, env, extra, home=home)
    ok(rc == 2 and "SAFETY FLOOR ACTIVE" in err and err.rstrip().endswith("armed=yes"),
       "canary arms the session and prints armed=yes last")
    ok(os.path.exists(marker(home, "review-1")),
       "marker is named by the SHA-256 of the session_id")
    ok(not os.path.exists(os.path.join(home, ".lq-maintainer", "armed", "review-1")),
       "marker is never named by the raw session_id")
    ok(oct(os.stat(os.path.join(home, ".lq-maintainer", "armed")).st_mode & 0o777) == "0o700",
       "marker directory is mode 0700")
    rc, err = run(CANARY, env, extra, home=home)
    ok(rc == 2 and "armed=yes" in err, "a second canary in the same session is still armed=yes")
    ok(" armed=no" not in err, "armed=no is never printed")
    rc, err = run("git push origin feature", env, extra, home=home)
    ok(rc == 2 and "BLOCKED" in err and "Floor: REVIEW" in err,
       "armed: git push origin feature blocks (review floor)")
    rc, err = run("gh api repos/o/r/issues/1 -fstate=closed", env, extra, home=home)
    ok(rc == 2, "armed: a glued -fkey=value field is screened as a write (v0.8.0, stricter)")
    for cmd in ("rm -rf ~/.lq-maintainer/armed", "find $HOME/.lq-maintainer -delete",
                "touch -d yesterday ~/.lq-maintainer/armed/x",
                "mv ~/.lq-maintainer ~/old", "echo x > ~/.lq-maintainer/armed2"):
        rc, err = run(cmd, env, extra, home=home)
        ok(rc == 2 and "one-way" in err, "armed: cannot disarm via Bash: %s" % cmd)
    rc, err = run("sh publish/site-refresh.sh", env, extra, home=home)
    ok(rc == 2 and "BLOCKED" in err and "PB-10" in err,
       "armed: site-refresh.sh with no --plan blocks (PB-10)")
    rc, err = run("sh publish/site-refresh.sh --plan", env, extra, home=home)
    ok(rc == 0, "armed: site-refresh.sh --plan passes")
    rc, err = run("publish/site-refresh.sh --plan --install-launchd", env, extra, home=home)
    ok(rc == 2 and "PB-10" in err,
       "armed: site-refresh.sh --plan plus a later mode flag blocks")

    # Review floor: no fetch by URL, no new remotes, no clone of a URL
    # (Codex session logs, 2026-11-06).
    for cmd in ("git fetch https://github.com/contrib/lq-ai.git fix/587-install-id-token",
                "git fetch http://example.com/r.git main",
                "git fetch ssh://git@github.com/contrib/lq-ai.git b",
                "git fetch git@github.com:contrib/lq-ai.git b",
                "git fetch git://example.com/r.git b",
                "git pull https://github.com/contrib/lq-ai.git b",
                "git ls-remote https://github.com/contrib/lq-ai.git",
                "git -C /tmp/x fetch --depth 1 https://github.com/contrib/lq-ai.git b",
                "git remote add contrib https://github.com/contrib/lq-ai.git",
                "git remote set-url origin https://github.com/contrib/lq-ai.git",
                "git remote -v add contrib git@github.com:contrib/lq-ai.git",
                "git clone https://github.com/contrib/lq-ai.git",
                "git clone --depth 1 git@github.com:contrib/lq-ai.git /tmp/c"):
        rc, err = run(cmd, env, extra, home=home)
        ok(rc == 2 and "never fetched into an armed session" in err,
           "armed blocks: %s" % cmd)
    for cmd in ("git fetch origin", "git fetch origin main", "git fetch --all --prune",
                "git pull origin main", "git remote -v", "git remote show origin",
                "git ls-remote origin"):
        rc, _ = run(cmd, env, extra, home=home)
        ok(rc == 0, "armed passes: %s" % cmd)

    # The coder floor: a session that never ran the canary.
    env, extra = coder("coder-1")
    for cmd in ("git push origin feature",
                "git push -u origin HEAD",
                "gh pr create --fill",
                "gh pr edit 5 --add-label bug",
                "gh pr comment 5 --body x",
                "gh issue create --title t --body b",
                "gh api -X PATCH repos/o/r/issues/1 -f title=x",
                "gh api -X PATCH repos/o/r/issues/1 -f state=open",
                "git fetch https://github.com/someone/lib.git main",
                "git remote add upstream https://github.com/o/r.git",
                "git clone https://github.com/o/r.git",
                "sh publish/site-refresh.sh",
                "git log --oneline -3"):
        rc, err = run(cmd, env, extra, home=home)
        ok(rc == 0, "unarmed passes: %s" % cmd)
    for cmd in ("gh pr merge 5",
                "gh pr merge 5 --squash --admin",
                "gh pr review 5 --approve",
                "gh pr review 5 --comment -b x",
                "gh pr close 5",
                "gh issue close 3",
                "gh pr checkout 12",
                "gh pr checkout feature-branch",
                "gh repo delete o/r --yes",
                "gh release delete v1",
                "git fetch origin refs/pull/7/head",
                "git fetch origin pull/7/head:pr-7",
                "gh api -X DELETE repos/o/r/issues/comments/1",
                "gh api graphql -f query='mutation{x}'",
                "gh api -X PUT repos/o/r/pulls/1/merge",
                "gh api -X POST repos/o/r/pulls/1/reviews -f event=APPROVE",
                "gh api -X PATCH repos/o/r/issues/1 -f state=closed",
                "gh api -X PATCH repos/o/r/pulls/1 --input body.json",
                "gh alias set m 'pr merge'",
                "gh extension install someone/gh-x",
                "git config alias.p push",
                "git -c alias.p=push p",
                "git-send-pack origin",
                "git-push origin",
                "rm -rf ~/.lq-maintainer",
                "touch -d yesterday ~/.lq-maintainer/armed/x",
                "ls ~/.lq-maintainer/armed"):
        rc, err = run(cmd, env, extra, home=home)
        ok(rc == 2 and "BLOCKED" in err,
           "unarmed still blocks: %s" % cmd)
    rc, err = run("gh pr merge 5", env, extra, home=home)
    ok("Floor: CODER" in err and "EVERY mode" in err,
       "coder-floor block names its floor and says the action is human-only in every mode")
    rc, err = run("sh /plugins/lq/skills/triage/scripts/uat-run.sh --pr 42 --sha abc --expectations e.json",
                  env, extra, home=home)
    ok(rc == 0, "unarmed uat-run.sh keeps the gated treatment (prompting mode passes to the prompt)")
    cenv, cextra = coder("coder-codex-uat", codex())
    rc, err = run("sh /plugins/lq/skills/triage/scripts/uat-run.sh --pr 42 --sha abc --expectations e.json",
                  cenv, cextra, home=home)
    ok(rc == 2 and "HANDED OVER" in err, "unarmed codex: uat-run.sh is still handed over")

    for fname, (fenv, fextra) in (("armed", coder("review-1")), ("unarmed", coder("coder-1"))):
        for cmd in ("cat ~/.lq-maintainer/site.conf",
                    "tail -n 50 ~/.lq-maintainer/logs/site-refresh.log",
                    "open ~/.lq-maintainer/site/build/index.html",
                    "ls ~/.lq-maintainer"):
            rc, _ = run(cmd, fenv, fextra, home=home)
            ok(rc == 0, "%s: a plain read under ~/.lq-maintainer passes: %s" % (fname, cmd))

    # Codex payload, unarmed: same coder floor.
    env, extra = coder("coder-codex", codex())
    rc, _ = run("git push origin feature", env, extra, home=home)
    ok(rc == 0, "unarmed codex: git push origin feature passes")
    rc, _ = run("gh pr merge 5", env, extra, home=home)
    ok(rc == 2, "unarmed codex: gh pr merge 5 blocks")

    # Fail-closed: missing session_id means armed.
    for label, sid in (("missing", None), ("empty", ""), ("non-string", 7)):
        env, extra = claude("default")
        extra = dict(extra)
        if sid is None:
            extra.pop("session_id")
        else:
            extra["session_id"] = sid
        rc, err = run("git push origin feature", env, extra, home=home)
        ok(rc == 2 and "Floor: REVIEW" in err,
           "%s session_id -> review floor (git push blocks)" % label)
    env, extra = claude("default")
    extra = dict(extra)
    extra.pop("session_id")
    rc, err = run(CANARY, env, extra, home=home)
    ok(rc == 2 and "armed=yes" in err, "canary with no session_id reports armed=yes (fail-closed)")

    # Stale marker (>24h): ignored -> coder floor.
    env, extra = coder("stale-1")
    path = marker(home, "stale-1")
    old = (datetime.datetime.now(datetime.timezone.utc)
           - datetime.timedelta(hours=25)).strftime("%Y-%m-%dT%H:%M:%SZ")
    with open(path, "w") as f:
        f.write(old + "\n")
    rc, _ = run("git push origin feature", env, extra, home=home)
    ok(rc == 0, "stale marker (>24h) is ignored -> coder floor")
    rc, err = run(CANARY, env, extra, home=home)
    ok(rc == 2 and "armed=yes" in err, "canary re-arms a stale session")
    rc, _ = run("git push origin feature", env, extra, home=home)
    ok(rc == 2, "re-armed session gets the review floor again")

    # Unparseable marker: present -> armed.
    env, extra = coder("garbled-1")
    with open(marker(home, "garbled-1"), "w") as f:
        f.write("not a timestamp\n")
    rc, _ = run("git push origin feature", env, extra, home=home)
    ok(rc == 2, "unparseable marker fails closed to armed")

    # Unreadable/unwritable marker directory: armed=failed, and armed.
    bad = tempfile.mkdtemp(prefix="lq-hook-bad-home-")
    os.makedirs(os.path.join(bad, ".lq-maintainer"))
    with open(os.path.join(bad, ".lq-maintainer", "armed"), "w") as f:
        f.write("a file where the directory should be\n")
    env, extra = coder("blocked-dir")
    rc, err = run(CANARY, env, extra, home=bad)
    ok(rc == 2 and "armed=failed" in err and "armed=yes" not in err,
       "unwritable marker dir -> canary prints armed=failed")
    rc, _ = run("git push origin feature", env, extra, home=bad)
    ok(rc == 2, "unreadable marker dir -> review floor (git push blocks)")


def session_log_cases():
    """v0.8.0, from the Claude Code session logs: 117 of 147 hook blocks in
    ordinary coding sessions were quoting false positives (heredocs,
    backticks), 19 were read-only gh commands missing from the allow-list,
    8 were risky words in grep patterns or document text."""
    home = tempfile.mkdtemp(prefix="lq-hook-logs-")
    armed = coder("logs-review")
    run("lq-maintainer-safety-canary", *armed, home=home)
    unarmed = coder("logs-coder")
    floors = (("armed", armed), ("unarmed", unarmed))

    def expect(cmd, want, floor_names=("armed", "unarmed"), label=None):
        for fname, (env, extra) in floors:
            if fname not in floor_names:
                continue
            rc, err = run(cmd, env, extra, home=home)
            if want == "pass":
                ok(rc == 0, "%s passes: %s" % (fname, label or cmd))
            else:
                ok(rc == 2 and "BLOCKED" in err, "%s blocks: %s" % (fname, label or cmd))

    # 1. Heredoc bodies are data unless something executes them.
    expect("cat <<'EOF' > notes.md\nIt's a note about gh pr merge\nEOF", "pass",
           label="cat heredoc whose body mentions gh pr merge (with an apostrophe)")
    expect("git commit -F - <<'EOF'\nDon't merge: gh pr merge stays human-only\nEOF", "pass",
           label="git commit -F - heredoc")
    expect("gh pr create --title t --body-file - <<'EOF'\nWhy it's needed; refs/pull/3/head is not touched\nEOF",
           "pass", ("unarmed",), label="gh pr create heredoc mentioning refs/pull")
    expect("cat <<-EOF > x.md\n\tIt's fine\n\tEOF", "pass", label="<<- heredoc with a tab-indented terminator")
    expect("bash <<'EOF'\ngit push origin main\nEOF", "block", ("armed",), label="bash heredoc running git push")
    expect("bash <<'EOF'\ngit push origin main\nEOF", "pass", ("unarmed",), label="bash heredoc running git push")
    expect("python3 - <<'EOF'\nimport os; os.system(\"gh pr merge 1\")\nEOF", "block",
           label="python3 heredoc running gh pr merge")
    expect("cat <<'EOF' | sh\ngh pr merge 1\nEOF", "block", label="cat heredoc piped into sh")
    expect("cat <<EOF > notes.md\nsee $(gh pr merge 1)\nEOF", "block",
           label="unquoted heredoc whose $(...) runs gh pr merge")
    expect("cat <<EOF > notes.md\nIt's \\`gh pr merge\\` -- no, run: `gh pr merge 2`\nEOF", "block",
           label="unquoted heredoc whose backticks run gh pr merge")
    expect("cat <<EOF > notes.md\nrun `gh pr merge 2` now\nEOF", "block",
           label="unquoted heredoc whose plain backticks run gh pr merge")
    expect("cat <<'EOF' > notes.md\nIt's `gh pr merge` -- never the agent's\nEOF", "pass",
           label="quoted heredoc: backticks are text")
    expect("cat <<'EOF' > notes.md\nno terminator, gh pr merge 1", "block",
           label="heredoc with no terminator is screened whole")

    # 2. Unparseable text: review floor blocks; coder floor scans for the invariants.
    expect("echo it's", "block", ("armed",), label="unbalanced quote")
    expect("echo it's", "pass", ("unarmed",), label="unbalanced quote")
    expect("echo it's && gh pr merge 3", "block", ("unarmed",),
           label="unbalanced quote hiding gh pr merge")
    expect("echo it's ; gh api -X DELETE repos/o/r/git/refs/heads/x", "block", ("unarmed",),
           label="unbalanced quote hiding gh api DELETE")
    expect("echo it's ; gh api graphql -f query='mutation{x}'", "block", ("unarmed",),
           label="unbalanced quote hiding a GraphQL mutation")
    expect("echo it's ; git config alias.p push", "block", ("unarmed",),
           label="unbalanced quote hiding alias definition")

    # 3. GraphQL: coder-floor queries pass, mutations block; review floor blocks all.
    expect("gh api graphql -f query='query{viewer{login}}'", "pass", ("unarmed",))
    expect("gh api graphql -f query='query{viewer{login}}'", "block", ("armed",))
    expect("gh api graphql -f query='mutation{mergePullRequest(input:{}){clientMutationId}}'", "block")
    expect("gh api graphql -F query=@q.graphql", "block", ("unarmed",),
           label="graphql query from a file the hook cannot read")

    # 4. Allow-list additions, both floors.
    expect("gh run download 123 -n logs", "pass")
    expect("gh run watch 123", "pass")
    expect("gh release download v1.0 -p '*.tar.gz'", "pass")

    # 5. A gh/git mention in a pattern or argument string is not a call.
    expect('grep -n "gh pr merge" docs/notes.md', "pass")
    expect('rg "git push" rules/', "pass")
    expect('echo "never run gh pr merge yourself"', "pass")
    expect("python3 -c 'import os; os.system(\"gh pr merge 1\")'", "block",
           label="python -c running gh pr merge still recursed")
    expect("find . -name x -exec sh -c 'gh pr merge 1' \\;", "block",
           label="find -exec sh -c still recursed")
    expect("watch 'gh pr merge 1'", "block", label="watch running gh pr merge")


def main():
    print("block-writes hook tests (%s)" % HOOK)
    for name, (env, extra) in RUNTIMES.items():
        # Every existing case runs on the REVIEW floor: arm first (RT-03).
        # Fixtures without a session_id are armed by fail-closed anyway.
        rc, err = run("lq-maintainer-safety-canary", env, extra)
        ok(rc == 2 and "armed=yes" in err, "%s canary arms the session" % name)
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

    two_floors()
    session_log_cases()

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
