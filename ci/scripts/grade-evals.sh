#!/bin/sh
# grade-evals.sh — mechanical eval grading for lq-maintainer-agent
# (design doc §4.1–§4.2). POSIX sh; run from the repository root.
#
# HONEST SCOPE FOR v0.1.0: this script validates the eval suite's
# STRUCTURE, not the agent's judgment. Grading actual lane assignment,
# escalation triggers, and salvage decomposition against the goldens
# requires running the agent over each fixture, and that harness lands
# with the M1 eval-harness milestone (§14 M1). Until then, a green run
# here means "the eval corpus is well-formed", never "the rules produce
# the golden outcomes". What IS checked, mechanically:
#
#   1. Pairing, both directions: every fixture in evals/fixtures/ has a
#      golden in evals/golden/ with the same base name, and every golden
#      has a fixture (an orphaned golden is as much a bug as an
#      ungraded fixture). Goldens must be non-empty.
#   2. Rule IDs: every rule ID cited in a golden (tokens shaped like
#      L-30, E-03, S-01, I-03 — uppercase dash-segments ending in a
#      2–3 digit number — or letter-suffixed IDs like S-DECLINE, the
#      salvage dispositions) exists verbatim somewhere in rules/.
#      Canon identifiers with known lq-ai prefixes (DE-, ADR-, CVE-,
#      GHSA-, CWE-, RFC-) are excluded: those belong to lq-ai's
#      canon, not this repo's rule set.
#   3. Repo paths: every backtick-cited rules/... or templates/... path
#      in a golden resolves in this repo.
#
# Environment:
#   EVAL_FIXTURE_CAP  — max fixtures to grade this run (0 or unset = no
#                       cap). §4.2 budget control: PR runs are capped;
#                       the `full-eval` label and the nightly run lift
#                       the cap. Capping a structural check costs
#                       little (nightly covers the tail), and keeping
#                       the same interface now means the M1 agent-run
#                       grader — where the cap really is the token
#                       budget — slots in without workflow changes.
#
# Exit status: 0 = suite well-formed (or corpus not yet present, with a
# loud notice); 1 = structural failure, listed one per line on stderr
# as GitHub error annotations.

set -u

FIXDIR="evals/fixtures"
GOLDDIR="evals/golden"
RULESDIR="rules"
CAP="${EVAL_FIXTURE_CAP:-0}"

fail=0
err() {
  # $1 = file to annotate, $2 = message
  echo "::error file=$1::$2" >&2
  fail=1
}

base_of() {
  # base name without a trailing extension; directories pass through
  b=$(basename "$1")
  case "$b" in
    *.*) printf '%s\n' "${b%.*}" ;;
    *)   printf '%s\n' "$b" ;;
  esac
}

has_entry() {
  # does directory $1 contain an entry named $2 (any extension or none)?
  for cand in "$1/$2" "$1/$2".*; do
    [ -e "$cand" ] && return 0
  done
  return 1
}

if [ ! -d "$FIXDIR" ] || [ -z "$(ls -A "$FIXDIR" 2>/dev/null)" ]; then
  echo "::notice::grade-evals: no fixtures found under $FIXDIR — the eval corpus lands with M1 (design doc §14). Nothing to grade; this is NOT a pass on judgment."
  exit 0
fi

# ---- 1. pairing, both directions --------------------------------------

count=0
capped_list=$(mktemp)
trap 'rm -f "$capped_list"' EXIT

for fx in $(ls -d "$FIXDIR"/* | sort); do
  count=$((count + 1))
  if [ "$CAP" -gt 0 ] && [ "$count" -gt "$CAP" ]; then
    echo "::notice::grade-evals: fixture cap reached (EVAL_FIXTURE_CAP=$CAP); $(ls -d "$FIXDIR"/* | wc -l | tr -d ' ') fixtures total. Add the 'full-eval' label (or wait for the nightly run) for the full suite (§4.2)."
    break
  fi
  b=$(base_of "$fx")
  printf '%s\n' "$b" >> "$capped_list"
  if ! has_entry "$GOLDDIR" "$b"; then
    err "$fx" "fixture '$fx' has no golden in $GOLDDIR/ (expected $GOLDDIR/$b.* — §4.1: expectations live in evals/golden/)"
  fi
done

for g in $(ls -d "$GOLDDIR"/* 2>/dev/null | sort); do
  b=$(base_of "$g")
  if ! has_entry "$FIXDIR" "$b"; then
    err "$g" "golden '$g' has no matching fixture in $FIXDIR/ — orphaned expectation"
  fi
  if [ -f "$g" ] && [ ! -s "$g" ]; then
    err "$g" "golden '$g' is empty"
  fi
done

# ---- 2 & 3. rule IDs and repo paths cited in goldens ------------------

graded_goldens() {
  # goldens for the (possibly capped) fixture set
  while IFS= read -r b; do
    for cand in "$GOLDDIR/$b" "$GOLDDIR/$b".*; do
      [ -f "$cand" ] && printf '%s\n' "$cand"
      [ -d "$cand" ] && find "$cand" -type f
    done
  done < "$capped_list" | sort -u
}

for g in $(graded_goldens); do
  # rule IDs: uppercase dash-segments ending in a 2-3 digit number
  # (L-30, E-03) OR in a 2+ letter segment (S-DECLINE — the salvage
  # dispositions), matched as whole words; lq-ai canon prefixes
  # excluded.
  for id in $(grep -woE '[A-Z][A-Z0-9]*(-[A-Z0-9]+)*-([0-9]{2,3}|[A-Z]{2,})' "$g" 2>/dev/null \
              | grep -vE '^(DE|ADR|CVE|GHSA|CWE|RFC)-' | sort -u); do
    if ! grep -rqwF -- "$id" "$RULESDIR"; then
      err "$g" "golden cites rule ID '$id' which does not exist anywhere in $RULESDIR/ — goldens must cite the assigning rule by its real ID (§4.1)"
    fi
  done

  # backtick-cited repo paths into rules/ or templates/
  for p in $(grep -oE '`(rules|templates)/[^`]+`' "$g" 2>/dev/null | tr -d '`' | sort -u); do
    p_clean="${p%%#*}"; p_clean="${p_clean%/}"
    if [ ! -e "$p_clean" ]; then
      err "$g" "golden cites '$p' which does not resolve in this repo"
    fi
  done
done

if [ "$fail" -ne 0 ]; then
  echo "grade-evals: structural failures found (see annotations above)." >&2
  exit 1
fi

echo "grade-evals: eval suite well-formed ($(wc -l < "$capped_list" | tr -d ' ') fixture(s) checked). Reminder: lane/trigger/salvage outcomes are NOT yet graded — that requires the M1 agent-run harness (§4.2, §14)."
