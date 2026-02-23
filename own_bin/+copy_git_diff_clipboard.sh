#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: copy_git_diff_clipboard.sh -a | -s | -u" >&2
  echo "  -a  all changes (as if: git add -A; then diff vs HEAD / empty tree)" >&2
  echo "  -s  staged changes" >&2
  echo "  -u  unstaged changes" >&2
  exit 1
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository" >&2
  exit 1
fi

MODE=""
while getopts "asu" opt; do
  case "$opt" in
    a) MODE="all" ;;
    s) MODE="staged" ;;
    u) MODE="unstaged" ;;
    *) usage ;;
  esac
done

# Require exactly one flag, and no extra args
shift $((OPTIND - 1))
if [ -z "${MODE}" ] || [ "${#}" -ne 0 ]; then
  usage
fi

GIT_DIR="$(git rev-parse --git-dir)"
INDEX_PATH="${GIT_DIR%/}/index"

CONTENT=""
LABEL=""

case "$MODE" in
  unstaged)
    CONTENT="$(git diff --no-color)"
    LABEL="unstaged changes"
    ;;

  staged)
    CONTENT="$(git diff --no-color --staged)"
    LABEL="staged changes"
    ;;

  all)
    LABEL="all changes"

    TMP_INDEX="$(mktemp)"
    RESTORE_INDEX="0"

    cleanup() {
      # Restore original index state
      if [ "$RESTORE_INDEX" = "1" ]; then
        if [ -f "$TMP_INDEX" ]; then
          # Original index existed
          cp -f "$TMP_INDEX" "$INDEX_PATH" 2>/dev/null || true
        else
          # Original index did not exist
          rm -f "$INDEX_PATH" 2>/dev/null || true
        fi
      fi
    }
    trap cleanup EXIT INT TERM

    # Snapshot whether index existed, and if so save it
    if [ -f "$INDEX_PATH" ]; then
      cp -f "$INDEX_PATH" "$TMP_INDEX"
    else
      # mark "no original index" by removing temp file
      rm -f "$TMP_INDEX"
      : >"$TMP_INDEX" # create empty marker then delete? nah, we just test -f later; so keep it deleted
      rm -f "$TMP_INDEX"
    fi

    RESTORE_INDEX="1"

    # Stage everything (creates index if missing)
    git add -A >/dev/null 2>&1

    # Diff the index vs base (HEAD if exists, else empty tree)
    if git rev-parse --verify HEAD >/dev/null 2>&1; then
      CONTENT="$(git diff --no-color --cached HEAD)"
    else
      EMPTY_TREE="$(git hash-object -t tree /dev/null)"
      CONTENT="$(git diff --no-color --cached "$EMPTY_TREE")"
    fi

    # Explicit restore now (trap still covers crashes)
    cleanup
    RESTORE_INDEX="0"
    trap - EXIT INT TERM
    ;;
esac

if [ -z "$CONTENT" ]; then
  echo "No $LABEL"
  exit 0
fi

TOTAL_LINES=$(printf "%s" "$CONTENT" | wc -l | tr -d ' ')
TOTAL_CHARS=$(printf "%s" "$CONTENT" | wc -c | tr -d ' ')

if command -v wl-copy >/dev/null 2>&1; then
  printf "%s" "$CONTENT" | wl-copy
  CLIP="wl-copy"
elif command -v xclip >/dev/null 2>&1; then
  printf "%s" "$CONTENT" | xclip -selection clipboard
  CLIP="xclip"
else
  echo "No clipboard tool found (need wl-copy or xclip)" >&2
  exit 1
fi

echo
echo "Copied $LABEL to clipboard via $CLIP"
echo "Total lines: $TOTAL_LINES"
echo "Total chars: $TOTAL_CHARS"
