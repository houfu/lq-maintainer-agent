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
import tempfile

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


def run(md, extra_env=None, args=None):
    """Render md through the real script as a subprocess; return (rc, stdout)."""
    env = dict(os.environ)
    env["CLAUDE_PLUGIN_ROOT"] = ROOT  # so glossary + canon:repo base load
    if extra_env:
        env.update(extra_env)
    p = subprocess.run([sys.executable, RENDER] + list(args or []), input=md,
                       env=env, capture_output=True, text=True)
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

# v2 receipts — the decision_scoping block (rules/decision-scoping.md D-12).
PR_ESCALATE_V2 = PR_BLOCKED.replace(
    "lq-maintainer-agent:receipt:v1", "lq-maintainer-agent:receipt:v2"
).replace(
    "  scope: high\n  review: high\n  tests: high\n  carry: high\n  safety: high\n",
    "  scope: high\n  review: high\n  tests: high\n  carry: high\n  safety: high\n"
    "decision_scoping:\n  applied: full\n  questions: 1\n  settled: 1\n"
    "  residual: 1\n  reserved_human: 0\n  residuals:\n"
    "    - {id: R-1, kind: structural, artifact: adr-draft}\n"
)

PR_CLEAN_V2 = (
    "## Triage Receipt — PR #903: clean standard item\n"
    "**Recommended lane:** standard (confidence: high; assigning rule: L-30)\n"
    "<!-- lq-maintainer-agent:receipt:v2\n"
    "profile: pr\nitem: legalquants/lq-ai#903\nlane: standard\n"
    "assigning_rule: L-30\nconfidence: high\ntriggers: []\nheld: false\n"
    + (FOOTER_PINNED % {"sha": "abc123def456"}) +
    "findings: []\nfindings_filtered: 0\n"
    "coverage:\n  - {item: runtime-behavior, status: never-by-design}\n"
    "decision_scoping:\n  applied: n-a\n"
    "-->\n"
)

ISSUE_ESCALATE_V2 = ISSUE_ESCALATE.replace(
    "lq-maintainer-agent:receipt:v1", "lq-maintainer-agent:receipt:v2"
).replace(
    "findings: []\nfindings_filtered: 0\n",
    "findings: []\nfindings_filtered: 0\n"
    "decision_scoping:\n  applied: partial\n  questions: 1\n  settled: 0\n"
    "  residual: 1\n  reserved_human: 0\n  residuals:\n"
    "    - {id: R-1, kind: forward-looking, artifact: de-stub}\n"
)

# Deep-dive cache report carrying a '### Below threshold' section (deck-only
# enrichment, skills/review-pr/SKILL.md Step 5). Includes an adversarial link:
# the link allow-list must hold in this section too.
REPORT_BELOW = (
    "# Long-form report — PR #900\n"
    "### Findings\n"
    "**F-1 — major** — the receipt-visible finding.\n"
    "### Below threshold\n"
    "- `gateway/app/client.py:44` — naming could match the module convention "
    "(code-quality pass, low confidence)\n"
    "- `docs/x.md:9` — see [ref](https://github.com/LegalQuants/lq-ai/issues/12) "
    "and [bad](https://evil.example.com/p) (anchor pass, low confidence)\n"
    "### Coverage notes\n"
    "- not part of the below-threshold section\n"
)

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

    # --- unit: render_linked must never lose text (regression: dropped tail /
    # empty output for link-free lines silently gutted the grounding cards) ---
    html_out, _ = mod.render_linked(
        "lead [ok](%sissues/9)). The tail after the last link survives." % base, base)
    check("render_linked: tail after last link kept",
          "The tail after the last link survives." in html_out, html_out)
    html_out, _ = mod.render_linked("no links at all — plain analysis text.", base)
    check("render_linked: link-free line kept verbatim",
          "no links at all — plain analysis text." in html_out, html_out)

    # --- unit: grounding card keeps intro, bucket text, and nested entries ---
    gmd = ("### References (IV-03)\n\n"
           "Searched **by the agent** (not the filer's claim).\n\n"
           "- **Duplicate:** none — no open issue proposes this.\n"
           "- **Adjacent:**\n"
           "  - [#287](https://github.com/LegalQuants/lq-ai/issues/287) — research-surface pressure.\n")
    ghtml = mod.render_grounding_card(gmd, base, r"References", "g-ref", "References")
    check("grounding: intro text kept", "Searched" in ghtml)
    check("grounding: bucket-line text kept", "none — no open issue proposes this." in ghtml)
    check("grounding: nested entry text kept", "research-surface pressure." in ghtml)

    # --- unit: CSS content glyphs are real escapes, not python-octal mangling ---
    import re as _re
    glyphs = dict((m.group(1), m.group(2)) for m in _re.finditer(
        r'grounding\.g-(ref|obs) li::before\{content:"([^"]*)"', mod.CSS))
    check("css: grounding glyphs are CSS escapes",
          glyphs.get("ref") == "\\2192" and glyphs.get("obs") == "\\25B8",
          repr(glyphs))

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
    check("PR v1: no Decisions-to-make panel (absent block == n-a)",
          "Decisions to make" not in out)

    # --- e2e: v2 decision-scoping panel (D-13) ---
    rc, out = run(PR_ESCALATE_V2)
    check("PR v2 escalate: exit 0", rc == 0, "rc=%d" % rc)
    check("PR v2 escalate: Decisions-to-make panel present", "Decisions to make" in out)
    check("PR v2 escalate: counts headline",
          "1 decisions to make" in out and "1 found settled" in out)
    check("PR v2 escalate: residual row with id", "R-1" in out)
    rc, out = run(PR_CLEAN_V2)
    check("PR v2 clean: exit 0", rc == 0, "rc=%d" % rc)
    check("PR v2 clean: no Decisions-to-make panel (D-00/RP-17)",
          "Decisions to make" not in out)
    rc, out = run(ISSUE_ESCALATE_V2)
    check("issue v2 escalate: exit 0", rc == 0, "rc=%d" % rc)
    check("issue v2 escalate: panel present", "Decisions to make" in out)
    check("issue v2 escalate: partial surfaced", "partial" in out)

    # --- e2e: below-threshold card (deck-only, from the cache report) ---
    check("PR without report arg: no below-threshold card",
          "Below threshold" not in run(PR_BLOCKED)[1])
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as tf:
        tf.write(REPORT_BELOW)
        report_path = tf.name
    try:
        rc, out = run(PR_BLOCKED, args=[report_path])
        check("PR with report: exit 0", rc == 0, "rc=%d" % rc)
        check("PR with report: below-threshold card present",
              "Below threshold — low-confidence notes" in out)
        check("PR with report: both bullets rendered, section-bounded",
              out.count('class="ci c-na"') == 2
              and "not part of the below-threshold section" not in out,
              "count=%d" % out.count('class="ci c-na"'))
        check("PR with report: marked deck-only", "deck only" in out)
        check("PR with report: allowed link emitted",
              'href="https://github.com/LegalQuants/lq-ai/issues/12"' in out)
        check("PR with report: evil URL in report NOT a live link",
              'href="https://evil' not in out)
    finally:
        os.unlink(report_path)
    rc, out = run(PR_BLOCKED, args=["/nonexistent/report.md"])
    check("PR with missing report: fail-open exit 0, no card",
          rc == 0 and "Below threshold" not in out, "rc=%d" % rc)

    # --- e2e: issue escalate deck ---
    rc, out = run(ISSUE_ESCALATE)
    check("issue: exit 0", rc == 0, "rc=%d" % rc)
    check("issue: Escalate headline",
          "Escalate — a named set of decisions needs more than one person" in out)
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
