#!/bin/sh
''''command -v python3 >/dev/null 2>&1 || { echo "lq-maintainer-agent publish-site: python3 not found on PATH; nothing was generated." >&2; exit 1; } # '''
''''exec python3 "$0" "$@" # '''
"""lq-maintainer-agent -- skills/triage/scripts/publish-site.sh

Generate the static, read-only website of the agent's review records that
GitHub Pages serves from the committee's repository (LegalQuants/
lq-ai-community), so that contributors who are not maintainers -- and their
agents -- can read what the agent did on a PR or issue, and see the flow from
triage through review to merge. Adopted from
docs/proposals/public-receipts-on-lq-ai-community.md (R2 layout, R3 header,
R4 status.yaml, R5 sanitization gate, R6 FOR-AGENTS, R8 generated index).

This script only reads and writes local files and makes READ-ONLY `gh`
calls. It never posts, pushes, labels or writes to GitHub, and never runs
contributed code. Publishing what it writes is a human's act, elsewhere.

The file is a sh/python3 polyglot (repo convention, like render-deck.sh);
run it as `sh publish-site.sh ...`. Stdlib only.

Usage
  sh publish-site.sh --caches <dir>[,<dir>...] --out <dir>
                     [--repo LegalQuants/lq-ai] [--status-from gh|none]
                     [--select merged|closed|all] [--since YYYY-MM-DD]
                     [--allow-security <n>[,<n>...]] [--agent-version-tag <v>]
                     [--gh-cache <dir>] [--gh-max-age-hours <h>]
                     [--dry-run] [--plan]
  sh publish-site.sh --self-test

The whitelist (R5, PB-01). From each cache the generator accepts ONLY
  <cache>/<repo-dir>/<number>/<40-hex head SHA | issue>/receipt.md
at exactly that depth (<repo-dir> matched case-insensitively against the
repo, so `legalquants-lq-ai` and `LegalQuants-lq-ai` are one repo). It reads
that file's text and its modification time and nothing else: not the cached
deck.html (the published deck is re-rendered from the sanitized receipt by
render-deck.sh --public-header, so it is reproducible from what is
published), not meta.json, final.json, work-log*, diff*, committee-packet.md,
report.md, findings-*.md, permission-*.json, feedback logs, history/ or
review-*/ subdirectories, nor anything else. Those are maintainer-only.

The gate, in order (R5):
  1. refuse an item if any of its receipts has no receipt:v1/v2 footer
     (its carve-outs cannot be checked), E-21 in `triggers`, `vuln-suspect`
     in burden.blockers, or `held: true`. A refused item is not mentioned
     anywhere on the site.
  2. hold an item with E-08 in any receipt's triggers, or any finding whose
     visible text is tagged security, unless --allow-security names it (the
     per-item human ruling, PB-03). A held item is not mentioned either.
  3. strip local paths to item-relative site paths.
  4. replace `Name <email>` with @login when the name is a login the record
     itself (or the item's GitHub record) names; otherwise remove the whole
     token. GitHub no-reply addresses, and the noreply@anthropic.com
     co-author address, may stay.
  5. remove permission-check prose; keep only the author-class words.
  6. label every drafted comment / merge message with what GitHub shows.
  7. scan EVERY generated file (local paths, emails, meeting links,
     token-shaped strings, permission-check prose) and refuse the whole run
     -- exit 3, nothing written -- on any hit. The scan is the floor.

Exit: 0 ok; 1 error; 2 usage; 3 the scan refused the run.
"""

import argparse
import datetime as _dt
import difflib
import html
import importlib.machinery
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
GENERATOR = "lq-maintainer-agent publish-site.sh"


def plugin_root():
    root = os.environ.get("CLAUDE_PLUGIN_ROOT") or os.environ.get("PLUGIN_ROOT")
    if root and os.path.isfile(os.path.join(root, "templates", "public-header.md")):
        return root
    return os.path.abspath(os.path.join(HERE, "..", "..", ".."))


ROOT = plugin_root()
RENDER_DECK = os.path.join(ROOT, "skills", "triage", "scripts", "render-deck.sh")


def _load_render_deck():
    """Import render-deck.sh as a module so the site parses footers and
    escapes text exactly as the deck does (one parser, one sanitizer)."""
    loader = importlib.machinery.SourceFileLoader("lq_render_deck", RENDER_DECK)
    spec = importlib.util.spec_from_loader("lq_render_deck", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


RD = _load_render_deck()

# ===========================================================================
# Sanitization -- pure functions (R5 steps 3-5, 7). Tested by --self-test.
# ===========================================================================

HEX40 = re.compile(r"^[0-9a-f]{40}$")

# --- step 3: local paths ---------------------------------------------------
_PATH_STOP = r"\s`'\"<>|)\]}*,;"
PATH_RE = re.compile(
    r"(?<![\w/.:-])(?:"
    r"\$\{?(?:CLAUDE_PLUGIN_DATA|CLAUDE_PLUGIN_ROOT|PLUGIN_DATA|PLUGIN_ROOT|CODEX_HOME|HOME|TMPDIR)\}?"
    r"(?:/[^" + _PATH_STOP + r"]*)?"
    r"|~/[^" + _PATH_STOP + r"]*"
    r"|/(?:Users|home|private|var/folders|tmp|root|opt/homebrew)/[^" + _PATH_STOP + r"]*"
    r")")


def strip_paths(text, repo_dir):
    """Replace every local filesystem path with an item-relative site path
    (`pr-<n>/<head>/<file>`) when it points into a receipt cache for this
    repo, else with a neutral placeholder. `repo_dir` is the cache's repo
    directory spelling (e.g. `LegalQuants-lq-ai`), matched case-insensitively."""
    item_re = re.compile(r"/" + re.escape(repo_dir) + r"/(\d+)(?:/([^/\s]+))?(/[^\s]*)?$", re.I)

    def repl(m):
        p = m.group(0)
        trail = ""
        while p and p[-1] in ".:":
            trail = p[-1] + trail
            p = p[:-1]
        im = item_re.search(p)
        if im:
            num, seg, rest = im.group(1), im.group(2) or "", im.group(3) or ""
            if seg == "issue":
                return "issue-%s/%s" % (num, rest.lstrip("/")) + trail if rest else "issue-%s/" % num + trail
            if seg and re.match(r"^[0-9a-f]{7,39}$", seg, re.I) and not rest:
                seg = seg[:12] + "…"      # a SHA cut short in the source text
            out = "pr-%s" % num + ("/" + seg if seg else "") + rest
            return out + trail
        if "/plugins/cache/" in p or "PLUGIN_ROOT" in p:
            return "<plugin install>" + trail
        if "plugins/data" in p or "PLUGIN_DATA" in p:
            return "<agent record store>" + trail
        return "<local path>" + trail
    return PATH_RE.sub(repl, text)


# --- step 4: email addresses -----------------------------------------------
EMAIL_PAT = r"[A-Za-z0-9._%+\[\]-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}"
EMAIL_RE = re.compile(r"(?<![\w.%+\]-])" + EMAIL_PAT)
ANGLE_EMAIL_RE = re.compile(r"<(" + EMAIL_PAT + r")>|&lt;(" + EMAIL_PAT + r")&gt;")
_ALLOWED_EMAIL = re.compile(
    r"(?:@users\.noreply\.github\.com|^noreply@github\.com|^noreply@anthropic\.com)$", re.I)


def email_allowed(addr):
    return bool(_ALLOWED_EMAIL.search(addr))


def known_logins(text, extra=()):
    """Logins the record itself names: @handles, `author <login>`,
    `posted by @<login>`, plus any passed in from the item's GitHub record."""
    out = {x.lower() for x in extra if x}
    for m in re.finditer(r"(?<![\w.@/-])@([A-Za-z0-9](?:[A-Za-z0-9-]{0,38}))\b", text):
        out.add(m.group(1).lower())
    for m in re.finditer(r"\bauthor[: ]+@?([A-Za-z0-9][A-Za-z0-9-]{0,38})\b", text, re.I):
        out.add(m.group(1).lower())
    return out


_STOP = {"as", "by", "is", "of", "to", "and", "the", "a", "an", "carry", "carries", "signed", "names",
         "under", "with", "from", "off", "on", "in", "sign-off", "trailer", "trailers", "identity", "author"}


def _replace_identity(prefix, logins):
    """Rewrite the end of `prefix` (the text just before an address) and
    return (new_prefix, replacement). The name is the trailer value after
    `<Key>-by:` / `Author:`, else the trailing Capitalized words, else one
    trailing lowercase word that is not a common word."""
    tj = re.search(r"([`\"'\s]*)$", prefix).group(1)
    core = prefix[:len(prefix) - len(tj)] if tj else prefix
    tm = re.search(r"((?:[A-Z][\w-]*-[Bb]y|[Aa]uthor|[Cc]ommitter)\s*:\s*)([^:|`<>]*)$", core)
    if tm:
        name = tm.group(2).strip()
        keep = core[:tm.start(2)]
    else:
        words = re.findall(r"\S+", core)
        take = []
        for w in reversed(words):
            bare = w.strip("*_()\"'`")
            if len(take) < 4 and re.match(r"^[A-Z][\w.'-]*$", bare):
                take.insert(0, w)
                continue
            break
        if not take and words:
            bare = words[-1].strip("*_()\"'`").lstrip("@")
            if bare.lower() not in _STOP and re.match(r"^[\w.-]+$", bare):
                take = [words[-1]]
        name = " ".join(take)
        keep = core[:core.rstrip().rfind(take[0])] if take else core
        if take and take[0][:1] in "`\"'":
            keep += take[0][0]
    nb = name.strip("*_()\"'` ").lstrip("@")
    lw = nb.split()[-1].lower() if nb.split() else ""
    if keep and not keep[-1].isspace() and keep[-1] not in "`\"'(":
        keep += " "
    if len(nb.split()) == 1 and (lw in logins or re.match(r"^[a-z0-9-]+\[bot\]$", lw)):
        return keep, "@" + nb.split()[-1]       # a login the record names, or a GitHub App bot account
    return keep, "[identity removed]"


def scrub_emails(text, logins):
    """`Name <email>` -> `@login` when the name is a known login, else the
    whole `Name <email>` token -> `[identity removed]`. A bare address ->
    `[email removed]`. Allowed no-reply addresses stay."""
    logins = {x.lower() for x in logins}
    out_lines = []
    for line in text.split("\n"):
        res, pos = [], 0
        for m in ANGLE_EMAIL_RE.finditer(line):
            addr = m.group(1) or m.group(2)
            if email_allowed(addr):
                continue
            prefix = "".join(res) + line[pos:m.start()]
            keep, rep = _replace_identity(prefix, logins)
            pos = m.end()
            after = line[pos:]
            if keep[-1:] in ("`", '"', "'") and after[:1] == keep[-1:]:
                keep, pos = keep[:-1], pos + 1
            res = [keep + rep]
        line2 = "".join(res) + line[pos:]

        def bare(m):
            return m.group(0) if email_allowed(m.group(0)) else "[email removed]"
        out_lines.append(EMAIL_RE.sub(bare, line2))
    return "\n".join(out_lines)


# --- step 5: permission-check prose ----------------------------------------
PERM_ROW = re.compile(
    r"collaborators/[^/\s|`]+/permission|permission GETs?\b|collaborator[- ]permission"
    r"|operator-permission|identity/permissions|permission-[\w.-]+\.json"
    r"|identity and permission|permissions/membership"
    r"|\b(?:operator|maintainer) permission\b|\bpermission\.json\b"
    r"|operator identity|identity and role|authenticated reviewer"
    r"|orgs/[^/\s|`]+/members|check-organization-membership|membership\.json"
    r"|\bmember(?:ship)? GET\b|identity and membership|identity, membership|\band membership API\b"
    r"|^\s*\|\s*\w+\s*\|\s*Membership\b|membership HTTP", re.I)
PERM_CLAUSE = re.compile(
    r"checked (?:via|through|with) the (?:GitHub )?API|API[- ]verified|API GETs?"
    r"|verified (?:via|through|by|with) (?:the )?(?:GitHub |parent )?API"
    r"|\b(?:admin|maintain|write|triage) permission\b"
    r"|permission on `?[\w-]+/[\w.-]+"
    r"|\bverified (?:admin|maintain|write)\b"
    r"|`(?:admin|maintain|write|read|triage)`\s*(?:⇒|=>|->|,)"
    r"|collaborators/[^/\s|`]+/permission|permission GETs?\b|permissions? (?:cached|verified)"
    r"|\b(?:operator|maintainer|repository|repo|collaborator) permission\b"
    r"|\bpermission `?(?:admin|maintain|write|read|triage)`?(?![\w-])"
    r"|`(?:admin|maintain|write|read|triage)`(?:/`(?:admin|maintain|write|read|triage)`)? permission\b"
    r"|\borg membership\b|\bnon-member\b|\bverified admin\b|\b\w+ admin and org member\b"
    r"|\badmin via collaborator\b"
    r"|membership (?:API|HTTP|GET)\b|\bmembership (?:HTTP )?(?:204|404)\b|is not a member of t|\bUser/MEMBER\b"
    r"|organizational membership|orgs/[^/\s|`]+/members", re.I)
_AUTHOR_CLASS = re.compile(r"maintainer of record|external(?: contributor| author)?\b|non-member|org member", re.I)


def _author_class_words(s):
    m = _AUTHOR_CLASS.search(s)
    if not m:
        return ""
    w = m.group(0).lower()
    return "maintainer of record" if w in ("maintainer of record", "org member") else "external contributor"


def _drop_clauses(s):
    """Drop the sentences / clauses of `s` that state a permission check.
    Returns (text, author_class_word_or_empty)."""
    s = re.sub(r"\s*\([^()]*\)", lambda m: "" if PERM_CLAUSE.search(m.group(0)) else m.group(0), s)
    if not PERM_CLAUSE.search(s):
        return s, ""
    parts = re.split(r"(?<=[.;!?])\s+|\s+[—–]\s+(?=[A-Za-z@`])", s)
    kept, cls = [], ""
    for p in parts:
        if PERM_CLAUSE.search(p):
            cls = cls or _author_class_words(p)
            continue
        kept.append(p)
    return " ".join(kept).strip(), cls


def scrub_permission_prose(text):
    out = []
    for line in text.split("\n"):
        is_row = bool(re.match(r"^\s*\|", line))
        if is_row and PERM_ROW.search(line):
            continue
        if not (PERM_CLAUSE.search(line) or PERM_ROW.search(line)):
            out.append(line)
            continue
        m = re.match(r"^(\s*[-*]\s+)(\*\*)?Identity(\*\*)?\s*:?\s*(\*\*)?", line)
        if m:
            out.append(m.group(1) + "Identity: maintainer of record.")
            continue
        if is_row:
            cells = line.strip().strip("|").split("|")
            new = []
            for c in cells:
                t, cls = _drop_clauses(c.strip())
                if not t:
                    t = ("author class: " + cls) if cls else "—"
                new.append(" " + t + " ")
            out.append("|" + "|".join(new) + "|")
            continue
        lead = re.match(r"^(\s*(?:[-*>]\s+|\d+\.\s+)?)", line).group(1)
        body = line[len(lead):]
        t, cls = _drop_clauses(body)
        if PERM_ROW.search(t):
            t, _ = _drop_clauses(PERM_ROW.sub("API check", t))
            if PERM_ROW.search(t) or PERM_CLAUSE.search(t):
                t = ""
        if not t.strip():
            if cls:
                out.append(lead + "Author class: " + cls + ".")
            continue
        out.append(lead + t)
    return "\n".join(out)


def sanitize_footer(raw):
    """state.yaml is the footer verbatim, except: a non-schema `permission:`
    key (a permission-check result, seen in one older decision block) is
    dropped, and paths/emails get the same treatment as the body. Returns
    (text, list_of_changes)."""
    changes, lines = [], []
    for ln in raw.split("\n"):
        if re.match(r"^\s*permission\s*:", ln):
            changes.append("dropped non-schema key `permission`")
            continue
        lines.append(ln)
    return "\n".join(lines), changes


INTERNAL_ID_RE = re.compile(r"\b(?:libfile|file|asset|upload)_[0-9a-f]{24,}\b")


def strip_internal_ids(text):
    """Opaque IDs of the maintainer's private file store (Codex `libfile_<hex>`)
    name nothing a reader can open; they become a placeholder."""
    return INTERNAL_ID_RE.sub("<internal file id>", text)


def sanitize_text(text, repo_dir, logins):
    t = strip_internal_ids(text)
    t = strip_paths(t, repo_dir)
    t = scrub_emails(t, logins)
    t = scrub_permission_prose(t)
    return t


# --- step 7: the output scan (the floor) -----------------------------------
SCAN_CLASSES = [
    ("local-path", re.compile(r"/Users/|/home/[A-Za-z]|\$\{?CLAUDE_PLUGIN_DATA|~/\.(?:codex|claude)\b|/private/var/|/var/folders/")),
    ("email", re.compile(r"(?<![\w.%+-])" + EMAIL_PAT)),
    ("meeting-url", re.compile(r"(?:[\w-]+\.)?zoom\.us/|meet\.google\.com/|teams\.(?:microsoft|live)\.com/|[\w-]+\.webex\.com/|whereby\.com/", re.I)),
    ("token", re.compile(
        r"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}|\bgithub_pat_[A-Za-z0-9_]{20,}"
        r"|(?<![\w-])sk-[A-Za-z0-9_-]{20,}|\bxox[abprs]-[A-Za-z0-9-]{10,}|\bAKIA[0-9A-Z]{16}\b"
        r"|-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("hex-secret", re.compile(r"(?<![0-9A-Za-z])[0-9A-Fa-f]{32,}(?![0-9A-Za-z])")),
    ("permission-prose", re.compile(
        r"collaborators/[^/\s|`]+/permission|checked (?:via|through) the (?:GitHub )?API"
        r"|\b(?:admin|maintain|write) permission on\b|API[- ]verified (?:admin|maintain|write)"
        r"|\b(?:operator|repository|repo|collaborator) permission\b|\bpermission `?(?:admin|maintain|write|triage)`?(?![\w-])"
        r"|`(?:admin|maintain|write|read|triage)` permission\b|\borg membership (?:404|200|verified|check)"
        r"|orgs/[^/\s|`]+/members|\bmembership (?:HTTP |API )?(?:204|404)\b|check-organization-membership", re.I)),
]


# A hex run that is a path segment of a public package-registry download URL
# (e.g. files.pythonhosted.org/packages/05/8e/<60 hex>/pyyaml-6.0...) is the
# registry's content address, published by the registry itself.
_PUBLIC_REGISTRY_PATH = re.compile(
    r"https://(?:files\.pythonhosted\.org/packages|registry\.npmjs\.org)/[^\s)>\]]*/[0-9a-f]{32,}/[^\s/]*$", re.I)


def scan_text(text):
    """List of (class, masked excerpt). SHAs (40 hex) and SHA-256 digests
    (64 hex) are not secrets; every other 32+ hex run is a hit."""
    hits = []
    for cls, rx in SCAN_CLASSES:
        for m in rx.finditer(text):
            s = m.group(0)
            if cls == "email" and email_allowed(s):
                continue
            if cls == "hex-secret" and len(s) in (40, 64):
                continue
            if cls == "hex-secret" and _PUBLIC_REGISTRY_PATH.search(text[max(0, m.start() - 120):m.end() + 1]):
                continue
            hits.append((cls, _mask(s)))
    return hits


def _mask(s):
    s = s.replace("\n", " ")
    return (s[:6] + "…(%d chars)" % len(s)) if len(s) > 8 else s[:2] + "…"


# ===========================================================================
# Gate -- refuse / hold (R5 steps 1-2). Pure.
# ===========================================================================

_RED_FLAGS = re.compile(r"\*\*Red flags:\*\*([^\n]*)")


def security_tagged(md):
    """True when any finding's visible text is tagged security: the RP-00
    red-flags line names `F-<i> (security)` or `security finding(s) F-…`, or
    a finding header in ### Findings carries the word security. Over-holds
    rather than under-holds."""
    for m in _RED_FLAGS.finditer(md):
        line = m.group(1)
        if re.search(r"F-?\d+[^;,.]{0,20}\(\s*security\b", line, re.I):
            return True
        if re.search(r"(?<!no )(?<!No )security findings?\s+(?:F-?\d|\()", line):
            return True
    sec = RD.extract_section(md, r"Findings")
    for ln in sec.splitlines():
        if re.match(r"^\s*\*\*F-?\d+", ln) and re.search(r"\bsecurity\b", ln, re.I):
            return True
    return False


def gate(review, allow_security=False):
    """('refuse'|'hold'|'ok', reason) for one parsed review."""
    if review.get("footer") is None:
        return "refuse", "a receipt has no receipt:v1/v2 footer, so its carve-outs cannot be checked"
    r = review["footer"]
    trig = [str(t).upper() for t in (r.get("triggers") or []) if t]
    blk = [str(b).lower() for b in ((r.get("burden") or {}).get("blockers") or []) if b]
    if "E-21" in trig:
        return "refuse", "E-21 (deliberate-attack) in triggers"
    if "vuln-suspect" in blk or str(r.get("classification") or "").lower() == "vuln-suspect":
        return "refuse", "vuln-suspect (C-40) in blockers"
    if r.get("held") is True or str(r.get("held")).lower() == "true":
        return "refuse", "held at contributor request"
    if not allow_security:
        if "E-08" in trig:
            return "hold", "E-08 (vulnerability content) in triggers"
        if security_tagged(review.get("body", "")):
            return "hold", "a finding is tagged security"
    return "ok", ""


# ===========================================================================
# Drafts vs GitHub (R5 step 6). Pure.
# ===========================================================================

def _norm(s):
    s = re.sub(r"\s+", " ", (s or "")).strip()
    return s


def draft_match(draft, candidates):
    """Best label for a draft against posted texts: 'posted as drafted'
    (whitespace-normalised equal), 'posted with edits' (similar), or None."""
    d = _norm(draft)
    if not d:
        return None, None
    best, best_i = 0.0, None
    for i, c in enumerate(candidates):
        cn = _norm(c)
        if not cn:
            continue
        if cn == d:
            return "posted as drafted", i
        sm = difflib.SequenceMatcher(None, d, cn, autojunk=False)
        if sm.real_quick_ratio() < 0.45 or sm.quick_ratio() < 0.45:
            continue
        r = sm.ratio()
        if r > best:
            best, best_i = r, i
    if best >= 0.55:
        return "posted with edits", best_i
    return None, None


# ===========================================================================
# Template reading (templates/public-header.md, templates/for-agents.md)
# ===========================================================================

def read_blocks(path, prefix):
    """{name: text} for every `<!-- <prefix>:<name> -->` marker, the text
    being the first fenced block after it."""
    with open(path, encoding="utf-8") as fh:
        t = fh.read()
    out = {}
    for m in re.finditer(r"<!--\s*" + re.escape(prefix) + r":([\w-]+)\s*-->\s*\n```[a-z]*\n(.*?)\n```", t, re.S):
        out[m.group(1)] = m.group(2)
    return out


def fill(tpl, values):
    return re.sub(r"\{\{(\w+)\}\}", lambda m: str(values.get(m.group(1), "")), tpl)


def md_inline(s):
    """Trusted mini-markdown inline: escape, then **bold**, `code`, links
    (https or site-relative targets only)."""
    s = html.escape(s, quote=False)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", s)

    def link(m):
        label, url = m.group(1), m.group(2)
        if re.match(r"^(https://|[\w./#-]+$)", url) and not url.startswith("javascript"):
            return '<a href="%s">%s</a>' % (html.escape(url, quote=True), label)
        return label
    s = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", link, s)
    return s


def md_to_html(md):
    out, para, ul = [], [], []

    def flush():
        if para:
            out.append("<p>%s</p>" % md_inline(" ".join(para)))
            para.clear()
        if ul:
            out.append("<ul>%s</ul>" % "".join("<li>%s</li>" % md_inline(x) for x in ul))
            ul.clear()
    for ln in md.split("\n"):
        s = ln.strip()
        if not s:
            flush()
            continue
        h = re.match(r"^(#{1,4})\s+(.*)$", s)
        if h:
            flush()
            n = len(h.group(1))
            out.append("<h%d>%s</h%d>" % (n, md_inline(h.group(2)), n))
        elif s.startswith("- "):
            if para:
                flush()
            ul.append(s[2:])
        elif ul and ln.startswith("  "):
            ul[-1] += " " + s
        else:
            para.append(s)
    flush()
    return "\n".join(out)


# ===========================================================================
# Discovery and parsing (the whitelist, PB-01)
# ===========================================================================

FOOTER_SPAN = re.compile(r"<!--\s*lq-maintainer-agent:receipt:v[12]\s*\n(.*?)-->", re.S)


def discover(caches, repo):
    want = repo.lower().replace("/", "-")
    found = []
    for c in caches:
        c = os.path.expanduser(c)
        if not os.path.isdir(c):
            continue
        for rd in sorted(os.listdir(c)):
            if rd.lower() != want or not os.path.isdir(os.path.join(c, rd)):
                continue
            for num in sorted(os.listdir(os.path.join(c, rd))):
                if not num.isdigit():
                    continue
                nd = os.path.join(c, rd, num)
                if not os.path.isdir(nd):
                    continue
                for h in sorted(os.listdir(nd)):
                    if not (HEX40.match(h) or h == "issue"):
                        continue
                    p = os.path.join(nd, h, "receipt.md")
                    if os.path.isfile(p):
                        found.append({"cache": c, "repo_dir": rd, "num": int(num), "dir": h, "path": p})
    return found


def _footer_get(r, *keys):
    v = r
    for k in keys:
        if not isinstance(v, dict):
            return None
        v = v.get(k)
    return v


def _clean_enum(v):
    if v is None or isinstance(v, (bool, list, dict)):
        return None
    s = str(v).strip()
    return None if s.lower() in ("", "null", "n-a", "none") else s


def parse_review(entry):
    with open(entry["path"], encoding="utf-8", errors="replace") as fh:
        text = fh.read()
    mtime = os.path.getmtime(entry["path"])
    m = FOOTER_SPAN.search(text)
    rev = dict(entry)
    rev["mtime"] = mtime
    rev["at"] = _dt.datetime.fromtimestamp(mtime, _dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    rev["raw"] = text
    if not m:
        rev["footer"] = None
        rev["footer_raw"] = None
        rev["body"] = text
        return rev
    rev["footer_raw"] = m.group(1).rstrip("\n")
    rev["footer"] = RD.parse_footer(m.group(1))
    rev["body"] = (text[:m.start()].rstrip() + "\n" + text[m.end():].strip()).rstrip() + "\n"
    r = rev["footer"]
    prof = _clean_enum(r.get("profile")) or ("issue" if entry["dir"] == "issue" else "pr")
    rev["kind"] = "issue" if prof == "issue" else "pr"
    pin = r.get("pinned") or {}
    rev["agent_version"] = _clean_enum(pin.get("agent_version")) or "unknown"
    rev["model"] = _clean_enum(pin.get("model_id")) or "not recorded"
    rev["canon_sha"] = _clean_enum(pin.get("canon_sha")) or ""
    head = _clean_enum(pin.get("pr_head_sha"))
    if rev["kind"] == "pr":
        rev["head"] = head if head and HEX40.match(head) else entry["dir"]
    else:
        rev["head"] = rev["canon_sha"] if HEX40.match(rev["canon_sha"] or "") else "issue"
    hm = re.search(r"runtime[=:]\s*`?(codex|claude-code)\b", text, re.I) or \
        re.search(r"\bRuntime:\s*`?(codex|claude-code)\b", text, re.I)
    rev["host"] = hm.group(1).lower() if hm else ("codex" if "/.codex/" in entry["cache"] + "/" else "claude-code")
    rev["lane"] = _clean_enum(r.get("lane")) or "not recorded"
    rev["tier"] = _clean_enum(r.get("tier"))
    if rev["kind"] == "issue":
        rev["outcome"] = _clean_enum(r.get("recommendation"))
    else:
        o = _clean_enum(r.get("outcome"))
        if o:
            for p in ("merge-after", "discuss"):
                if o.lower().startswith(p):
                    o = p
        rev["outcome"] = o
    counts = {"blocking": 0, "major": 0, "minor": 0}
    for f in r.get("findings") or []:
        sev = str((f or {}).get("severity") or "").lower() if isinstance(f, dict) else ""
        if sev in ("blocking", "blocker"):
            counts["blocking"] += 1
        elif sev in ("minor", "nit"):
            counts["minor"] += 1
        else:
            counts["major"] += 1
    rev["findings"] = counts
    dec = r.get("decision") if isinstance(r.get("decision"), dict) else None
    sec = RD.extract_section(rev["body"], r"Maintainer decision")
    align = _clean_enum((dec or {}).get("alignment"))
    if not align and sec:
        am = re.search(r"recommendation\s+\**(accepted|adjusted|overridden)", sec, re.I)
        align = am.group(1).lower() if am else None
    rev["decision"] = {"recorded": bool(dec) or bool(sec.strip()), "alignment": align,
                       "date": None}
    if rev["decision"]["recorded"]:
        dm = re.search(r"(\d{4}-\d{2}-\d{2})", sec or "") or re.search(r"(\d{4}-\d{2}-\d{2})", str((dec or {}).get("date") or ""))
        rev["decision"]["date"] = dm.group(1) if dm else None
    am = re.search(r"reviewed and posted by @([A-Za-z0-9-]+)", text)
    rev["attributed_to"] = am.group(1) if am else None
    rev["draft_comment"] = RD.extract_draft_block(rev["body"], r"Drafted public comment") if hasattr(RD, "extract_draft_block") else ""
    rev["draft_merge"] = RD.extract_draft_block(rev["body"], r"Drafted merge message") if hasattr(RD, "extract_draft_block") else ""
    tm = re.search(r"^##\s+Triage Receipt\s+—\s+(?:PR|Issue)\s+#\d+:\s*(.+)$", text, re.M)
    rev["title"] = tm.group(1).strip() if tm else ""
    return rev


# ===========================================================================
# GitHub state (R4) -- read-only gh, cached
# ===========================================================================

def _run(cmd):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return 1, "", str(exc)
    return p.returncode, p.stdout, p.stderr


def _login(x):
    return (x or {}).get("login") if isinstance(x, dict) else None


def fetch_github(num, kind_hint, repo, cache_dir, max_age_h):
    """Trimmed GitHub record for one item (logins only, never display
    names), from the cache when fresh, else from read-only gh calls."""
    os.makedirs(cache_dir, exist_ok=True)
    cf = os.path.join(cache_dir, "%s-%d.json" % (repo.replace("/", "-").lower(), num))
    if os.path.isfile(cf):
        try:
            with open(cf, encoding="utf-8") as fh:
                d = json.load(fh)
            age = (_dt.datetime.now(_dt.timezone.utc) - _dt.datetime.strptime(d["fetched_at"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=_dt.timezone.utc)).total_seconds() / 3600
            if age <= max_age_h:
                return d
        except (OSError, ValueError, KeyError):
            pass
    order = ["pr", "issue"] if kind_hint != "issue" else ["issue", "pr"]
    raw, kind = None, None
    for k in order:
        if k == "pr":
            rc, out, _ = _run(["gh", "pr", "view", str(num), "--repo", repo, "--json",
                               "state,createdAt,mergedAt,mergedBy,mergeCommit,closedAt,title,author,url,comments,reviews,labels,headRefOid"])
        else:
            rc, out, _ = _run(["gh", "issue", "view", str(num), "--repo", repo, "--json",
                               "state,stateReason,createdAt,closedAt,title,author,url,comments,labels"])
        if rc == 0:
            try:
                raw, kind = json.loads(out), k
                break
            except ValueError:
                pass
    if raw is None:
        return None
    d = {
        "fetched_at": _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "kind": kind, "state": str(raw.get("state") or "").lower(),
        "state_reason": str(raw.get("stateReason") or "").lower() or None,
        "created_at": raw.get("createdAt"), "merged_at": raw.get("mergedAt"),
        "closed_at": raw.get("closedAt"), "merged_by": _login(raw.get("mergedBy")),
        "merge_commit": (raw.get("mergeCommit") or {}).get("oid") if isinstance(raw.get("mergeCommit"), dict) else None,
        "title": raw.get("title"), "author": _login(raw.get("author")), "url": raw.get("url"),
        "head": raw.get("headRefOid"),
        "labels": [l.get("name") for l in raw.get("labels") or [] if isinstance(l, dict)],
        "comments": [{"login": _login(c.get("author")), "at": c.get("createdAt"), "url": c.get("url"),
                      "body": c.get("body") or "", "type": "comment"} for c in raw.get("comments") or []],
        "reviews": [{"login": _login(c.get("author")), "at": c.get("submittedAt"), "url": None,
                     "body": c.get("body") or "", "type": "review", "state": c.get("state")}
                    for c in raw.get("reviews") or []],
        "merge_message": None,
    }
    if d["merge_commit"]:
        rc, out, _ = _run(["gh", "api", "repos/%s/commits/%s" % (repo, d["merge_commit"]), "--jq", ".commit.message"])
        if rc == 0:
            d["merge_message"] = out.rstrip("\n")
    with open(cf, "w", encoding="utf-8") as fh:
        json.dump(d, fh, indent=1)
    return d


# ===========================================================================
# Words (plain language) -- glossary-backed
# ===========================================================================

G = RD.Gloss(RD.load_glossary(os.path.join(ROOT, "templates", "deck", "glossary.md")))
HOST_WORD = {"codex": "Codex", "claude-code": "Claude Code"}


def outcome_words(rev):
    o = rev.get("outcome")
    if not o:
        return "no action outcome recorded (older record; lane: %s)" % rev.get("lane", "not recorded")
    key = ("recommendation:" if rev["kind"] == "issue" else "outcome:") + o.lower()
    cap = G.cap(key, "")
    return cap if cap else o


def decision_words(dec):
    if not dec or not dec.get("recorded"):
        return "none recorded — absence is not agreement"
    a = dec.get("alignment")
    return {"accepted": "accepted the agent's recommendation",
            "adjusted": "adjusted the agent's recommendation",
            "overridden": "overrode the agent's recommendation"}.get(a, "recorded (how it relates to the recommendation is not stated)")


def short(sha, n=9):
    return (sha or "")[:n]


def day(ts):
    return (ts or "")[:10]


def github_words(gh, kind):
    if gh is None:
        return "not checked — this build ran offline"
    st = gh.get("state")
    if st == "merged":
        s = "merged %s" % day(gh.get("merged_at"))
        if gh.get("merged_by"):
            s += " by @%s" % gh["merged_by"]
        if gh.get("merge_commit"):
            s += " (merge commit `%s`)" % short(gh["merge_commit"])
        return s
    if st == "closed":
        if kind == "issue":
            why = " as %s" % gh["state_reason"].replace("_", " ") if gh.get("state_reason") else ""
            return "closed %s%s" % (day(gh.get("closed_at")), why)
        return "closed %s without merging" % day(gh.get("closed_at"))
    return "open"


# ===========================================================================
# Building the site (in memory; written only after the scan is clean)
# ===========================================================================

SITE_CSS_EXTRA = """
.site{max-width:860px;margin:0 auto;padding:20px 16px 64px}
.nav{font-size:14px;color:var(--ink-faint);margin:0 0 18px}
.nav a{color:var(--accent-ink)}
h1{font-family:var(--serif);font-weight:600;font-size:30px;line-height:1.2;margin:.2em 0 .3em;overflow-wrap:anywhere}
h2{font-family:var(--serif);font-weight:600;font-size:22px;margin:28px 0 10px}
a{color:var(--accent-ink)}
code{font-family:var(--mono);font-size:.88em;overflow-wrap:anywhere}
.ph{padding:18px 20px;border-left:6px solid var(--accent);font-size:15.5px;margin:0 0 22px}
.ph p{margin:0 0 10px}.ph p:last-child{margin-bottom:0}
.meta{color:var(--ink-soft);font-size:15px;margin:0 0 18px}
.legend{color:var(--ink-soft);font-size:14.5px;background:var(--surface-2);border:1px solid var(--line-soft);border-radius:10px;padding:10px 14px}
.timeline{list-style:none;margin:0;padding:0;border-left:2px solid var(--line);margin-left:8px}
.ev{position:relative;padding:0 0 18px 22px}
.ev::before{content:"";position:absolute;left:-7px;top:6px;width:12px;height:12px;border-radius:50%;background:var(--surface);border:2px solid var(--ink-faint)}
.ev.k-review::before{border-color:var(--accent);background:var(--accent)}
.ev.k-merged::before{border-color:var(--ok);background:var(--ok)}
.ev.k-closed::before{border-color:var(--bad);background:var(--bad)}
.ev.k-decision::before{border-color:var(--warn);background:var(--warn)}
.ev.k-nodecision::before{border-color:var(--warn)}
.ev .when{font-size:13px;color:var(--ink-faint);letter-spacing:.02em}
.ev .what{margin:2px 0 0}
.ev .card{padding:12px 16px;margin-top:6px}
.ev dl{display:grid;grid-template-columns:max-content 1fr;gap:2px 14px;margin:6px 0 0;font-size:15px}
.ev dt{color:var(--ink-faint)}.ev dd{margin:0;overflow-wrap:anywhere}
.ev .note{font-size:14px;color:var(--ink-soft);margin:6px 0 0}
.items{list-style:none;margin:0;padding:0}
.items li{padding:12px 0;border-bottom:1px solid var(--line-soft)}
.items .t{font-weight:600;overflow-wrap:anywhere}
.items .s{font-size:14.5px;color:var(--ink-soft);margin-top:2px}
.chip{display:inline-block;font-size:12.5px;padding:1px 8px;border-radius:999px;border:1px solid var(--line);background:var(--surface-2);color:var(--ink-soft);margin:2px 4px 2px 0}
.chip.ok{color:var(--ok);background:var(--ok-bg);border-color:var(--ok-line)}
.chip.warn{color:var(--warn);background:var(--warn-bg);border-color:var(--warn-line)}
.chip.bad{color:var(--bad);background:var(--bad-bg);border-color:var(--bad-line)}
.prose{max-width:70ch}
.foot{margin-top:40px;padding-top:14px;border-top:1px solid var(--line-soft);font-size:13px;color:var(--ink-faint)}
.foot a{color:var(--accent-ink)}
@media (max-width:560px){h1{font-size:25px}.ev dl{grid-template-columns:1fr}.ev dt{margin-top:4px}}
"""


def site_css():
    """The deck's own tokens (light + dark + explicit theme overrides) and
    base type, so the site and the decks read as one thing."""
    css = RD.CSS
    cut = css.find(".wrap{")
    base = css[:cut] if cut > 0 else css
    return base + SITE_CSS_EXTRA


def page(title, body, rel, footer_line):
    return ('<!doctype html><html lang="en"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1">'
            ''  # v0.8: no robots block — the site exists to be found; a committee may ask for one (R11)
            '<title>%s</title><style>%s</style></head><body><main class="site">'
            '<p class="nav"><a href="%sindex.html">All reviews</a> · <a href="%sabout.html">About this site</a> · '
            '<a href="%sfor-agents.html">For agents</a></p>%s'
            '<footer class="foot">%s <a href="%sabout.html">About</a> · <a href="%sfor-agents.html">For agents</a></footer>'
            '</main></body></html>') % (html.escape(title), site_css(), rel, rel, rel, body,
                                        html.escape(footer_line), rel, rel)


class Site:
    def __init__(self, args):
        self.args = args
        self.repo = args.repo
        self.files = {}           # relpath -> str
        self.now = _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        self.ph = read_blocks(os.path.join(ROOT, "templates", "public-header.md"), "public-header")
        self.fa = read_blocks(os.path.join(ROOT, "templates", "for-agents.md"), "for-agents")
        for need in ("short", "if-self-review", "if-older-rules", "if-escalate", "if-drafts", "discrepancy", "long"):
            if need not in self.ph:
                raise SystemExit("publish-site: templates/public-header.md lacks the `%s` block." % need)
        if "page" not in self.fa:
            raise SystemExit("publish-site: templates/for-agents.md lacks the `page` block.")
        self.disc = {}
        for ln in self.ph["discrepancy"].splitlines():
            m = re.match(r"^- ([\w-]+):\s*(.*)$", ln.strip())
            if m:
                self.disc[m.group(1)] = m.group(2)
        self.current = args.agent_version_tag or RD.renderer_version()
        self.agent_repo = "https://github.com/houfu/lq-maintainer-agent"

    # -- header ------------------------------------------------------------
    def header_md(self, item, rev, rel):
        gh = item["gh"]
        kind_label = "issue" if item["kind"] == "issue" else "PR"
        newest = item["reviews"][-1]
        dec = item["decision"]
        vals = {
            "repo": self.repo, "repo_name": self.repo.split("/")[-1], "kind_label": kind_label,
            "number": item["num"], "agent_version": rev["agent_version"],
            "host": HOST_WORD.get(rev["host"], "not recorded"), "model": rev["model"],
            "head_phrase": ("at head `%s`" % short(rev["head"])) if item["kind"] == "pr" else "on the issue as it then stood",
            "canon_short": short(rev["canon_sha"]) or "not recorded",
            "reviewed_on": day(rev["at"]),
            "rules_url": "%s/tree/v%s/rules" % (self.agent_repo, rev["agent_version"]),
            "governance_url": "https://github.com/%s/blob/main/GOVERNANCE.md" % self.repo,
            "recommendation": "%s (`%s`)" % (outcome_words(newest), newest.get("outcome") or "none") if newest.get("outcome") else outcome_words(newest),
            "decision": decision_words(dec),
            "checked_on": day(gh["fetched_at"]) if gh else "n/a",
            "github": github_words(gh, item["kind"]),
            "item_url": (gh or {}).get("url") or "https://github.com/%s/%s/%d" % (self.repo, "issues" if item["kind"] == "issue" else "pull", item["num"]),
            "for_agents_url": rel + "for-agents.html",
            "current_version": self.current,
            "compare_url": "%s/compare/v%s...v%s" % (self.agent_repo, rev["agent_version"], self.current),
            "github_head_short": short((gh or {}).get("head")),
        }
        if rev is not newest:
            vals["recommendation"] = vals["recommendation"] + " (newest review; this page shows an earlier one)"
        discs = []
        for key in item["discrepancies"]:
            if key in self.disc:
                discs.append(fill(self.disc[key], vals))
        vals["discrepancy"] = (" " + " ".join(discs)) if discs else ""
        parts = [fill(self.ph["short"], vals)]
        if item["self_review"]:
            parts.append(fill(self.ph["if-self-review"], vals))
        if rev["agent_version"] != self.current:
            parts.append(fill(self.ph["if-older-rules"], vals))
        if rev["lane"] == "escalate":
            parts.append(fill(self.ph["if-escalate"], vals))
        if rev.get("draft_labels"):
            vals["drafts"] = " ".join("%s: %s." % (k, v) for k, v in rev["draft_labels"])
            parts.append(fill(self.ph["if-drafts"], vals))
        return "\n\n".join(parts)

    def footer_line(self):
        return ("Generated by %s at %s from records produced by agent versions %s. "
                "A human maintainer decides, every time." % (GENERATOR, self.now, ", ".join(self.versions)))

    # -- item assembly -----------------------------------------------------
    def assemble(self, entries):
        by = {}
        for e in entries:
            rev = parse_review(e)
            key = (rev["num"], rev.get("head") or e["dir"])
            by.setdefault(rev["num"], {})
            prev = by[rev["num"]].get(key)
            if prev is None or rev["mtime"] > prev["mtime"]:
                by[rev["num"]][key] = rev
        items = []
        for num in sorted(by):
            revs = sorted(by[num].values(), key=lambda r: r["mtime"])
            kind = "issue" if any(r.get("kind") == "issue" for r in revs) else "pr"
            items.append({"num": num, "kind": kind, "reviews": revs})
        return items

    def dispose(self, item, allow):
        for rev in item["reviews"]:
            g, why = gate(rev, allow_security=allow)
            if g != "ok":
                return g, "%s (head %s)" % (why, short(rev.get("head") or rev["dir"]))
        return "ok", ""

    def enrich(self, item):
        a = self.args
        gh = None
        if a.status_from == "gh":
            gh = fetch_github(item["num"], item["kind"], self.repo, a.gh_cache, a.gh_max_age_hours)
        item["gh"] = gh
        if gh and gh.get("kind"):
            item["kind"] = gh["kind"]
        revs = item["reviews"]
        newest = revs[-1]
        item["title"] = (gh or {}).get("title") or newest.get("title") or ""
        decs = [r for r in revs if r.get("decision", {}).get("recorded")]
        item["decision"] = decs[-1]["decision"] if decs else {"recorded": False, "alignment": None, "date": None}
        item["decision_review"] = decs[-1] if decs else None
        st = (gh or {}).get("state")
        out = (newest.get("outcome") or "").lower()
        d = []
        if gh:
            if st == "merged" and not item["decision"]["recorded"]:
                d.append("merged-no-decision")
            if st == "closed" and not item["decision"]["recorded"]:
                d.append("closed-no-decision")
            if item["kind"] == "pr" and st == "merged" and out and not out.startswith("merge"):
                d.append("merged-not-recommended")
            if item["kind"] == "pr" and st == "closed" and out == "merge":
                d.append("closed-merge-recommended")
            if item["kind"] == "pr" and st == "open" and out == "merge":
                d.append("open-merge-recommended")
        if item["decision"].get("alignment") == "overridden":
            d.append("decision-overridden")
        if item["decision"].get("alignment") == "adjusted":
            d.append("decision-adjusted")
        if gh and item["kind"] == "pr" and gh.get("head") and gh["head"] != newest.get("head"):
            d.append("head-moved")
        item["discrepancies"] = d
        attributed = newest.get("attributed_to") or next((r.get("attributed_to") for r in revs[::-1] if r.get("attributed_to")), None)
        item["self_review"] = bool(gh and gh.get("author") and attributed and gh["author"].lower() == attributed.lower())
        # drafts vs GitHub
        posted = []
        if gh:
            posted = [c for c in gh["comments"] + gh["reviews"] if "lq-maintainer-agent" in (c.get("body") or "")]
        item["agent_comments"] = []
        matched = {}
        for c in posted:
            label, idx = None, None
            cands = [r.get("draft_comment") or "" for r in revs]
            label, idx = draft_match(c["body"], cands)
            if label is None and re.search(r"^#{1,3}\s*Triage Receipt", c["body"], re.M):
                label = "the full receipt, posted (the pre-v0.7 format)"
            if label is None:
                label = "unknown — agent-attributed, but it matches no draft in the published records"
            if idx is not None:
                matched.setdefault(idx, label)
            item["agent_comments"].append({"at": c.get("at"), "login": c.get("login"), "url": c.get("url"),
                                           "type": c.get("type"), "label": label,
                                           "head": revs[idx]["head"] if idx is not None else None})
        merge_best = None
        if gh and gh.get("merge_message"):
            drafts = [r.get("draft_merge") or "" for r in revs]
            # the newest draft that matches wins; earlier drafts read "not used"
            for i in range(len(drafts) - 1, -1, -1):
                lab, _ = draft_match(drafts[i], [gh["merge_message"]])
                if lab:
                    merge_best = (i, {"posted as drafted": "used as drafted", "posted with edits": "used with edits"}[lab])
                    break
        for i, r in enumerate(revs):
            labels = []
            if (r.get("draft_comment") or "").strip():
                if not gh:
                    labels.append(("Drafted public comment", "unknown (GitHub not checked)"))
                else:
                    labels.append(("Drafted public comment", matched.get(i, "not posted")))
            if (r.get("draft_merge") or "").strip():
                if not gh:
                    labels.append(("Drafted merge message", "unknown (GitHub not checked)"))
                elif gh.get("merge_message"):
                    if merge_best and merge_best[0] == i:
                        labels.append(("Drafted merge message", merge_best[1]))
                    elif merge_best:
                        labels.append(("Drafted merge message", "not used (a later draft was)"))
                    else:
                        labels.append(("Drafted merge message", "not used"))
                elif st == "merged":
                    labels.append(("Drafted merge message", "unknown (merge commit message not read)"))
                else:
                    labels.append(("Drafted merge message", "not used"))
            r["draft_labels"] = labels
        acts = [r["at"] for r in revs] + [c["at"] for c in item["agent_comments"] if c.get("at")]
        if gh:
            acts += [x for x in (gh.get("merged_at"), gh.get("closed_at"), gh.get("created_at")) if x]
        item["last_activity"] = max(acts)
        item["first_review"] = revs[0]["at"]

    def selected(self, item):
        sel = self.args.select
        if self.args.since and day(item["last_activity"]) < self.args.since:
            return False, "older than --since %s" % self.args.since
        if sel == "all":
            return True, ""
        st = (item["gh"] or {}).get("state")
        if st is None:
            return False, "not selected (--select %s, GitHub state unknown offline)" % sel
        if st != sel:
            return False, "not selected (GitHub: %s)" % st
        return True, ""

    # -- per-item output ---------------------------------------------------
    def item_dir(self, item):
        return "%s-%d" % (item["kind"], item["num"])

    def build_item(self, item):
        idir = self.item_dir(item)
        gh = item["gh"]
        extra_logins = []
        if gh:
            extra_logins = [gh.get("author"), gh.get("merged_by")] + [c.get("login") for c in gh["comments"] + gh["reviews"]]
        paths = {"page": idir + "/index.html", "status": idir + "/status.yaml", "heads": {}}
        for rev in item["reviews"]:
            hdir = "%s/%s" % (idir, rev["head"])
            logins = known_logins(rev["raw"], extra_logins)
            body = sanitize_text(rev["body"], rev["repo_dir"], logins)
            body = self.label_drafts(body, rev)
            foot, changes = sanitize_footer(rev["footer_raw"])
            foot = sanitize_text(foot, rev["repo_dir"], logins)
            rev["footer_changes"] = changes
            hmd = self.header_md(item, rev, "../../")
            nav = "[Flow page for this %s](../index.html) · [All reviews](../../index.html) · [About](../../about.html) · [For agents](../../for-agents.html)" % ("issue" if item["kind"] == "issue" else "PR")
            receipt_md = ("> " + hmd.replace("\n", "\n> ") + "\n>\n> " + nav + "\n>\n> *" + self.footer_line() + "*\n\n"
                          + body)
            self.files[hdir + "/receipt.md"] = receipt_md
            self.files[hdir + "/state.yaml"] = ("# lq-maintainer-agent:receipt footer, verbatim from the record%s\n" % (
                " (" + "; ".join(changes) + ")" if changes else "") + foot.strip("\n") + "\n")
            header_html = ('<div class="public-header"><p class="ph-nav"><a href="../index.html">← Flow page for this %s</a> · '
                           '<a href="../../index.html">All reviews</a> · <a href="../../about.html">About</a> · '
                           '<a href="../../for-agents.html">For agents</a></p><section class="card ph">%s'
                           '<p class="ph-gen">%s</p></section></div>') % (
                "issue" if item["kind"] == "issue" else "PR", md_to_html(hmd), html.escape(self.footer_line()))
            deck, err = self.render_deck(body + "\n<!-- lq-maintainer-agent:receipt:v2\n" + foot.strip("\n") + "\n-->\n", header_html)
            if deck is None:
                return "refuse", "the deck could not be re-rendered from the sanitized receipt (head %s): %s" % (short(rev["head"]), err)
            self.files[hdir + "/deck.html"] = deck
            paths["heads"][rev["head"]] = {"deck": hdir + "/deck.html", "receipt": hdir + "/receipt.md", "state": hdir + "/state.yaml"}
        item["paths"] = paths
        self.files[idir + "/status.yaml"] = self.status_yaml(item)
        self.files[idir + "/index.html"] = self.item_page(item)
        return "ok", ""

    def label_drafts(self, body, rev):
        labels = dict(rev.get("draft_labels") or [])

        def ins(m, key):
            lab = labels.get(key)
            if not lab:
                return m.group(0)
            return m.group(0) + "\n> **Draft status on GitHub: %s.** A draft is text prepared for a maintainer; only what GitHub shows was said.\n" % lab
        body = re.sub(r"^###\s+Drafted public comment[^\n]*\n", lambda m: ins(m, "Drafted public comment"), body, count=1, flags=re.M)
        body = re.sub(r"^###\s+Drafted merge message[^\n]*\n", lambda m: ins(m, "Drafted merge message"), body, count=1, flags=re.M)
        return body

    def render_deck(self, receipt, header_html):
        with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False, encoding="utf-8") as fh:
            fh.write(header_html)
            hp = fh.name
        try:
            env = dict(os.environ, CLAUDE_PLUGIN_ROOT=ROOT)
            p = subprocess.run(["python3", RENDER_DECK, "--public-header", hp], input=receipt,
                               capture_output=True, text=True, env=env, timeout=120)
        finally:
            os.unlink(hp)
        if p.returncode != 0:
            return None, (p.stderr.strip().splitlines() or ["exit %d" % p.returncode])[-1][:160]
        return p.stdout, ""

    def status_yaml(self, item):
        gh = item["gh"] or {}
        newest = item["reviews"][-1]
        st = gh.get("state") or "unknown"
        at = gh.get("merged_at") if st == "merged" else (gh.get("closed_at") if st == "closed" else gh.get("created_at"))
        method = "n-a"
        lines = [
            "# What GitHub showed when this site was generated (R4). If this and a record disagree, GitHub is right.",
            "checked_at: %s" % (gh.get("fetched_at") or "null"),
            "github:",
            "  state: %s            # open | merged | closed | unknown" % st,
            "  at: %s" % (at or "null"),
            "  by: %s" % (gh.get("merged_by") or "null"),
            "  merge_commit: %s" % (gh.get("merge_commit") or "null"),
            "  method: %s" % method,
            "  author: %s" % (gh.get("author") or "null"),
            "recommendation:",
            "  outcome: %s" % (newest.get("outcome") or "null"),
            "  at_head: %s" % newest["head"],
            "decision:",
            "  recorded: %s" % ("true" if item["decision"]["recorded"] else "false"),
            "  alignment: %s" % (item["decision"].get("alignment") or "n-a"),
            "head_moved_since_review: %s" % ("true" if "head-moved" in item["discrepancies"] else ("false" if gh else "unknown")),
            "discrepancies: [%s]" % ", ".join(item["discrepancies"]),
            "drafts:",
        ]
        any_d = False
        for r in item["reviews"]:
            for k, v in r.get("draft_labels") or []:
                any_d = True
                lines.append("  - {head: %s, draft: %s, status: %s}" % (
                    r["head"], "public-comment" if "comment" in k else "merge-message",
                    {"posted as drafted": "posted-as-drafted", "posted with edits": "posted-with-edits",
                     "used as drafted": "posted-as-drafted", "used with edits": "posted-with-edits",
                     "not posted": "not-posted", "not used": "not-posted",
                     "not used (a later draft was)": "not-posted"}.get(v, "unknown")))
        if not any_d:
            lines[-1] = "drafts: []"
        return "\n".join(lines) + "\n"

    def item_page(self, item):
        rel = "../"
        gh = item["gh"]
        newest = item["reviews"][-1]
        kl = "Issue" if item["kind"] == "issue" else "PR"
        hmd = self.header_md(item, newest, rel)
        evs = []   # (ts, order, html)
        if gh and gh.get("created_at"):
            evs.append((gh["created_at"], 0, "k-open", "Opened on GitHub · %s" % day(gh["created_at"]),
                        "Opened by @%s — “%s”" % (html.escape(gh.get("author") or "unknown"), RD.sanitize(item["title"])[0])))
        for i, r in enumerate(item["reviews"]):
            f = r["findings"]
            dl = [("Agent", "lq-maintainer-agent v%s, running under %s" % (html.escape(r["agent_version"]), HOST_WORD.get(r["host"], "not recorded"))),
                  ("Model", "<code>%s</code>" % html.escape(r["model"])),
                  ("Head" if item["kind"] == "pr" else "Read against", "<code>%s</code>" % short(r["head"] if item["kind"] == "pr" else r["canon_sha"])),
                  ("Lane", html.escape(r["lane"]) + (" — a security-sensitive path was touched, so a human reviewer was required; routing, not a finding" if r["lane"] == "escalate" else "")),
                  ("Tier", html.escape(r["tier"]) if r.get("tier") else "not recorded"),
                  ("Outcome", html.escape(outcome_words(r)) + (" (<code>%s</code>)" % html.escape(r["outcome"]) if r.get("outcome") else "")),
                  ("Findings", "%d blocking · %d major · %d minor" % (f["blocking"], f["major"], f["minor"]))]
            for k, v in r.get("draft_labels") or []:
                dl.append((k, html.escape(v)))
            hd = "%s/" % r["head"]
            links = '<a href="%sdeck.html">Read the deck</a> · <a href="%sreceipt.md">receipt.md</a> · <a href="%sstate.yaml">state.yaml</a>' % (hd, hd, hd)
            note = ""
            if gh and (gh.get("merged_at") or gh.get("closed_at")) and r["at"] > (gh.get("merged_at") or gh.get("closed_at")):
                note = '<p class="note">This record was last written after the %s closed on GitHub (a closing update), so its file time is later than the review itself.</p>' % kl
            title = "Agent review %d of %d%s" % (i + 1, len(item["reviews"]), " · newest" if r is newest else "")
            evs.append((r["at"], 1, "k-review", "%s · about %s, from the record's file time" % (title, day(r["at"])),
                        '<div class="card"><dl>%s</dl><p class="note">%s</p>%s</div>' % (
                            "".join("<dt>%s</dt><dd>%s</dd>" % (k, v) for k, v in dl), links, note)))
            if item["decision_review"] is r:
                dd = item["decision"]
                evs.append((r["at"], 2, "k-decision", "Maintainer's recorded decision%s" % (" · " + dd["date"] if dd.get("date") else ""),
                            "The maintainer %s. Recorded in the review of head <code>%s</code>; the record says it in the maintainer's words." % (
                                html.escape(decision_words(dd)), short(r["head"]))))
        if not item["decision"]["recorded"]:
            evs.append((newest["at"], 3, "k-nodecision", "Maintainer's decision · not recorded",
                        "No maintainer decision was recorded in any review of this %s. Absence is not agreement." % kl))
        for c in item["agent_comments"]:
            where = ('<a href="%s">%s</a>' % (html.escape(c["url"], quote=True), "comment") if c.get("url") and c["url"].startswith("https://github.com/")
                     else ("review" if c.get("type") == "review" else "comment"))
            evs.append((c.get("at") or "", 4, "k-comment", "Agent-attributed %s on GitHub · %s" % ("review" if c.get("type") == "review" else "comment", day(c.get("at"))),
                        "Posted by @%s — %s%s. (%s)" % (html.escape(c.get("login") or "unknown"), html.escape(c["label"]),
                                                       (" (draft from the review of head <code>%s</code>)" % short(c["head"])) if c.get("head") else "", where)))
        if gh and gh.get("state") == "merged":
            evs.append((gh["merged_at"], 5, "k-merged", "Merged on GitHub · %s" % day(gh["merged_at"]),
                        "Merged by @%s%s." % (html.escape(gh.get("merged_by") or "unknown"),
                                             (", merge commit <code>%s</code>" % short(gh["merge_commit"])) if gh.get("merge_commit") else "")))
        elif gh and gh.get("state") == "closed":
            evs.append((gh.get("closed_at") or "", 5, "k-closed", "Closed on GitHub · %s" % day(gh.get("closed_at")),
                        "Closed%s." % (" as " + html.escape(gh["state_reason"].replace("_", " ")) if gh.get("state_reason") else " without merging" if item["kind"] == "pr" else "")))
        elif gh:
            evs.append((self.now, 6, "k-open", "Still open on GitHub · checked %s" % day(gh["fetched_at"]), "No merge or close yet."))
        else:
            evs.append((self.now, 6, "k-open", "GitHub state not checked", "This site was generated offline; see the item on GitHub."))
        evs.sort(key=lambda e: (e[0], e[1]))
        tl = "".join('<li class="ev %s"><div class="when">%s</div><div class="what">%s</div></li>' % (k, html.escape(w), h)
                     for _, _, k, w, h in evs)
        url = (gh or {}).get("url") or ""
        body = ('<section class="card ph">%s</section>'
                '<h1>%s #%d — %s</h1>'
                '<p class="meta">%s · GitHub: %s · %d review%s · <a href="status.yaml">status.yaml</a>%s</p>'
                '<h2>From triage to %s</h2><ol class="timeline">%s</ol>') % (
            md_to_html(hmd), kl, item["num"], RD.sanitize(item["title"])[0],
            "Issue" if item["kind"] == "issue" else "Pull request", html.escape(github_words(gh, item["kind"]).replace("`", "")),
            len(item["reviews"]), "" if len(item["reviews"]) == 1 else "s",
            (' · <a href="%s">on GitHub</a>' % html.escape(url, quote=True)) if url.startswith("https://github.com/") else "",
            "merge" if item["kind"] == "pr" else "close", tl)
        return page("%s #%d — review flow" % (kl, item["num"]), body, rel, self.footer_line())

    # -- site-level pages --------------------------------------------------
    def index_pages(self, items):
        groups = [("open", "Open"), ("merged", "Merged"), ("closed", "Closed"), ("unknown", "GitHub state not checked")]
        secs = []
        for key, label in groups:
            its = [i for i in items if ((i["gh"] or {}).get("state") or "unknown") == key]
            if not its:
                continue
            lis = []
            for it in sorted(its, key=lambda i: i["last_activity"], reverse=True):
                newest = it["reviews"][-1]
                kl = "Issue" if it["kind"] == "issue" else "PR"
                o = newest.get("outcome") or ""
                ocls = "ok" if o == "merge" or o == "proceed" else ("bad" if o == "security-escalate" else "warn")
                dcls = "ok" if it["decision"]["recorded"] else "warn"
                lis.append('<li><div class="t"><a href="%s/index.html">%s #%d</a> — %s</div><div class="s">'
                           '<span class="chip %s">Agent: %s</span><span class="chip %s">Decision: %s</span>'
                           '<span class="chip">GitHub: %s</span><span class="chip">%d review%s</span>'
                           '<span class="chip">reviewed %s → last activity %s</span></div></li>' % (
                    self.item_dir(it), kl, it["num"], RD.sanitize(it["title"])[0], ocls, html.escape(outcome_words(newest)),
                    dcls, html.escape("recorded" + (" (%s)" % it["decision"]["alignment"] if it["decision"].get("alignment") else "") if it["decision"]["recorded"] else "not recorded"),
                    html.escape(github_words(it["gh"], it["kind"]).replace("`", "")), len(it["reviews"]),
                    "" if len(it["reviews"]) == 1 else "s", day(it["first_review"]), day(it["last_activity"])))
            secs.append((key, label, len(its), '<ul class="items">%s</ul>' % "".join(lis)))
        legend = ('<p class="legend">Each line is one pull request or issue the agent reviewed, newest activity first. '
                  '<b>Agent</b> is what its newest review recommended; <b>Decision</b> is whether a maintainer recorded a ruling '
                  '(absence is not agreement); <b>GitHub</b> is what GitHub showed when this site was generated, and it is right '
                  'when the three disagree. A human maintainer decides, every time.</p>')
        toc = " · ".join('<a href="index-%s.html">%s (%d)</a>' % (k, l, n) for k, l, n, _ in secs)
        intro = ('<h1>Reviews by lq-maintainer-agent on %s</h1>%s<p class="meta">%d items · %s</p>' % (
            html.escape(self.repo), legend, len(items), toc))
        body = intro + "".join('<h2 id="%s">%s (%d)</h2>%s' % (k, l, n, h) for k, l, n, h in secs)
        self.files["index.html"] = page("Agent reviews — %s" % self.repo, body, "", self.footer_line())
        for k, l, n, h in secs:
            self.files["index-%s.html" % k] = page("%s — agent reviews" % l, '<h1>%s (%d)</h1>%s<p class="meta"><a href="index.html">All items</a></p>%s' % (l, n, legend, h), "", self.footer_line())

    def index_json(self, items):
        out = []
        for it in sorted(items, key=lambda i: i["last_activity"], reverse=True):
            gh = it["gh"] or {}
            newest = it["reviews"][-1]
            st = gh.get("state") or "unknown"
            out.append({
                "number": it["num"], "kind": it["kind"], "title": it["title"],
                "url": gh.get("url") or "https://github.com/%s/%s/%d" % (self.repo, "issues" if it["kind"] == "issue" else "pull", it["num"]),
                "newest_head": newest["head"], "newest_outcome": newest.get("outcome"),
                "decision": {"recorded": it["decision"]["recorded"], "alignment": it["decision"].get("alignment")},
                "github": {"state": st, "at": gh.get("merged_at") if st == "merged" else gh.get("closed_at"),
                           "by": gh.get("merged_by"), "merge_commit": gh.get("merge_commit"), "checked_at": gh.get("fetched_at")},
                "discrepancies": it["discrepancies"],
                "reviews": [{"head": r["head"], "at": r["at"], "at_source": "file-mtime", "agent_version": r["agent_version"],
                             "host": r["host"], "model": r["model"], "lane": r["lane"], "tier": r.get("tier"),
                             "outcome": r.get("outcome"), "findings": r["findings"]} for r in it["reviews"]],
                "paths": it["paths"],
            })
        return json.dumps({"generated_at": self.now, "generator": GENERATOR, "repo": self.repo,
                           "agent_versions": self.versions, "item_count": len(out), "items": out}, indent=1) + "\n"

    def static_pages(self):
        vals = {"repo": self.repo, "site_repo": "LegalQuants/lq-ai-community", "agent_repo_url": self.agent_repo,
                "governance_url": "https://github.com/%s/blob/main/GOVERNANCE.md" % self.repo,
                "for_agents_url": "for-agents.html",
                "injection_posture_url": "%s/blob/v%s/rules/injection-posture.md" % (self.agent_repo, self.current)}
        about = fill(self.ph["long"], vals)
        self.files["about.html"] = page("About this site", '<div class="prose">%s</div>' % md_to_html(about), "", self.footer_line())
        fa = fill(self.fa["page"], vals)
        self.files["FOR-AGENTS.md"] = fa + "\n\n*" + self.footer_line() + "*\n"
        self.files["for-agents.html"] = page("For agents", '<div class="prose">%s</div>' % md_to_html(fa), "", self.footer_line())
        self.files[".nojekyll"] = ""
        self.files["README.md"] = ("# Generated site — do not edit\n\nEverything here is generated by %s from lq-maintainer-agent's "
                                   "review records and is replaced in full on every refresh. Start at `index.html`; machine readers "
                                   "start at `FOR-AGENTS.md` and `index.json`.\n\n*%s*\n" % (GENERATOR, self.footer_line()))


# ===========================================================================
# Plan, run, self-test
# ===========================================================================

def plan(args):
    caches = ", ".join(args.caches) if args.caches else "<none given>"
    steps = [
        "1. Discover receipts: <cache>/<repo-dir>/<number>/<40-hex|issue>/receipt.md only, in %s (repo %s; repo-dir matched case-insensitively). Read each receipt's text and file time; open nothing else." % (caches, args.repo),
        "2. Parse each receipt's lq-maintainer-agent:receipt:v1/v2 footer with render-deck.sh's parser; key items by GitHub number, reviews by head SHA (canon SHA for issues).",
        "3. Gate each item: refuse on a missing footer, E-21, vuln-suspect or held; hold on E-08 or a security-tagged finding%s." % (
            (" (except --allow-security %s)" % ",".join(map(str, args.allow_security))) if args.allow_security else ""),
        ("4. GitHub state: read-only `gh pr view` / `gh issue view` per item (and `gh api repos/<repo>/commits/<sha>` for merged PRs), cached in %s for %s h. The cache is written even under --dry-run; it is not site output." % (args.gh_cache, args.gh_max_age_hours))
        if args.status_from == "gh" else "4. GitHub state: not checked (--status-from none); every item's state is `unknown`, so --select merged|closed selects nothing.",
        "5. Select: --select %s%s." % (args.select, (", --since %s" % args.since) if args.since else ""),
        "6. Sanitize each selected receipt body and footer: local paths -> item-relative; Name <email> -> @login or removed; permission-check prose removed; drafts labelled with their GitHub status.",
        "7. Render in memory: item flow pages, status.yaml, per-head receipt.md / state.yaml / deck.html (render-deck.sh --public-header, header from templates/public-header.md), index.html + index-<state>.html, index.json, about.html, for-agents.html, FOR-AGENTS.md, README.md, .nojekyll.",
        "8. Scan every generated file for local paths, emails, meeting links, token-shaped strings and permission-check prose; any hit refuses the whole run (exit 3) and nothing is written.",
        ("9. --dry-run: print every item's disposition and the scan result; write nothing to %s." % args.out) if args.dry_run else
        ("9. Write the tree to %s (replacing a previous generated tree; refusing a non-empty directory that is not one)." % args.out),
    ]
    print("publish-site plan (nothing has run):")
    for s in steps:
        print("  " + s)
    return 0


def run(args):
    if not args.caches or (not args.out and not args.dry_run):
        sys.stderr.write("publish-site: --caches and --out are required (see --plan).\n")
        return 2
    site = Site(args)
    entries = discover(args.caches, args.repo)
    items = site.assemble(entries)
    allow = set(args.allow_security or [])
    published, disp = [], []
    tallies = {"published": 0, "refused": 0, "held": 0, "skipped": 0}
    for it in items:
        name = "%s-%d" % (it["kind"], it["num"])
        g, why = site.dispose(it, it["num"] in allow)
        if g != "ok":
            tallies["refused" if g == "refuse" else "held"] += 1
            disp.append((name, "refused" if g == "refuse" else "held", why + (
                "; publish only after a maintainer's per-item ruling (--allow-security %d)" % it["num"] if g == "hold" else "")))
            continue
        site.enrich(it)
        name = "%s-%d" % (it["kind"], it["num"])
        ok, why = site.selected(it)
        if not ok:
            tallies["skipped"] += 1
            disp.append((name, "skipped", why))
            continue
        published.append(it)
    site.versions = sorted({r["agent_version"] for it in published for r in it["reviews"]},
                           key=lambda v: [int(x) if x.isdigit() else 0 for x in re.split(r"[.-]", v)])
    final = []
    for it in published:
        name = "%s-%d" % (it["kind"], it["num"])
        g, why = site.build_item(it)
        if g != "ok":
            tallies["refused"] += 1
            disp.append((name, "refused", why))
            for k in [k for k in site.files if k.startswith(name + "/")]:
                del site.files[k]
            continue
        final.append(it)
        tallies["published"] += 1
        newest = it["reviews"][-1]
        disp.append((name, "published", "%d review%s; newest head %s, outcome %s; GitHub %s" % (
            len(it["reviews"]), "" if len(it["reviews"]) == 1 else "s", short(newest["head"]),
            newest.get("outcome") or "none", (it["gh"] or {}).get("state") or "unknown")))
    site.versions = sorted({r["agent_version"] for it in final for r in it["reviews"]},
                           key=lambda v: [int(x) if x.isdigit() else 0 for x in re.split(r"[.-]", v)])
    site.static_pages()
    site.index_pages(final)
    site.files["index.json"] = site.index_json(final)
    hits = []
    for path, text in sorted(site.files.items()):
        for cls, ex in scan_text(text):
            hits.append((cls, ex, path))
    for name, d, why in sorted(disp, key=lambda x: (x[0].split("-")[0], int(x[0].split("-")[1]))):
        print("%-11s %-10s %s" % (name, d, why))
    by_cls = {}
    for cls, ex, path in hits:
        by_cls[cls] = by_cls.get(cls, 0) + 1
        print("scan-hit    %-17s %-24s in %s" % (cls, ex, path))
    print("summary: %d receipts read over %d items; published %d, refused %d, held %d, skipped %d; files %d; scan hits %d%s" % (
        len(entries), len(items), tallies["published"], tallies["refused"], tallies["held"], tallies["skipped"],
        len(site.files), len(hits), (" (" + ", ".join("%s %d" % kv for kv in sorted(by_cls.items())) + ")") if hits else ""))
    if hits:
        print("publish-site: the output scan found %d hit(s); the whole run is refused and nothing was written." % len(hits))
        return 3
    if args.dry_run:
        print("publish-site: dry run; nothing was written.")
        return 0
    out = os.path.abspath(os.path.expanduser(args.out))
    if os.path.isdir(out) and os.listdir(out) and not (os.path.isfile(os.path.join(out, ".nojekyll")) and os.path.isfile(os.path.join(out, "index.json"))):
        sys.stderr.write("publish-site: %s is not empty and is not a generated site; refusing to replace it.\n" % out)
        return 1
    tmp = out + ".tmp-publish-site"
    if os.path.exists(tmp):
        shutil.rmtree(tmp)
    for path, text in site.files.items():
        p = os.path.join(tmp, path)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w", encoding="utf-8") as fh:
            fh.write(text)
    if os.path.exists(out):
        shutil.rmtree(out)
    os.rename(tmp, out)
    print("publish-site: wrote %d files to %s" % (len(site.files), out))
    return 0


def self_test():
    fails = []

    def check(name, cond):
        if not cond:
            fails.append(name)

    rd = "LegalQuants-lq-ai"
    t = strip_paths("receipt at /Users/houfu/.codex/plugins/data/lq-maintainer-lq-maintainer-agent/LegalQuants-lq-ai/752/" + "a" * 40 + "/receipt.md.", rd)
    check("path: codex receipt -> item-relative", t == "receipt at pr-752/" + "a" * 40 + "/receipt.md.")
    t = strip_paths("at ${CLAUDE_PLUGIN_DATA}/legalquants-lq-ai/663/" + "b" * 40 + "/receipt.md", rd)
    check("path: ${CLAUDE_PLUGIN_DATA}, lowercase repo dir", t == "at pr-663/" + "b" * 40 + "/receipt.md")
    check("path: plugin cache root", strip_paths("root=/Users/x/.codex/plugins/cache/lq/0.7.0 ok", rd) == "root=<plugin install> ok")
    check("path: home dir", strip_paths("see /home/alice/notes.txt", rd) == "see <local path>")
    check("path: tilde dot-dir", strip_paths("in ~/.claude/plugins/data/foo", rd) == "in <agent record store>")
    check("path: '~5 minutes' untouched", strip_paths("~5 minutes", rd) == "~5 minutes")
    check("path: URL untouched", strip_paths("https://github.com/a/b/tree/main/home/x", rd) == "https://github.com/a/b/tree/main/home/x")
    check("path: issue dir", strip_paths("/Users/h/.codex/plugins/data/x/LegalQuants-lq-ai/498/issue/receipt.md", rd) == "issue-498/receipt.md")

    lg = {"houfu"}
    check("email: trailer mapped to login", scrub_emails("Signed-off-by: houfu <houfu@outlook.sg>", lg) == "Signed-off-by: @houfu")
    check("email: unmapped trailer removed whole", scrub_emails("Signed-off-by: SAD LIFE <x.y@gmail.com>", lg) == "Signed-off-by: [identity removed]")
    check("email: identity prose mapped", scrub_emails("git identity houfu <houfu@outlook.sg>; ok", lg) == "git identity @houfu; ok")
    check("email: in backticks", scrub_emails("`Signed-off-by: houfu <houfu@outlook.sg>` on each", lg) == "`Signed-off-by: @houfu` on each")
    check("email: github noreply stays", scrub_emails("Co-authored-by: bot <1+bot@users.noreply.github.com>", lg) == "Co-authored-by: bot <1+bot@users.noreply.github.com>")
    check("email: anthropic noreply stays", "noreply@anthropic.com" in scrub_emails("Co-Authored-By: Claude <noreply@anthropic.com>", lg))
    check("email: bare removed", scrub_emails("mail alice@example.org now", lg) == "mail [email removed] now")
    check("email: version pins untouched", scrub_emails("pkg@1.2.3 and @scope/pkg", lg) == "pkg@1.2.3 and @scope/pkg")
    check("email: capitalized name in prose", scrub_emails("bodies carry Joel Kaufmann <j.k@gmail.com>; DCO pass", lg) == "bodies carry [identity removed]; DCO pass")
    check("email: backticked token", scrub_emails("signed off as `Alexios Kirillov <a.k@gmail.com>`, which", lg) == "signed off as [identity removed], which")
    check("email: quoted token", scrub_emails('names "Alexios Kirillov <a.k@gmail.com>", not', lg) == 'names [identity removed], not')
    check("email: dependabot noreply stays", "dependabot[bot]@users.noreply.github.com" in scrub_emails("Signed-off-by: dependabot[bot] <49699333+dependabot[bot]@users.noreply.github.com>", lg))
    check("email: lowercase login after 'sign-off'", scrub_emails("DCO sign-off houfu <houfu@outlook.sg>; two", lg) == "DCO sign-off @houfu; two")
    check("logins: from record", known_logins("by @houfu; author Hitesh-XS") >= {"houfu", "hitesh-xs"})

    t = scrub_permission_prose("| query | `gh api repos/LegalQuants/lq-ai/collaborators/houfu/permission` | admin | done |\n| read | x | y | done |")
    check("perm: work-log row dropped", t == "| read | x | y | done |")
    t = scrub_permission_prose("Author is a maintainer of record (org member; `admin`, checked via the API on 2026-10-14). The external full checklist (E-07) does not apply.")
    check("perm: parenthetical removed, class kept", t == "Author is a maintainer of record. The external full checklist (E-07) does not apply.")
    t = scrub_permission_prose("- Identity: verified via GitHub API — admin permission on LegalQuants/lq-ai.")
    check("perm: identity bullet -> class word", t == "- Identity: maintainer of record.")
    check("perm: unrelated row untouched", scrub_permission_prose("| Workflow secrets/permissions | pass |") == "| Workflow secrets/permissions | pass |")
    t = scrub_permission_prose("| E-07 | Not fired. Clear: author houfu org membership and repo admin permission verified by parent API GETs; trust itself remains human-only. |")
    check("perm: checklist cell clause dropped", "permission" not in t and "E-07" in t and "human-only" in t)
    t = scrub_permission_prose("| Author class | **external** — org membership 404, repo permission `read`; cross-repository fork. Playbook run. |")
    check("perm: membership lookup dropped, class kept", "404" not in t and "read" not in t and "external" in t and "Playbook run" in t)
    t = scrub_permission_prose("Class (L-07): `houfu`, type `User`, permission `admin`/`write` on the repo — a maintainer of record, not a bot.")
    check("perm: 'permission `admin`' dropped", "admin" not in t)
    check("perm: membership lookup row dropped", scrub_permission_prose("| query | gh api orgs/LegalQuants/memberships/Someone | membership.json | pass |\n| a | b |") == "| a | b |")
    t = scrub_permission_prose("| Author | external conservatively (membership API 404/scope limitation); safeguards retained. |")
    check("perm: membership 404 clause dropped", "404" not in t and "safeguards retained" in t)
    check("email: bot account kept as handle", scrub_emails("Signed-off-by: dependabot[bot] <support@github.com>", lg) == "Signed-off-by: @dependabot[bot]")
    check("perm: 'network permission' untouched", scrub_permission_prose("retried with network permission: PASS") == "retried with network permission: PASS")
    check("perm: workflow permissions block untouched", scrub_permission_prose("runs under `permissions: contents: read` with no secrets") == "runs under `permissions: contents: read` with no secrets")
    f, ch = sanitize_footer("decision:\n  decided_by: houfu\n  permission: write\n  alignment: adjusted")
    check("footer: non-schema permission key dropped", "permission" not in f and "alignment: adjusted" in f and ch)

    base = {"footer": {"triggers": [], "held": False, "burden": {"blockers": []}}, "body": ""}
    check("gate: clean ok", gate(base)[0] == "ok")
    check("gate: no footer refused", gate({"footer": None, "body": ""})[0] == "refuse")
    check("gate: E-21 refused", gate(dict(base, footer={"triggers": ["E-21"]}))[0] == "refuse")
    check("gate: vuln-suspect refused", gate(dict(base, footer={"burden": {"blockers": ["vuln-suspect"]}}))[0] == "refuse")
    check("gate: known-vuln is not vuln-suspect", gate(dict(base, footer={"burden": {"blockers": ["known-vuln"]}}))[0] == "ok")
    check("gate: held refused", gate(dict(base, footer={"held": True}))[0] == "refuse")
    check("gate: E-08 held", gate(dict(base, footer={"triggers": ["E-02", "E-08"]}))[0] == "hold")
    check("gate: E-08 allowed by ruling", gate(dict(base, footer={"triggers": ["E-08"]}), allow_security=True)[0] == "ok")
    check("gate: E-21 not lifted by ruling", gate(dict(base, footer={"triggers": ["E-21"]}), allow_security=True)[0] == "refuse")
    check("gate: security-tagged finding held", gate(dict(base, body="> **Red flags:** E-02 fired; F-1 (security)\n"))[0] == "hold")
    check("gate: 'no security finding' not held", gate(dict(base, body="> **Red flags:** none — no security finding\n"))[0] == "ok")
    check("gate: finding header tagged security", security_tagged("### Findings\n\n**F-2 — major — security** — `a.py:1`\n"))

    check("scan: SHA-1 not a hit", not scan_text("a" * 40))
    check("scan: SHA-256 not a hit", not scan_text("b" * 64))
    check("scan: 36 hex is a hit", [c for c, _ in scan_text("c" * 36)] == ["hex-secret"])
    check("scan: /Users/ hit", any(c == "local-path" for c, _ in scan_text("/Users/x")))
    check("scan: email hit", any(c == "email" for c, _ in scan_text("a@b.co")))
    check("scan: noreply allowed", not scan_text("1+x@users.noreply.github.com noreply@anthropic.com"))
    check("scan: handle not email", not scan_text("thanks @houfu."))
    check("scan: zoom hit", any(c == "meeting-url" for c, _ in scan_text("https://us02web.zoom.us/j/123")))
    check("scan: ghp token hit", any(c == "token" for c, _ in scan_text("ghp_" + "A1" * 15)))
    check("scan: sk- token hit", any(c == "token" for c, _ in scan_text("key sk-" + "x" * 24)))
    check("scan: 'task-' is not sk-", not scan_text("risk-" + "x" * 24))
    check("scan: hex glued to a word is not a run", not scan_text("tree" + "a" * 40 + " head" + "b" * 40))
    check("scan: registry content address allowed", not scan_text("https://files.pythonhosted.org/packages/05/8e/" + "c" * 60 + "/pyyaml-6.0.tar.gz"))
    check("scan: hex after '=' still a hit", any(c == "hex-secret" for c, _ in scan_text("key=" + "d" * 36)))
    check("sanitize: libfile id removed", strip_internal_ids("ID libfile_" + "e" * 32 + " x") == "ID <internal file id> x")
    check("path: truncated SHA shortened", strip_paths("/Users/h/x/LegalQuants-lq-ai/717/" + "f" * 35 + " ok", rd) == "pr-717/ffffffffffff… ok")
    check("scan: permission prose hit", any(c == "permission-prose" for c, _ in scan_text("checked via the API")))

    check("draft: exact", draft_match("Hi  there\nthanks", ["Hi there thanks"])[0] == "posted as drafted")
    check("draft: edited", draft_match("Hi @a — this looks ready to merge, CI is green and the rows match.",
                                       ["Hi @a — this looks ready to merge: CI is green, and the rows now match main."])[0] == "posted with edits")
    check("draft: unrelated", draft_match("Hi there, thanks for the fix.", ["Completely different text about another subject entirely."])[0] is None)

    blocks = read_blocks(os.path.join(ROOT, "templates", "public-header.md"), "public-header")
    check("template: header blocks present", all(k in blocks for k in ("short", "if-self-review", "if-older-rules", "if-escalate", "if-drafts", "discrepancy", "long")))
    check("template: header carries the decides line", "A human maintainer decides whether and how a change merges" in blocks.get("short", ""))
    check("template: header carries GitHub-is-right", "If these three disagree, GitHub is right." in blocks.get("short", ""))
    check("template: for-agents page present", "page" in read_blocks(os.path.join(ROOT, "templates", "for-agents.md"), "for-agents"))
    check("md: link + bold + code", md_to_html("**a** `b` [c](https://x.y/z)") == '<p><strong>a</strong> <code>b</code> <a href="https://x.y/z">c</a></p>')
    check("md: javascript link dropped", "href" not in md_to_html("[c](javascript:alert(1))"))

    for f in fails:
        print("FAIL: " + f)
    print("publish-site self-test: %d failed" % len(fails))
    return 1 if fails else 0


def main(argv):
    ap = argparse.ArgumentParser(prog="publish-site.sh", description="Generate the static review-records site (no JS, no external resources).")
    ap.add_argument("--caches", type=lambda s: [x for x in s.split(",") if x])
    ap.add_argument("--out")
    ap.add_argument("--repo", default="LegalQuants/lq-ai")
    ap.add_argument("--status-from", choices=("gh", "none"), default="gh")
    ap.add_argument("--select", choices=("merged", "closed", "all"), default="merged")
    ap.add_argument("--since")
    ap.add_argument("--allow-security", type=lambda s: [int(x) for x in s.split(",") if x.strip()], default=[])
    ap.add_argument("--agent-version-tag")
    ap.add_argument("--gh-cache", default=os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"), "lq-maintainer-agent", "publish-site-gh"))
    ap.add_argument("--gh-max-age-hours", type=float, default=12.0)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--plan", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args(argv)
    if args.since and not re.match(r"^\d{4}-\d{2}-\d{2}$", args.since):
        ap.error("--since must be YYYY-MM-DD")
    if args.self_test:
        return self_test()
    if args.plan:
        return plan(args)
    return run(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
