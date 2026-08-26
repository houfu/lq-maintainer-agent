#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "verdict: FAIL check=rules-index error=python3-missing (fail-closed)"; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
HELP = """lq-maintainer-agent -- skills/triage/scripts/rules-index.sh

Progressive reader for the normative rules/ tree (rules/loading.md,
LD-NN). It does NOT summarize: `spine` extracts each rule's own ID and
bolded title verbatim, and `section` prints the rule's full text
verbatim with the heading path that frames it. Nothing this script
prints was written by a model, so a spine can never drift from the file
it indexes and a section can never be a paraphrase.

No network, no dependencies beyond python3 stdlib. The file is an
sh/python3 polyglot; run it as `sh rules-index.sh` or directly.

Usage:
  rules-index.sh spine FILE...            # the index: IDs + titles
  rules-index.sh section FILE ID [ID...]  # those rules, in full
  rules-index.sh ids FILE...              # bare IDs, one per line

  rules-index.sh spine rules/lanes.md
  rules-index.sh section rules/lanes.md L-30 L-07

Exit: 0 = ok; 1 = unreadable file, unknown ID, or a file with no rule
IDs (fail-closed: read the whole file rather than trust an empty
index). An unknown ID is an error, never a silent omission -- a rule
you cannot fetch is a rule you must read the whole file for.
"""

import re
import sys

RULE = re.compile(r"^- \*\*([A-Z]{1,3}-\d{2}[a-z]?)\b\s*[-—]?\s*(.*)$")
HEAD = re.compile(r"^(#{1,6})\s+(.*)$")


def parse(path):
    """Return (lines, blocks, heads). blocks: id -> (start, end) line indices."""
    try:
        with open(path, encoding="utf-8") as fh:
            lines = fh.read().split("\n")
    except OSError as exc:
        sys.stderr.write("error: cannot read %s (%s)\n" % (path, exc))
        return None, None, None
    starts = []
    heads = []
    for i, line in enumerate(lines):
        mo = RULE.match(line)
        if mo:
            starts.append((i, mo.group(1), mo.group(2)))
        elif HEAD.match(line):
            heads.append(i)
    blocks = {}
    for k, (i, rid, _title) in enumerate(starts):
        end = starts[k + 1][0] if k + 1 < len(starts) else len(lines)
        # a heading closes a rule block early
        for h in heads:
            if i < h < end:
                end = h
                break
        blocks[rid] = (i, end)
    return lines, blocks, starts


def heading_path(lines, idx):
    """The nearest enclosing headings above idx, outermost first."""
    path, seen = [], 99
    for i in range(idx - 1, -1, -1):
        mo = HEAD.match(lines[i])
        if mo and len(mo.group(1)) < seen:
            seen = len(mo.group(1))
            path.append(lines[i])
            if seen == 1:
                break
    return list(reversed(path))


def title_of(raw):
    """First sentence of the bolded rule title, verbatim, trailing ** stripped."""
    t = raw.strip()
    cut = t.find("**")
    if cut != -1:
        t = t[:cut]
    t = t.split(". ")[0].rstrip().rstrip(".")
    return t


def cmd_spine(paths):
    rc = 0
    for path in paths:
        lines, blocks, starts = parse(path)
        if lines is None:
            rc = 1
            continue
        if not starts:
            sys.stdout.write(
                "## %s\nno rule IDs in this file -- read it whole (LD-04)\n\n" % path
            )
            rc = 1
            continue
        sys.stdout.write("## %s -- %d rules\n" % (path, len(starts)))
        last = None
        for i, rid, raw in starts:
            hp = heading_path(lines, i)
            crumb = " / ".join(h.lstrip("# ").strip() for h in hp[1:]) or "-"
            if crumb != last:
                sys.stdout.write("  [%s]\n" % crumb)
                last = crumb
            span = blocks[rid][1] - blocks[rid][0]
            sys.stdout.write("    %-8s %s  (%d lines)\n" % (rid, title_of(raw), span))
        sys.stdout.write(
            "\nfetch in full:  rules-index.sh section %s <ID>...\n\n" % path
        )
    return rc


def cmd_section(path, ids):
    lines, blocks, starts = parse(path)
    if lines is None:
        return 1
    if not starts:
        sys.stderr.write("error: %s defines no rule IDs -- read it whole\n" % path)
        return 1
    rc = 0
    for rid in ids:
        if rid not in blocks:
            sys.stderr.write(
                "error: %s not in %s -- read the file whole rather than guess\n"
                % (rid, path)
            )
            rc = 1
            continue
        start, end = blocks[rid]
        sys.stdout.write("<<< %s %s\n" % (path, rid))
        for h in heading_path(lines, start):
            sys.stdout.write("%s\n" % h)
        sys.stdout.write("\n")
        sys.stdout.write("\n".join(lines[start:end]).rstrip() + "\n")
        sys.stdout.write(">>> %s %s\n\n" % (path, rid))
    return rc


def cmd_ids(paths):
    rc = 0
    for path in paths:
        lines, _blocks, starts = parse(path)
        if lines is None:
            rc = 1
            continue
        for _i, rid, _raw in starts:
            sys.stdout.write("%s\n" % rid)
    return rc


def main(argv):
    if len(argv) < 2 or argv[1] in ("-h", "--help", "help"):
        sys.stdout.write(HELP)
        return 0
    mode, rest = argv[1], argv[2:]
    if mode == "spine" and rest:
        return cmd_spine(rest)
    if mode == "ids" and rest:
        return cmd_ids(rest)
    if mode == "section" and len(rest) >= 2:
        return cmd_section(rest[0], rest[1:])
    sys.stderr.write(HELP)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
