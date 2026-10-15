# https://specifications.freedesktop.org/basedir/latest/
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# Unofficial name for the common binary directory
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

# Ensure required XDG directories exist
ensure_dir "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_DATA_HOME"
ensure_dir "$XDG_CACHE_HOME" "$XDG_BIN_HOME"

export P4EDITOR="~/.emacs.d/ak-emacs/bin/emacs-connect emacs.p4 -t"
export GIT_EDITOR="~/.emacs.d/ak-emacs/bin/emacs-connect emacs.git -t"
export CLICOLOR=1  # Enable color ls output on MacOS, and most modern tools

# Otherwise corp default zshrc sets up default config that I do not like
export google_zsh_flysolo="yes"

path=($XDG_BIN_HOME $path)

# Add Python 3.14
PYTHON_DIR=/Library/Frameworks/Python.framework/Versions/3.14/bin
if [[ -d $PYTHON_DIR ]]; then
  path=($PYTHON_DIR $path)
fi

if [[ -r /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi
