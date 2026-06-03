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
    zoxide fzf
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
  local formulae=(zsh tmux vim git ghq rbenv ruby-build nvm coreutils zoxide fzf)
  brew install "${formulae[@]}" || true
}

# ---------------------------------------------------------------------------
# Ruby build deps (apt) - needed for rbenv install <version>
# ---------------------------------------------------------------------------
install_ruby_build_deps_linux() {
  [ "$OS" = linux ] || return 0
  log "Installing Ruby build deps"
  sudo apt-get install -y \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libncurses-dev libffi-dev liblzma-dev libyaml-dev
}

# ---------------------------------------------------------------------------
# rbenv + ruby-build (Linux; macOS uses brew)
# ---------------------------------------------------------------------------
install_rbenv_linux() {
  [ "$OS" = linux ] || return 0
  if [ -d "$HOME/.rbenv/.git" ]; then
    log "rbenv already cloned"
  else
    log "Cloning rbenv"
    git clone --depth=1 https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
  fi
  if [ -d "$HOME/.rbenv/plugins/ruby-build/.git" ]; then
    log "ruby-build already cloned"
  else
    log "Cloning ruby-build"
    git clone --depth=1 https://github.com/rbenv/ruby-build.git \
      "$HOME/.rbenv/plugins/ruby-build"
  fi
}

# ---------------------------------------------------------------------------
# nvm (Linux; macOS uses brew)
# ---------------------------------------------------------------------------
install_nvm_linux() {
  [ "$OS" = linux ] || return 0
  if [ -s "$HOME/.nvm/nvm.sh" ]; then
    log "nvm already installed"
    return
  fi
  log "Installing nvm"
  PROFILE=/dev/null bash -c \
    "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"
}

# ---------------------------------------------------------------------------
# ghq (binary release on Linux; brew handles macOS)
# ---------------------------------------------------------------------------
install_ghq_linux() {
  [ "$OS" = linux ] || return 0
  if command -v ghq >/dev/null || [ -x "$HOME/.local/bin/ghq" ]; then
    log "ghq already installed"
    return
  fi
  log "Installing ghq from GitHub release"
  local arch
  case "$(uname -m)" in
    x86_64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) warn "Unsupported arch: $(uname -m); skipping ghq"; return 0 ;;
  esac
  local url
  url="$(curl -fsSL https://api.github.com/repos/x-motemen/ghq/releases/latest \
    | grep -oE "\"browser_download_url\": *\"[^\"]+linux_${arch}\\.zip\"" \
    | head -1 | sed -E 's/.*"(https:[^"]+)".*/\1/')"
  if [ -z "$url" ]; then
    warn "Could not determine ghq download URL; skipping"
    return 0
  fi
  local tmpdir
  tmpdir="$(mktemp -d)"
  curl -fsSL -o "$tmpdir/ghq.zip" "$url"
  (cd "$tmpdir" && unzip -q ghq.zip)
  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$tmpdir"/ghq_linux_*/ghq "$HOME/.local/bin/ghq"
  rm -rf "$tmpdir"
  log "ghq -> $HOME/.local/bin/ghq"
}

# ---------------------------------------------------------------------------
# zoxide history migration (rupa/z の後継。.zshrc が zoxide init する)
# zoxide / fzf 本体は apt / brew のパッケージで導入済み。
# 旧 rupa/z の履歴 ~/.z があり、まだ zoxide db が無いときだけ一度だけ取り込む。
# ---------------------------------------------------------------------------
migrate_z_history() {
  command -v zoxide >/dev/null || return 0
  local db="${_ZO_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zoxide}/db.zo"
  if [ -f "$db" ]; then
    log "zoxide db already exists; skipping ~/.z import"
    return
  fi
  if [ -f "$HOME/.z" ]; then
    log "Importing rupa/z history (~/.z) into zoxide"
    zoxide import --from z "$HOME/.z"
  fi
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
# Default shell -> zsh
# ---------------------------------------------------------------------------
set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh || true)"
  if [ -z "$zsh_path" ]; then
    warn "zsh not found; skipping chsh"
    return
  fi
  if [ "${SHELL:-}" = "$zsh_path" ]; then
    log "Default shell already zsh"
    return
  fi
  if ! grep -qxF "$zsh_path" /etc/shells; then
    log "Adding $zsh_path to /etc/shells"
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi
  log "Changing default shell to zsh (you may be prompted for password)"
  chsh -s "$zsh_path" || warn "chsh failed; you can run it later"
}

# ---------------------------------------------------------------------------
# Vundle + plugin install (.vimrc expects rtp+=~/.vim/vundle)
# ---------------------------------------------------------------------------
setup_vim_plugins() {
  if [ -d "$HOME/.vim/vundle/.git" ]; then
    log "Vundle already cloned"
  else
    log "Cloning Vundle (rtp path matches .vimrc: ~/.vim/vundle)"
    git clone --depth=1 https://github.com/VundleVim/Vundle.vim.git \
      "$HOME/.vim/vundle"
  fi
  log "Running :PluginInstall (headless)"
  vim +PluginInstall +qall >/dev/null 2>&1 || \
    warn ":PluginInstall reported errors (often harmless on first run)"
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
main() {
  case "$OS" in
    linux)
      install_packages_linux
      setup_locale
      install_ghq_linux
      install_ruby_build_deps_linux
      install_rbenv_linux
      install_nvm_linux
      ;;
    macos)
      install_packages_macos
      ;;
  esac
  migrate_z_history
  link_dotfiles
  setup_vim_plugins
  set_default_shell

  log "Done. Open a new shell or run: exec zsh"
}

main "$@"
