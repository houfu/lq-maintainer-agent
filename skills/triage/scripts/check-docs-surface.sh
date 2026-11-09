#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "surface: unknown"; echo "routes: -"; echo "pages-changed: 0"; echo "error: python3-missing (fail-closed: unknown)"; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
HELP = """lq-maintainer-agent -- skills/triage/scripts/check-docs-surface.sh

The mechanical half of the documentation-surface check (rules/docs-surface.md
DS-01/DS-02): which published documentation pages does this change touch,
or sit under? It reads a changed-path list, the `canon:docs-routes` row of
rules/canon-map.md, and the target project's route manifests at the pinned
canon SHA -- and nothing else: no network, no execution, python3 stdlib
only, never a file from the contribution.

Input (stdin), one changed path per line, in `git diff --name-status`
shape -- `A<TAB>path`, `M<TAB>path`, `D<TAB>path`, `R100<TAB>old<TAB>new`
-- or bare paths (read as modified). `gh pr view N --json files --jq
'.files[] | [.changeType, .path] | @tsv'` produces an equivalent list.
A rename classifies BOTH its old and its new path.

Where the manifests come from (one of):
  --clone DIR --canon-sha SHA   `git show SHA:<routes>/<file>` in the
                                maintainer's clone -- the canon, never the PR
  --routes-dir DIR              a directory of manifest files (tests)

Output:
  path: <class> <path> [route=<r>[,<r>]] [reference]   one line per changed path
  route: <route> <page-changed|source-listed> <path>    one line per route hit
  reference: <path>                                     each generated-reference input hit
  pages-changed: <integer>                              routes whose source: is in the diff
  routes: <route>,<route> | -                           every route named above
  surface: page-changed|source-listed|reference-source|none|unknown

Per-path classes, strongest first:
  page-changed      the path IS a route's `source:` -- that page changed
  source-listed     the path is in a route's `sources:` and that route's
                    `source:` is NOT in the diff: the page's stamp will move,
                    its words were not touched
  reference-source  a generated-reference input (the row's list)
  covered           in a route's `sources:` whose `source:` is ALSO in the
                    diff -- informational; the page-changed line carries it
  manifest          a route-manifest file itself changed -- informational
  excluded / none

The `surface:` line is the strongest of page-changed / source-listed /
reference-source / none over all paths. The model may RAISE a surface the
script missed (`described`, with the reason -- DS-01); nothing lowers one.

Fail-closed: a missing or unparseable canon row, a manifest that cannot be
read at the canon SHA, or a manifest using YAML outside the subset below
prints `surface: unknown` plus an `error:` line and exits 1. `unknown` is a
cannot-verify reading on the docs rows (DS-03) and never gates anything.

YAML subset accepted (what the manifests use): a top-level list of
mappings (`- route: x` opens an entry; further keys at the entry's
indent), scalar values (optionally quoted), inline lists `[a, b]`, block
lists (`- item` lines under a key), nested mappings (skipped), folded or
literal block scalars (`>`, `|` -- skipped), and `#` comment lines.

Usage: check-docs-surface.sh (--clone DIR --canon-sha SHA | --routes-dir DIR)
                             [--canon-map PATH] < changed-paths
"""

import os
import re
import subprocess
import sys

ORDER = {"none": 0, "reference-source": 1, "source-listed": 2, "page-changed": 3}
STATUS = {"ADDED": "A", "MODIFIED": "M", "DELETED": "D", "RENAMED": "R",
          "COPIED": "C", "CHANGED": "M"}
KEY_RX = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):(?:\s+(.*))?$")
ENTRY_RX = re.compile(r"^- ([A-Za-z_][A-Za-z0-9_-]*):(?:\s+(.*))?$")


class Unknown(Exception):
    """A fail-closed condition: the reading is `unknown`."""


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
    if "*" not in pattern:
        return None
    rx, i = "", 0
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


def excluded(path, row):
    if any(matches(path, p) for p in row.get("exclude", [])):
        return True
    base = path.rsplit("/", 1)[-1]
    return any(frag in base or ("/%s/" % frag.strip("/")) in "/" + path
               for frag in row.get("exclude-names", []))


def norm(p):
    p = p.strip().strip('"').strip("'").strip()
    while p.startswith("./"):
        p = p[2:]
    return p


def _inline_list(v):
    v = v.strip()
    if not (v.startswith("[") and v.endswith("]")):
        return None
    inner = v[1:-1].strip()
    return [norm(x) for x in inner.split(",") if x.strip()] if inner else []


# ---- the manifest parser (the subset in HELP; anything else -> Unknown) ----

def parse_manifest(text, name):
    entries = []
    cur = None            # the entry being filled
    block_key = None      # a key at entry indent awaiting block-list items
    skip_from = None      # indent of a nested map / block scalar being skipped
    for n, raw in enumerate(text.splitlines(), 1):
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if raw.startswith("---") and raw.strip() == "---":
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        line = raw.strip()
        where = "%s:%d" % (name, n)
        if skip_from is not None:
            if indent > skip_from:
                continue
            skip_from = None
        if indent == 0:
            m = ENTRY_RX.match(line)
            if not m:
                raise Unknown("%s: expected a `- key:` entry at indent 0" % where)
            cur = {"_name": name, "sources": []}
            entries.append(cur)
            block_key = None
            _assign(cur, m.group(1), m.group(2), indent, where)
            if m.group(2) is None:
                block_key = m.group(1)
            continue
        if cur is None:
            raise Unknown("%s: content before the first entry" % where)
        if indent == 2:
            m = KEY_RX.match(line)
            if not m:
                raise Unknown("%s: expected `key: value` at the entry indent" % where)
            block_key = None
            val = m.group(2)
            if val is None:
                block_key = m.group(1)          # block list or nested map follows
                continue
            if val.strip() in (">", "|", ">-", "|-", ">+", "|+"):
                skip_from = indent              # block scalar: skip its body
                continue
            _assign(cur, m.group(1), val, indent, where)
            continue
        # indent > 2
        if block_key is None:
            raise Unknown("%s: unexpected indentation" % where)
        if line.startswith("- "):
            item = line[2:].strip()
            if block_key == "sources":
                if KEY_RX.match(item) and not item.startswith("["):
                    raise Unknown("%s: a mapping inside `sources:` is not accepted" % where)
                cur["sources"].append(norm(item))
            continue
        if KEY_RX.match(line):
            skip_from = indent - 1              # nested map (sidebar: order: 2): skip
            continue
        raise Unknown("%s: unparseable line" % where)
    for e in entries:
        if "route" not in e or "source" not in e:
            raise Unknown("%s: an entry lacks `route:` or `source:`" % e["_name"])
    return entries


def _assign(cur, key, val, indent, where):
    if val is None:
        return
    val = val.strip()
    lst = _inline_list(val)
    if key == "sources":
        if lst is None:
            raise Unknown("%s: `sources:` must be a list" % where)
        cur["sources"].extend(lst)
    elif key in ("route", "source"):
        if lst is not None or not val:
            raise Unknown("%s: `%s:` must be a scalar" % (where, key))
        cur[key] = norm(val)
    # every other key (title, description, kind, audience, status, next, …) is data we ignore


# ---- reading the manifests from the canon ----

def manifests_from_dir(d):
    out = {}
    try:
        names = sorted(f for f in os.listdir(d) if f.endswith((".yaml", ".yml")))
    except OSError as e:
        raise Unknown("routes directory unreadable: %s" % e)
    if not names:
        raise Unknown("no manifest files under %s" % d)
    for f in names:
        out[f] = open(os.path.join(d, f), encoding="utf-8").read()
    return out


def manifests_from_git(clone, sha, routes_dir):
    if not re.match(r"^[0-9a-f]{7,40}$", sha or ""):
        raise Unknown("--canon-sha must be a hex SHA")
    rd = routes_dir.rstrip("/")
    try:
        ls = subprocess.run(["git", "-C", clone, "ls-tree", "--name-only", sha, rd + "/"],
                            capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.SubprocessError) as e:
        raise Unknown("git ls-tree failed: %s" % e)
    if ls.returncode != 0:
        raise Unknown("routes directory %s not readable at %s" % (rd, sha[:12]))
    names = sorted(p for p in ls.stdout.split("\n") if p.endswith((".yaml", ".yml")))
    if not names:
        raise Unknown("no manifest files under %s at %s" % (rd, sha[:12]))
    out = {}
    for p in names:
        show = subprocess.run(["git", "-C", clone, "show", "%s:%s" % (sha, p)],
                              capture_output=True, text=True, timeout=60)
        if show.returncode != 0:
            raise Unknown("cannot read %s at %s" % (p, sha[:12]))
        out[p.rsplit("/", 1)[-1]] = show.stdout
    return out


def parse_line(line):
    parts = line.rstrip("\n").split("\t")
    if len(parts) == 1:
        return "M", [norm(parts[0])]
    status = STATUS.get(parts[0].strip().upper(), parts[0].strip()[:1].upper())
    if status in ("R", "C") and len(parts) >= 3:
        return status, [norm(parts[1]), norm(parts[2])]
    return status, [norm(parts[-1])]


def fail(reason):
    print("surface: unknown")
    print("routes: -")
    print("pages-changed: 0")
    print("error: %s (fail-closed: unknown)" % reason)
    return 1


def main(argv):
    if "-h" in argv or "--help" in argv:
        print(HELP)
        return 0

    def opt(name):
        return argv[argv.index(name) + 1] if name in argv and argv.index(name) + 1 < len(argv) else None

    cmap = opt("--canon-map") or os.path.join(plugin_root(), "rules", "canon-map.md")
    try:
        row = canon_row(cmap, "canon:docs-routes")
    except OSError:
        row = None
    if not row or not row.get("routes"):
        return fail("canon:docs-routes row missing or unparseable")
    routes_dir = row["routes"][0].rstrip("/")
    reference = set(norm(p) for p in row.get("reference-sources", []))

    changed = []            # (status, path)
    for line in sys.stdin:
        if not line.strip():
            continue
        status, paths = parse_line(line)
        for p in paths:
            if p:
                changed.append((status, p))
    diff_paths = set(p for _, p in changed)

    try:
        if opt("--routes-dir"):
            texts = manifests_from_dir(opt("--routes-dir"))
        elif opt("--clone") and opt("--canon-sha"):
            texts = manifests_from_git(opt("--clone"), opt("--canon-sha"), routes_dir)
        else:
            raise Unknown("no manifest source: pass --clone DIR --canon-sha SHA, or --routes-dir DIR")
        entries = []
        for name in sorted(texts):
            entries.extend(parse_manifest(texts[name], name))
    except Unknown as e:
        return fail(str(e))
    if not entries:
        return fail("no route entries found")

    source_of = {}          # source path -> [routes]
    listed_in = {}          # listed path -> [(route, source)]
    for e in entries:
        source_of.setdefault(e["source"], []).append(e["route"])
        for s in e["sources"]:
            listed_in.setdefault(s, []).append((e["route"], e["source"]))

    surface, route_lines, ref_lines, pages = "none", [], [], set()
    named = set()
    for status, p in changed:
        tags = []
        if excluded(p, row):
            cls = "excluded"
        elif p.startswith(routes_dir + "/"):
            cls = "manifest"
        elif p in source_of:
            cls = "page-changed"
            for r in source_of[p]:
                pages.add(r)
                named.add(r)
                route_lines.append("route: %s page-changed %s" % (r, p))
            tags.append("route=" + ",".join(sorted(source_of[p])))
        elif p in listed_in:
            open_routes = [r for r, src in listed_in[p] if src not in diff_paths]
            covered = [r for r, src in listed_in[p] if src in diff_paths]
            if open_routes:
                cls = "source-listed"
                for r in open_routes:
                    named.add(r)
                    route_lines.append("route: %s source-listed %s" % (r, p))
                tags.append("route=" + ",".join(sorted(open_routes)))
            else:
                cls = "covered"
                tags.append("route=" + ",".join(sorted(covered)))
        else:
            cls = "none"
        if p in reference and cls not in ("excluded",):
            tags.append("reference")
            ref_lines.append("reference: %s" % p)
            if cls in ("none", "covered"):
                cls = cls if cls == "covered" else "reference-source"
        print("path: %s %s%s" % (cls, p, (" " + " ".join(tags)) if tags else ""))
        if cls in ORDER and ORDER[cls] > ORDER[surface]:
            surface = cls
    for l in sorted(set(route_lines)):
        print(l)
    for l in sorted(set(ref_lines)):
        print(l)
    if ref_lines and surface == "none":
        surface = "reference-source"
    print("pages-changed: %d" % len(pages))
    print("routes: %s" % (",".join(sorted(named)) if named else "-"))
    print("surface: %s" % surface)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
