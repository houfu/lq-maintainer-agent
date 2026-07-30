#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "test-render-deck: python3 not found on PATH." >&2; exit 2; } # '''
''''exec python3 "$0" "$@" # '''
"""test-render-deck.sh — unit + adversarial tests for the reading-deck renderer.

Guards the properties a deterministic, no-network deck renderer must never
regress (design doc §8.6/§8.6a and v0.7 §7/§8, rules/canon-map.md link rule,
rules/injection-posture.md):

  1. It renders every profile a footer can carry — the PR burden deck, the
     issue recommendation deck, and (v0.7) the `profile: plan` design deck —
     and fails closed on a missing/bad footer.
  2. Click-through links are emitted ONLY for allow-listed, agent-constructable
     targets; a URL that reached the receipt body from contributor text is
     dropped to inert label text, never a live href.
  3. The v0.7 fields are additive: a footer carrying `outcome` renders the
     action-first hero with its undo line and demotes the burden axes to the
     auditor section; a footer WITHOUT them renders the v0.6 burden-led hero
     unchanged; an unrecognised enum value degrades to raw text instead of
     crashing or fabricating a gloss.
  4. The embedded-draft sections (decided 2026-07-26: the deck carries the
     drafted public comment / merge message and the recorded maintainer
     decision) render as cards when present, survive a `---` divider inside
     the fenced draft, keep the link allow-list, and are ABSENT — not
     empty — on every receipt written before the sections existed.

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

# v0.7 (design v0.7 §7/§8): the four optional enumerated fields on a v2 footer.
# A category-2, tier-1 quick pass ending in `merge-after` with a clean undo —
# the action-first hero path. Carries an off-host link in a finding so the
# allow-list is exercised on this path too, not only the legacy one.
PR_TIER1_V2 = (
    "## Triage Receipt — PR #904: pin the request timeout default\n"
    "**Recommended lane:** standard (confidence: high; assigning rule: L-30)\n"
    "### References (RP-15)\n"
    "- **Linked:** [issue #21](https://github.com/LegalQuants/lq-ai/issues/21)\n"
    "### Findings\n"
    "**F-1 — minor** — the timeout default is unpinned; see "
    "[bad](https://evil.example.com/x).\n"
    "<!-- lq-maintainer-agent:receipt:v2\n"
    "profile: pr\nitem: legalquants/lq-ai#904\nlane: standard\n"
    "assigning_rule: L-30\nconfidence: high\ntriggers: []\nheld: false\n"
    + (FOOTER_PINNED % {"sha": "abc123def456"}) +
    "findings:\n  - {id: F-1, severity: minor, disposition: relayable}\n"
    "findings_filtered: 0\n"
    "coverage:\n  - {item: runtime-behavior, status: never-by-design}\n"
    "burden:\n  overall: low\n  blockers: []\n"
    "  scope: low\n  review: low\n  tests: medium\n  carry: low\n  safety: low\n"
    "decision_scoping:\n  applied: n-a\n"
    "category: 2\ntier: 1\noutcome: merge-after\nundo: revert-clean\n"
    "-->\n"
)

# Same footer, an outcome value no glossary key covers: degrade, never crash.
PR_UNKNOWN_OUTCOME_V2 = PR_TIER1_V2.replace(
    "outcome: merge-after", "outcome: ponder-it-a-while")

# An irreversible-class undo must never read as reassurance (RV-03 / TG-06).
PR_IRREVERSIBLE_V2 = PR_TIER1_V2.replace(
    "outcome: merge-after", "outcome: discuss").replace(
    "undo: revert-clean", "undo: irreversible-class").replace(
    "tier: 1", "tier: 2")

# A nit-severity finding with no free-text body in the receipt: the caption
# must fall back to the glossary (severity:nit), never render empty.
PR_NIT_ONLY = (
    "## Triage Receipt — PR #906: rename a local variable\n"
    "**Recommended lane:** standard (confidence: high; assigning rule: L-30)\n"
    "<!-- lq-maintainer-agent:receipt:v2\n"
    "profile: pr\nitem: legalquants/lq-ai#906\nlane: standard\n"
    "assigning_rule: L-30\nconfidence: high\ntriggers: []\nheld: false\n"
    + (FOOTER_PINNED % {"sha": "abc123def456"}) +
    "findings:\n  - {id: F-1, severity: nit, disposition: trivial, scope: in-scope}\n"
    "findings_filtered: 0\n"
    "coverage:\n  - {item: runtime-behavior, status: never-by-design}\n"
    "-->\n"
)

# A finding carrying the new `scope` field (follow-up) and an `Impact:`/`Ask:`
# body (the receipt-side finding-schema change this renderer implements
# against). Severity major, so this also exercises the auto-open direction.
PR_SCOPED_FINDING = (
    "## Triage Receipt — PR #907: adjust cache eviction policy\n"
    "**Recommended lane:** standard (confidence: high; assigning rule: L-30)\n"
    "### Findings\n"
    "**F-1 — major** — The eviction policy change is unrelated to this PR's stated goal.\n"
    "Impact: Could evict hot cache entries under load spikes; not exercised by tests.\n"
    "Ask: Confirm whether this policy change belongs in a separate PR.\n"
    "<!-- lq-maintainer-agent:receipt:v2\n"
    "profile: pr\nitem: legalquants/lq-ai#907\nlane: standard\n"
    "assigning_rule: L-30\nconfidence: high\ntriggers: []\nheld: false\n"
    + (FOOTER_PINNED % {"sha": "abc123def456"}) +
    "findings:\n  - {id: F-1, severity: major, disposition: structural, scope: follow-up}\n"
    "findings_filtered: 0\n"
    "coverage:\n  - {item: runtime-behavior, status: never-by-design}\n"
    "-->\n"
)

# Issue profile, the new IV-01 value `design` (design v0.7 §6/§9).
ISSUE_DESIGN = ISSUE_ESCALATE.replace(
    "recommendation: escalate", "recommendation: design\ncategory: 1\ntier: 3"
).replace("lane: escalate", "lane: standard"
).replace("**Recommendation:** Escalate", "**Recommendation:** Design")

ISSUE_ESCALATE_V2 = ISSUE_ESCALATE.replace(
    "lq-maintainer-agent:receipt:v1", "lq-maintainer-agent:receipt:v2"
).replace(
    "findings: []\nfindings_filtered: 0\n",
    "findings: []\nfindings_filtered: 0\n"
    "decision_scoping:\n  applied: partial\n  questions: 1\n  settled: 0\n"
    "  residual: 1\n  reserved_human: 0\n  residuals:\n"
    "    - {id: R-1, kind: forward-looking, artifact: de-stub}\n"
)

# The design-path artifact (templates/design-plan.md, design v0.7 §9): the
# third profile, carrying the same v2 footer with `profile: plan`, the fixed
# category-1 / tier-3 / route-to-design call, `undo: null` (a plan merges
# nothing), the additive `plan` counts block, and the `tone_gate` field. The
# renderer must read it as an ordinary action-first deck — no burden axes on
# this path, and no crash on footer keys it has no gloss for.
PLAN_V2 = (
    "## Design plan — PR #905: nightly digest of newly matched documents\n"
    "**Category:** 1 — greenfield (rule: G-02) · **Outcome:** route-to-design\n"
    "### Predicted obstacles (DP-05)\n"
    "- The tree has no scheduler, so \"nightly\" is itself a decision.\n"
    "### References (DP-04)\n"
    "- **Linked:** [DE-114](https://github.com/LegalQuants/lq-ai/issues/114) "
    "and [bad](https://evil.example.com/x)\n"
    "<!-- lq-maintainer-agent:receipt:v2\n"
    "profile: plan\nitem: legalquants/lq-ai#905\nkind: pr\nlane: standard\n"
    "assigning_rule: L-30\nconfidence: high\ntriggers: []\nheld: false\n"
    + (FOOTER_PINNED % {"sha": "abc123def456"}) +
    "category: 1\ncategory_rule: G-02\ntier: 3\noutcome: route-to-design\n"
    "recommendation: n-a\nundo: null\ntone_gate: applied\n"
    "plan:\n  decisions: 4\n  settled: 1\n  adrs_drafted: 2\n  de_stubs: 1\n"
    "  obstacles: 3\n  atomic_changes: 5\n"
    "findings: []\nfindings_filtered: 0\n"
    "coverage:\n  - {item: code-review, status: never-by-design}\n"
    "  - {item: runtime-behavior, status: never-by-design}\n"
    "decision_scoping:\n  applied: n-a\n"
    "-->\n"
)

# Embedded drafts + recorded maintainer decision (decided 2026-07-26): the
# receipt carries the paste-ready drafts as fenced blocks and the human ruling
# as a body section; the deck renders them as cards. The comment deliberately
# contains a column-0 `---` divider (its attribution rule) and an off-host
# link, so fence-aware extraction and the allow-list are both exercised.
DRAFT_SECTIONS = (
    "### Maintainer decision\n\n"
    "Decided by @maintainer (2026-07-26): merge after the named fix lands.\n"
    "- Agent recommendation accepted; feedback: none.\n\n"
    "### Drafted public comment\n\n"
    "```markdown\n"
    "Hi @someone — this looks ready to merge once one change lands.\n\n"
    "Thanks for pinning the timeout default; see [bad](https://evil.example.com/x).\n\n"
    "---\n"
    "*Drafted by lq-maintainer-agent v0.2.0; reviewed and posted by @maintainer.*\n"
    "```\n\n"
    "### Drafted merge message\n\n"
    "```text\n"
    "Pin the request timeout default (#904)\n\n"
    "Triage: standard lane; receipt internal\n"
    "Signed-off-by: <maintainer name> <email>\n"
    "```\n\n"
)

PR_WITH_DRAFTS = PR_TIER1_V2.replace(
    "<!-- lq-maintainer-agent:receipt:v2\n",
    DRAFT_SECTIONS + "<!-- lq-maintainer-agent:receipt:v2\n"
).replace(
    "undo: revert-clean\n",
    "undo: revert-clean\n"
    "decision:\n  final_outcome: merge-after\n  alignment: accepted\n"
    "  verified: api\n  feedback_logged: false\n"
)

ISSUE_WITH_DRAFT = ISSUE_ESCALATE.replace(
    "<!-- lq-maintainer-agent:receipt:v1\n",
    "### Maintainer decision\n\n"
    "Decided by @maintainer: hold for the committee agenda.\n\n"
    "### Drafted public comment\n\n"
    "```markdown\nHi @filer — thanks for the detailed report.\n```\n\n"
    "<!-- lq-maintainer-agent:receipt:v1\n"
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

    # --- e2e: v0.7 action-first hero (footer carries `outcome`) ---
    rc, out = run(PR_TIER1_V2)
    check("PR v0.7: exit 0", rc == 0, "rc=%d" % rc)
    check("PR v0.7: hero leads with the action outcome, not the burden",
          "<h1>Ready to merge after one named change</h1>" in out
          and "<h1>Low burden" not in out)
    check("PR v0.7: undo path is the highlighted decision line",
          'class="undo' in out and "One revert puts this back" in out)
    check("PR v0.7: category + tier render as supporting detail",
          "Behaviour change" in out and "One focused pass" in out
          and 'class="ctx"' in out)
    check("PR v0.7: burden axes demoted to the auditor section",
          "How this was reviewed" in out and "internal evidence" in out
          and out.index("How this was reviewed") < out.index("tiles tiles-5"),
          "hero still owns the axes")
    check("PR v0.7: decision box states the human action",
          "One named change is asked for first" in out)
    check("PR v0.7: honesty rails intact",
          "What was <em>not</em> checked (on purpose)" in out
          and "Never checked" in out)
    check("PR v0.7: allow-list still holds on this path",
          'href="https://evil' not in out
          and 'href="https://github.com/LegalQuants/lq-ai/issues/21"' in out)

    # a legacy v2 footer (no v0.7 fields) keeps the burden-led hero exactly
    rc, out = run(PR_BLOCKED)
    check("PR legacy: burden hero, no action-first furniture",
          "Blocked — resolve first" in out and 'class="undo' not in out
          and "How this was reviewed" not in out)
    rc, out = run(PR_CLEAN_V2)
    check("PR v2 clean (no v0.7 fields): no action-first furniture",
          rc == 0 and 'class="undo' not in out
          and "How this was reviewed" not in out, "rc=%d" % rc)

    # an unrecognised enum degrades to raw text — never a crash, never a gloss
    rc, out = run(PR_UNKNOWN_OUTCOME_V2)
    check("PR v0.7 unknown outcome: exit 0", rc == 0, "rc=%d" % rc)
    check("PR v0.7 unknown outcome: rendered raw, warn state, no invented gloss",
          "Outcome: ponder-it-a-while" in out and "verdict s-warn" in out
          and "Ready to merge" not in out)

    # an irreversible undo never renders as reassurance (RV-03, TG-06)
    rc, out = run(PR_IRREVERSIBLE_V2)
    check("PR v0.7 irreversible: undo says it cannot be cleanly undone",
          rc == 0 and "cannot be cleanly undone" in out
          and "u-bad" in out, "rc=%d" % rc)

    # --- e2e: findings severity split, scope/disposition glossing, triggers ---
    rc, out = run(PR_BLOCKED)
    check("findings: auto-open when a major/blocking finding exists",
          '<details class="dd" open><summary>Findings' in out, "rc=%d" % rc)
    rc, out = run(PR_TIER1_V2)
    check("findings: stays collapsed when only minor/nit findings exist",
          '<details class="dd"><summary>Findings' in out
          and '<details class="dd" open><summary>Findings' not in out)
    check("findings: minor findings fold into the nested sub-disclosure",
          '<details class="dd sub"><summary>Minor findings' in out)
    rc, out = run(PR_NIT_ONLY)
    check("findings: nit-only stays collapsed too",
          '<details class="dd" open><summary>Findings' not in out, "rc=%d" % rc)
    check("findings: nit finding folds into the sub-disclosure",
          '<details class="dd sub"><summary>Minor findings' in out)
    check("findings: nit with no body text still gets a non-empty caption",
          "A nitpick" in out, out)
    rc, out = run(PR_SCOPED_FINDING)
    check("findings: exit 0", rc == 0, "rc=%d" % rc)
    check("findings: scope: follow-up renders its glossed tag",
          'class="tag g-mute"' in out
          and "need to hold this change up" in out, out)
    check("findings: disposition is glossed, not the raw word",
          "Recommends closing this and opening an issue instead" in out
          and ">structural<" not in out, out)
    check("findings: Impact:/Ask: body lines flow through to the deck",
          "Impact:" in out and "Ask:" in out
          and "Could evict hot cache entries" in out
          and "Confirm whether this policy change belongs" in out, out)

    # --- e2e: renderer version stamp (a stale installed plugin is visible on
    # the artifact itself, not just via the receipt's pinned agent_version) ---
    rc, out = run(PR_BLOCKED)
    check("provenance: renderer stamp present", "Rendered by lq-maintainer-agent v" in out
          and "renderer" in out, out)

    # --- e2e: "Why this escalated" card (fired E-NN triggers, glossed) ---
    rc, out = run(PR_BLOCKED)  # carries triggers: [E-10]
    check("triggers: Why this escalated card present", "Why this escalated" in out)
    check("triggers: fired trigger glossed, not left raw",
          "Adds or changes a file that instructs AI agents" in out)
    rc, out = run(PR_CLEAN_V2)  # triggers: []
    check("triggers: no card when nothing fired", "Why this escalated" not in out)
    rc, out = run(ISSUE_ESCALATE)  # no `triggers` key at all (pre-field footer)
    check("triggers: no crash / no card on a footer with no triggers key",
          rc == 0 and "Why this escalated" not in out, "rc=%d" % rc)

    # --- e2e: embedded drafts + maintainer decision (decided 2026-07-26) ---
    rc, out = run(PR_WITH_DRAFTS)
    check("drafts PR: exit 0", rc == 0, "rc=%d" % rc)
    check("drafts PR: comment card present, marked paste-ready",
          "The drafted comment" in out and "paste-ready" in out)
    check("drafts PR: block is one-click-selectable (user-select:all, no JS)",
          'class="receipt paste"' in out and "user-select:all" in out
          and "<script" not in out)
    check("drafts PR: comment survives its own --- divider (attribution kept)",
          "reviewed and posted by @maintainer" in out)
    check("drafts PR: merge-message card present with the drafted subject",
          "The drafted merge message" in out
          and "Pin the request timeout default (#904)" in out)
    check("drafts PR: off-host URL inside a draft is inert text, never a href",
          'href="https://evil' not in out)
    check("drafts PR: decision-record card present with the ruling",
          "What the maintainer decided" in out
          and "merge after the named fix lands" in out)
    check("drafts PR: decision footer block parses (additive, no crash)",
          "verdict" in out)  # rc==0 above is the real assertion; keep a probe
    rc, out = run(PR_TIER1_V2)
    check("no drafts: draft + decision cards absent, not empty",
          "The drafted comment" not in out
          and "The drafted merge message" not in out
          and "What the maintainer decided" not in out)
    rc, out = run(ISSUE_WITH_DRAFT)
    check("drafts issue: exit 0", rc == 0, "rc=%d" % rc)
    check("drafts issue: comment card present",
          "The drafted comment" in out
          and "thanks for the detailed report" in out)
    check("drafts issue: decision-record card present",
          "What the maintainer decided" in out
          and "hold for the committee agenda" in out)
    check("drafts issue: no merge-message card on the issue profile",
          "The drafted merge message" not in out)

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

    # --- e2e: issue `design` recommendation (IV-01, new in v0.7) ---
    rc, out = run(ISSUE_DESIGN)
    check("issue design: exit 0", rc == 0, "rc=%d" % rc)
    check("issue design: headline glossed, not raw",
          "This is a feature idea that deserves a design plan" in out
          and "Recommendation: design" not in out)
    check("issue design: decision line names the runnable command with the number",
          "/lq-maintainer:design-plan issue 901" in out)
    check("issue design: informational state, not an alarm", "verdict s-info" in out)
    check("issue design: category renders as supporting detail",
          "New feature" in out and 'class="ctx"' in out)
    check("issue design: no burden axes anywhere", '<div class="tiles' not in out)

    # --- e2e: the design-plan deck (profile: plan, new in v0.7) ---
    rc, out = run(PLAN_V2)
    check("plan: exit 0", rc == 0, "rc=%d" % rc)
    check("plan: action-first design hero, glossed from the outcome",
          "<h1>Bigger than a code review — this needs a design plan</h1>" in out)
    check("plan: informational state, not an alarm", "verdict s-info" in out)
    check("plan: decision line names the runnable command with the number",
          "/lq-maintainer:design-plan pr 905" in out)
    check("plan: category + tier render as supporting detail",
          "New feature" in out and "Committee or design path" in out
          and 'class="ctx"' in out)
    check("plan: burden axes nowhere on this path",
          "tiles tiles-5" not in out and 'class="tile t-bad"' not in out)
    check("plan: auditor card present",
          "How this was reviewed" in out and "internal evidence" in out)
    check("plan: no undo furniture — `undo: null` reads as absent, not as a gloss",
          'class="undo' not in out and "Undo path recorded" not in out)
    check("plan: allow-list still holds on this path",
          'href="https://evil' not in out
          and 'href="https://github.com/LegalQuants/lq-ai/issues/114"' in out)

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
