#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "test-docs-surface: python3 missing"; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
"""Tests for skills/triage/scripts/check-docs-surface.sh (rules/docs-surface.md
DS-01/DS-02; design v0.8 §5).

Deterministic and offline: no network, no lq-ai clone. The manifests come
from ci/fixtures/docs-surface/ — read through --routes-dir, and once
through a throwaway git repository so the `git show <sha>:<path>` road is
exercised too. Properties under test:

  - classes: page-changed > source-listed > reference-source > none, with
    `covered` and `manifest` informational, `excluded` first;
  - a listed source whose page ALSO changed is `covered`, not source-listed;
  - a rename classifies both its paths; status words are accepted;
  - fail-closed: a bad manifest, a missing row, a missing routes dir, and
    no manifest source all print `surface: unknown` and exit 1;
  - the subset parser skips folded scalars, nested maps and comments.

Run from the repo root: sh ci/scripts/test-docs-surface.sh
"""

import os
import shutil
import subprocess
import sys
import tempfile

SCRIPT = "skills/triage/scripts/check-docs-surface.sh"
FIX = "ci/fixtures/docs-surface"
CMAP = os.path.join(FIX, "canon-map-test.md")
checks = 0
failed = 0


def ok(cond, label):
    global checks, failed
    checks += 1
    print(("  ok   %s" if cond else "  FAIL %s") % label)
    if not cond:
        failed += 1


def run(lines, *extra, canon_map=CMAP, routes_dir=os.path.join(FIX, "routes")):
    args = ["sh", SCRIPT, "--canon-map", canon_map]
    if routes_dir:
        args += ["--routes-dir", routes_dir]
    args += list(extra)
    p = subprocess.run(args, input="\n".join(lines) + "\n", capture_output=True, text=True)
    out = {}
    paths, routes = {}, []
    for l in p.stdout.splitlines():
        k, _, v = l.partition(": ")
        if k == "path":
            cls, _, rest = v.partition(" ")
            paths[rest.split(" ")[0]] = (cls, rest)
        elif k == "route":
            routes.append(v)
        else:
            out[k] = v
    return p.returncode, out, paths, routes


def main():
    print("check-docs-surface.sh")
    rc, out, paths, routes = run(["M\tapi/app/api/auth.py"])
    ok(rc == 0 and out["surface"] == "source-listed", "listed source, page untouched -> source-listed")
    ok(paths["api/app/api/auth.py"][0] == "source-listed" and "route=start/is-it-for-you" in paths["api/app/api/auth.py"][1],
       "path line names the route")
    ok(routes == ["start/is-it-for-you source-listed api/app/api/auth.py"], "route line: source-listed with the listed path")
    ok(out["routes"] == "start/is-it-for-you" and out["pages-changed"] == "0", "routes list and zero pages changed")

    rc, out, paths, routes = run(["M\tdocs/start/is-it-for-you.md", "M\tapi/app/api/auth.py"])
    ok(out["surface"] == "page-changed" and out["pages-changed"] == "1", "page source in diff -> page-changed")
    ok(paths["api/app/api/auth.py"][0] == "covered", "listed source whose page also changed -> covered")
    ok(routes == ["start/is-it-for-you page-changed docs/start/is-it-for-you.md"], "only the page-changed route line")

    rc, out, paths, routes = run(["M\tdocker-compose.yml"])
    ok(out["surface"] == "source-listed", "compose: listed under two pages -> source-listed wins over reference")
    ok(paths["docker-compose.yml"][0] == "source-listed" and "reference" in paths["docker-compose.yml"][1],
       "compose also tagged reference")
    ok(out["routes"] == "operate/install,start/what-it-touches", "both routes named, sorted")

    rc, out, paths, routes = run(["M\tapi/app/config.py"])
    ok(out["surface"] == "reference-source" and paths["api/app/config.py"][0] == "reference-source",
       "generated-reference input alone -> reference-source")
    ok(out["routes"] == "-", "no route named for a pure reference hit")

    rc, out, paths, routes = run(["M\tapi/app/pipeline/parsers.py", "A\tapi/tests/test_parsers.py"])
    ok(out["surface"] == "none" and paths["api/app/pipeline/parsers.py"][0] == "none", "unlisted code -> none")
    ok(paths["api/tests/test_parsers.py"][0] == "none", "a test file under no exclude-name is just none")

    rc, out, paths, routes = run(["M\tweb/src/__tests__/x.test.ts", "M\tsite/astro.config.mjs", "M\tuv.lock"])
    ok(all(paths[p][0] == "excluded" for p in paths) and out["surface"] == "none", "exclude and exclude-names come first")

    rc, out, paths, routes = run(["M\tdocs/site/routes/start.yaml"])
    ok(paths["docs/site/routes/start.yaml"][0] == "manifest" and out["surface"] == "none", "a manifest edit is informational")

    rc, out, paths, routes = run(["R100\tdocs/start/what-it-touches.md\tdocs/start/installed.md"])
    ok(paths["docs/start/what-it-touches.md"][0] == "page-changed" and paths["docs/start/installed.md"][0] == "none",
       "a rename classifies both paths; the old one is the page source")

    rc, out, paths, routes = run(["MODIFIED\tdocs/deployment-cookbook.md", "README.md"])
    ok(paths["docs/deployment-cookbook.md"][0] == "page-changed" and paths["README.md"][0] == "source-listed",
       "status words and bare paths are accepted")

    rc, out, paths, routes = run(["M\tdocs/site/reference/configuration.intro.md"])
    ok(out["surface"] == "page-changed", "an intro file is a route source like any other")

    # fail-closed
    rc, out, _, _ = run(["M\tREADME.md"], routes_dir=os.path.join(FIX, "bad"))
    ok(rc == 1 and out["surface"] == "unknown" and "sources" in out.get("error", ""),
       "a mapping inside sources: -> unknown, exit 1")
    rc, out, _, _ = run(["M\tREADME.md"], routes_dir=os.path.join(FIX, "nowhere"))
    ok(rc == 1 and out["surface"] == "unknown", "missing routes directory -> unknown")
    rc, out, _, _ = run(["M\tREADME.md"], routes_dir=None)
    ok(rc == 1 and out["surface"] == "unknown" and "no manifest source" in out.get("error", ""),
       "no --clone/--routes-dir -> unknown")
    rc, out, _, _ = run(["M\tREADME.md"], canon_map="rules/uat.md")
    ok(rc == 1 and out["surface"] == "unknown" and "row" in out.get("error", ""), "missing canon row -> unknown")

    # the git road: manifests read with `git show <sha>:<path>`, never from the worktree
    tmp = tempfile.mkdtemp()
    try:
        repo = os.path.join(tmp, "clone")
        shutil.copytree(os.path.join(FIX, "routes"), os.path.join(repo, "docs", "site", "routes"))
        env = dict(os.environ, GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@x", GIT_COMMITTER_NAME="t",
                   GIT_COMMITTER_EMAIL="t@x")
        for cmd in (["git", "init", "-q"], ["git", "add", "."], ["git", "commit", "-q", "-m", "m"]):
            subprocess.run(cmd, cwd=repo, check=True, env=env, capture_output=True)
        sha = subprocess.run(["git", "rev-parse", "HEAD"], cwd=repo, capture_output=True, text=True).stdout.strip()
        # a worktree edit must not be seen: the canon is the commit
        open(os.path.join(repo, "docs", "site", "routes", "start.yaml"), "a").write(
            "- route: late\n  source: late.md\n")
        rc, out, paths, _ = run(["M\tlate.md", "M\tapi/app/api/auth.py"], "--clone", repo, "--canon-sha", sha,
                                routes_dir=None)
        ok(rc == 0 and out["surface"] == "source-listed" and paths["late.md"][0] == "none",
           "git road reads the committed manifests, not the worktree")
        rc, out, _, _ = run(["M\tREADME.md"], "--clone", repo, "--canon-sha", "0" * 40, routes_dir=None)
        ok(rc == 1 and out["surface"] == "unknown", "unknown SHA -> unknown")
        rc, out, _, _ = run(["M\tREADME.md"], "--clone", repo, "--canon-sha", "not-a-sha", routes_dir=None)
        ok(rc == 1 and out["surface"] == "unknown", "non-hex SHA -> unknown")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    h = subprocess.run(["sh", SCRIPT, "--help"], capture_output=True, text=True)
    ok(h.returncode == 0 and "check-docs-surface.sh" in h.stdout, "--help works")

    print("%d checks, %d failed" % (checks, failed))
    if failed:
        print("docs-surface tests FAILED")
        return 1
    print("all docs-surface tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
