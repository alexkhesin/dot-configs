#!/usr/bin/env bash

sys_stow() { stow --verbose=2 -t ~ --dotfiles "$@"; }

sys_stow emacs tmux zsh

OS_SUFFIX=$(uname | tr '[:upper:]' '[:lower:]')

echo "Installing *-${OS_SUFFIX} configs..."
sys_stow *-${OS_SUFFIX}
