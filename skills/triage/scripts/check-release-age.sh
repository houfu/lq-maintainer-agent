#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "verdict: FAIL check=release-age error=python3-missing (fail-closed)"; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
HELP = """lq-maintainer-agent -- skills/triage/scripts/check-release-age.sh

Deterministic fast-lane check 6 of design 5.1: the release-age
cooldown. The registry publish timestamp of every target version must
be at least 7 days old (--min-days to override -- raising it is fine;
lowering it below 7 needs a rules change, not a flag). Malicious
releases are typically pulled within 24-72 hours; this is the control
that would have screened the 2025 axios incident had anyone run it.

Supported registries, per the design: npm (registry.npmjs.org) and
PyPI (pypi.org). Anything else FAILS as unsupported -- fail-closed: a
bump whose age cannot be verified is not a fast-lane merge candidate.
Unauthenticated GETs only (design 10). python3 stdlib only;
sh/python3 polyglot -- run as `sh check-release-age.sh` or directly.

Usage:
  check-release-age.sh [--min-days N] ECOSYSTEM:NAME@VERSION [...]
  check-semver.sh pr.diff | check-release-age.sh   # consumes `pair:` lines
  check-release-age.sh --pairs pairs.txt

Output (machine-parseable; the receipt renders line 1):
  line 1:  verdict: PASS|FAIL check=release-age packages=N min-days=N [...]
  then     age: <ecosystem> <name> <version> published=<iso> age-days=<n> <PASS|FAIL>

Exit: 0 = every package is old enough; 1 = any package younger than
the cooldown, unsupported, missing from the registry, or any network
error (fail-closed).
"""

import json
import os
import re
import shutil
import ssl
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

CHECK = "release-age"
DEFAULT_MIN_DAYS = 7
TIMEOUT = 30
USER_AGENT = "lq-maintainer-agent-check-release-age (+https://github.com/legalquants/lq-maintainer-agent)"

# TLS verification is NEVER disabled. Some python3 installs (notably
# python.org builds on macOS) ship without a wired-up trust store; try
# the default store, then well-known OS CA bundles, then curl (which
# uses the operating-system trust store).
CA_BUNDLE_CANDIDATES = [
    "/etc/ssl/cert.pem",
    "/etc/ssl/certs/ca-certificates.crt",
    "/etc/pki/tls/certs/ca-bundle.crt",
    "/etc/ssl/ca-bundle.pem",
]


def _tls_contexts():
    try:
        ctx = ssl.create_default_context()
        if ctx.cert_store_stats().get("x509_ca", 0) > 0:
            yield ctx
    except Exception:
        pass
    for path in CA_BUNDLE_CANDIDATES:
        if os.path.exists(path):
            try:
                yield ssl.create_default_context(cafile=path)
            except Exception:
                continue


def http_json(url, headers=None):
    headers = dict(headers or {})
    headers.setdefault("User-Agent", USER_AGENT)
    last_ssl_error = None
    for ctx in _tls_contexts():
        req = urllib.request.Request(url, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError:
            raise  # a real server response; not a trust-store problem
        except (ssl.SSLError, urllib.error.URLError) as exc:
            reason = getattr(exc, "reason", exc)
            if isinstance(exc, ssl.SSLError) or isinstance(reason, ssl.SSLError):
                last_ssl_error = exc
                continue
            raise
    if shutil.which("curl"):
        cmd = ["curl", "-fsS", "--max-time", str(TIMEOUT)]
        for key, value in headers.items():
            cmd += ["-H", "%s: %s" % (key, value)]
        cmd.append(url)
        proc = subprocess.run(cmd, capture_output=True)
        if proc.returncode != 0:
            raise RuntimeError("curl-fallback-failed:%s"
                               % proc.stderr.decode("utf-8", "replace").strip()[:80])
        return json.loads(proc.stdout.decode("utf-8"))
    raise last_ssl_error or RuntimeError("no-usable-tls-trust-store")

ECOSYSTEMS = {"npm": "npm", "pypi": "PyPI"}


def fail(reason):
    print("verdict: FAIL check=%s %s" % (CHECK, reason))
    sys.exit(1)


def parse_arg(arg):
    m = re.match(r"^([^:]+):(.+)@([^@]+)$", arg)
    if not m:
        fail("error=bad-argument:%s(want=ECOSYSTEM:NAME@VERSION)"
             % arg.replace(" ", "_"))
    return (m.group(1).strip(), m.group(2), m.group(3))


def parse_pair_lines(lines):
    pairs = []
    for line in lines:
        parts = line.split()
        if len(parts) >= 5 and parts[0] == "pair:":
            pairs.append((parts[1], parts[2], parts[4]))
    return pairs


def get_json(url):
    return http_json(url, headers={"Accept": "application/json"})


def parse_iso(ts):
    ts = ts.strip()
    if ts.endswith("Z"):
        ts = ts[:-1] + "+00:00"
    dt = datetime.fromisoformat(ts)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def published_at(eco_raw, name, version):
    """Return (iso-timestamp, error) -- exactly one is None."""
    eco = ECOSYSTEMS.get(eco_raw.lower())
    if eco is None:
        return None, "unsupported-ecosystem:%s(npm+PyPI-only)" % eco_raw
    try:
        if eco == "npm":
            url = ("https://registry.npmjs.org/"
                   + urllib.parse.quote(name, safe="@"))
            data = get_json(url)
            ts = (data.get("time") or {}).get(version)
            if not ts:
                return None, "version-not-in-registry"
            return ts, None
        # PyPI
        url = ("https://pypi.org/pypi/%s/%s/json"
               % (urllib.parse.quote(name, safe=""), urllib.parse.quote(version, safe="")))
        data = get_json(url)
        uploads = [f.get("upload_time_iso_8601")
                   for f in (data.get("urls") or []) if f.get("upload_time_iso_8601")]
        if not uploads:
            return None, "no-release-files-in-registry"
        return min(uploads), None
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            return None, "not-found-in-registry"
        return None, "http-%d" % exc.code
    except Exception as exc:
        return None, "network:%s" % str(exc).replace(" ", "_")[:100]


def main():
    args = sys.argv[1:]
    if args and args[0] in ("-h", "--help"):
        sys.stdout.write(HELP)
        return 0
    min_days = DEFAULT_MIN_DAYS
    if args and args[0] == "--min-days":
        if len(args) < 2 or not args[1].isdigit():
            fail("error=bad-min-days")
        min_days = int(args[1])
        args = args[2:]
    if args and args[0] == "--pairs":
        if len(args) < 2:
            fail("error=missing-pairs-file")
        with open(args[1], "r", encoding="utf-8") as f:
            pairs = parse_pair_lines(f.readlines())
    elif args:
        pairs = [parse_arg(a) for a in args]
    else:
        pairs = parse_pair_lines(sys.stdin.readlines())
    if not pairs:
        fail("error=no-packages-given")  # nothing to verify is not a pass

    now = datetime.now(timezone.utc)
    details, too_young, errors = [], [], []
    for eco_raw, name, version in pairs:
        ts, err = published_at(eco_raw, name, version)
        if err:
            errors.append("%s/%s@%s:%s" % (eco_raw, name, version, err))
            details.append("age: %s %s %s published=? age-days=? FAIL(%s)"
                           % (eco_raw, name, version, err))
            continue
        try:
            age_days = int((now - parse_iso(ts)).total_seconds() // 86400)
        except Exception:
            errors.append("%s/%s@%s:unparseable-timestamp" % (eco_raw, name, version))
            details.append("age: %s %s %s published=%s age-days=? FAIL(unparseable-timestamp)"
                           % (eco_raw, name, version, ts))
            continue
        ok = age_days >= min_days
        details.append("age: %s %s %s published=%s age-days=%d %s"
                       % (eco_raw, name, version, ts, age_days,
                          "PASS" if ok else "FAIL"))
        if not ok:
            too_young.append("%s/%s@%s:%dd" % (eco_raw, name, version, age_days))

    ok = not too_young and not errors
    verdict = ("verdict: %s check=%s packages=%d min-days=%d too-young=%d errors=%d"
               % ("PASS" if ok else "FAIL", CHECK, len(pairs), min_days,
                  len(too_young), len(errors)))
    if too_young:
        verdict += " young=" + ",".join(too_young[:6])
    if errors:
        verdict += " error-detail=" + ",".join(errors[:4])
    print(verdict)
    for line in details:
        print(line)
    return 0 if ok else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SystemExit:
        raise
    except Exception as exc:  # fail closed
        print("verdict: FAIL check=%s error=%s (fail-closed)"
              % (CHECK, str(exc).replace(" ", "_")[:120]))
        sys.exit(1)
