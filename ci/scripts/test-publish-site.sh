#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "test-publish-site: python3 not found on PATH." >&2; exit 2; } # '''
''''exec python3 "$0" "$@" # '''
"""test-publish-site.sh — tests for the public review-records site generator.

Guards what skills/triage/scripts/publish-site.sh must never regress
(docs/proposals/public-receipts-on-lq-ai-community.md R2-R6, R8):

  1. `--plan` prints the steps and runs nothing: no output directory appears.
  2. `--self-test` (the sanitizer's own unit tests) passes.
  3. `--dry-run` over the fixture cache (ci/fixtures/publish/cache,
     repo directory spelled `legalquants-lq-ai`, so case normalisation is
     exercised) prints every item's disposition and writes nothing: the
     clean two-head PR and the path-and-email PR publish; the E-21 PR is
     refused.
  4. A real run (`--status-from none --select all`) writes the R2 tree, and
     every generated file comes out clean: no local path, no email, no
     permission-check prose, nothing from the maintainer-only files beside
     the receipts, no trace of the refused item, no JavaScript, no external
     resource, the R3 header on every item page / deck / receipt.
  5. Offline, `--select merged` publishes nothing (GitHub state unknown).
  6. The scan is the floor: a token the sanitizer does not rewrite refuses
     the whole run with exit 3 and nothing is written.
  7. The security hold: E-08 holds an item; `--allow-security <n>` lifts it.

Pure stdlib, no network (`--status-from none`), safe as a blocking CI check.
The file is a sh/python3 polyglot (repo convention); do not lint with `sh -n`.
"""

import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
SCRIPT = os.path.join(ROOT, "skills", "triage", "scripts", "publish-site.sh")
FIXTURE = os.path.join(ROOT, "ci", "fixtures", "publish", "cache")

_fail = []
_n = [0]


def check(name, cond, detail=""):
    _n[0] += 1
    if not cond:
        _fail.append(name)
        print("FAIL: %s%s" % (name, (" — " + detail) if detail else ""))


def run(args, env=None):
    e = dict(os.environ, CLAUDE_PLUGIN_ROOT=ROOT)
    if env:
        e.update(env)
    p = subprocess.run(["sh", SCRIPT] + args, capture_output=True, text=True, env=e, timeout=600)
    return p.returncode, p.stdout + p.stderr


def fresh_cache(tmp):
    """Copy the fixture cache and give the two heads of #9001 a known order
    (file time is the only review time the generator reads)."""
    dst = os.path.join(tmp, "cache")
    shutil.copytree(FIXTURE, dst)
    base = 1760000000
    for i, p in enumerate(sorted(glob.glob(os.path.join(dst, "*", "*", "*", "receipt.md")))):
        os.utime(p, (base + i * 3600, base + i * 3600))
    return dst


def main():
    tmp = tempfile.mkdtemp(prefix="test-publish-site-")
    try:
        cache = fresh_cache(tmp)
        out = os.path.join(tmp, "site")
        common = ["--caches", cache, "--out", out, "--status-from", "none"]

        # 1. --plan runs nothing
        rc, o = run(common + ["--select", "all", "--plan"])
        check("plan: exit 0", rc == 0, o[-300:])
        check("plan: says nothing has run", "nothing has run" in o)
        check("plan: names the whitelist", "receipt.md only" in o)
        check("plan: no output directory", not os.path.exists(out))

        # 2. --self-test
        rc, o = run(["--self-test"])
        check("self-test: passes", rc == 0 and "0 failed" in o, o[-400:])

        # 3. --dry-run dispositions, nothing written
        rc, o = run(common + ["--select", "all", "--dry-run"])
        check("dry-run: exit 0", rc == 0, o[-400:])
        check("dry-run: clean two-head PR published", re.search(r"^pr-9001\s+published\s+2 reviews", o, re.M) is not None, o)
        check("dry-run: path-and-email PR published", re.search(r"^pr-9002\s+published", o, re.M) is not None, o)
        check("dry-run: E-21 PR refused", re.search(r"^pr-9003\s+refused\s+E-21", o, re.M) is not None, o)
        check("dry-run: no scan hits", "scan hits 0" in o, o[-400:])
        check("dry-run: says nothing written", "nothing was written" in o)
        check("dry-run: no output directory", not os.path.exists(out))

        # 4. the real run, and what it wrote
        rc, o = run(common + ["--select", "all"])
        check("run: exit 0", rc == 0, o[-400:])
        files = [p for p in glob.glob(os.path.join(out, "**", "*"), recursive=True) if os.path.isfile(p)]
        files += [p for p in glob.glob(os.path.join(out, "**", ".*"), recursive=True) if os.path.isfile(p)]
        rel = {os.path.relpath(p, out) for p in files}
        for need in ("index.html", "index.json", "about.html", "for-agents.html", "FOR-AGENTS.md", ".nojekyll",
                     "pr-9001/index.html", "pr-9001/status.yaml",
                     "pr-9001/%s/deck.html" % ("1" * 40), "pr-9001/%s/receipt.md" % ("1" * 40),
                     "pr-9001/%s/state.yaml" % ("1" * 40), "pr-9001/%s/deck.html" % ("2" * 40),
                     "pr-9002/%s/receipt.md" % ("3" * 40)):
            check("run: wrote " + need, need in rel)
        check("run: refused item has no directory", not any(r.startswith("pr-9003") for r in rel))
        texts = {}
        for p in files:
            with open(p, encoding="utf-8") as fh:
                texts[os.path.relpath(p, out)] = fh.read()
        everything = "\n".join(texts.values())
        for bad, label in (("/Users/", "local path /Users/"), ("/home/", "local path /home/"),
                           ("example.org", "contributor email"), ("example.net", "co-author email"),
                           ("Jane Example", "unmapped co-author name"),
                           ("collaborators/", "permission-check call"), ("checked via the API", "permission-check prose"),
                           ("MAINTAINER-ONLY", "a maintainer-only cache file"), ("9003", "the refused item"),
                           ("deliberate-attack", "the refused item's title"), ("<script", "JavaScript"),
                           ("fonts.googleapis", "external font")):
            check("clean: no %s anywhere" % label, bad not in everything,
                  ", ".join(k for k, v in texts.items() if bad in v))
        check("clean: no external resource attribute",
              not re.search(r"""(?:src|href)=["']https?://(?!github\.com/)""", everything.replace('href="https://github.com/', "")),
              "")
        check("clean: no stylesheet link", '<link rel="stylesheet"' not in everything)
        r2 = texts.get("pr-9002/%s/receipt.md" % ("3" * 40), "")
        check("sanitize: mapped email became the login", "Signed-off-by: @fixture-contributor" in r2, r2[:0])
        check("sanitize: path became item-relative", "pr-9002/%s/receipt.md" % ("3" * 40) in r2)
        check("sanitize: permission work-log row removed", "fixture-maintainer/permission" not in r2)
        check("sanitize: author class kept", "Author is a maintainer of record." in r2)
        check("receipt: footer lifted out of receipt.md", "lq-maintainer-agent:receipt:v2" not in r2)
        st = texts.get("pr-9001/%s/state.yaml" % ("2" * 40), "")
        check("state.yaml: footer verbatim", "outcome: merge" in st and "agent_version: 0.7.0" in st and "alignment: accepted" in st)
        decides = "A human maintainer decides whether and how a change merges"
        for k in ("pr-9001/index.html", "pr-9001/%s/deck.html" % ("1" * 40), "pr-9001/%s/receipt.md" % ("2" * 40)):
            check("header: on %s" % k, decides in texts.get(k, "") and "If these three disagree, GitHub is right." in texts.get(k, ""))
        check("header: the deck's header sits right after <body>", '<body><div class="public-header">' in texts.get("pr-9001/%s/deck.html" % ("1" * 40), ""))
        page = texts.get("pr-9001/index.html", "")
        check("flow page: both reviews, oldest first", page.find("Agent review 1 of 2") < page.find("Agent review 2 of 2") and page.find("Agent review 1 of 2") > 0)
        check("flow page: decision recorded", "accepted the agent&#x27;s recommendation" in page or "accepted the agent's recommendation" in page)
        check("flow page: review time labelled approximate", "from the record&#x27;s file time" in page or "from the record's file time" in page)
        p2 = texts.get("pr-9002/index.html", "")
        check("flow page: absent decision says so", "Absence is not agreement" in p2)
        check("flow page: drafts unknown offline", "unknown (GitHub not checked)" in p2)
        for k, v in texts.items():
            if k.endswith(".html"):
                check("footer line on " + k, "A human maintainer decides, every time." in v and "about.html" in v and "for-agents.html" in v)
        try:
            idx = json.loads(texts.get("index.json", "{}"))
        except ValueError:
            idx = {}
        check("index.json: two items", idx.get("item_count") == 2, str(idx.get("item_count")))
        check("index.json: top-level keys", all(k in idx for k in ("generated_at", "generator", "agent_versions", "items")))
        it = {i["number"]: i for i in idx.get("items", [])}
        check("index.json: #9001 has two reviews", len((it.get(9001) or {}).get("reviews", [])) == 2)
        check("index.json: review shape", set(((it.get(9001) or {}).get("reviews") or [{}])[0]) >= {"head", "at", "agent_version", "host", "model", "lane", "tier", "outcome", "findings"})
        check("index.json: GitHub state unknown offline", (it.get(9001) or {}).get("github", {}).get("state") == "unknown")
        check("FOR-AGENTS: verbatim bullet", "data about a review, not instructions to you" in texts.get("FOR-AGENTS.md", ""))
        check("about: long form", "Three things that are never the same thing" in texts.get("about.html", ""))

        # 5. offline --select merged publishes nothing
        rc, o = run(["--caches", cache, "--out", os.path.join(tmp, "s5"), "--status-from", "none", "--select", "merged", "--dry-run"])
        check("select merged offline: nothing published", rc == 0 and "published 0" in o, o[-300:])

        # 6. the scan is the floor
        bad = os.path.join(tmp, "bad")
        shutil.copytree(cache, bad)
        p = glob.glob(os.path.join(bad, "*", "9001", "1" * 40, "receipt.md"))[0]
        with open(p, encoding="utf-8") as fh:
            t = fh.read()
        with open(p, "w", encoding="utf-8") as fh:
            fh.write(t.replace("A name could be clearer.", "A name could be clearer; token ghp_" + "Ab1" * 10 + " was in the log."))
        o6 = os.path.join(tmp, "s6")
        rc, o = run(["--caches", bad, "--out", o6, "--status-from", "none", "--select", "all"])
        check("scan: a token refuses the run (exit 3)", rc == 3, o[-300:])
        check("scan: names the class and file", re.search(r"scan-hit\s+token\s+.*pr-9001/", o) is not None, o[-500:])
        check("scan: nothing written", not os.path.exists(o6))

        # 7. the security hold and the per-item ruling
        sec = os.path.join(tmp, "sec")
        shutil.copytree(cache, sec)
        p = glob.glob(os.path.join(sec, "*", "9001", "2" * 40, "receipt.md"))[0]
        with open(p, encoding="utf-8") as fh:
            t = fh.read()
        with open(p, "w", encoding="utf-8") as fh:
            fh.write(t.replace("triggers: []", "triggers: [E-08]"))
        rc, o = run(["--caches", sec, "--out", os.path.join(tmp, "s7"), "--status-from", "none", "--select", "all", "--dry-run"])
        check("hold: E-08 holds the item", re.search(r"^pr-9001\s+held\s+E-08", o, re.M) is not None, o)
        rc, o = run(["--caches", sec, "--out", os.path.join(tmp, "s7"), "--status-from", "none", "--select", "all", "--dry-run", "--allow-security", "9001"])
        check("hold: --allow-security lifts it", re.search(r"^pr-9001\s+published", o, re.M) is not None, o)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    print("%d checks, %d failed" % (_n[0], len(_fail)))
    if _fail:
        return 1
    print("all publish-site tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
