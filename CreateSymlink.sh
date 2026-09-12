#!/usr/bin/env bash
# mklink.sh — Create symlinks of files/directories inside a fixed target directory.
# Usage: mklink.sh <source_path> [source_path ...]
set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
LINK_DIR="${LINK_DIR:-$HOME/Games/World of Warcraft/_retail_/Interface/AddOns}"   # Override via env var or edit here
# ─────────────────────────────────────────────────────────────────────────────

# ── Helpers ──────────────────────────────────────────────────────────────────
usage() {
  echo "Usage: $(basename "$0") <source_path> [source_path ...]"
  echo
  echo "Creates a symlink inside: $LINK_DIR"
  echo "for each source path given. Override the target directory by setting"
  echo "the LINK_DIR env variable."
  exit 1
}

err() { echo "Error: $*" >&2; }

# Resolve, validate, and link a single source path.
# Returns 0 on success, 1 on failure (and never aborts the whole script).
link_one() {
  local raw="$1"
  local source link_name

  # Resolve to an absolute path (works on Linux & macOS, no readlink -f needed)
  source="$(cd "$(dirname "$raw")" 2>/dev/null && pwd)/$(basename "$raw")" \
    || { err "Cannot resolve path: $raw"; return 1; }

  [[ -e "$source" ]] || { err "Source does not exist: $source"; return 1; }

  link_name="$LINK_DIR/$(basename "$source")"

  if [[ -L "$link_name" ]]; then
    echo "Warning: Replacing existing symlink at $link_name"
    rm "$link_name"
  elif [[ -e "$link_name" ]]; then
    err "A non-symlink file already exists at $link_name — refusing to overwrite."
    return 1
  fi

  ln -s "$source" "$link_name" || { err "Failed to create symlink for $raw"; return 1; }
  echo "✓ Symlink created: $link_name → $source"
  return 0
}
# ─────────────────────────────────────────────────────────────────────────────

[[ $# -lt 1 ]] && usage
[[ "$1" == "-h" || "$1" == "--help" ]] && usage

# Create the target directory if it doesn't exist yet
mkdir -p "$LINK_DIR" || { err "Cannot create link directory: $LINK_DIR"; exit 1; }

ok_count=0
fail_count=0

for src in "$@"; do
  if link_one "$src"; then
    ok_count=$((ok_count + 1))
  else
    fail_count=$((fail_count + 1))
  fi
done

echo
echo "Done: $ok_count linked, $fail_count failed."
[[ $fail_count -eq 0 ]] || exit 1
