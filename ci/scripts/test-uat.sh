#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "test-uat: python3 missing"; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
"""Tests for the UAT detector and runner (rules/uat.md UA-NN; design v0.7.6).

Deterministic and offline: no Docker, no network, no clone. The runner is
exercised only in --plan mode and through its pure functions, which is
exactly the surface that decides what a real run is ALLOWED to do:

  - check-ui-surface.sh classifies paths against canon:ui-surface
    (UA-01): exclude > indirect > rendered, new-surface on ADDED files
    only, and fails closed (rendered) on an unreadable canon row;
  - uat-run.sh refuses every UA-06 case before anything is fetched,
    rejects unsafe expectations, and its plan carries every UA-07
    containment property;
  - the throwaway .env never carries a credential (UA-07.3).

Run from the repo root: sh ci/scripts/test-uat.sh
"""

import importlib.machinery
import importlib.util
import json
import os
import subprocess
import sys
import tempfile

DETECT = "skills/triage/scripts/check-ui-surface.sh"
RUNNER = "skills/triage/scripts/uat-run.sh"
SHA = "a" * 40
checks = 0
failed = 0


def ok(cond, label):
    global checks, failed
    checks += 1
    print(("  ok   %s" if cond else "  FAIL %s") % label)
    if not cond:
        failed += 1


def detect(lines, *extra):
    p = subprocess.run(["sh", DETECT] + list(extra), input="\n".join(lines) + "\n",
                       capture_output=True, text=True)
    out = dict(l.split(": ", 1) for l in p.stdout.splitlines()
               if l.split(": ", 1)[0] in ("surface", "new-surface", "gate-floor"))
    return p.returncode, out


def runner(tmp, changed, exps=None, *extra):
    exp = os.path.join(tmp, "exp.json")
    json.dump(exps or {"expectations": [{"id": "E1", "route": "/lq-ai/matters"}]},
              open(exp, "w"))
    ch = os.path.join(tmp, "changed.txt")
    open(ch, "w").write("\n".join(changed) + "\n")
    p = subprocess.run(["sh", RUNNER, "--plan", "--pr", "42", "--sha", SHA,
                        "--expectations", exp, "--changed", ch, "--clone", tmp] + list(extra),
                       capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr


def load_runner():
    loader = importlib.machinery.SourceFileLoader("uat_run", RUNNER)
    spec = importlib.util.spec_from_loader("uat_run", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


def main():
    print("UAT detector")
    rc, o = detect(["M\tweb/src/lib/lq-ai/components/MatterRail.svelte"])
    ok(o.get("surface") == "rendered" and o.get("gate-floor") == "required", "component edit -> rendered/required")
    rc, o = detect(["M\tweb/src/lib/i18n/locales/en-US/translation.json"])
    ok(o.get("surface") == "indirect" and o.get("gate-floor") == "recommended", "i18n copy -> indirect/recommended")
    rc, o = detect(["M\tapi/app/schemas/matter.py"])
    ok(o.get("surface") == "indirect", "API schema -> indirect")
    rc, o = detect(["M\tweb/src/lib/lq-ai/__tests__/rail.test.ts", "M\tweb/cypress/e2e/a.cy.ts"])
    ok(o.get("surface") == "none" and o.get("gate-floor") == "n-a", "tests only -> none")
    rc, o = detect(["A\tweb/src/routes/lq-ai/reports/+page.svelte"])
    ok(o.get("new-surface") == "yes" and o.get("gate-floor") == "required", "added page -> new surface, required")
    rc, o = detect(["M\tweb/src/routes/lq-ai/reports/+page.svelte"])
    ok(o.get("new-surface") == "no", "modified page is not a new surface")
    rc, o = detect(["ADDED\tweb/src/lib/lq-ai/components/Badge.svelte"])
    ok(o.get("new-surface") == "yes", "gh changeType ADDED is read as added")
    rc, o = detect(["R100\tweb/src/old.svelte\tdocs/x.md"])
    ok(o.get("surface") == "none", "a rename is classified by its new path")
    rc, o = detect(["M\tREADME.md", "M\tweb/static/favicon.png"])
    ok(o.get("surface") == "rendered", "strongest class wins across paths")
    with tempfile.TemporaryDirectory() as tmp:
        bad = os.path.join(tmp, "cmap.md")
        open(bad, "w").write("| `canon:repo` | x | y | z |\n")
        rc, o = detect(["M\tREADME.md"], "--canon-map", bad)
        ok(rc == 1 and o.get("surface") == "rendered", "missing canon row fails closed (rendered, exit 1)")

    print("UAT runner -- eligibility (UA-06) and expectations (UA-04)")
    with tempfile.TemporaryDirectory() as tmp:
        rc, out = runner(tmp, ["M\tweb/src/lib/lq-ai/components/MatterRail.svelte"])
        ok(rc == 0 and "ELIGIBLE" in out, "web-only change is eligible")
        for label, changed, why in [
            ("dependency manifest", ["M\tweb/src/x.svelte", "M\tweb/package.json"], "UA-06.2"),
            ("lockfile", ["M\tweb/package-lock.json"], "UA-06.2"),
            ("the web Dockerfile", ["M\tweb/Dockerfile"], "UA-06.2"),
            ("backend requirements", ["M\tweb/backend/requirements.txt"], "UA-06.2"),
            ("a path outside web/", ["M\tweb/src/x.svelte", "M\tapi/app/x.py"], "UA-06.1"),
            ("a workflow", ["M\t.github/workflows/ci.yml"], "UA-06.1"),
            ("the compose file", ["M\tdocker-compose.yml"], "UA-06.1"),
            ("a rename out of web/", ["R090\tweb/src/a.ts\tapi/a.ts"], "UA-06.1"),
        ]:
            rc, out = runner(tmp, changed)
            ok(rc == 3 and "REFUSED" in out and why in out, "refuses %s (%s)" % (label, why))
        for label, exps in [
            ("no expectations", {"expectations": []}),
            ("an absolute URL", {"expectations": [{"id": "E1", "route": "https://evil.example/x"}]}),
            ("a protocol-relative route", {"expectations": [{"id": "E1", "route": "//evil.example"}]}),
            ("path traversal", {"expectations": [{"id": "E1", "route": "/../../etc/passwd"}]}),
            ("a shell-ish id", {"expectations": [{"id": "E1;rm", "route": "/x"}]}),
            ("an unknown viewport", {"expectations": [{"id": "E1", "route": "/x", "viewports": ["4k"]}]}),
        ]:
            rc, out = runner(tmp, ["M\tweb/src/x.svelte"], exps)
            ok(rc == 3 and "REFUSED" in out, "refuses %s" % label)
        p = subprocess.run(["sh", RUNNER, "--plan", "--pr", "42", "--sha", "abc",
                            "--expectations", "x", "--changed", "y"], capture_output=True, text=True)
        ok(p.returncode == 2, "a non-40-hex SHA is a usage error")
        p = subprocess.run(["sh", RUNNER, "--out", "--plan", "--pr", "1", "--sha", SHA,
                            "--expectations", "x"], capture_output=True, text=True)
        ok(p.returncode == 2, "a flag is never accepted as another flag's value")

        print("UAT runner -- the plan carries every containment property (UA-07)")
        rc, plan = runner(tmp, ["M\tweb/src/x.svelte"])
        lines = plan.splitlines()
        cmd = [l for l in lines if l.startswith("  ") and not l.startswith("  |")]
        ok(any("networks:" in l for l in lines) and any("internal: true" in l for l in lines),
           "override puts the stack on an internal network")
        ok(any("network: none" in l for l in lines), "contributed build is network=none")
        ok(any("ports: !reset []" in l for l in lines), "published ports are reset")
        ok(any("mcr.microsoft.com/playwright/python:" in l and "@sha256:" in l for l in lines),
           "camera image is digest-pinned")
        docker_git = [l for l in cmd if " docker " in " " + l or " git " in " " + l]
        ok(docker_git and all(l.strip().startswith("env -i") for l in docker_git),
           "every docker/git command runs under env -i")
        ok(not any("docker.sock" in l for l in lines), "the Docker socket is never mounted")
        ok(any("--cap-drop ALL" in l for l in cmd), "camera drops all capabilities")
        ok(any("down -v" in l for l in cmd) and any("image rm" in l for l in cmd)
           and any(l.strip().startswith("rm -rf") for l in cmd), "teardown removes volumes, image, scratch")
        ok(any("refs/pull/42/head" in l and "pr.git" in l for l in cmd),
           "the PR head is fetched into a scratch bare repo, not the clone")
        ok(any("@verify-head" in l for l in cmd) and any("@verify-changed" in l for l in cmd),
           "a real run re-verifies the head SHA and the changed paths")
        trusted_build = [l for l in cmd if " build" in l and "uat-override" not in l]
        ok(trusted_build and "network" not in trusted_build[0],
           "the trusted build runs without the offline override")

    print("UAT runner -- throwaway .env (UA-07.3)")
    mod = load_runner()
    stack = mod.canon_row("rules/canon-map.md", "canon:uat-stack")
    example = ("POSTGRES_PASSWORD=\nJWT_SECRET=\nANTHROPIC_API_KEY=sk-live-should-vanish\n"
               "OPENAI_API_KEY=\nLOG_LEVEL=info\n"
               "PUBLIC_LQ_AI_API_BASE_URL=http://localhost:8000/api/v1\n"
               "# LQ_AI_CORS_ORIGINS=http://localhost:3000\n")
    text = mod.env_text(example, stack)
    env = dict(l.split("=", 1) for l in text.splitlines() if l and not l.startswith("#"))
    ok(len(env.get("POSTGRES_PASSWORD", "")) >= 32, "listed secrets get fresh random values")
    ok(env.get("ANTHROPIC_API_KEY") == "", "a provider key is forced empty, whatever the example says")
    ok(env.get("LOG_LEVEL") == "info", "ordinary settings pass through")
    ok(env.get("PUBLIC_LQ_AI_API_BASE_URL") == "http://api:8000/api/v1"
       and text.count("PUBLIC_LQ_AI_API_BASE_URL=") == 1, "recipe build-arg replaces, never duplicates")
    ok(env.get("LQ_AI_CORS_ORIGINS") == "http://web:8080", "recipe env is set even where the example comments it")
    ok(mod.env_text(example, stack) != text, "secrets differ run to run")

    print("\n%d checks, %d failed" % (checks, failed))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
