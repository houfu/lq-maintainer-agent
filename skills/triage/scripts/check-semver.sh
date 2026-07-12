#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "verdict: FAIL check=semver-delta error=python3-missing (fail-closed)"; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
HELP = """lq-maintainer-agent -- skills/triage/scripts/check-semver.sh

Deterministic fast-lane checks 3 and 4 of design 5.1, run against a
manifest/lockfile unified diff (e.g. the output of `gh pr diff N`):

  check 3 (semver-delta): every changed dependency parses as a PATCH
    or MINOR bump on a >=1.0.0 dependency. Major bumps, pre-1.0
    dependencies, downgrades, equal versions, prerelease targets, and
    unparseable versions all FAIL.
  check 4 (new-names): NO new package name appears anywhere in the
    diff, including lockfile transitive churn -- typosquats and
    event-stream-style compromises arrive as *added* names, not bumps.

No network, no dependencies beyond python3 stdlib. The file is a
sh/python3 polyglot; run it as `sh check-semver.sh` or directly.

Usage:
  check-semver.sh [DIFF_FILE]        # default: read the diff on stdin
  gh pr diff 123 | check-semver.sh

Output (machine-parseable; the receipt renders line 1):
  line 1:  verdict: PASS|FAIL check=semver-delta pairs=N patch=N minor=N \
           new-names=N removed-names=N [reasons=...]
  then     pair: <ecosystem> <name> <old> <new> <patch|minor|FAIL:why>
           new-name: <ecosystem> <name> [<version>]
           removed-name: <ecosystem> <name>
           unrecognized-path: <path>
           unattributable: <path> <version>
  Downstream scripts (check-osv.sh, check-release-age.sh) consume the
  `pair:` lines: fields 2=ecosystem 3=name 4=old 5=new.

Exit: 0 = all checks pass; 1 = any failure, including parse/internal
errors (fail-closed: an unverifiable diff is not a merge candidate).

Fail-closed cases, by design:
  - any diff path that is not a recognized manifest/lockfile (this
    also backstops check 2, "diff touches only manifest/lockfile
    paths", which the skill verifies via the PR file list);
  - a version change that cannot be attributed to a package name from
    the hunk's context lines;
  - ambiguous multi-version churn that cannot be paired by major.

Known limitation (documented, accepted): a dependency added to
package.json with a non-semver value (git URL, workspace:*, file:) is
not parseable here; the lockfile diff -- which any real install
produces -- carries the added name and is where check 4 catches it.
The scripts never inspect package *contents*; the receipt's coverage
statement discloses that (design 5.1).
"""

import re
import sys
from collections import defaultdict

CHECK = "semver-delta"

STRUCT_KEYS = {
    "", "dependencies", "devDependencies", "peerDependencies",
    "optionalDependencies", "requires", "packages", "engines",
    "overrides", "resolutions", "funding", "bin", "scripts",
    "_meta", "default", "develop", "sources",
}
NPM_NON_DEP_KEYS = {
    "version", "name", "description", "main", "module", "types",
    "typings", "license", "type", "packageManager", "node", "npm",
    "resolved", "integrity", "tarball", "shasum", "from", "os", "cpu",
}
TOML_NON_DEP_KEYS = {
    "version", "name", "description", "python", "requires-python",
    "edition", "authors", "license", "rust-version", "readme",
    "documentation", "repository", "homepage", "content-hash",
    "python-versions", "lock-version", "requires_python", "source",
}


def classify(path):
    base = path.rsplit("/", 1)[-1]
    if base == "package.json":
        return ("npm", "npm-manifest")
    if base in ("package-lock.json", "npm-shrinkwrap.json"):
        return ("npm", "json-lock")
    if base == "Pipfile.lock":
        return ("PyPI", "json-lock")
    if base == "yarn.lock":
        return ("npm", "yarn-lock")
    if base == "pnpm-lock.yaml":
        return ("npm", "pnpm-lock")
    if re.match(r"^(requirements[^/]*|constraints[^/]*)\.txt$", base):
        return ("PyPI", "pip-req")
    if base in ("pyproject.toml", "Pipfile"):
        return ("PyPI", "toml-manifest")
    if base in ("poetry.lock", "uv.lock"):
        return ("PyPI", "toml-lock")
    if base == "Cargo.toml":
        return ("crates.io", "toml-manifest")
    if base == "Cargo.lock":
        return ("crates.io", "toml-lock")
    if base in ("go.mod", "go.sum"):
        return ("Go", "go")
    if base == "Gemfile":
        return ("RubyGems", "gem-manifest")
    if base == "Gemfile.lock":
        return ("RubyGems", "gem-lock")
    return None


VERSIONISH = re.compile(r"^[\s\^~><=v]*([0-9][0-9A-Za-z.\-+]*)")


def version_from_range(value):
    m = VERSIONISH.match(value.strip())
    return m.group(1) if m else None


class Collector(object):
    def __init__(self):
        self.old_versions = defaultdict(set)   # (eco, name) -> versions
        self.new_versions = defaultdict(set)
        self.old_names = set()                 # (eco, name) any old-side evidence
        self.new_names = set()                 # (eco, name) any new-side evidence
        self.unattributable = []               # (path, version)
        self.unrecognized = []                 # paths

    def name_evidence(self, eco, name, side):
        key = (eco, name)
        if side in ("-", " "):
            self.old_names.add(key)
        if side in ("+", " "):
            self.new_names.add(key)

    def version_evidence(self, eco, name, version, side):
        self.name_evidence(eco, name, side)
        if side == "-":
            self.old_versions[(eco, name)].add(version)
        elif side == "+":
            self.new_versions[(eco, name)].add(version)


def parse_diff(text):
    col = Collector()
    eco = fmt = cur_path = None
    minus_path = None
    ctx = {"-": None, "+": None}   # nearest attributable name per side

    def set_ctx(name, side):
        if side in ("-", " "):
            ctx["-"] = name
        if side in ("+", " "):
            ctx["+"] = name

    for raw in text.splitlines():
        if raw.startswith("--- "):
            minus_path = raw[4:].strip()
            continue
        if raw.startswith("+++ "):
            plus_path = raw[4:].strip()
            path = plus_path if plus_path != "/dev/null" else minus_path
            for prefix in ("a/", "b/"):
                if path and path.startswith(prefix):
                    path = path[2:]
            cur_path = path
            ctx["-"] = ctx["+"] = None
            kind = classify(path) if path else None
            if kind is None:
                col.unrecognized.append(path or "<unknown>")
                eco = fmt = None
            else:
                eco, fmt = kind
            continue
        if raw.startswith("@@"):
            ctx["-"] = ctx["+"] = None
            continue
        if raw.startswith(("diff ", "index ", "new file", "deleted file",
                           "similarity", "rename ", "old mode", "new mode",
                           "Binary files", "\\ No newline")):
            continue
        if fmt is None or not raw or raw[0] not in "+- ":
            continue
        side, content = raw[0], raw[1:]

        if fmt == "npm-manifest":
            m = re.match(r'^\s*"([^"]+)"\s*:\s*"([^"]*)"\s*,?\s*$', content)
            if m and m.group(1) not in NPM_NON_DEP_KEYS:
                v = version_from_range(m.group(2))
                if v:
                    col.version_evidence(eco, m.group(1), v, side)

        elif fmt == "json-lock":
            m = re.match(r'^\s*"([^"]+)"\s*:\s*\{\s*$', content)
            if m:
                raw_key = m.group(1)
                if raw_key not in STRUCT_KEYS:
                    name = raw_key.split("node_modules/")[-1]
                    col.name_evidence(eco, name, side)
                    set_ctx(name, side)
                continue
            m = re.match(r'^\s*"version"\s*:\s*"([=<>~^!]*)([0-9][^"]*)"', content)
            if m and side in ("-", "+"):
                name = ctx[side]
                if name is None:
                    col.unattributable.append((cur_path, m.group(2)))
                else:
                    col.version_evidence(eco, name, m.group(2), side)
                continue
            m = re.match(r'^\s*"([^"]+)"\s*:\s*"([^"]*)"\s*,?\s*$', content)
            if m and m.group(1) not in NPM_NON_DEP_KEYS and m.group(1) not in STRUCT_KEYS:
                if version_from_range(m.group(2)):
                    col.name_evidence(eco, m.group(1).split("node_modules/")[-1], side)

        elif fmt == "yarn-lock":
            if content and not content[0].isspace() and content.rstrip().endswith(":"):
                spec = content.split(",")[0].strip().strip('":')
                if "@" in spec[1:]:
                    name = spec[: spec.rindex("@")]
                    col.name_evidence(eco, name, side)
                    set_ctx(name, side)
                continue
            m = re.match(r'^\s+version\s+"([^"]+)"', content)
            if m and side in ("-", "+"):
                name = ctx[side]
                if name is None:
                    col.unattributable.append((cur_path, m.group(1)))
                else:
                    col.version_evidence(eco, name, m.group(1), side)

        elif fmt == "pnpm-lock":
            m = re.match(r"^\s*'?/?((?:@[^\s@'/]+/)?[^\s@'/]+)@([0-9][^:()'\s]*)", content)
            if m:
                col.version_evidence(eco, m.group(1), m.group(2), side)
                continue
            m = re.match(r"^\s+((?:@[^\s/]+/)?[A-Za-z0-9._\-]+):\s+[\^~]?([0-9][^\s()]*)", content)
            if m:
                col.version_evidence(eco, m.group(1), m.group(2), side)

        elif fmt == "pip-req":
            s = content.strip()
            if not s or s.startswith(("#", "-")):
                continue
            m = re.match(
                r"^([A-Za-z0-9][A-Za-z0-9._\-]*)(\[[^\]]*\])?\s*"
                r"(===|==|~=|>=|<=|!=|>|<)\s*([0-9][^\s;#,]*)", s)
            if m:
                name = re.sub(r"[-_.]+", "-", m.group(1).lower())
                col.version_evidence(eco, name, m.group(4), side)
                continue
            m = re.match(r"^([A-Za-z0-9][A-Za-z0-9._\-]*)(\[[^\]]*\])?\s*(;|$)", s)
            if m:
                name = re.sub(r"[-_.]+", "-", m.group(1).lower())
                col.name_evidence(eco, name, side)

        elif fmt == "toml-manifest":
            m = re.match(r'^\s*([A-Za-z0-9._\-]+)\s*=\s*(.+)$', content)
            if m and m.group(1) not in TOML_NON_DEP_KEYS:
                rhs = m.group(2).strip()
                vm = (re.match(r'^"([^"]*)"', rhs)
                      or re.search(r'version\s*=\s*"([^"]*)"', rhs))
                if vm:
                    v = version_from_range(vm.group(1))
                    if v:
                        name = m.group(1)
                        if eco == "PyPI":
                            name = re.sub(r"[-_.]+", "-", name.lower())
                        col.version_evidence(eco, name, v, side)
                continue
            m = re.match(
                r'^\s*"([A-Za-z0-9._\-]+)(\[[^\]]*\])?\s*'
                r'(===|==|~=|>=|<=|!=|>|<)\s*([0-9][^",;\s]*)', content)
            if m:
                name = re.sub(r"[-_.]+", "-", m.group(1).lower())
                col.version_evidence(eco, name, m.group(4), side)

        elif fmt == "toml-lock":
            m = re.match(r'^\s*name\s*=\s*"([^"]+)"', content)
            if m:
                name = m.group(1)
                if eco == "PyPI":
                    name = re.sub(r"[-_.]+", "-", name.lower())
                col.name_evidence(eco, name, side)
                set_ctx(name, side)
                continue
            if re.match(r"^\s*\[\[package\]\]", content):
                set_ctx(None, side)
                continue
            m = re.match(r'^\s*version\s*=\s*"([0-9][^"]*)"', content)
            if m and side in ("-", "+"):
                name = ctx[side]
                if name is None:
                    col.unattributable.append((cur_path, m.group(1)))
                else:
                    col.version_evidence(eco, name, m.group(1), side)

        elif fmt == "go":
            s = content.strip()
            if s.startswith(("//", "module ", "go ", "toolchain")):
                continue
            s = re.sub(r"^(require|replace|exclude)\s+", "", s)
            m = re.match(r"^([A-Za-z0-9.\-_~/]+\.[A-Za-z]{2}[A-Za-z0-9.\-_~/]*)\s+v([0-9][^\s]*)", s)
            if m:
                version = m.group(2)
                if version.endswith("/go.mod"):
                    version = version[: -len("/go.mod")]
                col.version_evidence(eco, m.group(1), version, side)

        elif fmt == "gem-manifest":
            m = re.match(r'^\s*gem\s+["\']([^"\']+)["\']\s*,\s*["\']([^"\']*)["\']', content)
            if m:
                v = version_from_range(m.group(2))
                if v:
                    col.version_evidence(eco, m.group(1), v, side)
                else:
                    col.name_evidence(eco, m.group(1), side)

        elif fmt == "gem-lock":
            m = re.match(r"^\s{2,}([A-Za-z0-9._\-]+)\s+\(([0-9][^)]*)\)", content)
            if m:
                col.version_evidence(eco, m.group(1), m.group(2), side)

    return col


class Ver(object):
    __slots__ = ("major", "minor", "patch", "extra", "suffix")

    def tuple(self):
        return (self.major, self.minor, self.patch, self.extra)


def parse_version(v):
    v = v.strip().lstrip("vV")
    m = re.match(r"^(\d+)(?:\.(\d+))?(?:\.(\d+))?(.*)$", v)
    if not m:
        return None
    out = Ver()
    out.major = int(m.group(1))
    out.minor = int(m.group(2) or 0)
    out.patch = int(m.group(3) or 0)
    out.extra = 0
    out.suffix = m.group(4) or ""
    em = re.match(r"^\.(\d+)$", out.suffix)
    if em:  # four-component versions (1.2.3.4) common on PyPI
        out.extra = int(em.group(1))
        out.suffix = ""
    return out


def classify_pair(old, new):
    po, pn = parse_version(old), parse_version(new)
    if po is None or pn is None:
        return "FAIL:unparseable-version"
    if pn.suffix:
        return "FAIL:prerelease-or-suffixed-target"
    if po.suffix:
        return "FAIL:bump-from-prerelease"
    if po.major < 1:
        return "FAIL:pre-1.0-dependency"
    if pn.tuple() <= po.tuple():
        return "FAIL:not-a-forward-bump"
    if pn.major != po.major:
        return "FAIL:major-bump"
    return "minor" if pn.minor != po.minor else "patch"


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
        print("verdict: FAIL check=%s reason=empty-diff" % CHECK)
        return 1

    col = parse_diff(text)
    reasons, details = [], []
    counts = {"patch": 0, "minor": 0}
    pairs = 0

    new_only = sorted(col.new_names - col.old_names)
    removed_only = sorted(col.old_names - col.new_names)
    for eco, name in new_only:
        versions = sorted(col.new_versions.get((eco, name), []))
        details.append("new-name: %s %s%s"
                       % (eco, name, (" " + versions[-1]) if versions else ""))
        reasons.append("new-name:%s/%s" % (eco, name))
    for eco, name in removed_only:
        details.append("removed-name: %s %s" % (eco, name))

    changed = sorted(set(list(col.old_versions) + list(col.new_versions)))
    for key in changed:
        eco, name = key
        if key in new_only:
            continue
        olds = col.old_versions.get(key, set())
        news = col.new_versions.get(key, set())
        news_changed = news - olds
        olds_changed = olds - news
        if not news_changed and not olds_changed:
            continue
        if not olds_changed and news_changed:
            # versions appeared for a name that already existed
            # (e.g. a lockfile dedup added a second copy): fail closed
            reasons.append("added-version-no-old:%s/%s" % (eco, name))
            details.append("pair: %s %s ? %s FAIL:no-old-version"
                           % (eco, name, sorted(news_changed)[-1]))
            pairs += 1
            continue
        if not news_changed and olds_changed:
            # a version disappeared without replacement; the name
            # survives elsewhere in the tree -- dedup churn, no bump
            continue
        if len(olds_changed) == 1 and len(news_changed) == 1:
            old_v, new_v = next(iter(olds_changed)), next(iter(news_changed))
            outcome = classify_pair(old_v, new_v)
            pairs += 1
            details.append("pair: %s %s %s %s %s" % (eco, name, old_v, new_v, outcome))
            if outcome in ("patch", "minor"):
                counts[outcome] += 1
            else:
                reasons.append("%s:%s/%s@%s->%s"
                               % (outcome[5:], eco, name, old_v, new_v))
            continue
        # multiple versions of one name changed (lockfile dedup trees):
        # pair by major; anything that will not pair fails closed
        by_major_old = defaultdict(list)
        by_major_new = defaultdict(list)
        for v in olds_changed:
            p = parse_version(v)
            by_major_old[p.major if p else -1].append(v)
        for v in news_changed:
            p = parse_version(v)
            by_major_new[p.major if p else -1].append(v)
        if sorted(by_major_old) != sorted(by_major_new):
            reasons.append("ambiguous-version-churn:%s/%s" % (eco, name))
            details.append("pair: %s %s %s %s FAIL:ambiguous-churn"
                           % (eco, name, ",".join(sorted(olds_changed)),
                          ",".join(sorted(news_changed))))
            pairs += 1
            continue
        def vkey(v):
            p = parse_version(v)
            return p.tuple() if p else (-1, -1, -1, -1)

        for major in sorted(by_major_old):
            old_v = sorted(by_major_old[major], key=vkey)[-1]
            new_v = sorted(by_major_new[major], key=vkey)[-1]
            outcome = classify_pair(old_v, new_v)
            pairs += 1
            details.append("pair: %s %s %s %s %s" % (eco, name, old_v, new_v, outcome))
            if outcome in ("patch", "minor"):
                counts[outcome] += 1
            else:
                reasons.append("%s:%s/%s@%s->%s"
                               % (outcome[5:], eco, name, old_v, new_v))

    for path in col.unrecognized:
        details.append("unrecognized-path: %s" % path)
        reasons.append("unrecognized-path:%s" % path)
    for path, version in col.unattributable:
        details.append("unattributable: %s %s" % (path, version))
        reasons.append("unattributable-version:%s" % path)
    if pairs == 0 and not new_only and not reasons:
        reasons.append("no-dependency-changes-found")

    ok = not reasons
    verdict = ("verdict: %s check=%s pairs=%d patch=%d minor=%d "
               "new-names=%d removed-names=%d"
               % ("PASS" if ok else "FAIL", CHECK, pairs, counts["patch"],
                  counts["minor"], len(new_only), len(removed_only)))
    if not ok:
        shown = reasons[:6]
        if len(reasons) > 6:
            shown.append("+%d-more" % (len(reasons) - 6))
        verdict += " reasons=" + ",".join(shown)
    print(verdict)
    for line in details:
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
