#!/bin/sh
# lq-maintainer-agent -- publish/site-refresh.sh
#
# The scheduled refresh of the public reviews site (rules/publishing.md
# PB-11/PB-12). A maintainer runs this from their own terminal or from
# launchd on their own machine. It is NOT part of any skill: it runs no
# model, opens no agent session, and refuses to run inside one (below).
# It regenerates the whole site from the local caches with
# skills/triage/scripts/publish-site.sh, runs that script's sanitization
# scan, and -- only when the maintainer's configuration says publishing
# is enabled, and only to the branch the committee designated for
# generated output -- commits and pushes the result with the
# maintainer's own gh credential. It never touches `main`.
#
# Everything stops before a push on: a refused item, a scan hit, a
# generator error, a missing Pages branch, a gh or git failure. A run
# that cannot publish still leaves the generated site in the build
# directory for the maintainer to read.
#
# Usage:
#   sh publish/site-refresh.sh              # generate; push only if PUBLISH=yes
#   sh publish/site-refresh.sh --plan       # print the steps, run nothing
#   sh publish/site-refresh.sh --dry-run    # generate + scan, never push
#   sh publish/site-refresh.sh --install-launchd    # write + load the LaunchAgent
#   sh publish/site-refresh.sh --uninstall-launchd
#
# Configuration: ~/.lq-maintainer/site.conf (POSIX sh assignments; created
# with defaults on first run, PUBLISH=no). Keys:
#   PLUGIN_ROOT      the lq-maintainer-agent checkout (default: this script's parent)
#   CACHES           comma-separated cache roots (default: the three known stores)
#   COMMUNITY_REPO   owner/name (default LegalQuants/lq-ai-community)
#   PAGES_BRANCH     the branch Pages serves from (default gh-pages)
#   SELECT           merged | closed | all (default merged)
#   ALLOW_SECURITY   space-separated item numbers a maintainer has ruled publishable (PB-03)
#   PUBLISH          yes | no (default no): whether a successful build is pushed
#   WORKDIR          build + clone directory (default ~/.lq-maintainer/site)
#   SCHEDULE_HOUR    launchd hour, 0-23 (default 6)
#
# Exit: 0 generated (and pushed, if enabled and changed); 1 stopped before
# push, reason on stderr and in the log; 2 refused to run (agent session,
# lock held, missing tool).

set -u

LABEL="com.legalquants.lq-ai-reviews-site"
CONF_DIR="${HOME}/.lq-maintainer"
CONF="${CONF_DIR}/site.conf"
LOG_DIR="${CONF_DIR}/logs"
LOG="${LOG_DIR}/site-refresh.log"

here=$(cd "$(dirname "$0")" && pwd)
default_root=$(cd "${here}/.." && pwd)

mode="run"
for a in "$@"; do
  case "$a" in
    --plan) mode="plan" ;;
    --dry-run) mode="dry" ;;
    --install-launchd) mode="install" ;;
    --uninstall-launchd) mode="uninstall" ;;
    -h|--help) sed -n '2,45p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "site-refresh: unknown argument $a" >&2; exit 2 ;;
  esac
done

# --- never from inside an agent session (PB-10/PB-11) ----------------------
# Claude Code sets CLAUDE_PROJECT_DIR / CLAUDE_PLUGIN_ROOT for its tools and
# hooks; Codex sets PLUGIN_ROOT / CODEX_* . Any of them means a model is
# driving this shell, and the whole point of this script is that no model
# ever pushes to the community repository.
if [ -n "${CLAUDE_PROJECT_DIR:-}${CLAUDE_PLUGIN_ROOT:-}${CLAUDE_PLUGIN_DATA:-}${PLUGIN_ROOT:-}${PLUGIN_DATA:-}${CODEX_SANDBOX:-}${CODEX_HOME_OVERRIDE:-}" ] && [ "$mode" != "plan" ]; then
  echo "site-refresh: refusing to run inside an agent session (rules/publishing.md PB-11)." >&2
  echo "Run it from your own terminal, or let launchd run it." >&2
  exit 2
fi

mkdir -p "$CONF_DIR" "$LOG_DIR" 2>/dev/null || true
chmod 700 "$CONF_DIR" 2>/dev/null || true

if [ ! -f "$CONF" ]; then
  cat >"$CONF" <<EOF
# lq-maintainer-agent site refresh -- see publish/README.md
PLUGIN_ROOT="${default_root}"
CACHES=""
COMMUNITY_REPO="LegalQuants/lq-ai-community"
PAGES_BRANCH="gh-pages"
SELECT="merged"
ALLOW_SECURITY=""
PUBLISH="no"
WORKDIR="${CONF_DIR}/site"
SCHEDULE_HOUR="6"
EOF
  echo "site-refresh: wrote default configuration to ${CONF} (PUBLISH=no)." >&2
fi
# shellcheck disable=SC1090
. "$CONF"

PLUGIN_ROOT="${PLUGIN_ROOT:-$default_root}"
COMMUNITY_REPO="${COMMUNITY_REPO:-LegalQuants/lq-ai-community}"
PAGES_BRANCH="${PAGES_BRANCH:-gh-pages}"
SELECT="${SELECT:-merged}"
PUBLISH="${PUBLISH:-no}"
WORKDIR="${WORKDIR:-${CONF_DIR}/site}"
SCHEDULE_HOUR="${SCHEDULE_HOUR:-6}"
BUILD="${WORKDIR}/build"
CLONE="${WORKDIR}/repo"
GENERATOR="${PLUGIN_ROOT}/skills/triage/scripts/publish-site.sh"

if [ -z "${CACHES:-}" ]; then
  CACHES=""
  for c in \
    "${HOME}/.codex/plugins/data/lq-maintainer-lq-maintainer-agent" \
    "${HOME}/.claude/plugins/data/lq-maintainer-lq-maintainer-agent" \
    "${HOME}/.claude/plugins/data/lq-maintainer-inline"; do
    [ -d "$c" ] && CACHES="${CACHES}${CACHES:+,}${c}"
  done
fi

allow_flags=""
for n in ${ALLOW_SECURITY:-}; do allow_flags="${allow_flags} --allow-security ${n}"; done

stamp() { date -u +%Y-%m-%dT%H:%M:%SZ; }
log() { printf '%s %s\n' "$(stamp)" "$*" >>"$LOG"; }
stop() { echo "site-refresh: $*" >&2; log "stopped: $*"; exit 1; }

# --- launchd install / uninstall -------------------------------------------
plist_path="${HOME}/Library/LaunchAgents/${LABEL}.plist"
if [ "$mode" = "install" ]; then
  mkdir -p "${HOME}/Library/LaunchAgents"
  sed -e "s|__SCRIPT__|${here}/site-refresh.sh|g" \
      -e "s|__LOG_DIR__|${LOG_DIR}|g" \
      -e "s|<integer>6</integer><!-- SCHEDULE_HOUR -->|<integer>${SCHEDULE_HOUR}</integer>|g" \
      -e "s|__HOME__|${HOME}|g" \
      "${here}/${LABEL}.plist" >"$plist_path"
  launchctl bootout "gui/$(id -u)/${LABEL}" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "$plist_path" || { echo "site-refresh: launchctl bootstrap failed" >&2; exit 1; }
  echo "site-refresh: installed ${LABEL}, daily at ${SCHEDULE_HOUR}:00 local time. PUBLISH=${PUBLISH} in ${CONF}."
  exit 0
fi
if [ "$mode" = "uninstall" ]; then
  launchctl bootout "gui/$(id -u)/${LABEL}" >/dev/null 2>&1 || true
  rm -f "$plist_path"
  echo "site-refresh: removed ${LABEL}."
  exit 0
fi

# --- plan -------------------------------------------------------------------
if [ "$mode" = "plan" ]; then
  cat <<EOF
site-refresh plan (nothing below runs under --plan)
  config      ${CONF}
  generator   ${GENERATOR}
  caches      ${CACHES:-<none found>}
  select      ${SELECT}   allow-security: ${ALLOW_SECURITY:-<none>}
  build       ${BUILD}
  1. acquire lock ${WORKDIR}/.lock (stop if held)
  2. ${GENERATOR} --caches <caches> --out ${BUILD}.new --status-from gh --select ${SELECT}${allow_flags}
     -> any refusal, hold-without-ruling, scan hit or non-zero exit: stop, no push
  3. swap ${BUILD}.new into ${BUILD}
  4. PUBLISH=${PUBLISH}: $( [ "$PUBLISH" = "yes" ] && echo "continue" || echo "stop here (generated locally, nothing pushed)" )
  5. clone or fetch ${COMMUNITY_REPO} branch ${PAGES_BRANCH} into ${CLONE} (stop if the branch does not exist on the remote)
  6. replace the branch tree with ${BUILD} (+ a generated README.md and .nojekyll), commit if changed
  7. git push origin ${PAGES_BRANCH} -- with the maintainer's own credential; never main
  8. append one line to ${LOG}
EOF
  exit 0
fi

# --- preflight --------------------------------------------------------------
command -v python3 >/dev/null 2>&1 || { echo "site-refresh: python3 not found" >&2; exit 2; }
command -v gh >/dev/null 2>&1 || { echo "site-refresh: gh not found" >&2; exit 2; }
[ -f "$GENERATOR" ] || { echo "site-refresh: generator not found at ${GENERATOR}" >&2; exit 2; }
[ -n "$CACHES" ] || { echo "site-refresh: no cache directories found; set CACHES in ${CONF}" >&2; exit 2; }
mkdir -p "$WORKDIR"
if ! mkdir "${WORKDIR}/.lock" 2>/dev/null; then
  echo "site-refresh: another run holds ${WORKDIR}/.lock" >&2; exit 2
fi
trap 'rmdir "${WORKDIR}/.lock" 2>/dev/null' EXIT INT TERM

# --- 2. generate -------------------------------------------------------------
rm -rf "${BUILD}.new"
log "start select=${SELECT} publish=${PUBLISH} mode=${mode}"
# shellcheck disable=SC2086
if ! sh "$GENERATOR" --caches "$CACHES" --out "${BUILD}.new" --status-from gh --select "$SELECT" $allow_flags >"${LOG_DIR}/generate.last" 2>&1; then
  stop "generator failed or refused (see ${LOG_DIR}/generate.last); nothing pushed"
fi
summary=$(tail -1 "${LOG_DIR}/generate.last" 2>/dev/null)
[ -f "${BUILD}.new/index.html" ] || stop "generator produced no index.html"
rm -rf "${BUILD}.old"; [ -d "$BUILD" ] && mv "$BUILD" "${BUILD}.old"
mv "${BUILD}.new" "$BUILD"; rm -rf "${BUILD}.old"
log "generated: ${summary}"

if [ "$mode" = "dry" ] || [ "$PUBLISH" != "yes" ]; then
  echo "site-refresh: generated ${BUILD}; not pushed ($( [ "$mode" = "dry" ] && echo "--dry-run" || echo "PUBLISH=${PUBLISH}" ))."
  log "not pushed: $( [ "$mode" = "dry" ] && echo "dry-run" || echo "publish disabled" )"
  exit 0
fi

# --- 5. the Pages branch -----------------------------------------------------
if [ ! -d "${CLONE}/.git" ]; then
  gh repo clone "$COMMUNITY_REPO" "$CLONE" -- --quiet --no-checkout >/dev/null 2>&1 || stop "could not clone ${COMMUNITY_REPO}"
fi
( cd "$CLONE" && git fetch --quiet origin ) || stop "git fetch failed"
if ! ( cd "$CLONE" && git rev-parse --verify --quiet "origin/${PAGES_BRANCH}" >/dev/null ); then
  stop "branch ${PAGES_BRANCH} does not exist on ${COMMUNITY_REPO}; the committee has not designated a Pages branch (PB-12)"
fi
( cd "$CLONE" && git checkout --quiet -B "$PAGES_BRANCH" "origin/${PAGES_BRANCH}" ) || stop "checkout of ${PAGES_BRANCH} failed"

# --- 6. replace the tree -----------------------------------------------------
( cd "$CLONE" && find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} + )
cp -R "${BUILD}/." "$CLONE/"
touch "${CLONE}/.nojekyll"
cat >"${CLONE}/README.md" <<EOF
# lq-ai reviews — generated site

This branch holds **generated output**: the public reading decks and
records of lq-maintainer-agent's reviews of LegalQuants/lq-ai pull
requests and issues, regenerated by \`publish/site-refresh.sh\` from the
maintainer's local records. Nothing here is a decision. A human
maintainer decides whether and how a change merges; the committee's
record is on \`main\`.

Regenerated $(stamp). Do not edit by hand: the next refresh replaces
this tree in full. Generator and rules: https://github.com/houfu/lq-maintainer-agent
(\`rules/publishing.md\`).
EOF
if ( cd "$CLONE" && git add -A && git diff --cached --quiet ); then
  echo "site-refresh: site unchanged; nothing to push."
  log "unchanged"
  exit 0
fi
( cd "$CLONE" && git -c user.name="$(git config --get user.name || echo lq-maintainer site refresh)" \
                   -c user.email="$(git config --get user.email || echo noreply@localhost)" \
                   commit --quiet -m "site: refresh $(stamp)

${summary}" ) || stop "commit failed"

# --- 7. push -----------------------------------------------------------------
( cd "$CLONE" && git push --quiet origin "$PAGES_BRANCH" ) || stop "push to ${PAGES_BRANCH} failed"
echo "site-refresh: pushed ${PAGES_BRANCH} on ${COMMUNITY_REPO}."
log "pushed ${PAGES_BRANCH}: ${summary}"
exit 0
