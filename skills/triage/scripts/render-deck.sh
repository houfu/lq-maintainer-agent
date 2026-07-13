#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "lq-maintainer-agent render-deck: python3 not found on PATH; cannot render the deck (the receipt itself is unaffected)." >&2; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
"""lq-maintainer-agent -- skills/triage/scripts/render-deck.sh

Render a Triage Receipt into a self-contained HTML "reading deck": a
plain-language, verdict-first view of the same facts the receipt already
carries, for a maintainer reading outside the terminal. It is a PRIVATE
LOCAL VIEW, never a published artifact -- the markdown receipt remains the
thing posted to GitHub. This script only reformats data that already exists;
it never fetches, never runs contributed code, and never writes to GitHub.

The file is a sh/python3 polyglot (design doc convention): the two quoted
lines above run under /bin/sh and exec python3 on this same file; if python3
is missing it exits 1 (the receipt is unaffected). Run it as
`sh render-deck.sh` or directly.

Input  : the rendered receipt markdown on stdin (the exact text Step 9 of
         skills/triage/SKILL.md produces -- it contains the versioned
         `lq-maintainer-agent:receipt:v1` footer, which is the single
         source of truth for the structured facts).
Output : a complete, self-contained HTML document on stdout (inline CSS,
         native <details> disclosure, NO JavaScript, NO external resource,
         NO network) -- open it in a browser or drop it on a static host.
Exit   : 0 on success; 1 fail-closed (missing/unparseable footer, or a
         schema this script does not understand) -- it emits a minimal
         "could not render, read the receipt" page rather than a
         confidently-wrong one, and logs the reason to stderr.

Design contract honoured (see docs/design v0.6 and rules/):
  - The four pinned fields (PR head SHA, canon SHA, agent version, model)
    always appear.
  - Coverage items that are "never checked by design" (runtime behaviour
    always; package contents for dependency bumps) and the permanently-open
    human-only judgments are shown prominently and can NEVER render as
    resolved. The cheerful layout must not imply "checks passed = safe".
  - Only the recommendation is shown; the decision is the human's. The deck
    never implies a merge/approve/close/post happened.
  - All contributor-derived free text (PR title, findings) is NFKC-normalised,
    stripped of invisible/bidi/tag characters (visibly flagged if any were
    present -- rules/injection-posture.md I-10), then HTML-escaped. It is
    shown as data, never interpreted as markup or instructions.

Plain-language captions come from `templates/deck/glossary.md` (resolved via
${CLAUDE_PLUGIN_ROOT}); a missing glossary degrades to the raw enum values
rather than hiding a fact. No dependencies beyond the python3 stdlib.
"""

import html
import os
import re
import sys
import unicodedata

CHECK_ORDER = [
    "author_identity", "manifest_only", "semver_delta",
    "no_new_packages", "osv_lookup", "release_age", "ci_green",
]

# Invisible / direction-controlling code points that can hide a payload in
# rendered output (rules/injection-posture.md I-10). Stripped and flagged.
_ZERO_WIDTH = {0x200B, 0x200C, 0x200D, 0x2060, 0xFEFF}
_BIDI = set(range(0x202A, 0x2030)) | set(range(0x2066, 0x206A))
_TAGS = set(range(0xE0000, 0xE0080))


def sanitize(s):
    """(escaped_text, had_hidden_chars). Strip invisible/bidi/tag chars,
    NFKC-normalise, then HTML-escape. Safe to drop straight into HTML text."""
    if s is None:
        return "", False
    hidden = False
    kept = []
    for ch in s:
        cp = ord(ch)
        if cp in _ZERO_WIDTH or cp in _BIDI or cp in _TAGS:
            hidden = True
            continue
        kept.append(ch)
    norm = unicodedata.normalize("NFKC", "".join(kept))
    return html.escape(norm), hidden


# --------------------------------------------------------------------------
# Footer parsing -- the enumerated lq-maintainer-agent:receipt:v1 schema only.
# --------------------------------------------------------------------------

def _scalar(v):
    v = v.strip()
    if v in ("", "null"):
        return None
    if v == "true":
        return True
    if v == "false":
        return False
    if v == "[]":
        return []
    if v.startswith("[") and v.endswith("]"):
        inner = v[1:-1].strip()
        return [x.strip() for x in inner.split(",")] if inner else []
    return v


def _inline_dict(s):
    s = s.strip()
    if s.startswith("{"):
        s = s[1:]
    if s.endswith("}"):
        s = s[:-1]
    d = {}
    for part in s.split(","):
        if ":" in part:
            k, val = part.split(":", 1)
            d[k.strip()] = _scalar(val)
    return d


def extract_footer(md):
    """Return the raw text lines inside the receipt:v1 HTML comment, or None."""
    m = re.search(
        r"<!--\s*lq-maintainer-agent:receipt:v1\s*\n(.*?)-->",
        md, re.DOTALL,
    )
    return m.group(1) if m else None


def extract_findings_text(md):
    """Map finding id -> its human-readable text from the visible ### Findings
    section (contributor-adjacent free text; sanitised at render time)."""
    m = re.search(r"^###\s+Findings\s*$(.*?)(?=^###\s|^---\s*$|\Z)",
                  md, re.MULTILINE | re.DOTALL)
    if not m:
        return {}
    out = {}
    for part in re.split(r"\n(?=\*\*F-?\d)", m.group(1)):
        mid = re.match(r"\*\*(F-?\d+)", part.strip())
        if not mid:
            continue
        text = re.sub(r"^\*\*F-?\d+\s*[—-]\s*[\w-]+\*\*\s*[—-]?\s*", "", part.strip())
        out[mid.group(1).replace(" ", "").upper()] = text.strip()
    return out


def render_inline(s):
    """Sanitise + escape, then re-mark `code` spans (backticks survive escaping)."""
    txt, hidden = sanitize(s)
    txt = re.sub(r"`([^`]+)`", r"<code>\1</code>", txt)
    return txt, hidden


def parse_footer(text):
    """Indentation parser for the bounded v1 schema: top-level scalars, the
    2-space nested maps (pinned / deterministic_checks / salvage), and lists
    of inline dicts (coverage / findings / salvage.parts)."""
    root = {}
    parent_key = None      # current top-level key holding a map or list
    deep_parent = None     # a nested map we are filling at indent 2
    deep_list_key = None   # a list key inside deep_parent (salvage.parts)
    for raw in text.splitlines():
        if not raw.strip():
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        line = raw.strip()
        if indent == 0:
            deep_parent = None
            deep_list_key = None
            if line.endswith(":"):
                parent_key = line[:-1].strip()
                root[parent_key] = None  # children decide map vs list
            else:
                key, _, val = line.partition(":")
                parent_key = key.strip()
                root[parent_key] = _scalar(val)
        elif indent == 2 and parent_key is not None:
            if line.startswith("- "):
                item = line[2:].strip()
                val = _inline_dict(item) if item.startswith("{") else _scalar(item)
                if not isinstance(root.get(parent_key), list):
                    root[parent_key] = []
                root[parent_key].append(val)
                deep_parent = None
            elif line.endswith(":"):
                if not isinstance(root.get(parent_key), dict):
                    root[parent_key] = {}
                deep_parent = root[parent_key]
                deep_list_key = line[:-1].strip()
                deep_parent[deep_list_key] = None
            else:
                key, _, val = line.partition(":")
                if not isinstance(root.get(parent_key), dict):
                    root[parent_key] = {}
                root[parent_key][key.strip()] = _scalar(val)
                deep_parent = root[parent_key]
                deep_list_key = None
        elif indent >= 4 and deep_parent is not None and deep_list_key is not None:
            if line.startswith("- "):
                item = line[2:].strip()
                val = _inline_dict(item) if item.startswith("{") else _scalar(item)
                if not isinstance(deep_parent.get(deep_list_key), list):
                    deep_parent[deep_list_key] = []
                deep_parent[deep_list_key].append(val)
    return root


# --------------------------------------------------------------------------
# Glossary -- plain-language captions keyed by enumerated value.
# --------------------------------------------------------------------------

def load_glossary(path):
    g = {}
    try:
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
    except OSError:
        return g
    cur, cap, dec, in_dec = None, [], None, False

    def flush():
        if cur is not None:
            g[cur] = (" ".join(cap).strip(), dec)

    for line in text.splitlines():
        if line.startswith("### "):
            flush()
            cur, cap, dec, in_dec = line[4:].strip().lower(), [], None, False
        elif cur is not None:
            s = line.strip()
            if s.startswith("## ") or s == "---":
                flush()
                cur, cap, dec, in_dec = None, [], None, False
            elif s.startswith("→"):
                dec, in_dec = s[1:].strip(), True
            elif in_dec and s:          # continuation of a wrapped → line
                dec = (dec + " " + s).strip()
            elif s:
                cap.append(s)
    flush()
    return g


class Gloss:
    def __init__(self, table):
        self.t = table

    def cap(self, key, fallback=""):
        return self.t.get(key.lower(), (fallback, None))[0] or fallback

    def dec(self, key):
        return self.t.get(key.lower(), ("", None))[1]


# --------------------------------------------------------------------------
# HTML helpers
# --------------------------------------------------------------------------

def esc(s):
    """Escape TRUSTED text (our glossary / static strings). No hidden-char flag."""
    return html.escape(s or "")


def mono(s):
    t, _ = sanitize(s)
    return '<code>%s</code>' % t


CSS = """
:root{
  --paper:#eef1f5; --surface:#ffffff; --surface-2:#f5f7fa;
  --ink:#181d27; --ink-soft:#525c6b; --ink-faint:#7b8595;
  --line:#d8dee7; --line-soft:#e7ecf2;
  --accent:#38468f; --accent-ink:#38468f;
  --ok:#1f7a46; --ok-bg:#e4f2e9; --ok-line:#bfe0cd;
  --warn:#9a6410; --warn-bg:#faf0dc; --warn-line:#ecd3a1;
  --bad:#b22f22; --bad-bg:#fae7e4; --bad-line:#eebfb8;
  --info:#345a86; --info-bg:#e7eef7; --info-line:#c3d5ea;
  --shadow:0 1px 2px rgba(20,30,50,.06),0 8px 24px rgba(20,30,50,.06);
  --serif:"Iowan Old Style","Palatino Linotype",Palatino,Georgia,"Times New Roman",serif;
  --sans:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  --mono:ui-monospace,"SF Mono",Menlo,Consolas,"Liberation Mono",monospace;
}
@media (prefers-color-scheme:dark){
  :root{
    --paper:#0f131a; --surface:#171c25; --surface-2:#1d232e;
    --ink:#e8ecf3; --ink-soft:#aab4c2; --ink-faint:#7c8797;
    --line:#2b323d; --line-soft:#232a34;
    --accent:#aeb9ee; --accent-ink:#c2cbf3;
    --ok:#5cc487; --ok-bg:#16281e; --ok-line:#265238;
    --warn:#e0aa53; --warn-bg:#2b2213; --warn-line:#574321;
    --bad:#f0796b; --bad-bg:#2c1815; --bad-line:#5a2c26;
    --info:#8fb4e0; --info-bg:#152130; --info-line:#274058;
    --shadow:0 1px 2px rgba(0,0,0,.4),0 10px 30px rgba(0,0,0,.35);
  }
}
:root[data-theme="light"]{
  --paper:#eef1f5; --surface:#ffffff; --surface-2:#f5f7fa;
  --ink:#181d27; --ink-soft:#525c6b; --ink-faint:#7b8595;
  --line:#d8dee7; --line-soft:#e7ecf2; --accent:#38468f; --accent-ink:#38468f;
  --ok:#1f7a46; --ok-bg:#e4f2e9; --ok-line:#bfe0cd;
  --warn:#9a6410; --warn-bg:#faf0dc; --warn-line:#ecd3a1;
  --bad:#b22f22; --bad-bg:#fae7e4; --bad-line:#eebfb8;
  --info:#345a86; --info-bg:#e7eef7; --info-line:#c3d5ea;
}
:root[data-theme="dark"]{
  --paper:#0f131a; --surface:#171c25; --surface-2:#1d232e;
  --ink:#e8ecf3; --ink-soft:#aab4c2; --ink-faint:#7c8797;
  --line:#2b323d; --line-soft:#232a34; --accent:#aeb9ee; --accent-ink:#c2cbf3;
  --ok:#5cc487; --ok-bg:#16281e; --ok-line:#265238;
  --warn:#e0aa53; --warn-bg:#2b2213; --warn-line:#574321;
  --bad:#f0796b; --bad-bg:#2c1815; --bad-line:#5a2c26;
  --info:#8fb4e0; --info-bg:#152130; --info-line:#274058;
}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{
  margin:0; background:var(--paper); color:var(--ink);
  font-family:var(--sans); font-size:17px; line-height:1.6;
  -webkit-font-smoothing:antialiased;
}
.wrap{max-width:820px; margin:0 auto; padding:40px 22px 72px}
.eyebrow{
  font-size:12.5px; letter-spacing:.09em; text-transform:uppercase;
  color:var(--ink-faint); font-weight:600; margin:0 0 12px;
}
.card{
  background:var(--surface); border:1px solid var(--line);
  border-radius:14px; box-shadow:var(--shadow);
}
/* Verdict hero */
.verdict{padding:30px 30px 26px; margin-bottom:18px; position:relative; overflow:hidden}
.verdict::before{content:""; position:absolute; inset:0 auto 0 0; width:6px}
.verdict.s-warn::before{background:var(--warn)}
.verdict.s-ok::before{background:var(--ok)}
.verdict.s-bad::before{background:var(--bad)}
.verdict.s-info::before{background:var(--info)}
.verdict h1{
  font-family:var(--serif); font-weight:600; font-size:33px; line-height:1.15;
  letter-spacing:-.01em; text-wrap:balance; margin:.1em 0 .35em;
}
.verdict .lede{font-size:18px; color:var(--ink-soft); margin:0; max-width:60ch}
.verdict .lede code{font-family:var(--mono); font-size:.86em; color:var(--ink)}
.pinrow{
  display:flex; flex-wrap:wrap; gap:6px 18px; margin-top:22px;
  padding-top:16px; border-top:1px solid var(--line-soft);
  font-size:12.5px; color:var(--ink-faint);
}
.pinrow b{color:var(--ink-soft); font-weight:600}
.pinrow code{font-family:var(--mono); font-size:12px; color:var(--ink-soft)}
/* Up-front alert */
.alert{
  display:flex; gap:12px; padding:16px 18px; margin-bottom:18px;
  border-radius:12px; background:var(--warn-bg);
  border:1px solid var(--warn-line);
}
.alert .mark{color:var(--warn); font-size:20px; line-height:1.3; flex:none}
.alert p{margin:0; font-size:15.5px; color:var(--ink)}
.alert strong{color:var(--warn)}
.flagline{
  margin-bottom:18px; padding:12px 16px; border-radius:10px;
  background:var(--bad-bg); border:1px solid var(--bad-line);
  color:var(--bad); font-size:14px; font-weight:500;
}
/* Tiles */
.tiles{display:grid; grid-template-columns:repeat(3,1fr); gap:12px; margin-bottom:14px}
.tiles-5{grid-template-columns:repeat(auto-fit,minmax(132px,1fr))}
.tile{padding:16px 16px 15px; border-radius:12px}
.tile.t-ok{background:var(--ok-bg); border:1px solid var(--ok-line)}
.tile.t-warn{background:var(--warn-bg); border:1px solid var(--warn-line)}
.tile.t-bad{background:var(--bad-bg); border:1px solid var(--bad-line)}
.tile .k{font-size:12px; letter-spacing:.04em; text-transform:uppercase; color:var(--ink-faint); font-weight:600}
.tile .v{font-size:24px; font-weight:700; margin-top:4px; font-variant-numeric:tabular-nums}
.tile.t-ok .v{color:var(--ok)} .tile.t-warn .v{color:var(--warn)} .tile.t-bad .v{color:var(--bad)}
.tile .s{font-size:13px; color:var(--ink-soft); margin-top:2px}
/* Gate meter */
.meter{
  display:flex; align-items:center; gap:14px; flex-wrap:wrap;
  padding:14px 18px; margin-bottom:20px; border-radius:12px;
  background:var(--surface-2); border:1px solid var(--line-soft);
}
.meter .lab{font-size:12.5px; color:var(--ink-faint); font-weight:600; text-transform:uppercase; letter-spacing:.05em}
.dots{display:flex; gap:7px}
.dot{width:19px; height:19px; border-radius:50%; display:grid; place-items:center; font-size:12px; font-weight:700; color:#fff}
.dot.d-pass{background:var(--ok)} .dot.d-fail{background:var(--bad)} .dot.d-na{background:var(--ink-faint); opacity:.5}
.legend{font-size:12.5px; color:var(--ink-faint); margin-left:auto}
/* Decision */
.decision{padding:22px 24px; margin-bottom:22px; border:1px solid var(--accent); border-left-width:4px}
.decision h2{font-family:var(--serif); font-size:21px; font-weight:600; margin:0 0 8px}
.decision p{margin:0 0 8px; font-size:16px}
.decision .standing{
  margin-top:12px; padding-top:12px; border-top:1px solid var(--line-soft);
  font-size:14px; color:var(--ink-soft); font-style:italic;
}
/* Next steps checklist */
.nextsteps{padding:22px 24px; margin-bottom:22px; border:1px solid var(--info-line); background:var(--info-bg)}
.nextsteps h2{font-family:var(--serif); font-size:21px; font-weight:600; margin:0 0 3px}
.nextsteps .ns-intro{margin:0 0 10px; font-size:14px; color:var(--ink-soft)}
.nextsteps ul{margin:0; padding:0; list-style:none}
.nextsteps li{position:relative; padding:9px 0 9px 30px; border-top:1px solid var(--line-soft); font-size:15px}
.nextsteps li:first-child{border-top:0}
.nextsteps li::before{content:"\\2610"; position:absolute; left:2px; top:7px; color:var(--info); font-size:17px}
/* Section heading */
.sec-h{
  font-size:13px; letter-spacing:.08em; text-transform:uppercase; font-weight:700;
  color:var(--ink-faint); margin:30px 4px 12px;
}
/* Drill-downs */
details.dd{
  background:var(--surface); border:1px solid var(--line);
  border-radius:12px; margin-bottom:10px; overflow:hidden;
}
details.dd+details.dd{margin-top:0}
details.dd>summary{
  list-style:none; cursor:pointer; padding:16px 20px;
  display:flex; align-items:center; gap:12px; font-weight:600; font-size:16.5px;
}
details.dd>summary::-webkit-details-marker{display:none}
details.dd>summary::before{
  content:"\\203A"; font-size:20px; color:var(--ink-faint);
  transition:transform .15s ease; flex:none; width:14px;
}
details.dd[open]>summary::before{transform:rotate(90deg)}
details.dd>summary .tag{margin-left:auto; font-size:12px; font-weight:600; padding:2px 9px; border-radius:20px}
.tag.g-ok{background:var(--ok-bg); color:var(--ok); border:1px solid var(--ok-line)}
.tag.g-warn{background:var(--warn-bg); color:var(--warn); border:1px solid var(--warn-line)}
.tag.g-bad{background:var(--bad-bg); color:var(--bad); border:1px solid var(--bad-line)}
.tag.g-mute{background:var(--surface-2); color:var(--ink-faint); border:1px solid var(--line-soft)}
.dd .body{padding:2px 20px 20px; border-top:1px solid var(--line-soft)}
.dd .body>.intro{color:var(--ink-soft); font-size:15.5px; margin:14px 0 6px}
/* check list */
.checks{list-style:none; margin:8px 0 0; padding:0}
.checks li{display:flex; gap:12px; padding:12px 0; border-top:1px solid var(--line-soft)}
.checks li:first-child{border-top:0}
.ci{flex:none; width:22px; height:22px; border-radius:50%; display:grid; place-items:center; font-size:13px; font-weight:700; color:#fff; margin-top:2px}
.ci.c-pass{background:var(--ok)} .ci.c-fail{background:var(--bad)} .ci.c-na{background:var(--ink-faint); opacity:.55}
.checks .name{font-weight:600; font-size:15px}
.checks .name .id{font-family:var(--mono); font-size:11.5px; color:var(--ink-faint); font-weight:500; margin-left:6px}
.checks .txt{font-size:14.5px; color:var(--ink-soft); margin-top:2px}
.decnote{
  margin-top:6px; font-size:14px; color:var(--ink); background:var(--warn-bg);
  border-left:3px solid var(--warn); padding:6px 12px; border-radius:0 6px 6px 0;
}
.decnote.d-bad{background:var(--bad-bg); border-left-color:var(--bad)}
/* coverage / human-only lists */
.cov{list-style:none; margin:6px 0 0; padding:0}
.cov li{padding:11px 0; border-top:1px solid var(--line-soft); font-size:15px}
.cov li:first-child{border-top:0}
.cov .h{font-weight:600}
.cov .never{color:var(--bad); font-weight:600; font-size:12.5px; text-transform:uppercase; letter-spacing:.03em}
.cov .open{color:var(--warn); font-weight:600; font-size:12.5px; text-transform:uppercase; letter-spacing:.03em}
.cov .d{color:var(--ink-soft); font-size:14.5px; margin-top:2px}
pre.receipt{
  margin:14px 0 0; padding:16px; border-radius:10px; background:var(--surface-2);
  border:1px solid var(--line-soft); overflow-x:auto;
  font-family:var(--mono); font-size:12.5px; line-height:1.55; color:var(--ink-soft);
  white-space:pre; -moz-tab-size:2; tab-size:2;
}
.foot{margin-top:34px; padding-top:18px; border-top:1px solid var(--line); font-size:13px; color:var(--ink-faint)}
.foot .prov{display:grid; grid-template-columns:auto 1fr; gap:4px 14px; margin-bottom:14px}
.foot .prov dt{font-weight:600; color:var(--ink-soft)}
.foot .prov dd{margin:0; font-family:var(--mono); font-size:12px; color:var(--ink-soft); word-break:break-all}
.foot a{color:var(--accent-ink)}
:focus-visible{outline:2px solid var(--accent); outline-offset:2px; border-radius:4px}
@media (prefers-reduced-motion:reduce){*{transition:none!important}}
@media (max-width:560px){
  .tiles,.tiles-5{grid-template-columns:1fr} .verdict h1{font-size:27px}
  .wrap{padding:26px 15px 60px}
}
"""

STATE_WORD = {"pass": ("c-pass", "✓"), "fail": ("c-fail", "✗"), "n-a": ("c-na", "–")}
DOT_WORD = {"pass": ("d-pass", "✓"), "fail": ("d-fail", "✗"), "n-a": ("d-na", "–")}


def build_deck(md, g):
    r = parse_footer(extract_footer(md) or "")
    if not r.get("lane") or not isinstance(r.get("pinned"), dict):
        raise ValueError("no parseable receipt:v1 footer (missing lane/pinned)")

    lane = r.get("lane")
    demoted = r.get("demoted_from")
    held = r.get("held") is True
    checks = r.get("deterministic_checks") or {}
    findings = r.get("findings") or []
    coverage = r.get("coverage") or []
    pinned = r.get("pinned") or {}
    item = r.get("item") or ""
    ftext_map = extract_findings_text(md)
    burden = r.get("burden") if isinstance(r.get("burden"), dict) else None

    # --- item number + PR title (title is contributor-derived; sanitize) ---
    num = ""
    mnum = re.search(r"#(\d+)", item)
    if mnum:
        num = mnum.group(1)
    title_raw = ""
    mtitle = re.search(r"^##\s*Triage Receipt\s*[—-]\s*(?:PR|Issue)\s*#\d+:\s*(.+)$",
                       md, re.MULTILINE)
    if mtitle:
        title_raw = mtitle.group(1).strip()
    title, title_hidden = sanitize(title_raw)

    # --- verdict state + copy ---
    BSTATE = {"blocked": "s-bad", "high": "s-bad", "medium": "s-warn", "low": "s-ok"}
    burden_overall = str(burden.get("overall")) if burden and burden.get("overall") else None
    if burden_overall:
        state = BSTATE.get(burden_overall, "s-warn")
        headline = g.cap("burden:%s" % burden_overall, "Needs your review")
    elif held:
        state, headline = "s-warn", "On hold — a person answers this"
    elif lane == "escalate":
        state, headline = "s-bad", "Escalated — needs a second reviewer"
    elif lane == "fast":
        state, headline = "s-ok", "Cleared the safety gate — your merge click"
    elif lane == "docs":
        state, headline = "s-info", "Documentation change — a light review"
    else:  # standard
        state = "s-warn"
        headline = ("Needs your review — didn’t qualify for auto-merge"
                    if demoted == "fast" else "Needs your review")

    # sub-line: prefer a concrete dependency-bump sentence built from the title
    lede = ""
    dep = re.search(r"(?:bump|update)\s+(\S+?)(?:\s+requirement)?\s+from\s+(.+?)\s+to\s+(\S+)",
                    title_raw, re.I)
    if dep and checks.get("semver_delta") == "fail":
        pkg, _ = sanitize(dep.group(1))
        old, _ = sanitize(dep.group(2))
        new, _ = sanitize(dep.group(3))
        is_range = bool(re.search(r"[<>,~^]|requirement", dep.group(2) + dep.group(3) + title_raw))
        if is_range:
            lede = ("A bot widened the allowed versions for <code>%s</code> (from "
                    "<code>%s</code> to <code>%s</code>) — a dependency-manifest change the "
                    "automated gate won’t fast-track on its own. It’s your call." % (pkg, old, new))
        else:
            lede = ("A bot changed <code>%s</code> from <code>%s</code> to <code>%s</code> "
                    "— a bigger jump than the automated gate fast-tracks, so a person decides."
                    % (pkg, old, new))
    elif lane == "fast":
        lede = "Every automated safety check passed. You still make the final merge click."
    elif lane == "escalate":
        lede = "A trigger fired that puts this beyond a single reviewer. Route it, don’t decide it alone."
    else:
        lede = g.cap("lane:" + str(lane), "")

    out = []
    A = out.append

    # verdict hero
    A('<header class="card verdict %s">' % state)
    eyebrow = "Triage reading view"
    if num:
        eyebrow += " · PR #%s" % esc(num)
    if lane:
        eyebrow += " · %s lane" % esc(str(lane))
    A('<p class="eyebrow">%s</p>' % eyebrow)
    A('<h1>%s</h1>' % esc(headline))
    if title:
        A('<p class="lede">%s</p>' % lede if lede else "")
        A('<p class="lede" style="margin-top:10px;font-size:15px;color:var(--ink-faint)">%s</p>' % title)
    elif lede:
        A('<p class="lede">%s</p>' % lede)
    if burden_overall in ("high", "medium"):
        worst = [k for k in ("scope", "review", "tests", "carry", "safety")
                 if str(burden.get(k)) == burden_overall]
        if worst:
            labels = ", ".join(g.cap("burden:%s:label" % k, k) for k in worst)
            A('<p class="lede" style="margin-top:12px;font-size:14px;color:var(--ink-faint)">'
              'Driven by: <b style="color:var(--ink-soft)">%s</b></p>' % esc(labels))
    A('<div class="pinrow">')
    A('<span><b>Reviewed commit</b> <code>%s</code></span>' % _short(pinned.get("pr_head_sha")))
    A('<span><b>Against canon</b> <code>%s</code></span>' % _short(pinned.get("canon_sha")))
    A('<span><b>Agent</b> <code>%s</code></span>' % esc(str(pinned.get("agent_version") or "?")))
    A('</div>')
    A('</header>')

    if title_hidden:
        A('<div class="flagline">⚠ Hidden characters were found in the title and removed '
          'before display. Treat the original text with suspicion.</div>')

    # blocker layer — resolve before it is even a burden question
    if burden_overall == "blocked":
        items = "".join("<li>%s</li>" % esc(g.cap("blocker:%s" % b, str(b)))
                        for b in (burden.get("blockers") or []))
        A('<div class="alert" style="background:var(--bad-bg);border-color:var(--bad-line)">'
          '<span class="mark" style="color:var(--bad)">⛔</span><p>'
          '<strong style="color:var(--bad)">Resolve before merging:</strong>'
          '<ul style="margin:6px 0 0;padding-left:18px">%s</ul></p></div>'
          % (items or "<li>a blocking condition is present</li>"))

    # up-front "not checked" alert (runtime behaviour never-by-design)
    never = [c for c in coverage if _cov_status(c) == "never-by-design"]
    runtime_dec = g.dec("coverage:runtime-behavior")
    if any(_cov_item(c) == "runtime-behavior" for c in never) and runtime_dec:
        A('<div class="alert"><span class="mark">⚠</span><p>'
          '<strong>Not checked:</strong> %s</p></div>' % esc(runtime_dec))

    # glance tiles
    considered = [(k, checks.get(k)) for k in CHECK_ORDER if checks.get(k) in ("pass", "fail")]
    npass = sum(1 for _, v in considered if v == "pass")
    ntot = len(considered)
    failed_names = [k for k, v in considered if v == "fail"]
    if burden and burden.get("overall"):
        # burden axes are the glance tiles
        TLEVEL = {"low": "t-ok", "medium": "t-warn", "high": "t-bad"}
        A('<div class="tiles tiles-5">')
        for key in ("scope", "review", "tests", "carry", "safety"):
            lvl = str(burden.get(key, "low"))
            A(_tile(TLEVEL.get(lvl, "t-ok"),
                    g.cap("burden:%s:label" % key, key.title()),
                    esc(lvl.title()),
                    g.cap("burden:%s:concern" % key, "")))
        A('</div>')
    else:
        A('<div class="tiles">')
        if ntot:
            gate_cls = "t-ok" if not failed_names else "t-warn"
            nfail = len(failed_names)
            sub = ("all passed" if not nfail else "%d flagged for you" % nfail)
            A(_tile(gate_cls, "Safety gate", "%d / %d" % (npass, ntot), sub))
        fcls = "t-ok" if not findings else "t-warn"
        A(_tile(fcls, "Findings", str(len(findings)), "issues in the changed lines"))
        if lane == "fast":
            A(_tile("t-ok", "Auto-merge", "Yes", "cleared every check"))
        elif lane == "escalate":
            A(_tile("t-bad", "Auto-merge", "No", "needs escalation"))
        elif held:
            A(_tile("t-warn", "Status", "On hold", "contributor asked"))
        else:
            A(_tile("t-warn", "Auto-merge", "No", "needs your review"))
        A('</div>')

    # gate meter (glance)
    if ntot:
        A('<div class="meter"><span class="lab">Safety gate</span><div class="dots">')
        for k in CHECK_ORDER:
            st = checks.get(k)
            if st not in ("pass", "fail", "n-a"):
                continue
            cls, gl = DOT_WORD.get(st, ("d-na", "–"))
            label = g.cap("check:%s:label" % k, k.replace("_", " "))
            A('<span class="dot %s" title="%s: %s" aria-label="%s: %s">%s</span>'
              % (cls, esc(label), esc(st), esc(label), esc(st), gl))
        A('</div><span class="legend">✓ passed · ✗ needs a human</span></div>')

    # decision box
    A('<section class="card decision">')
    A('<h2>Your call</h2>')
    A('<p>%s</p>' % esc(_decision_line(lane, demoted, held)))
    A('<p class="standing">The agent has not merged, approved, closed, or posted anything. '
      'Every GitHub action here is yours to take.</p>')
    A('</section>')

    # next steps — the concrete human follow-ups (rules/burden.md B-14)
    steps = []
    if burden and str(burden.get("overall")) == "blocked":
        for b in burden.get("blockers") or []:
            steps.append("Resolve: " + g.cap("blocker:%s" % b, str(b)))
    for k in CHECK_ORDER:
        if checks.get(k) == "fail":
            d = g.dec("check:%s:fail" % k)
            if d:
                steps.append(d)
    for c in coverage:
        if _cov_status(c) == "never-by-design":
            d = g.dec("coverage:%s" % _cov_item(c))
            if d:
                steps.append(d)
    if burden:
        for ax in ("scope", "review", "tests", "carry", "safety"):
            if str(burden.get(ax)) in ("medium", "high"):
                d = g.cap("burden:%s:next" % ax, "")
                if d:
                    steps.append(d)
    seen, uniq = set(), []
    for s in steps:
        key = s.strip()
        if key and key not in seen:
            seen.add(key)
            uniq.append(s)
    if uniq:
        A('<section class="card nextsteps"><h2>Next steps to check</h2>'
          '<p class="ns-intro">The follow-ups only you can do before deciding.</p><ul>')
        for s in uniq:
            A('<li>%s</li>' % esc(s))
        A('</ul></section>')

    # ---- drill-downs ----
    A('<p class="sec-h">The detail, on demand</p>')

    # why not auto-approved (only when a bump was demoted / a check failed)
    if failed_names and (demoted or lane == "standard"):
        A('<details class="dd"><summary>Why it’s not auto-approved'
          '<span class="tag g-warn">your call</span></summary><div class="body">')
        for k in failed_names:
            A(_check_row(k, "fail", g, note=True))
        A('</div></details>')

    # what was checked
    if ntot:
        tag = "g-ok" if not failed_names else "g-warn"
        A('<details class="dd"><summary>What was checked — the %d-point safety gate'
          '<span class="tag %s">%d / %d</span></summary><div class="body">'
          % (ntot, tag, npass, ntot))
        A('<p class="intro">Automated checks that decide whether a dependency bump is routine enough to fast-track.</p>')
        A('<ul class="checks">')
        for k in CHECK_ORDER:
            st = checks.get(k)
            if st not in ("pass", "fail", "n-a"):
                continue
            A(_check_row(k, st, g, note=(st == "fail")))
        A('</ul></div></details>')

    # what was NOT checked
    A('<details class="dd" open><summary>What was <em>not</em> checked (on purpose)'
      '<span class="tag g-bad">read this</span></summary><div class="body">')
    A('<p class="intro">Some things are never machine-checked here. They stay a human judgment '
      'and can never be marked done.</p><ul class="cov">')
    for c in coverage:
        st = _cov_status(c)
        if st not in ("never-by-design", "not-covered"):
            continue
        it = _cov_item(c)
        A('<li><span class="never">Never checked</span> '
          '<span class="h">%s</span><div class="d">%s</div></li>'
          % (esc(_cov_title(it)), esc(g.dec("coverage:" + it) or g.cap("coverage:" + it, ""))))
    for hk, htitle in (("human:contributor-trust", "Do you trust this contributor"),
                       ("human:supply-chain-hygiene", "Do you trust this dependency")):
        A('<li><span class="open">Human-only</span> <span class="h">%s</span>'
          '<div class="d">%s</div></li>' % (esc(htitle), esc(g.cap(hk, ""))))
    A('</ul></div></details>')

    # findings
    A('<details class="dd"><summary>Findings'
      '<span class="tag %s">%d</span></summary><div class="body">'
      % ("g-mute" if not findings else "g-warn", len(findings)))
    if not findings:
        try:
            filt = int(r.get("findings_filtered") or 0)
        except (TypeError, ValueError):
            filt = 0
        A('<p class="intro">No issues were raised in the lines this change touches.%s</p>'
          % ("" if filt <= 0 else " (%d low-signal note%s were filtered out.)"
             % (filt, "" if filt == 1 else "s")))
    else:
        A('<p class="intro">Issues the review raised in the lines this change touches.</p>')
        A('<ul class="checks">')
        for f in findings:
            fid = str(f.get("id", "F"))
            sev = str(f.get("severity", "minor"))
            disp = str(f.get("disposition", ""))
            real_text = ftext_map.get(fid.replace(" ", "").upper())
            if real_text:
                txt_html, _ = render_inline(real_text)
            else:
                txt_html = esc(g.cap("severity:" + sev, ""))
            A('<li><span class="ci c-fail">!</span><div>'
              '<div class="name">%s <span class="id">%s%s</span></div>'
              '<div class="txt">%s</div></div></li>'
              % (esc(sev.title()), esc(fid), (" · " + esc(disp)) if disp else "", txt_html))
        A('</ul>')
    A('</div></details>')

    # full technical receipt (verbatim, escaped)
    receipt_txt, _ = sanitize(md.strip())
    A('<details class="dd"><summary>The full technical receipt'
      '<span class="tag g-mute">for auditors</span></summary><div class="body">')
    A('<p class="intro">The exact receipt as posted to GitHub — the auditable record.</p>')
    A('<pre class="receipt">%s</pre></div></details>' % receipt_txt)

    # provenance footer
    A('<footer class="foot"><dl class="prov">')
    A('<dt>PR head SHA</dt><dd>%s</dd>' % _sanidd(pinned.get("pr_head_sha")))
    A('<dt>Canon SHA</dt><dd>%s</dd>' % _sanidd(pinned.get("canon_sha")))
    A('<dt>Agent version</dt><dd>%s</dd>' % _sanidd(pinned.get("agent_version")))
    A('<dt>Model</dt><dd>%s</dd>' % _sanidd(pinned.get("model_id")))
    A('</dl>')
    A('<p>A plain-language reading view of the Triage Receipt, generated by '
      'lq-maintainer-agent. It reformats the receipt only — the receipt is the '
      'record. A human decides, every time.</p>')
    A('</footer>')

    return "".join(out)


def _short(sha):
    s = str(sha or "")
    return esc(s[:10]) if s and s != "n-a" else esc(s or "?")


def _sanidd(v):
    t, _ = sanitize(str(v) if v is not None else "—")
    return t


def _tile(cls, k, v, s):
    return ('<div class="tile %s"><div class="k">%s</div><div class="v">%s</div>'
            '<div class="s">%s</div></div>' % (cls, esc(k), v, esc(s)))


def _decision_line(lane, demoted, held):
    if held:
        return ("The contributor asked for a human. Read their message in the receipt and "
                "respond yourself; the agent has drafted nothing further.")
    if lane == "escalate":
        return ("Route this to the right reviewers (a committee or security review). Do not "
                "merge or reject it on your own.")
    if lane == "fast":
        return ("Decide whether to merge. Every automated check passed, so this is a routine "
                "click — but the click is yours.")
    if lane == "docs":
        return "Decide whether the documentation change is accurate and well-placed, then merge or send back."
    return ("Decide whether to merge this change. Read “why it’s not auto-approved” and "
            "“what was not checked” first. Posting the receipt to the PR is a separate, "
            "second approval.")


def _cov_item(c):
    return str(c.get("item")) if isinstance(c, dict) else ""


def _cov_status(c):
    return str(c.get("status")) if isinstance(c, dict) else ""


_COV_TITLES = {
    "runtime-behavior": "Whether the code actually runs correctly",
    "package-contents": "What is inside the dependency package",
    "code-quality": "A close read of the code",
    "test-adequacy": "Whether it is covered by tests",
    "anchor": "Whether it is tied to a real source",
    "vetting-checklist": "The security pass",
    "deterministic-gate": "The automated gate",
    "salvage": "Breaking an overreaching change into parts",
}


def _cov_title(it):
    return _COV_TITLES.get(it, it.replace("-", " ").capitalize())


def _check_row(k, st, g, note=False):
    cls, glyph = STATE_WORD.get(st, ("c-na", "–"))
    label = g.cap("check:%s:label" % k, k.replace("_", " ").title())
    body = g.cap("check:%s:%s" % (k, st), "")
    rid = {"author_identity": "F-01", "manifest_only": "F-02", "semver_delta": "F-03",
           "no_new_packages": "F-04", "osv_lookup": "F-05", "release_age": "F-06",
           "ci_green": "F-07"}.get(k, "")
    row = ['<li><span class="ci %s">%s</span><div>' % (cls, glyph)]
    row.append('<div class="name">%s<span class="id">%s</span></div>' % (esc(label), esc(rid)))
    row.append('<div class="txt">%s</div>' % esc(body))
    if note and st == "fail":
        dec = g.dec("check:%s:fail" % k)
        if dec:
            row.append('<div class="decnote d-bad">%s</div>' % esc(dec))
    row.append('</div></li>')
    return "".join(row)


HEAD = ('<!doctype html><html lang="en"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        '<title>%s</title><style>%s</style></head><body><main class="wrap">')
TAIL = '</main></body></html>'


def error_page(reason):
    return (HEAD % ("Triage deck — unavailable", CSS)
            + '<header class="card verdict s-bad"><p class="eyebrow">Triage reading view</p>'
              '<h1>Could not render the deck</h1>'
              '<p class="lede">%s Read the Triage Receipt directly — it is the record; '
              'this view is only a convenience.</p></header>' % esc(reason)
            + TAIL)


def main():
    md = sys.stdin.read()
    if not md.strip():
        sys.stderr.write("render-deck: empty input on stdin (expected receipt markdown).\n")
        sys.stdout.write(error_page("No receipt was provided."))
        return 1
    glossary_root = os.environ.get("CLAUDE_PLUGIN_ROOT")
    if not glossary_root:
        glossary_root = os.path.abspath(
            os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
    g = Gloss(load_glossary(os.path.join(glossary_root, "templates", "deck", "glossary.md")))
    try:
        body = build_deck(md, g)
    except Exception as exc:  # fail closed: never emit a confidently-wrong deck
        sys.stderr.write("render-deck: %s\n" % exc)
        sys.stdout.write(error_page("This receipt could not be parsed (%s)." % html.escape(str(exc))))
        return 1
    title = "Triage deck"
    sys.stdout.write(HEAD % (esc(title), CSS) + body + TAIL)
    return 0


if __name__ == "__main__":
    sys.exit(main())
