#!/usr/bin/env bash

set -euo pipefail

# In case we just installed homebrew on a new laptop, and zshrc does
# not have its path yet
PATH="$PATH:/opt/homebrew/bin/"

# Install packages for various packages

case "$(uname -s)" in
  Darwin)
    xcode-select -p >/dev/null 2>&1 || xcode-select --install # C compiler
    brew install enchant pkgconf stow fzf uv bat eza
    ;;
  Linux)
    if ! command -v uv >/dev/null; then
      command -v curl >/dev/null || { echo "curl is required to install uv" >&2; exit 1; }
      # UV_NO_MODIFY_PATH: do not let the installer edit ~/.zshrc, print warning
      # instead.
      curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
      PATH="$HOME/.local/bin:$PATH"
    fi

    if command -v apt-get >/dev/null; then
      sudo apt-get install -y build-essential libenchant-2-dev pkgconf hunspell-en-us stow fzf uv bat eza
    elif command -v dnf >/dev/null; then
      sudo dnf install -y gcc enchant2-devel pkgconf-pkg-config hunspell-en-US stow fzf uv bat eza
    elif command -v pacman >/dev/null; then
      sudo pacman -S --needed --noconfirm base-devel enchant pkgconf hunspell-en_us stow fzf uv bat eza
    else
      echo "Install: stow, enchant (+dev files), pkgconf, a C compiler, a hunspell English dictionary" >&2
      exit 1
    fi
    ;;
esac

command -v uv >/dev/null || { echo "uv not found on PATH after install" >&2; exit 1; }

# Install only if missing. Upgrade on your own schedule: uv tool upgrade pyrefly
tools=$(uv tool list 2>/dev/null || true)
grep -q '^pyrefly ' <<<"$tools" || uv tool install pyrefly

case ":$PATH:" in
  *":$HOME/.local/bin:"*) local_bin_on_path=1 ;;
  *) local_bin_on_path= ;;
esac

if [ -z "$local_bin_on_path" ]; then
  echo "NOTE: add ~/.local/bin to PATH in your shell config so Emacs can find pyrefly" >&2
fi

# C/C++ language server for Emacs (eglot runs `clangd`).
if ! command -v clangd >/dev/null; then
  case "$(uname -s)" in
    Darwin)
      echo "ERROR: clangd not on PATH; check xcode-select or install llvm" >&2
      exit 1
      ## brew install llvm
      ## # Homebrew's llvm is keg-only (not linked into PATH). Link just clangd, so
      ## # Emacs can find it without putting llvm's own clang ahead of Apple's.
      ## mkdir -p "$HOME/.local/bin"
      ## ln -sf "$(brew --prefix llvm)/bin/clangd" "$HOME/.local/bin/clangd"
      ;;
    Linux)
      if command -v apt-get >/dev/null; then
        sudo apt-get install -y clangd || sudo apt-get install -y clang-tools
      elif command -v dnf >/dev/null; then
        sudo dnf install -y clang-tools-extra
      elif command -v pacman >/dev/null; then
        sudo pacman -S --needed --noconfirm clang
      else
        echo "Install clangd (often packaged as clang-tools or clang-tools-extra)" >&2
        exit 1
      fi
      ;;
  esac
fi

my_stow() { stow --verbose=2 -t ~ --dotfiles "$@"; }

OS_SUFFIX=$(uname | tr '[:upper:]' '[:lower:]')

my_stow emacs tmux ghostty vim git bat jj *-${OS_SUFFIX}
# zsh has dot-files inside of dot-directory
my_stow --no-folding zsh

# set email address for future github commits
jj config set --repo user.email "1182112+alexkhesin@users.noreply.github.com"
