#!/usr/bin/env bash
# check-canon-drift.sh — resolve every canon citation in rules/,
# templates/, and skills/ against a checked-out lq-ai tree, and enforce
# the portability discipline (design doc §4.3, §2.2).
#
# Usage: ci/scripts/check-canon-drift.sh <path-to-lq-ai-checkout> [<pin-sha-for-messages>]
# Run from the repository root. Exit 0 if every citation resolves AND
# no canon citation appears outside rules/canon-map.md; exit 1 with one
# GitHub error annotation per violation.
#
# TWO checks ride one scan (§4.3):
#
#   DRIFT — a citation that resolves in neither this repo nor the
#   pinned lq-ai tree is dangling: lq-ai moved or removed a doc. Fix
#   rules/canon-map.md — the canon is the API (§11).
#
#   PORTABILITY (new in v0.6, §2.2) — a citation that is NOT a
#   self-reference but DOES resolve in the lq-ai tree is lq-ai
#   structure hardcoded outside the one file allowed to hold it.
#   rules/canon-map.md is the ONLY place lq-ai paths, doc names, and
#   policy locations may be encoded; every other rule and skill
#   references canon through canon-map keys, and templates use
#   {{placeholders}} filled at posting time. Naming lq-ai in template
#   PROSE is fine (§2.2) — prose is not backticked and never trips
#   this lint.
#
# What counts as a citation: a backtick-quoted, path-shaped token in
# any rules/, templates/, or skills/ *.md file — it contains a "/" or
# ends in a known file extension, or is a well-known extensionless
# root file (CODEOWNERS, LICENSE). Lines containing "{{" are skipped:
# those are template placeholders whose backticked contents are
# illustrative examples (e.g. `docs/adr/ADR-0007.md` in a fill hint),
# not normative citations. Section anchors (`path#anchor`) are checked
# at path level; glob patterns (`.github/workflows/**`) are checked at
# their fixed prefix.
#
# NOT citations, and skipped everywhere EXCEPT rules/canon-map.md
# (where every path-shaped token is normative and must resolve):
#   - generic mechanism filenames the rules must name as diff PATTERNS
#     (§10.2: CLAUDE.md, AGENTS.md, `.claude/**`, `.github/**` — these
#     mean "any repo's agent-instruction/workflow files", not lq-ai's);
#   - git refs (`origin/main`) and angle-bracket placeholders
#     (`${CLAUDE_PLUGIN_ROOT}/<path>`);
#   - bare slashless *.md names that resolve nowhere — those are
#     runtime artifact names (a cached `report.md`, §3.5), not canon
#     citations. A bare name that DOES resolve in lq-ai is still a
#     canon citation and still trips the portability lint.
#
# Resolution order for each citation:
#   1. exists in THIS repo — at the root or as a sibling of the citing
#      file (a directory README citing `repro-request.md` cites its
#      neighbour)                        -> self-reference, OK anywhere
#      (a `${CLAUDE_PLUGIN_ROOT}/...` path resolves here too — the
#       plugin root IS this repo at runtime, §3.3)
#   2. exists in the lq-ai tree, or under .github/ there (CODEOWNERS
#      and friends may live at the root or .github/ — see
#      rules/canon-map.md)
#        -> canon reference: OK in rules/canon-map.md,
#           PORTABILITY FAILURE anywhere else (§2.2)
#   3. otherwise                         -> dangling, DRIFT FAILURE
#      (bare slashless *.md names excepted outside canon-map.md — see
#       above: runtime artifact names, not citations)
#
# Known accepted gap: a name that exists in BOTH repos (e.g. a bare
# `CODEOWNERS`) resolves as a self-reference and never reaches the
# portability check — path-level resolution cannot tell which repo the
# author meant. Reviewers catch those; the lint catches the rest.

set -uo pipefail

CANON_DIR="${1:?usage: check-canon-drift.sh <lq-ai-checkout-dir> [pin-sha]}"
PIN="${2:-$(git -C "$CANON_DIR" rev-parse HEAD 2>/dev/null || echo 'unknown')}"

if [ ! -d "$CANON_DIR" ]; then
  echo "::error::canon checkout not found at '$CANON_DIR'"
  exit 1
fi

viol="$(mktemp)"
checked="$(mktemp)"
trap 'rm -f "$viol" "$checked"' EXIT

find rules templates skills -type f -name '*.md' 2>/dev/null | sort | while IFS= read -r f; do
  # Skip placeholder lines ({{...}}), then pull out backticked tokens.
  grep -vE '\{\{' "$f" | grep -oE '`[^`]+`' | tr -d '`' | sort -u | \
  while IFS= read -r tok; do
    # Reject tokens that are not path citations: commands (contain a
    # space), skill invocations (leading /), URLs, flags, placeholders
    # (<...>), git refs, bare words.
    case "$tok" in
      *' '*|*'<'*|http*|git@*|'#'*|-*) continue ;;
      '${CLAUDE_PLUGIN_ROOT}'/*) ;;  # plugin-root path: self-reference, resolved below (§3.3)
      '${'*) continue ;;  # other runtime variables (${CLAUDE_PLUGIN_DATA}/... is a cache key, not a citation)
      /*) continue ;;
      origin/*|refs/*|upstream/*) continue ;;  # git refs, not paths
      n/a|N/A) continue ;;
      legalquants/*) continue ;;  # owner/repo slugs, not paths
    esac
    case "$tok" in
      */*) : ;;  # contains a slash: path-shaped
      CODEOWNERS|LICENSE|*.md) : ;;  # root doc files cited bare
      *) continue ;;  # bare identifiers, mechanism files (conftest.py,
                      # package.json, ...), rule IDs, DE-XXX, `main`, ...
    esac

    # Generic mechanism filenames (§10.2): the rules must name these as
    # diff PATTERNS — "any repo's agent-instruction / workflow files" —
    # so outside canon-map.md they are data, not lq-ai citations.
    # Inside canon-map.md every token is normative and stays checked.
    if [ "$f" != "rules/canon-map.md" ]; then
      case "$tok" in
        CLAUDE.md|AGENTS.md|.claude|.claude/*|.github|.github/*) continue ;;
      esac
    fi

    path="${tok#\$\{CLAUDE_PLUGIN_ROOT\}/}"  # plugin root = this repo at runtime
    path="${path%%#*}"  # strip section anchor
    case "$path" in     # reduce globs to their fixed prefix
      *'*'*) path="${path%%\**}" ;;
    esac
    path="${path%/}"
    [ -n "$path" ] || continue

    printf '%s\n' "$path" >> "$checked"
    if [ -e "$path" ]; then continue; fi                    # self-reference, OK anywhere
    if [ -e "$(dirname "$f")/$path" ]; then continue; fi    # sibling reference, OK anywhere

    if [ -e "$CANON_DIR/$path" ] || [ -e "$CANON_DIR/.github/$path" ]; then
      # Canon reference: only rules/canon-map.md may hold these (§2.2).
      if [ "$f" = "rules/canon-map.md" ]; then continue; fi
      printf '%s\tPORT\t%s\n' "$f" "$tok" >> "$viol"
    else
      # A bare slashless *.md name that resolves nowhere is a runtime
      # artifact name (a cached report.md, §3.5), not a citation —
      # except in canon-map.md, where every name must resolve.
      if [ "$f" != "rules/canon-map.md" ]; then
        case "$tok" in
          */*) : ;;
          *) continue ;;
        esac
      fi
      printf '%s\tDRIFT\t%s\n' "$f" "$tok" >> "$viol"
    fi
  done
done

n_checked="$(sort -u "$checked" | wc -l | tr -d ' ')"

if [ -s "$viol" ]; then
  echo "Canon-citation violations against legalquants/lq-ai@${PIN}:"
  while IFS="$(printf '\t')" read -r f kind tok; do
    case "$kind" in
      DRIFT)
        echo "::error file=${f}::dangling canon reference \`${tok}\` — not found in this repo or in lq-ai@${PIN}. If lq-ai moved this doc, fix rules/canon-map.md (the canon is the API, design doc §11)."
        ;;
      PORT)
        echo "::error file=${f}::canon citation \`${tok}\` outside rules/canon-map.md — it resolves in lq-ai@${PIN}, so this file hardcodes lq-ai structure it may not hold (§2.2 portability discipline). Put the location in rules/canon-map.md under a key and reference the key here; templates use a {{placeholder}} filled at posting time."
        ;;
    esac
  done < "$viol"
  exit 1
fi

echo "canon-drift-check: ${n_checked} distinct citations in rules/, templates/, and skills/ all resolve against lq-ai@${PIN}, and no canon citation appears outside rules/canon-map.md (§2.2, §4.3)."
