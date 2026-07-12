#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "verdict: FAIL check=osv error=python3-missing (fail-closed)"; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
HELP = """lq-maintainer-agent -- skills/triage/scripts/check-osv.sh

Deterministic fast-lane check 5 of design 5.1: every changed
name+version pair must clear an OSV batch lookup (MAL-/CVE/GHSA
advisories). Single unauthenticated POST to the public OSV API --
https://api.osv.dev/v1/querybatch -- which is compatible with the
agent's read-only posture (design 10: the check scripts are the only
network the triage skill touches, OSV and registry endpoints only).

No dependencies beyond python3 stdlib. sh/python3 polyglot; run as
`sh check-osv.sh` or directly.

Usage:
  check-osv.sh ECOSYSTEM:NAME@VERSION [ECOSYSTEM:NAME@VERSION ...]
  check-semver.sh pr.diff | check-osv.sh      # consumes `pair:` lines
  check-osv.sh --pairs pairs.txt              # file of `pair:` lines

Accepted ecosystems (OSV names; case-insensitive aliases in parens):
  npm, PyPI (pypi), Go (go), crates.io (cargo, crates), RubyGems
  (rubygems, gem).

Output (machine-parseable; the receipt renders line 1):
  line 1:  verdict: PASS|FAIL check=osv packages=N advisories=N [...]
  then     advisory: <ecosystem> <name> <version> <id[,id...]>
           checked: <ecosystem> <name> <version> clean

Exit: 0 = no advisories for any pair; 1 = any advisory found, or any
input/network error (fail-closed: an unverifiable package is not a
merge candidate). A `MAL-` id means OSV's malicious-package corpus
matched -- treat as disqualifying, not as a judgment call.
"""

import json
import os
import re
import shutil
import ssl
import subprocess
import sys
import urllib.error
import urllib.request

CHECK = "osv"
ENDPOINT = "https://api.osv.dev/v1/querybatch"
BATCH = 500
TIMEOUT = 30
USER_AGENT = "lq-maintainer-agent-check-osv (+https://github.com/legalquants/lq-maintainer-agent)"

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


def http_json(url, body=None, headers=None):
    headers = dict(headers or {})
    headers.setdefault("User-Agent", USER_AGENT)
    last_ssl_error = None
    for ctx in _tls_contexts():
        req = urllib.request.Request(url, data=body, headers=headers)
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
        if body is not None:
            cmd += ["-X", "POST", "--data-binary", "@-"]
        cmd.append(url)
        proc = subprocess.run(cmd, input=body, capture_output=True)
        if proc.returncode != 0:
            raise RuntimeError("curl-fallback-failed:%s"
                               % proc.stderr.decode("utf-8", "replace").strip()[:80])
        return json.loads(proc.stdout.decode("utf-8"))
    raise last_ssl_error or RuntimeError("no-usable-tls-trust-store")

ECOSYSTEMS = {
    "npm": "npm",
    "pypi": "PyPI",
    "go": "Go",
    "crates.io": "crates.io",
    "cargo": "crates.io",
    "crates": "crates.io",
    "rubygems": "RubyGems",
    "gem": "RubyGems",
}


def fail(reason):
    print("verdict: FAIL check=%s %s" % (CHECK, reason))
    sys.exit(1)


def normalize_ecosystem(raw):
    eco = ECOSYSTEMS.get(raw.strip().lower())
    if eco is None:
        fail("error=unknown-ecosystem:%s" % raw)
    return eco


def parse_arg(arg):
    m = re.match(r"^([^:]+):(.+)@([^@]+)$", arg)
    if not m:
        fail("error=bad-argument:%s(want=ECOSYSTEM:NAME@VERSION)"
             % arg.replace(" ", "_"))
    return (normalize_ecosystem(m.group(1)), m.group(2), m.group(3))


def parse_pair_lines(lines):
    pairs = []
    for line in lines:
        parts = line.split()
        if len(parts) >= 5 and parts[0] == "pair:":
            # check-semver.sh format: pair: <eco> <name> <old> <new> [outcome]
            pairs.append((normalize_ecosystem(parts[1]), parts[2], parts[4]))
    return pairs


def clean_version(eco, version):
    version = version.strip()
    if eco == "Go":
        version = version.lstrip("vV")
    return version


def query(pairs):
    findings = []
    for start in range(0, len(pairs), BATCH):
        chunk = pairs[start:start + BATCH]
        body = json.dumps({
            "queries": [
                {"package": {"name": name, "ecosystem": eco},
                 "version": clean_version(eco, version)}
                for eco, name, version in chunk
            ]
        }).encode("utf-8")
        try:
            data = http_json(ENDPOINT, body=body,
                             headers={"Content-Type": "application/json"})
        except Exception as exc:
            fail("error=network:%s" % str(exc).replace(" ", "_")[:120])
        results = data.get("results")
        if not isinstance(results, list) or len(results) != len(chunk):
            fail("error=malformed-osv-response")
        for pair, result in zip(chunk, results):
            vulns = (result or {}).get("vulns") or []
            ids = [v.get("id", "?") for v in vulns]
            if (result or {}).get("next_page_token"):
                ids.append("+more-paginated")
            findings.append((pair, ids))
    return findings


def main():
    args = sys.argv[1:]
    if args and args[0] in ("-h", "--help"):
        sys.stdout.write(HELP)
        return 0
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

    findings = query(pairs)
    details, advisories = [], 0
    for (eco, name, version), ids in findings:
        if ids:
            advisories += 1
            details.append("advisory: %s %s %s %s"
                           % (eco, name, version, ",".join(ids[:10])))
        else:
            details.append("checked: %s %s %s clean" % (eco, name, version))

    ok = advisories == 0
    verdict = ("verdict: %s check=%s packages=%d advisories=%d"
               % ("PASS" if ok else "FAIL", CHECK, len(pairs), advisories))
    if not ok:
        hit = [d.split()[2] for d in details if d.startswith("advisory:")]
        verdict += " packages-hit=" + ",".join(hit[:6])
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
