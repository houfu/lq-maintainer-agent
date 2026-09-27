#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "test-rules-index: python3 missing"; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
"""Tests for skills/triage/scripts/rules-index.sh (rules/loading.md LD-NN).

The property under test is LD-04/LD-05: the script never invents text.
Every byte a `section` prints must appear in the source file, and every
`spine` line must name a rule the file actually defines. Run from the
repo root: sh ci/scripts/test-rules-index.sh
"""

import glob
import os
import re
import subprocess
import sys

SCRIPT = "skills/triage/scripts/rules-index.sh"
RULE = re.compile(r"^- \*\*([A-Z]{1,3}-\d{2}[a-z]?)\b", re.M)
checks = 0
failed = 0


def run(*args):
    return subprocess.run(
        ["sh", SCRIPT] + list(args), capture_output=True, text=True
    )


def ok(cond, label):
    global checks, failed
    checks += 1
    if cond:
        print("  ok   %s" % label)
    else:
        failed += 1
        print("  FAIL %s" % label)


def main():
    files = sorted(glob.glob("rules/*.md"))
    ok(bool(files), "found rules/*.md")

    for path in files:
        src = open(path, encoding="utf-8").read()
        ids = RULE.findall(src)
        sp = run("spine", path)

        if not ids:
            # LD-06: a file with no rule IDs must fail closed, not print an empty index
            ok(sp.returncode == 1, "%s: no-IDs file fails closed" % path)
            ok("read it whole" in sp.stdout, "%s: says read it whole" % path)
            continue

        ok(sp.returncode == 0, "%s: spine exits 0" % path)
        # LD-04: every ID the file defines appears in the spine, and no others
        listed = set(re.findall(r"^\s{4}([A-Z]{1,3}-\d{2}[a-z]?)\s", sp.stdout, re.M))
        ok(listed == set(ids), "%s: spine lists exactly its %d IDs" % (path, len(ids)))
        # the spine must be materially smaller, or it is not worth a second read
        ok(
            len(sp.stdout) < len(src) / 2,
            "%s: spine is <50%% of the file (%d%%)"
            % (path, 100 * len(sp.stdout) // max(1, len(src))),
        )

        # LD-05: a fetched section is verbatim — every line of it is in the source
        sec = run("section", path, ids[0], ids[-1])
        ok(sec.returncode == 0, "%s: section exits 0" % path)
        body = [
            ln
            for ln in sec.stdout.split("\n")
            if ln.strip() and not ln.startswith(("<<< ", ">>> "))
        ]
        stray = [ln for ln in body if ln not in src]
        ok(not stray, "%s: section is verbatim (%d stray lines)" % (path, len(stray)))
        ok(
            ("**%s" % ids[0]) in sec.stdout and ("**%s" % ids[-1]) in sec.stdout,
            "%s: section returns both requested rules" % path,
        )

    # LD-06: an unknown ID is an error, never a silent omission
    bad = run("section", "rules/lanes.md", "L-99")
    ok(bad.returncode == 1, "unknown ID fails closed")
    ok("read the file whole" in bad.stderr, "unknown ID says read it whole")
    ok(not bad.stdout.strip(), "unknown ID prints no content")

    # unreadable input fails closed rather than printing an empty index
    miss = run("spine", "rules/does-not-exist.md")
    ok(miss.returncode == 1, "missing file fails closed")

    # help is reachable and exits clean
    h = run("--help")
    ok(h.returncode == 0 and "rules-index.sh" in h.stdout, "--help works")

    print("\n%d checks, %d failed" % (checks, failed))
    if failed:
        print("rules-index tests FAILED")
        return 1
    print("all rules-index tests passed")
    return 0


if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)) + "/../..")
    sys.exit(main())
