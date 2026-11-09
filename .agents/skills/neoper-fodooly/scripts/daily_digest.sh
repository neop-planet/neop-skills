#!/usr/bin/env bash
# ponytail: single script resolves bk (seen) and fr (client + super-admin) from monorepo root
# Usage: daily_digest.sh [bk|fr|client|super-admin|all|<path>] [since=midnight] [branch]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TARGET="${1:-bk}"
SINCE="${2:-midnight}"
BRANCH="${3:-}"

resolve_repos() {
  case "$1" in
    bk|backend|seen)      echo "$ROOT/seen" ;;
    fr|frontend)          echo "$ROOT/client"; echo "$ROOT/super-admin" ;;
    client)               echo "$ROOT/client" ;;
    super-admin|admin)    echo "$ROOT/super-admin" ;;
    all|both)             echo "$ROOT/seen"; echo "$ROOT/client"; echo "$ROOT/super-admin" ;;
    *)                    echo "$1" ;;
  esac
}

if [ "${1:-}" = "--check" ]; then
  [ "$(resolve_repos bk)" = "$ROOT/seen" ]
  [ "$(resolve_repos fr | wc -l)" -eq 2 ]
  echo "OK"
  exit 0
fi

PATTERN_BK='(routes/|Controllers/|Resources/|Requests/|Enums/|Models/|migrations/|Services/|Middleware/|Permissions|\.env\.example|config/)'
PATTERN_FR='(types/entities/|enums/|constants/endpoints|config/endpoints|services/|modules/|composables/|components/|views/|i18n/locales/)'

for REPO in $(resolve_repos "$TARGET"); do
  if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: not a git repo: $REPO" >&2
    continue
  fi

  g() { git -C "$REPO" "$@"; }
  NAME="$(basename "$REPO")"
  CURRENT="$(g rev-parse --abbrev-ref HEAD)"
  REF_BRANCH="${BRANCH:-$CURRENT}"

  echo "=========================================="
  echo "== Repo: $NAME ($REPO)"
  echo "== Branch: $REF_BRANCH (since: $SINCE)"

  if [ "$REF_BRANCH" != "$CURRENT" ]; then
    echo "NOTE: on '$CURRENT', not '$REF_BRANCH'. Fetching only."
    g fetch --quiet origin "$REF_BRANCH" 2>&1 || echo "WARN: fetch failed"
    RANGE_REF="origin/$REF_BRANCH"
  elif [ -n "$(g status --porcelain --untracked-files=no)" ]; then
    echo "WARN: working tree dirty. Fetching only (skipping pull)."
    g fetch --quiet origin 2>&1 || echo "WARN: fetch failed"
    RANGE_REF="origin/$REF_BRANCH"
  else
    if g pull --ff-only --quiet 2>&1; then
      echo "== Pull: OK (fast-forward)"
    else
      echo "WARN: pull --ff-only failed. Using local HEAD."
    fi
    RANGE_REF="HEAD"
  fi

  g rev-parse --verify --quiet "$RANGE_REF" >/dev/null || RANGE_REF="HEAD"

  COUNT="$(g rev-list --count --since="$SINCE" "$RANGE_REF" 2>/dev/null || echo 0)"
  if [ "$COUNT" = "0" ]; then
    echo "== Commits since $SINCE: (none)"
    echo "Last commit: $(g log -1 --format='%h | %an | %ad | %s' --date=format:'%Y-%m-%d %H:%M' "$RANGE_REF")"
    echo
    continue
  fi

  echo "== Commits since $SINCE ($COUNT):"
  g log --since="$SINCE" --reverse --date=format:'%Y-%m-%d %H:%M' \
    --format='--- %h | %an | %ad | %s' --name-status "$RANGE_REF"

  echo
  echo "== Neoper-relevant files touched:"
  PAT="$PATTERN_FR"
  [ "$NAME" = "seen" ] && PAT="$PATTERN_BK"
  g log --since="$SINCE" --name-only --format='' "$RANGE_REF" \
    | sort -u | grep -Ei "$PAT" || echo "(none matched)"
  echo
done
