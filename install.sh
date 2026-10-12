#!/usr/bin/env bash

set -euo pipefail

# Install packages for emacs spell-checker, jinx
case "$(uname -s)" in
  Darwin)
    xcode-select -p >/dev/null 2>&1 || xcode-select --install   # C compiler
    brew install enchant pkgconf
    ;;
  Linux)
    if   command -v apt-get >/dev/null; then
      sudo apt-get install -y build-essential libenchant-2-dev pkgconf hunspell-en-us
    elif command -v dnf >/dev/null; then
      sudo dnf install -y gcc enchant2-devel pkgconf-pkg-config hunspell-en-US
    elif command -v pacman >/dev/null; then
      sudo pacman -S --needed --noconfirm base-devel enchant pkgconf hunspell-en_us
    else
      echo "Install: enchant (+dev files), pkgconf, a C compiler, a hunspell English dictionary" >&2
      exit 1
    fi
    ;;
esac

sys_stow() { stow --verbose=2 -t ~ --dotfiles "$@"; }

sys_stow emacs tmux zsh

OS_SUFFIX=$(uname | tr '[:upper:]' '[:lower:]')

echo "Installing *-${OS_SUFFIX} configs..."
sys_stow *-${OS_SUFFIX}
