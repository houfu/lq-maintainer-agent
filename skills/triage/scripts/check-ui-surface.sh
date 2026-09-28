#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "surface: rendered"; echo "error: python3-missing (fail-closed: treated as rendered)"; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
HELP = """lq-maintainer-agent -- skills/triage/scripts/check-ui-surface.sh

The mechanical half of UAT detection (rules/uat.md UA-01): does this
change reach what a person sees? It reads a changed-path list and the
`canon:ui-surface` row of rules/canon-map.md, and nothing else: no
network, no clone read, no execution, python3 stdlib only.

Input (stdin), one changed path per line, in `git diff --name-status`
shape -- `A<TAB>path`, `M<TAB>path`, `D<TAB>path`, `R100<TAB>old<TAB>new`
-- or bare paths (read as modified). `gh pr view N --json files --jq
'.files[] | [.changeType, .path] | @tsv'` produces an equivalent list
(ADDED/MODIFIED/DELETED/RENAMED are accepted too).

Output:
  surface: rendered|indirect|none      the strongest class any path hit
  new-surface: yes|no                  an ADDED file matched `new-surface`
  gate-floor: required|recommended|n-a UA-02 before the category rule
  path: <class> <path>                 one line per changed path
  new: <path>                          each added path that matched

UA-02's category rule is NOT applied here -- the script cannot know the
category. A category-1 (greenfield) item whose surface is not `none`
is `required` regardless of this floor; the skill applies that.

Honest bounds: a path list cannot see a backend change that alters a
rendered screen without touching a listed path. The model may RAISE the
surface with a stated reason (UA-01); nothing lowers it. A canon-map
row that cannot be parsed fails closed: `surface: rendered`, exit 1.

Usage: check-ui-surface.sh [--canon-map PATH] < changed-paths
"""

import os
import re
import sys

ORDER = {"none": 0, "indirect": 1, "rendered": 2}
STATUS = {"ADDED": "A", "MODIFIED": "M", "DELETED": "D", "RENAMED": "R",
          "COPIED": "C", "CHANGED": "M"}


def plugin_root():
    root = os.environ.get("CLAUDE_PLUGIN_ROOT") or os.environ.get("PLUGIN_ROOT")
    return root or os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                "..", "..", ".."))


def canon_row(path, key):
    """The third cell of the canon-map row whose first cell is `key`,
    parsed as `class: value, value; class: ...` (backticks optional)."""
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


def glob_re(pattern):
    """`**/` spans directories, `*` stays within one; a pattern with no
    wildcard is a prefix (a directory ends in `/`) or an exact file."""
    if "*" not in pattern:
        return None
    rx = ""
    i = 0
    while i < len(pattern):
        if pattern.startswith("**/", i):
            rx += "(?:.*/)?"
            i += 3
        elif pattern[i] == "*":
            rx += "[^/]*"
            i += 1
        else:
            rx += re.escape(pattern[i])
            i += 1
    return re.compile("^" + rx + "$")


def matches(path, pattern):
    rx = glob_re(pattern)
    if rx is not None:
        return bool(rx.match(path))
    if pattern.endswith("/"):
        return path.startswith(pattern)
    return path == pattern


def classify(path, row):
    if any(matches(path, p) for p in row.get("exclude", [])):
        return "excluded"
    base = path.rsplit("/", 1)[-1]
    if any(frag in base or ("/%s/" % frag.strip("/")) in "/" + path
           for frag in row.get("exclude-names", [])):
        return "excluded"
    if any(matches(path, p) for p in row.get("indirect", [])):
        return "indirect"
    if any(matches(path, p) for p in row.get("rendered", [])):
        return "rendered"
    return "none"


def parse_line(line):
    parts = line.rstrip("\n").split("\t")
    if len(parts) == 1:
        return "M", parts[0].strip()
    status = STATUS.get(parts[0].strip().upper(), parts[0].strip()[:1].upper())
    return status, parts[-1].strip()


def main(argv):
    if "-h" in argv or "--help" in argv:
        print(HELP)
        return 0
    cmap = os.path.join(plugin_root(), "rules", "canon-map.md")
    if "--canon-map" in argv:
        cmap = argv[argv.index("--canon-map") + 1]
    try:
        row = canon_row(cmap, "canon:ui-surface")
    except OSError:
        row = None
    if not row or not (row.get("rendered") or row.get("indirect")):
        print("surface: rendered")
        print("new-surface: no")
        print("gate-floor: required")
        print("error: canon:ui-surface row missing or unparseable (fail-closed)")
        return 1

    surface, new = "none", []
    for line in sys.stdin:
        if not line.strip():
            continue
        status, path = parse_line(line)
        cls = classify(path, row)
        print("path: %s %s" % (cls, path))
        if cls in ORDER and ORDER[cls] > ORDER[surface]:
            surface = cls
        if status == "A" and cls != "excluded" and \
                any(matches(path, p) for p in row.get("new-surface", [])):
            new.append(path)
    for path in new:
        print("new: %s" % path)
    floor = "required" if surface == "rendered" or new else \
        ("recommended" if surface == "indirect" else "n-a")
    print("surface: %s" % surface)
    print("new-surface: %s" % ("yes" if new else "no"))
    print("gate-floor: %s" % floor)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
