#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "test-render-deck: python3 not found on PATH." >&2; exit 2; } # '''
''''exec python3 "$0" "$@" # '''
"""test-render-deck.sh — unit + adversarial tests for the reading-deck renderer.

Guards the two properties a deterministic, no-network deck renderer must never
regress (design doc §8.6/§8.6a, rules/canon-map.md link rule,
rules/injection-posture.md):

  1. It renders BOTH profiles from a receipt:v1 footer — the PR burden deck and
     the issue recommendation deck — and fails closed on a missing/bad footer.
  2. Click-through links are emitted ONLY for allow-listed, agent-constructable
     targets; a URL that reached the receipt body from contributor text is
     dropped to inert label text, never a live href.

Pure stdlib, no tokens, no canon clone, no network — safe as a blocking CI
check. Run from anywhere: `sh ci/scripts/test-render-deck.sh` or directly.
The file is a sh/python3 polyglot (repo convention); do not lint with `sh -n`.
"""

import importlib.machinery
import importlib.util
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
RENDER = os.path.join(ROOT, "skills", "triage", "scripts", "render-deck.sh")

_fail = []
_count = 0


def check(name, cond, detail=""):
    global _count
    _count += 1
    if cond:
        print("  ok   %s" % name)
    else:
        print("  FAIL %s%s" % (name, (" — " + detail) if detail else ""))
        _fail.append(name)


def run(md, extra_env=None):
    """Render md through the real script as a subprocess; return (rc, stdout)."""
    env = dict(os.environ)
    env["CLAUDE_PLUGIN_ROOT"] = ROOT  # so glossary + canon:repo base load
    if extra_env:
        env.update(extra_env)
    p = subprocess.run([sys.executable, RENDER], input=md, env=env,
                       capture_output=True, text=True)
    return p.returncode, p.stdout


def load_module():
    # render-deck.sh is a valid-Python polyglot, but the .sh extension blocks
    # loader inference — name the SourceFileLoader explicitly.
    loader = importlib.machinery.SourceFileLoader("render_deck", RENDER)
    spec = importlib.util.spec_from_loader("render_deck", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)  # __name__ != __main__, so main() does not run
    return mod


# --------------------------------------------------------------------------
# Fixtures — minimal but valid receipt:v1 documents.
# --------------------------------------------------------------------------

FOOTER_PINNED = (
    "pinned:\n"
    "  pr_head_sha: %(sha)s\n"
    "  canon_sha: unread-no-clone\n"
    "  agent_version: 0.2.0\n"
    "  model_id: test\n"
)

PR_BLOCKED = (
    "## Triage Receipt — PR #900: test primitives\n"
    "**Recommended lane:** escalate (confidence: high; assigning rule: E-10)\n"
    "### References (RP-15)\n"
    "- **Linked:** [ADR 0022](https://github.com/LegalQuants/lq-ai/blob/main/docs/adr/0022-x.md)\n"
    "### Findings\n"
    "**F-1 — major** — `CLAUDE.md` agent-instruction file changed; see "
    "[evil](https://evil.example.com/x) and [issue](https://github.com/LegalQuants/lq-ai/issues/7).\n"
    "<!-- lq-maintainer-agent:receipt:v1\n"
    "profile: pr\nitem: legalquants/lq-ai#900\nlane: escalate\n"
    "assigning_rule: E-10\nconfidence: high\ntriggers: [E-10]\nheld: false\n"
    + (FOOTER_PINNED % {"sha": "abc123def456"}) +
    "deterministic_checks:\n"
    "  author_identity: n-a\n  manifest_only: n-a\n  semver_delta: n-a\n"
    "  no_new_packages: n-a\n  osv_lookup: n-a\n  release_age: n-a\n  ci_green: n-a\n"
    "findings:\n  - {id: F-1, severity: major, disposition: structural}\n"
    "findings_filtered: 0\n"
    "coverage:\n"
    "  - {item: code-quality, status: not-covered}\n"
    "  - {item: runtime-behavior, status: never-by-design}\n"
    "burden:\n  overall: blocked\n  blockers: [attack-escalation, ci-red]\n"
    "  scope: high\n  review: high\n  tests: high\n  carry: high\n  safety: high\n"
    "-->\n"
)

ISSUE_ESCALATE = (
    "## Triage Receipt — issue #901: proposal test\n"
    "**Recommendation:** Escalate (rule: IV-01) — scope decision.\n"
    "**Classification:** feature (rule: C-02) · **Lane:** escalate\n"
    "### Predicted obstacles — if this became a PR (IV-02)\n"
    "- Contradicts [canon:prd §1.6](https://github.com/LegalQuants/lq-ai/blob/main/docs/PRD.md#16-out-of-scope-v1) (E-04).\n"
    "### References (IV-03)\n"
    "- **Contradicting:** [canon:prd §1.6](https://github.com/LegalQuants/lq-ai/blob/main/docs/PRD.md#16-out-of-scope-v1) excludes it.\n"
    "- **Linked:** [nope](https://evil.example.com/steal) and [ok](https://github.com/LegalQuants/lq-ai/issues/5).\n"
    "<!-- lq-maintainer-agent:receipt:v1\n"
    "profile: issue\nitem: legalquants/lq-ai#901\nlane: escalate\n"
    "assigning_rule: E-04\nclassification: feature\nclassification_rule: C-02\n"
    "recommendation: escalate\nheld: false\n"
    + (FOOTER_PINNED % {"sha": "n-a"}) +
    "findings: []\nfindings_filtered: 0\n"
    "coverage:\n"
    "  - {item: anchor, status: not-covered}\n"
    "  - {item: runtime-behavior, status: never-by-design}\n"
    "-->\n"
)

ISSUE_DECOMPOSE = ISSUE_ESCALATE.replace(
    "recommendation: escalate", "recommendation: decompose"
).replace("**Recommendation:** Escalate", "**Recommendation:** Decompose")

HIDDEN_TITLE = (
    "## Triage Receipt — issue #902: clean​title‮here\n"
    "**Recommendation:** Proceed (rule: IV-01)\n"
    "<!-- lq-maintainer-agent:receipt:v1\n"
    "profile: issue\nitem: legalquants/lq-ai#902\nlane: standard\n"
    "assigning_rule: L-30\nclassification: feature\nclassification_rule: C-02\n"
    "recommendation: proceed\nheld: false\n"
    + (FOOTER_PINNED % {"sha": "n-a"}) +
    "findings: []\nfindings_filtered: 0\n"
    "coverage:\n  - {item: runtime-behavior, status: never-by-design}\n"
    "-->\n"
)


# --------------------------------------------------------------------------
def main():
    print("render-deck renderer tests")
    print("root:", ROOT)

    mod = load_module()
    base = mod.repo_base()
    check("repo_base resolves canon:repo web base",
          base.startswith("https://github.com/") and "lq-ai" in base, base)

    # --- unit: URL allow-list ---
    check("allow: under canon:repo base",
          mod._url_allowed(base + "blob/main/docs/PRD.md", base))
    check("allow: github issues on any owner/repo",
          mod._url_allowed("https://github.com/o/r/issues/1", base))
    check("allow: github blob on any owner/repo",
          mod._url_allowed("https://github.com/o/r/blob/main/x.md", base))
    check("deny: off-host URL", not mod._url_allowed("https://evil.example.com/x", base))
    check("deny: javascript scheme", not mod._url_allowed("javascript:alert(1)", base))
    check("deny: non-https github", not mod._url_allowed("http://github.com/o/r/issues/1", base))
    check("deny: github non-item path", not mod._url_allowed("https://github.com/o/r/settings", base))

    # --- unit: render_linked drops disallowed link to label, keeps allowed ---
    html_out, _ = mod.render_linked(
        "see [bad](https://evil.example.com/x) and [good](%sissues/9)" % base, base)
    check("render_linked: disallowed -> inert label (no evil href)",
          "href=\"https://evil" not in html_out and ">bad<" not in html_out
          and "bad" in html_out)
    check("render_linked: allowed -> anchor",
          "<a href=\"%sissues/9\">good</a>" % base in html_out)

    # --- e2e: PR blocked deck ---
    rc, out = run(PR_BLOCKED)
    check("PR: exit 0", rc == 0, "rc=%d" % rc)
    check("PR: headline Blocked", "Blocked — resolve first" in out)
    check("PR: five high axis tiles", out.count('class="tile t-bad"') == 5,
          "count=%d" % out.count('class="tile t-bad"'))
    check("PR: References grounding card present", 'grounding g-ref' in out)
    check("PR: allowed ADR link emitted",
          'href="https://github.com/LegalQuants/lq-ai/blob/main/docs/adr/0022-x.md"' in out)
    check("PR: contributor evil URL NOT a live link", 'href="https://evil' not in out)
    check("PR: allowed issue link in finding emitted",
          'href="https://github.com/LegalQuants/lq-ai/issues/7"' in out)
    check("PR: coverage distinguishes never vs not-yet",
          "Never checked" in out and "Not yet — resumable" in out)

    # --- e2e: issue escalate deck ---
    rc, out = run(ISSUE_ESCALATE)
    check("issue: exit 0", rc == 0, "rc=%d" % rc)
    check("issue: Escalate headline", "Escalate — take this to a meeting" in out)
    check("issue: obstacles + references cards", 'grounding g-obs' in out and 'grounding g-ref' in out)
    check("issue: NO burden tiles element", '<div class="tiles' not in out)
    check("issue: NO safety-gate element", 'Safety gate</span>' not in out and '<div class="meter"' not in out)
    check("issue: evil URL inert", 'href="https://evil' not in out)
    check("issue: allowed issue link emitted",
          'href="https://github.com/LegalQuants/lq-ai/issues/5"' in out)
    check("issue: next-step derived from recommendation", "committee / roadmap agenda" in out)

    # --- e2e: issue decompose deck ---
    rc, out = run(ISSUE_DECOMPOSE)
    check("issue decompose: headline", "Decompose into smaller issues" in out)
    check("issue decompose: warn state", 'verdict s-warn' in out)

    # --- e2e: hidden-character title is stripped + flagged ---
    rc, out = run(HIDDEN_TITLE)
    check("hidden-title: zero-width char removed from output", "​" not in out)
    check("hidden-title: flagged to reviewer", "Hidden characters were found" in out)

    # --- e2e: fail-closed ---
    rc, out = run("")
    check("empty stdin: exit 1", rc == 1, "rc=%d" % rc)
    check("empty stdin: error page", "No receipt was provided" in out)
    rc, out = run("just some text, no footer at all\n")
    check("no footer: exit 1", rc == 1, "rc=%d" % rc)
    check("no footer: error page", "Could not render the deck" in out)

    print("\n%d checks, %d failed" % (_count, len(_fail)))
    if _fail:
        for n in _fail:
            print("  FAILED:", n)
        return 1
    print("all renderer tests passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
