#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "uat: REFUSED reason=python3-missing (fail-closed)"; exit 3; } # '''
''''exec python3 "$0" "$@" # '''
HELP = """lq-maintainer-agent -- skills/triage/scripts/uat-run.sh

The UAT runner (rules/uat.md UA-05..UA-07): the ONE channel through which
the agent executes contributed code (rules/injection-posture.md I-05 as
amended, design delta v0.7.6). It brings the target's stack up in a
disposable, egress-free Docker sandbox with the PR's web tree built in,
photographs the screens named in an expectations file, and tears it all
down. It is a GATED ACTION (rules/runtime.md RT-04): the safety hook
passes it only where the host guarantees a human approval prompt, and
hands it over elsewhere. It is never in any skill's allowed-tools.

Usage:
  uat-run.sh --pr N --sha HEAD_SHA --expectations FILE [--out DIR]
  uat-run.sh --plan --pr N --sha HEAD_SHA --expectations FILE --changed FILE

  Run from inside the maintainer's clone of the target repo (the trusted
  recipe is read from its `main`). --plan does no network, no Docker and
  no fetch: it reads a name-status list (--changed), applies every
  eligibility check, and prints the exact command sequence a real run
  would execute. A real run re-derives the changed paths itself from the
  fetched PR head and never trusts a list it was handed.

Expectations file (JSON; rules/uat.md UA-04):
  {"expectations": [{"id": "E1", "route": "/lq-ai/matters",
                     "viewports": ["desktop", "phone"],
                     "schemes": ["light", "dark"]}]}
  ids are [A-Za-z0-9_-]{1,32}; routes are same-origin paths only.

Exit: 0 ran (or --plan: eligible); 3 REFUSED (UA-06 -- the reason is
printed, and the human-run path applies); 4 the run failed after starting
(build, boot, or camera -- the sandbox is still torn down); 2 usage.

Containment (UA-07), every item visible in --plan output:
  1. recipe from `main` at the canon SHA: Dockerfile, compose file,
     .env.example, dependency manifests -- re-copied over the PR tree;
  2. trusted build WITH network first; contributed rebuild with
     network=none, so a layer missing the trusted cache fails closed;
  3. compose project on an internal network (no egress), every published
     port reset, no Docker socket, no host mounts outside the scratch
     dir, all compose commands under `env -i` with a throwaway .env and
     no provider keys;
  4. screenshots from a digest-pinned Playwright image on the internal
     network, running this plugin's uat-shoot.py (read-only mount);
  5. teardown on every exit: `down -v`, the contributed image removed,
     the scratch tree deleted. Trusted images stay cached between runs.
"""

import json
import os
import re
import secrets
import shlex
import shutil
import subprocess
import sys
import tempfile

CAMERA = ("mcr.microsoft.com/playwright/python:v1.63.0-noble"
          "@sha256:72bd171a9ffc2b4b59532aaa6210e21014d07093120dc25528870c0b840da1f0")
ID_RE = re.compile(r"^[A-Za-z0-9_-]{1,32}$")
ROUTE_RE = re.compile(r"^/[A-Za-z0-9/_\-.~%+=&?]*$")
SHA_RE = re.compile(r"^[0-9a-f]{40}$")


class Refused(Exception):
    pass


def plugin_root():
    root = os.environ.get("CLAUDE_PLUGIN_ROOT") or os.environ.get("PLUGIN_ROOT")
    return root or os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                "..", "..", ".."))


def canon_row(path, key):
    for line in open(path, encoding="utf-8"):
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 3 and cells[0] == "`%s`" % key:
            out = {}
            for part in cells[2].split(";"):
                if ":" not in part:
                    continue
                k, v = part.split(":", 1)
                vals = [x.strip().strip("`").strip() for x in v.split(",")]
                out[k.strip()] = [x for x in vals if x]
            return out
    return None


def web_base(cmap):
    text = open(cmap, encoding="utf-8").read()
    m = re.search(r"`canon:repo`.*?web base `(https://[^\s`]+)`", text, re.S)
    if not m:
        raise Refused("canon:repo web base not found in canon-map")
    return m.group(1).rstrip("/")


def one(stack, key):
    vals = stack.get(key) or []
    if len(vals) != 1:
        raise Refused("canon:uat-stack field `%s` missing or ambiguous" % key)
    return vals[0]


def validate_expectations(path):
    try:
        data = json.load(open(path, encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise Refused("expectations file unreadable: %s" % type(exc).__name__)
    exps = data.get("expectations") if isinstance(data, dict) else None
    if not exps:
        raise Refused("no expectations -- UA-04: write down what should be seen first")
    for e in exps:
        if not ID_RE.match(str(e.get("id", ""))):
            raise Refused("expectation id %r is not [A-Za-z0-9_-]{1,32}" % e.get("id"))
        r = e.get("route")
        if not isinstance(r, str) or not ROUTE_RE.match(r) or "//" in r or ".." in r:
            raise Refused("expectation %s route is not a same-origin path" % e["id"])
        for v in e.get("viewports") or []:
            if v not in ("desktop", "phone"):
                raise Refused("expectation %s viewport %r unknown" % (e["id"], v))
        for s in e.get("schemes") or []:
            if s not in ("light", "dark"):
                raise Refused("expectation %s scheme %r unknown" % (e["id"], s))
    return {"expectations": exps}


def parse_changed(text):
    out = []
    for line in text.splitlines():
        parts = line.split("\t")
        if line.strip():
            out.append(parts[-1].strip())
            if len(parts) == 3:  # a rename: the old path changed too
                out.append(parts[1].strip())
    return out


def eligibility(changed, stack):
    """UA-06.1 and UA-06.2 -- mechanical, before anything is fetched or built."""
    ctx = one(stack, "web-context")
    ctx = ctx if ctx.endswith("/") else ctx + "/"
    if not changed:
        raise Refused("the PR changes no files")
    outside = [p for p in changed if not p.startswith(ctx)]
    if outside:
        raise Refused("UA-06.1: changed paths outside the web context `%s`: %s"
                      % (ctx, ", ".join(sorted(outside)[:5])))
    guard = stack.get("containment") or []
    hit = [p for p in changed for g in guard
           if (g.endswith("/") and p.startswith(g)) or p == g]
    if hit:
        raise Refused("UA-06.2: containment-bearing file(s) changed: %s"
                      % ", ".join(sorted(set(hit))))


def env_block(stack, scratch):
    """The clean environment every docker / git command runs under (UA-07.3)."""
    env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"),
           "HOME": os.path.join(scratch, "home"),
           "DOCKER_CONFIG": os.environ.get("DOCKER_CONFIG")
           or os.path.expanduser("~/.docker"),
           "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null",
           "GIT_TERMINAL_PROMPT": "0", "DOCKER_BUILDKIT": "1"}
    for k in ("DOCKER_HOST", "DOCKER_CONTEXT"):
        if os.environ.get(k):
            env[k] = os.environ[k]
    return env


def build_plan(a, stack, cmap, canon_sha, scratch, out):
    """The whole run as data: (label, argv, cwd) triples. --plan prints it;
    a real run executes it. One source, so what is printed is what runs."""
    web = one(stack, "web-service")
    port = one(stack, "web-port")
    ctx = one(stack, "web-context").rstrip("/")
    compose = one(stack, "compose")
    project = "lq-uat-pr%s" % a.pr
    image = "lq-uat-contrib-web:%s" % a.sha[:12]
    trusted, contrib = os.path.join(scratch, "trusted"), os.path.join(scratch, "contrib")
    override = os.path.join(scratch, "uat-override.yml")
    repo_git = web_base(cmap) + ".git"
    bare = os.path.join(scratch, "pr.git")
    clean = ["env", "-i"] + ["%s=%s" % kv for kv in sorted(env_block(stack, scratch).items())]
    dc = clean + ["docker", "compose", "-p", project, "-f", compose]
    dco = dc + ["-f", override]  # contributed phases only: internal net, offline build
    steps = [
        ("recipe: trusted tree from main@%s" % canon_sha[:12],
         clean + ["sh", "-c", "git -C %s archive %s | tar -x -C %s"
                  % (shlex.quote(a.clone), canon_sha, shlex.quote(trusted))], None),
        ("fetch the PR head into a scratch bare repo (never the clone), anonymously",
         clean + ["git", "init", "-q", "--bare", bare], None),
        ("", clean + ["git", "-C", bare, "fetch", "-q", "--no-tags", repo_git,
                      "+refs/pull/%s/head:refs/uat/head" % a.pr], None),
        ("", clean + ["git", "-C", bare, "fetch", "-q", "--no-tags", a.clone,
                      "+%s:refs/uat/canon" % canon_sha], None),
        ("verify the fetched head is the approved SHA (UA-06.3)",
         ["@verify-head", bare, a.sha], None),
        ("re-derive changed paths from the fetched head; re-check UA-06.1/.2",
         ["@verify-changed", bare, a.sha], None),
        ("contributed tree = trusted tree with the PR's `%s/` swapped in" % ctx,
         clean + ["sh", "-c", "cp -R %s %s && rm -rf %s/%s && git -C %s archive %s %s/ | tar -x -C %s"
                  % (shlex.quote(trusted), shlex.quote(contrib), shlex.quote(contrib), ctx,
                     shlex.quote(bare), a.sha, ctx, shlex.quote(contrib))], None),
        ("re-copy every containment file from the trusted tree over the PR tree (UA-07.1)",
         ["@recopy-containment", trusted, contrib], None),
        ("throwaway .env from the trusted .env.example: random secrets, no provider keys",
         ["@write-env", trusted, contrib], None),
        ("compose override: internal network, ports reset, contributed web image, offline build",
         ["@write-override", override, contrib], None),
        ("trusted build (network ON; main's recipe and manifests only -- no contributed code)",
         dc + ["build"], trusted),
        ("contributed build (network=none -- a layer missing the trusted cache fails closed)",
         dco + ["build", web], contrib),
        ("boot the stack and wait for health (internal network, no published ports)",
         dco + ["up", "-d", "--wait", web], contrib),
        ("mint throwaway admin credentials inside the sandbox",
         ["@admin-bootstrap", project, contrib], None),
        ("camera: pinned Playwright image on the internal network",
         clean + ["docker", "run", "--rm", "--network", "%s_default" % project,
                  "--tmpfs", "/tmp", "--cap-drop", "ALL",
                  "-v", "%s:/out" % out,
                  "-v", "%s:/plan/plan.json:ro" % os.path.join(scratch, "plan.json"),
                  "-v", "%s:/shoot.py:ro" % os.path.join(plugin_root(), "skills", "triage",
                                                         "scripts", "uat-shoot.py"),
                  "-e", "UAT_BASE=http://%s:%s" % (web, port), "-e", "UAT_OUT=/out",
                  "-e", "UAT_LOGIN=%s" % (stack.get("login-route") or [""])[0],
                  "--env-file", os.path.join(scratch, "camera.env"),
                  CAMERA, "python", "/shoot.py"], None),
    ]
    teardown = [
        ("teardown: stop and delete the sandbox, its volumes and the contributed image",
         dco + ["down", "-v", "--remove-orphans"], contrib),
        ("", clean + ["docker", "image", "rm", "-f", image], None),
        ("", ["rm", "-rf", scratch], None),
    ]
    return steps, teardown, {"project": project, "image": image, "web": web,
                             "ctx": ctx, "trusted": trusted, "contrib": contrib}


def override_yaml(services, meta, stack):
    lines = ["# generated by uat-run.sh -- rules/uat.md UA-07.3",
             "networks:", "  default:", "    internal: true", "services:"]
    for svc in services:
        lines.append("  %s:" % svc)
        lines.append("    ports: !reset []")
        if svc == meta["web"]:
            lines.append("    image: %s" % meta["image"])
            lines.append("    build:")
            lines.append("      network: none")
            args = stack.get("build-arg") or []
            if args:
                lines.append("      args:")
                for kv in args:
                    k, v = kv.split("=", 1)
                    lines.append("        %s: %s" % (k, json.dumps(v)))
    envs = stack.get("env") or []
    api = (stack.get("api-service") or [None])[0]
    if envs and api in services:
        idx = lines.index("  %s:" % api)
        block = ["    environment:"] + ["      %s: %s" % (kv.split("=", 1)[0],
                                                      json.dumps(kv.split("=", 1)[1]))
                                         for kv in envs]
        lines[idx + 2:idx + 2] = block
    return "\n".join(lines) + "\n"


def env_text(example_text, stack):
    """The throwaway .env (UA-07.3): the trusted .env.example with every
    listed secret set to a fresh random value, every other credential-
    shaped variable forced empty, and the recipe's build-arg / env pairs
    replacing (never duplicating) their example lines."""
    keep = set(stack.get("secrets") or [])
    forced = dict(kv.split("=", 1) for kv in
                  (stack.get("build-arg") or []) + (stack.get("env") or []))
    out, seen = [], set()
    for line in example_text.splitlines():
        m = re.match(r"^\s*#?\s*([A-Z][A-Z0-9_]*)=(.*)$", line)
        if not m or (line.lstrip().startswith("#") and m.group(1) not in forced):
            out.append(line)
            continue
        name = m.group(1)
        if name in forced:
            if name not in seen:
                out.append("%s=%s" % (name, forced[name]))
                seen.add(name)
        elif name in keep:
            out.append("%s=%s" % (name, secrets.token_hex(24)))
        elif re.search(r"(KEY|SECRET|TOKEN|PASSWORD|CREDENTIALS)", name):
            out.append("%s=" % name)  # never a real credential
        else:
            out.append(line)
    out += ["%s=%s" % (k, v) for k, v in forced.items() if k not in seen]
    return "\n".join(out) + "\n"


def write_env(trusted, contrib, stack):
    example = open(os.path.join(trusted, one(stack, "env-example")), encoding="utf-8").read()
    text = env_text(example, stack)
    for root in (trusted, contrib):
        with open(os.path.join(root, ".env"), "w", encoding="utf-8") as fh:
            fh.write(text)


def run(argv, cwd=None):
    p = subprocess.run(argv, cwd=cwd, capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError("%s failed (exit %d): %s" % (argv[0], p.returncode,
                                                       p.stderr.strip()[-400:]))
    return p.stdout


def parse_args(argv):
    class A:
        pass
    a = A()
    a.plan, a.pr, a.sha, a.exp, a.changed, a.out = False, None, None, None, None, None
    a.clone, a.cmap = os.getcwd(), os.path.join(plugin_root(), "rules", "canon-map.md")
    it = iter(argv)
    for tok in it:
        if tok == "--plan":
            a.plan = True
        elif tok in ("--pr", "--sha", "--expectations", "--changed", "--out",
                     "--clone", "--canon-map"):
            val = next(it, None)
            if val is None or val.startswith("--"):
                print("uat: %s needs a value, not %r" % (tok, val), file=sys.stderr)
                raise SystemExit(2)
            setattr(a, {"--expectations": "exp", "--canon-map": "cmap"}.get(tok, tok[2:]), val)
        elif tok in ("-h", "--help"):
            print(HELP)
            raise SystemExit(0)
        else:
            print("uat: unknown argument %r" % tok, file=sys.stderr)
            raise SystemExit(2)
    if not (a.pr and a.pr.isdigit() and a.sha and SHA_RE.match(a.sha) and a.exp):
        print("uat: --pr <number> --sha <40-hex> --expectations <file> are required",
              file=sys.stderr)
        raise SystemExit(2)
    if a.plan and not a.changed:
        print("uat: --plan needs --changed <name-status file>", file=sys.stderr)
        raise SystemExit(2)
    return a


def main(argv):
    a = parse_args(argv)
    try:
        stack = canon_row(a.cmap, "canon:uat-stack")
        if not stack:
            raise Refused("canon:uat-stack row missing -- this target has no UAT recipe")
        plan = validate_expectations(a.exp)
        if a.plan:
            eligibility(parse_changed(open(a.changed, encoding="utf-8").read()), stack)
            canon_sha = "0" * 40
            try:
                canon_sha = run(["git", "-C", a.clone, "rev-parse", "main"]).strip() or canon_sha
            except (RuntimeError, OSError):
                pass
            scratch = os.path.join(tempfile.gettempdir(), "lq-uat-PLAN")
            out = a.out or os.path.join("<data>", "uat", "pr-%s" % a.pr, a.sha[:12])
            steps, teardown, meta = build_plan(a, stack, a.cmap, canon_sha, scratch, out)
            print("uat: ELIGIBLE pr=%s sha=%s (plan only -- nothing was fetched or run)"
                  % (a.pr, a.sha))
            print("override: ports reset on every service; networks.default.internal: true; "
                  "%s build.network: none; image %s" % (meta["web"], meta["image"]))
            clean = ["env", "-i"] + ["%s=%s" % kv for kv in
                                     sorted(env_block(stack, scratch).items())]
            print("clean-env: " + " ".join(shlex.quote(x) for x in clean[2:]))
            print("camera: " + CAMERA)
            for label, argv_, cwd in steps + teardown:
                if label:
                    print("# " + label)
                shown = argv_
                if argv_[:len(clean)] == clean:
                    shown = ["env", "-i", "<clean-env>"] + argv_[len(clean):]
                print("  " + " ".join(shlex.quote(x) for x in shown)
                      + ("    (in %s)" % cwd if cwd else ""))
            print("override:")
            for line in override_yaml([meta["web"], "api", "postgres"], meta, stack).splitlines():
                print("  | " + line)
            return 0
    except Refused as exc:
        print("uat: REFUSED %s" % exc)
        print("uat: the human-run path applies (rules/uat.md UA-05; canon:sandbox-discipline)")
        return 3
    return real_run(a, stack, plan)


def real_run(a, stack, plan):
    for tool in ("docker", "git", "tar"):
        if not shutil.which(tool):
            print("uat: REFUSED %s not found on PATH" % tool)
            return 3
    canon_sha = run(["git", "-C", a.clone, "rev-parse", "main"]).strip()
    data = os.environ.get("CLAUDE_PLUGIN_DATA") or os.environ.get("PLUGIN_DATA")
    out = os.path.abspath(a.out or os.path.join(data or ".", "uat", "pr-%s" % a.pr, a.sha[:12]))
    os.makedirs(out, exist_ok=True)
    scratch = tempfile.mkdtemp(prefix="lq-uat-")
    for d in ("trusted", "home"):
        os.makedirs(os.path.join(scratch, d))
    json.dump(plan, open(os.path.join(scratch, "plan.json"), "w"))
    steps, teardown, meta = build_plan(a, stack, a.cmap, canon_sha, scratch, out)
    admin_pw = secrets.token_urlsafe(18)
    email = (stack.get("admin-email") or ["admin@example.invalid"])[0]
    with open(os.path.join(scratch, "camera.env"), "w") as fh:
        fh.write("UAT_EMAIL=%s\nUAT_PASSWORD=%s\n" % (email, admin_pw))
    status = 0
    try:
        for label, argv_, cwd in steps:
            if label:
                print("uat: " + label, flush=True)
            op = argv_[0]
            if op == "@verify-head":
                got = run(["git", "-C", argv_[1], "rev-parse", "refs/uat/head"]).strip()
                if got != argv_[2]:
                    raise Refused("UA-06.3: PR head is %s, the approved SHA is %s" % (got, argv_[2]))
            elif op == "@verify-changed":
                base = run(["git", "-C", argv_[1], "merge-base", "refs/uat/canon", argv_[2]]).strip()
                changed = parse_changed(run(["git", "-C", argv_[1], "diff", "--name-status",
                                             base, argv_[2]]))
                eligibility(changed, stack)
            elif op == "@recopy-containment":
                for g in stack.get("containment") or []:
                    src, dst = os.path.join(argv_[1], g), os.path.join(argv_[2], g)
                    if os.path.isfile(src):
                        shutil.copyfile(src, dst)
            elif op == "@write-env":
                write_env(argv_[1], argv_[2], stack)
            elif op == "@write-override":
                clean = ["env", "-i"] + ["%s=%s" % kv for kv in
                                         sorted(env_block(stack, scratch).items())]
                services = run(clean + ["docker", "compose", "-f", one(stack, "compose"),
                                        "config", "--services"], cwd=meta["trusted"]).split()
                with open(argv_[1], "w") as fh:
                    fh.write(override_yaml(services, meta, stack))
            elif op == "@admin-bootstrap":
                cmd = (stack.get("admin-bootstrap") or [""])[0]
                api = (stack.get("api-service") or [""])[0]
                if cmd and api:
                    cmd = cmd.replace("EMAIL", email).replace("PASSWORD", admin_pw)
                    env = ["env", "-i"] + ["%s=%s" % kv for kv in
                                          sorted(env_block(stack, scratch).items())]
                    run(env + ["docker", "compose", "-p", argv_[1], "exec", "-T", api]
                        + shlex.split(cmd), cwd=argv_[2])
            else:
                run(argv_, cwd=cwd)
        manifest = json.load(open(os.path.join(out, "manifest.json")))
        shots = manifest.get("shots", [])
        print("uat: DONE pr=%s sha=%s out=%s captured=%d not-reached=%d signed_in=%s"
              % (a.pr, a.sha, out, sum(s.get("status") == "captured" for s in shots),
                 sum(s.get("status") != "captured" for s in shots), manifest.get("signed_in")))
    except Refused as exc:
        print("uat: REFUSED %s" % exc)
        status = 3
    except Exception as exc:  # noqa: BLE001 -- reported; teardown still runs
        print("uat: FAILED %s" % exc)
        status = 4
    finally:
        for label, argv_, cwd in teardown:
            if label:
                print("uat: " + label, flush=True)
            subprocess.run(argv_, cwd=cwd if cwd and os.path.isdir(cwd) else None,
                           capture_output=True)
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
