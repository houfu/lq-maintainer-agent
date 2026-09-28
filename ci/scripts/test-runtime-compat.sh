#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "test-runtime-compat: python3 missing"; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
"""Two-host packaging lint (rules/runtime.md RT-NN; design delta v0.7.5).

The agent ships to Claude Code and Codex from one tree. Each guarantee
has one switch per host, and the failure this lint exists to catch is a
switch set on one host and forgotten on the other -- a skill that is
explicit-only under Claude Code and auto-invocable under Codex looks
fine in every Claude Code test. Checks:

  - every skill carries BOTH explicit-invocation switches (RT-05);
  - every skill runs the canary at Step 0 and grants it (RT-03);
  - no skill's allowed-tools grants a GitHub write (design 3.3);
  - every Codex custom agent is sandboxed read-only (RT-06);
  - both plugin manifests name the same plugin at the same version, and
    both marketplaces list it;
  - the hook registration is the same script in every copy;
  - the Codex command rules decide as documented -- only when a `codex`
    binary is on PATH (CI runners have none; maintainers do).

Run from the repo root: sh ci/scripts/test-runtime-compat.sh
"""

import glob
import json
import os
import re
import shutil
import subprocess
import sys

try:
    import tomllib
except ImportError:  # python < 3.11
    tomllib = None

checks = 0
failed = 0

WRITE_GRANTS = re.compile(
    r"Bash\((gh (pr|issue) (comment|merge|review|close|edit)|gh api|"
    r"gh label (create|edit|delete)|gh release (create|edit)|git push)")


def ok(cond, label):
    global checks, failed
    checks += 1
    if cond:
        print("  ok   %s" % label)
    else:
        failed += 1
        print("  FAIL %s" % label)


def frontmatter(path):
    text = open(path, encoding="utf-8").read()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    return (m.group(1) if m else ""), text


def main():
    print("runtime compat lint")
    skills = sorted(glob.glob("skills/*/SKILL.md"))
    ok(len(skills) >= 7, "found %d skills" % len(skills))
    for path in skills:
        name = path.split("/")[1]
        fm, text = frontmatter(path)
        ok(re.search(r"^disable-model-invocation:\s*true\s*$", fm, re.M),
           "%s: disable-model-invocation: true (Claude Code)" % name)
        sidecar = os.path.join("skills", name, "agents", "openai.yaml")
        side = open(sidecar, encoding="utf-8").read() if os.path.exists(sidecar) else ""
        ok(re.search(r"^policy:\s*\n\s+allow_implicit_invocation:\s*false\s*$", side, re.M),
           "%s: agents/openai.yaml allow_implicit_invocation: false (Codex)" % name)
        tools = re.search(r"^allowed-tools:(.*)$", fm, re.M)
        tools = tools.group(1) if tools else ""
        ok("Bash(lq-maintainer-safety-canary)" in tools,
           "%s: allowed-tools grants the canary" % name)
        ok(not WRITE_GRANTS.search(tools),
           "%s: allowed-tools grants no GitHub write" % name)
        step0 = re.search(r"^## Step 0 [^\n]*\n(.*?)^## ", text, re.S | re.M)
        ok(step0 and "lq-maintainer-safety-canary" in step0.group(1)
           and "rules/runtime.md" in step0.group(1),
           "%s: Step 0 runs the canary and binds rules/runtime.md" % name)

    for path in sorted(glob.glob("agents/codex/*.toml")):
        raw = open(path, "rb").read()
        if tomllib:
            data = tomllib.loads(raw.decode("utf-8"))
            mode, has_name = data.get("sandbox_mode"), bool(data.get("name"))
        else:
            m = re.search(rb'^sandbox_mode\s*=\s*"([^"]+)"', raw, re.M)
            mode, has_name = (m.group(1).decode() if m else None), b"name =" in raw
        ok(mode == "read-only" and has_name, "%s: named, sandbox_mode read-only" % path)

    claude = json.load(open(".claude-plugin/plugin.json"))
    codex = json.load(open(".codex-plugin/plugin.json"))
    ok(claude["name"] == codex["name"], "manifests agree on the plugin name")
    ok(claude["version"] == codex["version"],
       "manifests agree on the version (%s / %s)" % (claude["version"], codex["version"]))
    ok(codex.get("hooks") == "./hooks/hooks.json", "Codex manifest points at hooks/hooks.json")
    for mk in (".claude-plugin/marketplace.json", ".agents/plugins/marketplace.json"):
        names = [p["name"] for p in json.load(open(mk))["plugins"]]
        ok(claude["name"] in names, "%s lists %s" % (mk, claude["name"]))

    hooks = json.load(open("hooks/hooks.json"))["hooks"]["PreToolUse"]
    settings = json.load(open("settings/claude-settings.json"))["hooks"]["PreToolUse"]
    for label, block in (("hooks/hooks.json", hooks), ("settings/claude-settings.json", settings)):
        cmds = [h["command"] for g in block if g.get("matcher") == "Bash" for h in g["hooks"]]
        ok(any("block-writes.sh" in c for c in cmds), "%s registers block-writes.sh on Bash" % label)

    rules = os.path.abspath("settings/codex/lq-maintainer.rules")
    ok(os.path.exists(rules), "Codex command rules present")
    if shutil.which("codex"):
        expect = [
            (["git", "push", "origin", "main"], "forbidden"),
            (["gh", "pr", "merge", "3"], "forbidden"),
            (["gh", "pr", "checkout", "3"], "forbidden"),
            (["gh", "issue", "edit", "3"], "forbidden"),
            (["gh", "repo", "clone", "o/r"], "forbidden"),
            (["gh", "pr", "comment", "3"], "prompt"),
            (["gh", "api", "repos/o/r/issues/3/comments"], "prompt"),
            (["gh", "pr", "view", "3"], None),
            (["git", "log"], None),
        ]
        for argv, want in expect:
            p = subprocess.run(["codex", "execpolicy", "check", "--rules", rules] + argv,
                               capture_output=True, text=True)
            try:
                got = json.loads(p.stdout).get("decision")
            except ValueError:
                got = "error: " + p.stderr.strip()[:80]
            ok(got == want, "execpolicy: %s -> %s" % (" ".join(argv), want))
    else:
        print("  skip execpolicy decisions (no codex binary on PATH)")

    print("\n%d checks, %d failed" % (checks, failed))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
