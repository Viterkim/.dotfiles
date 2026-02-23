#!/usr/bin/env bash
set -eu

RECURSIVE=0

# Parse flags
while [ "${1:-}" ]; do
  case "$1" in
    -r)
      RECURSIVE=1
      shift
      ;;
    -*)
      echo "unknown flag: $1" >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

DIR="${1:-}"

if [ -z "$DIR" ] || [ ! -d "$DIR" ]; then
  echo "usage: copy-files-clipboard.sh [-r] <directory>" >&2
  exit 1
fi

FILE_COUNT=0
TOTAL_LINES=0
TOTAL_CHARS=0
CONTENT=""

if [ "$RECURSIVE" -eq 1 ]; then
  FILES=$(find "$DIR" -type f | sort)
else
  FILES=$(find "$DIR" -maxdepth 1 -type f | sort)
fi

for f in $FILES; do
  FILE_COUNT=$((FILE_COUNT + 1))

  LINES=$(wc -l < "$f" | tr -d ' ')
  CHARS=$(wc -c < "$f" | tr -d ' ')

  TOTAL_LINES=$((TOTAL_LINES + LINES))
  TOTAL_CHARS=$((TOTAL_CHARS + CHARS))

  echo "file: $f"
  echo "  lines: $LINES"
  echo "  chars: $CHARS"

  CONTENT="$CONTENT===== $f =====
$(cat "$f")

"
done

if [ "$FILE_COUNT" -eq 0 ]; then
  echo "No files found in $DIR" >&2
  exit 1
fi

# Clipboard
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
echo "Copied $FILE_COUNT files to clipboard via $CLIP"
echo "Total lines: $TOTAL_LINES"
echo "Total chars: $TOTAL_CHARS"
