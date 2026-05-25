#!/usr/bin/env bash
# One-liner entry point: install minimal prereqs, clone the repo into
# ghq layout, then exec install.sh.
#
# Usage on a fresh machine:
#   curl -fsSL https://raw.githubusercontent.com/mekajiki/dotfiles/master/bootstrap.sh | bash

set -euo pipefail

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/mekajiki/dotfiles.git}"
TARGET_DIR="${DOTFILES_DIR:-$HOME/ghq/github.com/mekajiki/dotfiles}"

log() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

ensure_prereqs() {
  if command -v git >/dev/null && command -v curl >/dev/null; then
    return
  fi
  if command -v apt-get >/dev/null; then
    log "Installing git+curl via apt"
    sudo apt-get update
    sudo apt-get install -y git curl ca-certificates
  elif command -v brew >/dev/null; then
    log "Installing git via brew"
    brew install git
  else
    echo "No supported package manager (apt/brew). Install git+curl manually." >&2
    exit 1
  fi
}

clone_or_update() {
  mkdir -p "$(dirname "$TARGET_DIR")"
  if [ -d "$TARGET_DIR/.git" ]; then
    log "Updating existing checkout: $TARGET_DIR"
    git -C "$TARGET_DIR" pull --ff-only || true
  else
    log "Cloning $REPO_URL -> $TARGET_DIR"
    git clone "$REPO_URL" "$TARGET_DIR"
  fi
}

ensure_prereqs
clone_or_update
cd "$TARGET_DIR"
exec ./install.sh "$@"
