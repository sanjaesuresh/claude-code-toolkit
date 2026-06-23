#!/usr/bin/env bash
# install.sh
#
# Installs the global toolkit (CLAUDE.md, settings.json, skills, agents,
# scripts) from this repo into ~/.claude.
#
# Defaults to COPY mode (safe everywhere, including corporate machines that
# dislike symlinks). Pass --symlink to link instead.
#
#   bash scripts/install.sh             # copy mode (default)
#   bash scripts/install.sh --symlink   # symlink mode
#   bash scripts/install.sh --dry-run   # show what would happen
#
# Behavior:
#   - Never deletes files it did not create.
#   - Backs up any existing target before overwriting (timestamped).
#   - Does NOT touch settings.local.json or any credentials.
set -uo pipefail

MODE="copy"
DRY=0
for arg in "$@"; do
  case "$arg" in
    --symlink) MODE="symlink" ;;
    --copy)    MODE="copy" ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/global"
DEST="$HOME/.claude"
STAMP="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo backup)"

say() { echo "[install] $*"; }
do_() { if [ "$DRY" -eq 1 ]; then echo "  DRY: $*"; else eval "$*"; fi; }

[ -d "$SRC" ] || { echo "Missing $SRC — run from the repo root." >&2; exit 1; }

say "mode=$MODE  source=$SRC  dest=$DEST"
do_ "mkdir -p '$DEST'"

backup() { # backup a path if it exists and we're about to replace it
  local target="$1"
  [ -e "$target" ] || [ -L "$target" ] || return 0
  local bdir="$DEST/.toolkit-backups/$STAMP"
  do_ "mkdir -p '$bdir'"
  do_ "cp -R '$target' '$bdir/' 2>/dev/null || true"
  say "backed up $(basename "$target") -> $bdir/"
}

place_dir() { # place_dir <name>  (skills/agents/scripts)
  local name="$1"
  local s="$SRC/$name" d="$DEST/$name"
  [ -d "$s" ] || { [ "$name" = "scripts" ] && s="$REPO/scripts"; } # scripts live at repo root
  [ -d "$s" ] || { say "skip $name (no source)"; return 0; }
  backup "$d"
  if [ "$MODE" = "symlink" ]; then
    do_ "rm -rf '$d'"
    do_ "ln -s '$s' '$d'"
  else
    do_ "rm -rf '$d'"
    do_ "mkdir -p '$d'"
    do_ "cp -R '$s/.' '$d/'"
  fi
  say "installed $name"
}

place_file() { # place_file <relsrc> <reldest>
  local s="$SRC/$1" d="$DEST/$2"
  [ -f "$s" ] || { say "skip $2 (no source)"; return 0; }
  backup "$d"
  if [ "$MODE" = "symlink" ]; then
    do_ "rm -f '$d'"
    do_ "ln -s '$s' '$d'"
  else
    do_ "cp '$s' '$d'"
  fi
  say "installed $2"
}

merge_settings() { # merge toolkit settings.json INTO existing, preserving user keys
  local s="$SRC/settings.json" d="$DEST/settings.json"
  [ -f "$s" ] || { say "skip settings.json (no source)"; return 0; }

  # Fresh machine: nothing to preserve, just copy.
  if [ ! -f "$d" ]; then
    do_ "cp '$s' '$d'"
    say "installed settings.json (new)"
    return 0
  fi

  backup "$d"

  # Merge requires jq. Without it, NEVER clobber the user's settings.
  if ! command -v jq >/dev/null 2>&1; then
    say "WARNING: jq not found — left your settings.json untouched."
    say "  Manually merge keys from: $s"
    return 0
  fi

  # Deep-merge: existing first, toolkit second (toolkit wins on the keys it sets:
  # hooks, permissions, skillOverrides, token knobs). User-only keys (plugins,
  # theme, env, ...) are preserved.
  if [ "$DRY" -eq 1 ]; then
    echo "  DRY: jq -s '.[0] * .[1]' '$d' '$s' > '$d' (deep-merge, preserve user keys)"
  else
    if jq -s '.[0] * .[1]' "$d" "$s" > "$d.tmp" && jq empty "$d.tmp" 2>/dev/null; then
      mv "$d.tmp" "$d"
      say "merged settings.json (your plugins/theme/env preserved)"
    else
      rm -f "$d.tmp"
      say "WARNING: settings.json merge failed — left existing file untouched."
    fi
  fi
}

install_global_gitignore() { # wire ~/.gitignore_global into git's core.excludesfile, idempotently
  local s="$SRC/gitignore_global"
  [ -f "$s" ] || { say "skip gitignore_global (no source)"; return 0; }
  local marker="# >>> claude-code-toolkit global excludes >>>"
  local endmark="# <<< claude-code-toolkit global excludes <<<"
  local block
  block="$(printf '%s\n' "$marker"; cat "$s"; printf '%s\n' "$endmark")"

  # Respect an existing excludesfile; otherwise default to ~/.gitignore_global.
  local current target
  current="$(git config --global core.excludesfile 2>/dev/null || true)"
  if [ -n "$current" ]; then
    target="${current/#\~/$HOME}"
  else
    target="$HOME/.gitignore_global"
  fi

  if [ "$DRY" -eq 1 ]; then
    echo "  DRY: ensure toolkit excludes block in '$target' and set core.excludesfile"
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  touch "$target"
  if grep -qF "$marker" "$target" 2>/dev/null; then
    # Replace the existing managed block so updates take effect.
    awk -v m="$marker" -v e="$endmark" '
      $0==m {skip=1; next} $0==e {skip=0; next} !skip' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
  fi
  printf '%s\n' "$block" >> "$target"
  [ -n "$current" ] || git config --global core.excludesfile "$HOME/.gitignore_global"
  say "global gitignore: managed block written to $target"
}

place_file "CLAUDE.md" "CLAUDE.md"
merge_settings
install_global_gitignore
place_dir "skills"
place_dir "agents"

# scripts (sourced from repo root, copied into ~/.claude/scripts and chmod'd)
backup "$DEST/scripts"
if [ "$MODE" = "symlink" ]; then
  do_ "rm -rf '$DEST/scripts'"
  do_ "ln -s '$REPO/scripts' '$DEST/scripts'"
else
  do_ "rm -rf '$DEST/scripts'"
  do_ "mkdir -p '$DEST/scripts'"
  do_ "cp -R '$REPO/scripts/.' '$DEST/scripts/'"
fi
do_ "chmod +x '$DEST/scripts/'*.sh 2>/dev/null || true"
say "installed scripts (executable)"

echo
say "Done. settings.local.json and credentials were left untouched."
say "Verify with: bash '$REPO/scripts/validate-claude-config.sh'"
