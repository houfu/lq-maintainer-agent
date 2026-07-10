#!/usr/bin/env bash
# check-canon-drift.sh — resolve every canon citation in rules/ and
# templates/ against a checked-out lq-ai tree (design doc §4.3).
#
# Usage: ci/scripts/check-canon-drift.sh <path-to-lq-ai-checkout> [<pin-sha-for-messages>]
# Run from the repository root. Exit 0 if every citation resolves,
# exit 1 with one GitHub error annotation per dangling reference.
#
# What counts as a citation: a backtick-quoted, path-shaped token in any
# rules/*.md or templates/**/*.md file — it contains a "/" or ends in a
# known file extension, or is a well-known extensionless root file
# (CODEOWNERS, LICENSE). Lines containing "{{" are skipped: those are
# template placeholders whose backticked contents are illustrative
# examples (e.g. `docs/adr/ADR-0007.md` in a fill hint), not normative
# citations. Section anchors (`path#anchor`) are checked at path level;
# glob patterns (`.github/workflows/**`) are checked at their fixed
# prefix.
#
# Resolution order for each citation:
#   1. exists in THIS repo            -> self-reference, OK
#   2. exists in the lq-ai tree       -> canon reference, OK
#   3. exists under .github/ in lq-ai -> OK (CODEOWNERS and friends may
#                                        live at the root or .github/ —
#                                        see rules/canon-map.md)
#   4. otherwise                      -> dangling, FAIL
#
# rules/canon-map.md is the only place lq-ai structure may be encoded
# (design doc §11), but this script deliberately scans ALL of rules/ and
# templates/: a canon path hardcoded outside canon-map.md is exactly the
# kind of drift that must fail loudly here.

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

find rules templates -type f -name '*.md' 2>/dev/null | sort | while IFS= read -r f; do
  # Skip placeholder lines ({{...}}), then pull out backticked tokens.
  grep -vE '\{\{' "$f" | grep -oE '`[^`]+`' | tr -d '`' | sort -u | \
  while IFS= read -r tok; do
    # Reject tokens that are not path citations: commands (contain a
    # space), skill invocations (leading /), URLs, flags, bare words.
    case "$tok" in
      *' '*|/*|http*|git@*|'#'*|-*) continue ;;
      legalquants/*) continue ;;  # owner/repo slugs, not paths
    esac
    case "$tok" in
      */*) : ;;  # contains a slash: path-shaped
      CODEOWNERS|LICENSE|*.md) : ;;  # root doc files cited bare
      *) continue ;;  # bare identifiers, mechanism files (conftest.py,
                      # package.json, ...), rule IDs, DE-XXX, `main`, ...
    esac

    path="${tok%%#*}"   # strip section anchor
    case "$path" in     # reduce globs to their fixed prefix
      *'*'*) path="${path%%\**}" ;;
    esac
    path="${path%/}"
    [ -n "$path" ] || continue

    printf '%s\n' "$path" >> "$checked"
    if [ -e "$path" ]; then continue; fi                     # self-reference
    if [ -e "$CANON_DIR/$path" ]; then continue; fi          # canon
    if [ -e "$CANON_DIR/.github/$path" ]; then continue; fi  # .github/ variant
    printf '%s\t%s\n' "$f" "$tok" >> "$viol"
  done
done

n_checked="$(sort -u "$checked" | wc -l | tr -d ' ')"

if [ -s "$viol" ]; then
  echo "Dangling canon references (resolve in neither this repo nor legalquants/lq-ai@${PIN}):"
  while IFS="$(printf '\t')" read -r f tok; do
    echo "::error file=${f}::dangling canon reference \`${tok}\` — not found in this repo or in lq-ai@${PIN}. If lq-ai moved this doc, fix rules/canon-map.md (the canon is the API, design doc §11)."
  done < "$viol"
  exit 1
fi

echo "canon-drift-check: ${n_checked} distinct citations in rules/ and templates/ all resolve against lq-ai@${PIN}."
