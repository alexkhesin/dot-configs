# https://specifications.freedesktop.org/basedir/latest/
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# Unofficial name for the common binary directory
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

export GIT_EDITOR="~/.emacs.d/ak-emacs/bin/emacs-connect emacs.git -t"
export CLICOLOR=yes  # Enable color ls output

# Prevent duplicates in the path array
typeset -U path

path=($XDG_BIN_HOME $path)

# Add Python 3.14
PYTHON_DIR=/Library/Frameworks/Python.framework/Versions/3.14/bin
if [[ -d $PYTHON_DIR ]]; then
  path=($PYTHON_DIR $path)
fi

if [[ -r /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi
