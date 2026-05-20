#!/usr/bin/env bash
# Bootstrap a new machine to match this dotfiles repo.
# Idempotent on macOS / Linux / WSL2.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# ---------------------------------------------------------------------------
# OS detection
# ---------------------------------------------------------------------------
OS=""
IS_WSL=0
case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)
    OS=linux
    if grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
      IS_WSL=1
    fi
    ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
log "Detected OS: $OS$([ "$IS_WSL" = 1 ] && echo ' (WSL)')"

# ---------------------------------------------------------------------------
# Packages
# ---------------------------------------------------------------------------
install_packages_linux() {
  log "Installing apt packages"
  local pkgs=(
    zsh tmux vim git curl unzip ca-certificates
    build-essential locales xclip
  )
  sudo apt-get update
  sudo apt-get install -y "${pkgs[@]}"
}

install_packages_macos() {
  if ! command -v brew >/dev/null; then
    log "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  log "Installing brew formulae"
  local formulae=(zsh tmux vim git coreutils)
  brew install "${formulae[@]}" || true
}

# ---------------------------------------------------------------------------
# Locale (Linux/WSL)
# ---------------------------------------------------------------------------
setup_locale() {
  [ "$OS" = linux ] || return 0
  log "Generating en_US.UTF-8 locale"
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8
}

# ---------------------------------------------------------------------------
# Symlinks
# ---------------------------------------------------------------------------
link_dotfiles() {
  log "Linking dotfiles"
  (cd "$REPO_DIR" && ./link_files.sh)
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
main() {
  case "$OS" in
    linux)
      install_packages_linux
      setup_locale
      ;;
    macos)
      install_packages_macos
      ;;
  esac
  link_dotfiles

  log "Done. Open a new shell or run: exec zsh"
}

main "$@"
