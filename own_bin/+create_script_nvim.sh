#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: create_script_nvim.sh <name>"
  echo "example: create_script_nvim.sh my_tool"
  exit 1
}

if [ "${1:-}" = "" ]; then
  usage
fi

NAME="$1"

if [[ "$NAME" != *.sh ]]; then
  NAME="${NAME}.sh"
fi

TARGET="$PWD/$NAME"

if [ -e "$TARGET" ]; then
  echo "File already exists: $TARGET"
  exit 1
fi

cat > "$TARGET" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

EOF

chmod 755 "$TARGET"

echo "Created $TARGET"
nvim "$TARGET"
