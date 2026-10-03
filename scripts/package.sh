#!/usr/bin/env bash
# Sync OryxOS local changes to GitHub (commit + push).
# Replaces the old remote-relay flow: no server needed, GitHub is the target.
#
# Usage:
#   ./scripts/package.sh                      # auto-generate commit message
#   ./scripts/package.sh "feat: add X"        # use a custom commit message
#
# What it does:
#   1. Collects all local changes (uncommitted / staged / untracked / unpushed)
#   2. Builds a meaningful commit message (areas + file counts + file list)
#   3. Commits everything and pushes to origin/<current-branch>, with retry

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
REMOTE="${ORYXOS_SYNC_REMOTE:-origin}"   # git remote to push to
MAX_RETRIES=3                             # push retry count (network hiccups)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Logging helpers ────────────────────────────────────────────────────────────
info()  { echo "[INFO]  $*"; }
warn()  { echo "[WARN]  $*" >&2; }
error() { echo "[ERROR] $*" >&2; }

# ── Commit message builder ──────────────────────────────────────────────────────
# Subject line summarises affected top-level areas + file counts,
# body lists the files (capped to keep the message readable).
build_commit_message() {
  local changed="$1"
  local n_changed areas subject
  local -i cap=30

  n_changed=$(printf '%s\n' "$changed" | grep -c '[^[:space:]]' || true)
  [[ "$n_changed" =~ ^[0-9]+$ ]] || n_changed=0

  areas=$(printf '%s\n' "$changed" \
    | grep '[^[:space:]]' \
    | sed 's#/.*##' \
    | sort -u | paste -sd ', ' -)

  subject="chore: update ${areas:-changes} (${n_changed} file(s))"

  printf '%s\n' "$subject"
  printf '\nChanged:\n'
  printf '%s\n' "$changed" | grep '[^[:space:]]' | head -n "$cap" | sed 's/^/  - /'
  [[ "$n_changed" -gt "$cap" ]] && printf '  - ... and %s more\n' "$((n_changed - cap))"
  return 0
}

# ── Branch detection ───────────────────────────────────────────────────────────
BRANCH=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD)
info "Branch: ${BRANCH} → ${REMOTE}"

if ! git -C "$PROJECT_ROOT" rev-parse --verify --quiet "${REMOTE}/${BRANCH}" >/dev/null; then
  warn "Remote branch ${REMOTE}/${BRANCH} not found (first push?)."
fi

# ── Collect changed files (for reporting / commit message) ────────────────────
# 1. Uncommitted (workdir vs HEAD, incl. staged)
WORKDIR_FILES=$(git -C "$PROJECT_ROOT" diff --name-only --diff-filter=ACMR HEAD 2>/dev/null || true)
# 2. Untracked new files (respects .gitignore)
UNTRACKED_FILES=$(git -C "$PROJECT_ROOT" ls-files --others --exclude-standard 2>/dev/null || true)
# 3. Committed locally but not pushed yet
UNPUSHED_FILES=$(git -C "$PROJECT_ROOT" diff --name-only --diff-filter=ACMR \
  "${REMOTE}/${BRANCH}"...HEAD 2>/dev/null || true)

ALL_FILES=$(printf '%s\n%s\n%s' "$WORKDIR_FILES" "$UNTRACKED_FILES" "$UNPUSHED_FILES" \
  | grep -v '\.tar\.gz$' \
  | grep -v '\.DS_Store' \
  | grep -vE '(^|/)target/' \
  | grep '[^[:space:]]' \
  | sort -u || true)

# ── Debug summary ──────────────────────────────────────────────────────────────
echo "--- Change sources ---"
info "[uncommitted] $(printf '%s\n' "$WORKDIR_FILES" | grep -c '[^[:space:]]' || true) file(s)"
info "[untracked]   $(printf '%s\n' "$UNTRACKED_FILES" | grep -c '[^[:space:]]' || true) file(s)"
info "[unpushed]    $(printf '%s\n' "$UNPUSHED_FILES" | grep -c '[^[:space:]]' || true) file(s)"
echo "----------------------"

# ── Build commit message ──────────────────────────────────────────────────────
if [[ -n "$ALL_FILES" ]]; then
  info "Files to sync:"
  echo "$ALL_FILES" | sed 's/^/  /'
  COMMIT_MSG=$(build_commit_message "$ALL_FILES")
else
  COMMIT_MSG=""
fi

# Custom message from first argument wins
[[ -n "${1:-}" ]] && COMMIT_MSG="$1"

if [[ -z "$COMMIT_MSG" ]]; then
  info "Nothing to sync: working tree clean and nothing unpushed."
  exit 0
fi

info "Commit message:"
printf '%s\n' "$COMMIT_MSG" | sed 's/^/  | /'

# ── Commit ────────────────────────────────────────────────────────────────────
git -C "$PROJECT_ROOT" add -A
if git -C "$PROJECT_ROOT" diff --cached --quiet; then
  info "No staged changes to commit (maybe only unpushed commits remain)."
else
  git -C "$PROJECT_ROOT" commit -m "$COMMIT_MSG"
  info "Local commit done."
fi

# ── Push with retry ───────────────────────────────────────────────────────────
info "Pushing to ${REMOTE}/${BRANCH} ..."
RETRY=0
DELAY=2
until git -C "$PROJECT_ROOT" push "${REMOTE}" "${BRANCH}" 2>&1 | tee /tmp/oryxos_push_output.txt; do
  PUSH_OUTPUT=$(cat /tmp/oryxos_push_output.txt)
  if echo "${PUSH_OUTPUT}" | grep -qiE 'refusing|403|permission|scope|authentication|not allowed'; then
    error "Push permanently rejected (auth/permission error). Aborting."
    exit 1
  fi
  RETRY=$((RETRY + 1))
  if [[ ${RETRY} -ge ${MAX_RETRIES} ]]; then
    error "Push failed after ${MAX_RETRIES} retries. Giving up."
    exit 1
  fi
  warn "Push failed, retrying in ${DELAY}s (${RETRY}/${MAX_RETRIES}) ..."
  sleep "${DELAY}"
  DELAY=$((DELAY * 2))
done

info "Push succeeded."
info "All done."
