#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "verdict: FAIL check=breaking error=python3-missing (fail-closed)"; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
HELP = """lq-maintainer-agent -- skills/triage/scripts/check-breaking.sh

The mechanical half of breaking-change detection (rules/breaking-changes.md
BC-01..BC-04), run over a unified diff at triage Step 6b for every
standard-lane category-2/3 PR and inside review-pr's Tier-1 pass and
Tier-2 security/quality context. It reads diff TEXT and nothing else:
no network, no clone read, no execution, python3 stdlib only. The file
is a sh/python3 polyglot; run it as `sh check-breaking.sh` or directly.

What it detects, per file, by pairing the diff's old side against its
new side:

  symbols  removed or renamed public symbols and breaking signature
           changes -- python `def`/`async def`/`class` (names starting
           with `_` are treated as private and skipped) and JS/TS
           `export function|const|let|var|class|interface|type|enum`,
           `export { ... }`, `module.exports.x =`, `exports.x =`.
           Breaking = the symbol is gone from the new side, or an
           existing parameter was removed/renamed/reordered, or the
           declared return type changed.
  config   removed config keys, environment variables, and CLI flags:
           keys in config-ish files (yaml/yml/toml/ini/cfg/json/.env/
           *config*/*settings*), module-level ALL_CAPS constants,
           `os.environ[...]`/`os.getenv()`/`process.env.X`/`ENV["X"]`
           reads, and quoted `--long-flags`.
  routes   removed or renamed HTTP route registrations that are
           textually visible: `@app.route`/`@router.get(...)` and the
           other verb decorators, `app.get("/x", ...)`-style express
           registrations, Django `path()`/`re_path()`/`url()`, and
           bare `get "/x"` router DSL lines.
  schema   migration/schema hunks that drop or narrow: DROP TABLE /
           DROP COLUMN / RENAME COLUMN / ALTER COLUMN ... TYPE / SET
           NOT NULL and their alembic and JS-migration equivalents,
           plus a VARCHAR/CHAR length reduced on the same column. A
           schema hit is two irreversible classes at once, so its
           evidence line cites both: `rv=RV-02.2,RV-02.3` (BC-01).
  files    a deleted or renamed source/config file (its import path
           and every public symbol in it go with it).

Honest bounds -- this is a textual heuristic, not a parser (BC-03):

  - Only python and JS/TS symbols are recognized. Go, Rust, Java, C#,
    Ruby, and everything else are NOT scanned for symbol breaks.
  - Semantic breaks under an unchanged signature -- a behavior,
    default, error, or wire-format change -- are invisible here. They
    are the model's job (BC-02), not this script's.
  - A parameter *added* to an existing signature is not flagged; a new
    REQUIRED parameter is a real break the model must catch (BC-02).
  - Only the hunks are visible. A symbol whose declaration is outside
    every hunk is not scanned, and a rename across files reads as a
    removal here.
  - Dependency manifests and lockfiles are skipped entirely: major
    dependency bumps are check-semver.sh's job, one authority per
    check (BC-04). Skipped paths are printed.

A PASS therefore means exactly "no textual break detected" -- never
"non-breaking" -- and can never move an item to a lighter lane, tier,
or category (BC-03, rules/tiers.md TR-09, rules/lanes.md L-04).

Usage:
  check-breaking.sh [DIFF_FILE]      # default: read the diff on stdin
  gh pr diff 123 | check-breaking.sh

Output (machine-parseable; the receipt renders line 1):
  line 1:  verdict: PASS|FAIL check=breaking findings=N symbols=N \\
           config=N routes=N schema=N files=N scanned=N [kinds=...]
  line 2:  note: PASS means "no textual break detected", never
           "non-breaking" (BC-03) ... -- always printed, both verdicts
  then     break: <kind> at=<path>:<line> <field=value ...> \\
             evidence="<the hunk line, quoted>"
           skipped: <path> reason=<why>

Exit: 0 = no textual break detected; 1 = any detection, an empty or
unreadable diff, or any internal error (fail-closed: an unverifiable
diff is not evidence that nothing broke).
"""

import re
import sys
from collections import OrderedDict

CHECK = "breaking"
MAX_DETAILS = 50
MAX_EVIDENCE = 140

# A schema hit is two irreversible classes at once: the data class and
# the public-API class. BC-01 requires the evidence line to cite both.
SCHEMA_RV = "RV-02.2,RV-02.3"

# --- path classification -----------------------------------------------

MANIFEST_BASENAMES = {
    "package.json", "package-lock.json", "npm-shrinkwrap.json",
    "yarn.lock", "pnpm-lock.yaml", "Pipfile", "Pipfile.lock",
    "pyproject.toml", "poetry.lock", "uv.lock", "Cargo.toml",
    "Cargo.lock", "go.mod", "go.sum", "Gemfile", "Gemfile.lock",
}
MANIFEST_RE = re.compile(r"^(requirements[^/]*|constraints[^/]*)\.txt$")

PY_EXT = (".py", ".pyi")
JS_EXT = (".js", ".jsx", ".mjs", ".cjs", ".ts", ".tsx", ".mts", ".cts")
SQL_EXT = (".sql",)
CONFIG_EXT = (".yaml", ".yml", ".toml", ".ini", ".cfg", ".conf",
              ".json", ".env", ".properties")
SOURCE_EXT = PY_EXT + JS_EXT + SQL_EXT + CONFIG_EXT + (
    ".go", ".rb", ".rs", ".java", ".kt", ".cs", ".php", ".sh")

MIGRATION_RE = re.compile(r"(^|/)(migrations?|alembic|schema|db/migrate)(/|$)",
                          re.I)


def basename(path):
    return path.rsplit("/", 1)[-1]


def is_manifest(path):
    base = basename(path)
    return base in MANIFEST_BASENAMES or bool(MANIFEST_RE.match(base))


def lang_of(path):
    low = path.lower()
    if low.endswith(PY_EXT):
        return "python"
    if low.endswith(JS_EXT):
        return "js"
    return None


def is_schema(path):
    low = path.lower()
    return low.endswith(SQL_EXT) or bool(MIGRATION_RE.search(low))


def is_configish(path):
    low = path.lower()
    base = basename(low)
    return (low.endswith(CONFIG_EXT) or base.startswith(".env")
            or "config" in base or "settings" in base)


def is_source(path):
    return path.lower().endswith(SOURCE_EXT)


# --- diff parsing --------------------------------------------------------

HUNK_RE = re.compile(r"^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@")


class FileDiff(object):
    def __init__(self, path):
        self.path = path
        self.old = []          # (lineno, text, changed, hunk)
        self.new = []
        self.deleted = False
        self.created = False
        self.renamed_from = None


def parse_diff(text):
    files = OrderedDict()
    cur = None
    minus_path = None
    pending_rename = None
    old_no = new_no = 0
    hunk = ""

    def get(path):
        if path not in files:
            files[path] = FileDiff(path)
        return files[path]

    for raw in text.splitlines():
        if raw.startswith("rename from "):
            pending_rename = raw[len("rename from "):].strip()
            continue
        if raw.startswith("rename to "):
            target = raw[len("rename to "):].strip()
            fd = get(target)
            fd.renamed_from = pending_rename
            pending_rename = None
            continue
        if raw.startswith("--- "):
            minus_path = raw[4:].strip()
            continue
        if raw.startswith("+++ "):
            plus = raw[4:].strip()
            deleted = plus == "/dev/null"
            created = minus_path == "/dev/null"
            path = minus_path if deleted else plus
            for prefix in ("a/", "b/"):
                if path and path.startswith(prefix):
                    path = path[2:]
            cur = get(path or "<unknown>")
            cur.deleted = cur.deleted or deleted
            cur.created = cur.created or created
            old_no = new_no = 0
            hunk = ""
            continue
        m = HUNK_RE.match(raw)
        if m:
            old_no, new_no = int(m.group(1)), int(m.group(2))
            hunk = "-%s+%s" % (m.group(1), m.group(2))
            continue
        if cur is None or not raw:
            continue
        if raw.startswith(("diff ", "index ", "new file", "deleted file",
                           "similarity", "old mode", "new mode",
                           "Binary files", "\\ No newline", "GIT binary")):
            continue
        side, content = raw[0], raw[1:]
        if side == " ":
            cur.old.append((old_no, content, False, hunk))
            cur.new.append((new_no, content, False, hunk))
            old_no += 1
            new_no += 1
        elif side == "-":
            cur.old.append((old_no, content, True, hunk))
            old_no += 1
        elif side == "+":
            cur.new.append((new_no, content, True, hunk))
            new_no += 1
    return files


def logical_lines(entries):
    """Join continuation lines so a multi-line signature reads as one."""
    out = []
    n = len(entries)
    for i in range(n):
        lineno, text, changed, hunk = entries[i]
        depth = text.count("(") - text.count(")")
        joined, j = text, i
        while depth > 0 and j + 1 < n and (j - i) < 10:
            j += 1
            nxt = entries[j]
            joined += " " + nxt[1].strip()
            changed = changed or nxt[2]
            depth += nxt[1].count("(") - nxt[1].count(")")
        out.append((lineno, joined, changed, hunk, text))
    return out


# --- symbol detection ----------------------------------------------------

PY_DEF = re.compile(r"^\s*(?:async\s+)?def\s+([A-Za-z_]\w*)\s*\((.*)$")
PY_CLASS = re.compile(r"^\s*class\s+([A-Za-z_]\w*)\s*(?:\((.*))?")
JS_FUNC = re.compile(
    r"^\s*export\s+(?:default\s+)?(?:async\s+)?function\s*\*?\s*"
    r"([A-Za-z_$][\w$]*)\s*\((.*)$")
JS_DECL = re.compile(
    r"^\s*export\s+(?:declare\s+)?(?:default\s+)?(?:abstract\s+)?"
    r"(?:const|let|var|class|interface|type|enum)\s+([A-Za-z_$][\w$]*)")
JS_NAMED = re.compile(r"^\s*export\s*\{([^}]*)\}")
JS_CJS = re.compile(r"^\s*(?:module\.)?exports\.([A-Za-z_$][\w$]*)\s*=")
ARROW_PARAMS = re.compile(r"=\s*(?:async\s*)?\((.*)$")
PY_RETURN = re.compile(r"\)\s*->\s*([^:{]+)")
TS_RETURN = re.compile(r"\)\s*:\s*([A-Za-z_$][\w$<>\[\]|, .]*)")


def split_params(tail):
    """tail starts just after the opening paren; None if unbalanced."""
    depth, buf, params, closed = 1, [], [], False
    for ch in tail:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
            if depth == 0:
                closed = True
                break
        if ch == "," and depth == 1:
            params.append("".join(buf))
            buf = []
            continue
        buf.append(ch)
    if not closed:
        return None
    params.append("".join(buf))
    names = []
    for p in params:
        p = p.strip()
        if not p or p in ("*", "/"):
            continue
        p = p.split("=")[0].split(":")[0].strip()
        p = p.lstrip("*&").strip()
        if p.startswith("..."):
            p = p[3:].strip()
        if p:
            names.append(p)
    return names


def return_type(text, lang):
    m = PY_RETURN.search(text) if lang == "python" else TS_RETURN.search(text)
    return m.group(1).strip() if m else None


def symbols_on_side(entries, lang):
    """name -> dict(line, params, ret, changed, raw, hunk); first wins."""
    found = OrderedDict()

    def record(name, params, ret, lineno, changed, raw, hunk, kind):
        if name in found:
            if changed and not found[name]["changed"]:
                found[name]["changed"] = True
            return
        found[name] = {"line": lineno, "params": params, "ret": ret,
                       "changed": changed, "raw": raw, "hunk": hunk,
                       "kind": kind}

    for lineno, text, changed, hunk, raw in logical_lines(entries):
        if lang == "python":
            m = PY_DEF.match(text)
            if m and not m.group(1).startswith("_"):
                record(m.group(1), split_params(m.group(2)),
                       return_type(text, "python"), lineno, changed, raw,
                       hunk, "function")
                continue
            m = PY_CLASS.match(text)
            if m and not m.group(1).startswith("_"):
                record(m.group(1), None, None, lineno, changed, raw, hunk,
                       "class")
            continue
        if lang != "js":
            continue
        m = JS_FUNC.match(text)
        if m:
            record(m.group(1), split_params(m.group(2)),
                   return_type(text, "js"), lineno, changed, raw, hunk,
                   "function")
            continue
        m = JS_DECL.match(text)
        if m:
            arrow = ARROW_PARAMS.search(text)
            record(m.group(1),
                   split_params(arrow.group(1)) if arrow else None,
                   return_type(text, "js") if arrow else None,
                   lineno, changed, raw, hunk, "declaration")
            continue
        m = JS_NAMED.match(text)
        if m:
            for spec in m.group(1).split(","):
                spec = spec.strip()
                if not spec:
                    continue
                name = spec.split(" as ")[-1].strip()
                if name:
                    record(name, None, None, lineno, changed, raw, hunk,
                           "named-export")
            continue
        m = JS_CJS.match(text)
        if m:
            arrow = ARROW_PARAMS.search(text)
            record(m.group(1),
                   split_params(arrow.group(1)) if arrow else None,
                   None, lineno, changed, raw, hunk, "cjs-export")
    return found


def signature_break(old, new):
    reasons = []
    if old["params"] is not None and new["params"] is not None:
        gone = [p for p in old["params"] if p not in new["params"]]
        if gone:
            reasons.append("params-removed=" + ",".join(gone[:4]))
        else:
            idx = [new["params"].index(p) for p in old["params"]]
            if idx != sorted(idx):
                reasons.append("params-reordered")
    if old["ret"] and new["ret"] and old["ret"] != new["ret"]:
        reasons.append("return-type=%s->%s" % (old["ret"], new["ret"]))
    return reasons


# --- config keys, env vars, CLI flags ------------------------------------

CONFIG_KEY = re.compile(
    r"""^\s*(?:-\s*)?(?:"([A-Za-z_][\w.\-]*)"|'([A-Za-z_][\w.\-]*)'"""
    r"""|([A-Za-z_][\w.\-]*))\s*[:=]\s*\S""")
CONST_KEY = re.compile(r"^([A-Z][A-Z0-9_]{2,})\s*[:=]")
ENV_READ = re.compile(
    r"""(?:os\.environ(?:\.get)?[\[(]\s*["']([A-Za-z_]\w*)["']"""
    r"""|os\.getenv\(\s*["']([A-Za-z_]\w*)["']"""
    r"""|process\.env\.([A-Za-z_]\w*)"""
    r"""|process\.env\[\s*["']([A-Za-z_]\w*)["']"""
    r"""|ENV\[\s*["']([A-Za-z_]\w*)["']"""
    r"""|System\.getenv\(\s*["']([A-Za-z_]\w*)["'])""")
CLI_FLAG = re.compile(r"""["'](--[A-Za-z][\w\-]*)["']""")
CLI_FLAG_CASE = re.compile(r"^\s*(--[A-Za-z][\w\-]*)\)")


def contract_keys(entries, path):
    """side -> {(kind, key): (lineno, raw, hunk)} for the changed lines."""
    out = OrderedDict()

    def add(kind, key, lineno, raw, hunk):
        out.setdefault((kind, key), (lineno, raw, hunk))

    configish = is_configish(path)
    for lineno, raw, changed, hunk in entries:
        if not changed:
            continue
        stripped = raw.strip()
        if not stripped or stripped.startswith(("#", "//", "*", "<!--")):
            continue
        for m in ENV_READ.finditer(raw):
            name = next(g for g in m.groups() if g)
            add("env-var", name, lineno, raw, hunk)
        for m in CLI_FLAG.finditer(raw):
            add("cli-flag", m.group(1), lineno, raw, hunk)
        m = CLI_FLAG_CASE.match(raw)
        if m:
            add("cli-flag", m.group(1), lineno, raw, hunk)
        m = CONST_KEY.match(raw)
        if m:
            add("config-key", m.group(1), lineno, raw, hunk)
            continue
        if configish:
            m = CONFIG_KEY.match(raw)
            if m:
                key = m.group(1) or m.group(2) or m.group(3)
                add("config-key", key, lineno, raw, hunk)
    return out


# --- routes --------------------------------------------------------------

ROUTE_PATTERNS = [
    re.compile(r"""^\s*@\s*[\w.]*\.(route|get|post|put|patch|delete|head"""
               r"""|options)\(\s*["'`]([^"'`]+)"""),
    re.compile(r"""^\s*[\w.]*\.(get|post|put|patch|delete|head|options|all"""
               r"""|use)\(\s*["'`](/[^"'`]*)"""),
    re.compile(r"""^\s*(?:re_)?(path|url)\(\s*r?["']([^"']*)"""),
    re.compile(r"""^\s*(get|post|put|patch|delete)\s+["']([^"']+)["']"""),
]


def routes(entries):
    out = OrderedDict()
    for lineno, raw, changed, hunk in entries:
        if not changed:
            continue
        for pat in ROUTE_PATTERNS:
            m = pat.match(raw)
            if m:
                key = (m.group(1).lower(), m.group(2))
                out.setdefault(key, (lineno, raw, hunk))
                break
    return out


# --- schema --------------------------------------------------------------

SCHEMA_PATTERNS = [
    (re.compile(r"\bDROP\s+TABLE\b", re.I), "drop-table"),
    (re.compile(r"\bDROP\s+COLUMN\b", re.I), "drop-column"),
    (re.compile(r"\bRENAME\s+(COLUMN|TO)\b", re.I), "rename-column"),
    (re.compile(r"\bALTER\s+COLUMN\b.*\b(TYPE|SET\s+NOT\s+NULL)\b", re.I),
     "narrow-column"),
    (re.compile(r"\bdrop_table\s*\(", re.I), "drop-table"),
    (re.compile(r"\bdrop_column\s*\(", re.I), "drop-column"),
    (re.compile(r"\balter_column\s*\(.*(nullable\s*=\s*False|type_\s*=)",
                re.I), "narrow-column"),
    (re.compile(r"\brename_column\s*\(", re.I), "rename-column"),
    (re.compile(r"\b(dropColumn|removeColumn|dropTable)\s*\(", re.I),
     "drop-column"),
    (re.compile(r"\bSET\s+NOT\s+NULL\b", re.I), "narrow-column"),
]
VARCHAR = re.compile(r"^\s*[\"'`]?(\w+)[\"'`]?\s+(?:VARCHAR|CHAR)\s*\((\d+)\)",
                     re.I)


def schema_findings(fd):
    """Detections on the added side, plus varchar narrowing across sides."""
    out = []
    for lineno, raw, changed, hunk in fd.new:
        if not changed:
            continue
        stripped = raw.strip()
        if stripped.startswith(("--", "#", "//")):
            continue
        for pat, kind in SCHEMA_PATTERNS:
            if pat.search(raw):
                out.append((kind, lineno, raw, hunk))
                break
    old_widths = {}
    for lineno, raw, changed, hunk in fd.old:
        if not changed:
            continue
        m = VARCHAR.match(raw)
        if m:
            old_widths[m.group(1).lower()] = int(m.group(2))
    for lineno, raw, changed, hunk in fd.new:
        if not changed:
            continue
        m = VARCHAR.match(raw)
        if m:
            col = m.group(1).lower()
            if col in old_widths and int(m.group(2)) < old_widths[col]:
                out.append(("narrow-column", lineno, raw, hunk))
    # a column definition removed from a CREATE TABLE body
    new_cols = set()
    for _, raw, changed, _ in fd.new:
        m = VARCHAR.match(raw)
        if m:
            new_cols.add(m.group(1).lower())
    for lineno, raw, changed, hunk in fd.old:
        if not changed:
            continue
        m = VARCHAR.match(raw)
        if m and m.group(1).lower() not in new_cols:
            out.append(("drop-column", lineno, raw, hunk))
    return out


# --- reporting -----------------------------------------------------------

def quote(raw):
    text = raw.strip().replace('"', "'")
    if len(text) > MAX_EVIDENCE:
        text = text[:MAX_EVIDENCE] + "..."
    return text


class Report(object):
    def __init__(self):
        self.details = []
        self.skipped = []
        self.kinds = OrderedDict()
        self.counts = {"symbols": 0, "config": 0, "routes": 0,
                       "schema": 0, "files": 0}

    def add(self, kind, bucket, path, lineno, fields, raw, hunk):
        self.counts[bucket] += 1
        self.kinds[kind] = True
        parts = ["break: %s" % kind, "at=%s:%s" % (path, lineno),
                 "hunk=%s" % (hunk or "n-a")]
        parts += ["%s=%s" % kv for kv in fields]
        parts.append('evidence="%s"' % quote(raw))
        self.details.append(" ".join(parts))

    @property
    def findings(self):
        return sum(self.counts.values())


def analyze(files):
    rep = Report()
    scanned = 0
    for path, fd in files.items():
        if is_manifest(path):
            rep.skipped.append(
                "skipped: %s reason=dependency-manifest "
                "(BC-04 — check-semver.sh owns dependency majors)" % path)
            continue
        if not is_source(path):
            rep.skipped.append(
                "skipped: %s reason=not-a-scanned-file-type "
                "(BC-03 — heuristic bound)" % path)
            continue
        scanned += 1

        if fd.renamed_from:
            rep.add("file-renamed", "files", path, 0,
                    [("from", fd.renamed_from)],
                    "rename from %s" % fd.renamed_from, "n-a")
            continue
        if fd.deleted:
            rep.add("file-deleted", "files", path, 0, [],
                    "deleted file %s" % path, "n-a")
            continue
        if fd.created:
            # a brand-new file adds no symbol, key, or route — but a new
            # migration is exactly how a column gets dropped
            if is_schema(path):
                for kind, lineno, raw, hunk in schema_findings(fd):
                    rep.add("schema-%s" % kind, "schema", path, lineno,
                            [("rv", SCHEMA_RV)], raw, hunk)
            continue

        lang = lang_of(path)
        if lang:
            old_syms = symbols_on_side(fd.old, lang)
            new_syms = symbols_on_side(fd.new, lang)
            for name, old in old_syms.items():
                if not old["changed"]:
                    continue
                new = new_syms.get(name)
                if new is None:
                    fields = [("name", name), ("kind", old["kind"]),
                              ("lang", lang)]
                    twin = None
                    if old["params"]:
                        for cand, info in new_syms.items():
                            if (info["changed"] and cand not in old_syms
                                    and info["params"] == old["params"]):
                                twin = cand
                                break
                    if twin:
                        fields.append(("possible-rename-to", twin))
                    rep.add("symbol-removed", "symbols", path, old["line"],
                            fields, old["raw"], old["hunk"])
                    continue
                reasons = signature_break(old, new)
                if reasons:
                    rep.add("signature-changed", "symbols", path,
                            new["line"],
                            [("name", name), ("lang", lang)]
                            + [tuple(r.split("=", 1)) if "=" in r
                               else (r, "yes") for r in reasons],
                            new["raw"], new["hunk"])

        old_keys = contract_keys(fd.old, path)
        new_keys = contract_keys(fd.new, path)
        for (kind, key), (lineno, raw, hunk) in old_keys.items():
            if (kind, key) in new_keys:
                continue
            rep.add("%s-removed" % kind, "config", path, lineno,
                    [("name", key)], raw, hunk)

        old_routes = routes(fd.old)
        new_routes = routes(fd.new)
        for (verb, spec), (lineno, raw, hunk) in old_routes.items():
            if (verb, spec) in new_routes:
                continue
            fields = [("method", verb), ("path", spec)]
            twin = [s for (v, s) in new_routes if v == verb and s != spec]
            if twin:
                fields.append(("possible-rename-to", twin[0]))
            rep.add("route-removed", "routes", path, lineno, fields, raw,
                    hunk)

        if is_schema(path):
            for kind, lineno, raw, hunk in schema_findings(fd):
                rep.add("schema-%s" % kind, "schema", path, lineno,
                        [("rv", SCHEMA_RV)], raw, hunk)
    return rep, scanned


NOTE = ('note: PASS means "no textual break detected", never '
        '"non-breaking" (BC-03) — heuristic, diff-textual, python/JS/TS '
        'symbols only; semantic breaks are the model\'s job (BC-02) and '
        'a PASS never moves an item lighter (TR-09, L-04).')


def main():
    if len(sys.argv) > 1 and sys.argv[1] in ("-h", "--help"):
        sys.stdout.write(HELP)
        return 0
    if len(sys.argv) > 1:
        with open(sys.argv[1], "r", encoding="utf-8", errors="replace") as f:
            text = f.read()
    else:
        text = sys.stdin.read()
    if not text.strip():
        print("verdict: FAIL check=%s reason=empty-diff (fail-closed)"
              % CHECK)
        print(NOTE)
        return 1

    files = parse_diff(text)
    rep, scanned = analyze(files)
    ok = rep.findings == 0

    verdict = ("verdict: %s check=%s findings=%d symbols=%d config=%d "
               "routes=%d schema=%d files=%d scanned=%d"
               % ("PASS" if ok else "FAIL", CHECK, rep.findings,
                  rep.counts["symbols"], rep.counts["config"],
                  rep.counts["routes"], rep.counts["schema"],
                  rep.counts["files"], scanned))
    if not ok:
        kinds = list(rep.kinds)[:6]
        if len(rep.kinds) > 6:
            kinds.append("+%d-more" % (len(rep.kinds) - 6))
        verdict += " kinds=" + ",".join(kinds)
    print(verdict)
    print(NOTE)
    for line in rep.details[:MAX_DETAILS]:
        print(line)
    if len(rep.details) > MAX_DETAILS:
        print("break: +%d-more suppressed (evidence cap)"
              % (len(rep.details) - MAX_DETAILS))
    for line in rep.skipped:
        print(line)
    return 0 if ok else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except BrokenPipeError:
        sys.exit(1)
    except Exception as exc:  # fail closed
        print("verdict: FAIL check=%s error=%s (fail-closed)"
              % (CHECK, str(exc).replace(" ", "_")[:120]))
        sys.exit(1)
