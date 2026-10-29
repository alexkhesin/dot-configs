#!/usr/bin/env bash

set -euo pipefail

# Install packages for various packages

case "$(uname -s)" in
  Darwin)
    # In case we just installed homebrew on a new laptop, and zshrc does
    # not have its path yet
    PATH="$PATH:/opt/homebrew/bin/"

    # C compiler (maybe not needed now that I am using brew instead of macports)
    # But clang is still needed as C/C+ language server for Emacs (eglot runs
    # `clangd`).
    xcode-select -p >/dev/null 2>&1 || xcode-select --install

    # If xcode-select will not be appropriate one day, can install llvm instead
    ## brew install llvm
    ## # Homebrew's llvm is keg-only (not linked into PATH). Link just clangd, so
    ## # Emacs can find it without putting llvm's own clang ahead of Apple's.
    ## mkdir -p "$HOME/.local/bin"
    ## ln -sf "$(brew --prefix llvm)/bin/clangd" "$HOME/.local/bin/clangd"

    brew install enchant pkgconf stow fzf uv bat eza
    ;;
  Linux)
    if command -v apt-get >/dev/null; then
      sudo apt-get install -y build-essential libenchant-2-dev pkgconf \
        hunspell-en-us pipx stow fzf bat eza
      sudo apt-get install -y clangd || sudo apt-get install -y clang-tools
    else
      echo "Unsupported Linux, fix the script"
      exit 1
    fi

    # uv is not in apt repo on my Linux, install it using pipx
    pipx upgrade uv 2>/dev/null || pipx install uv
    ;;
esac

uv tool install --upgrade pyrefly

my_stow() { stow --verbose=2 -t ~ --dotfiles "$@"; }

OS_SUFFIX=$(uname | tr '[:upper:]' '[:lower:]')

my_stow emacs tmux ghostty vim git bat jj *-${OS_SUFFIX}
# zsh has dot-files inside of dot-directory
my_stow --no-folding zsh

# set email address for future github commits
jj config set --repo user.email "1182112+alexkhesin@users.noreply.github.com"
