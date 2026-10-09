PLUGIN_DIR=$HOME/.local/share/zsh-plugins
ensure_dir $PLUGIN_DIR

# BOOTSTRAP: Automatically clone external plugins & themes if missing
if [ ! -d $PLUGIN_DIR/zsh-syntax-highlighting ]; then
  echo "📥 Cloning zsh-syntax-highlighting for the first time..."
  git clone --depth=1 --shallow-submodules https://github.com/zsh-users/zsh-syntax-highlighting.git $PLUGIN_DIR/zsh-syntax-highlighting
fi

if [ ! -d $PLUGIN_DIR/powerlevel10k ]; then
  echo "📥 Cloning powerlevel10k theme..."
  git clone --depth=1 --shallow-submodules https://github.com/romkatv/powerlevel10k.git $PLUGIN_DIR/powerlevel10k
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

. ~/dot-configs/public/zsh/aliases

set -o ignoreeof    # do not exit upon reading ^D

#
# ZSH options
#
ensure_dir "$XDG_STATE_HOME/zsh" "$XDG_CACHE_HOME/zsh"
HISTFILE="$XDG_STATE_HOME/zsh/histfile.ext"
HISTSIZE=1000000
SAVEHIST=1000000
DIRSTACKSIZE=10

# Navigation & Directories
setopt AUTO_CD              # Typing a folder path cd's into it
setopt AUTO_PUSHD           # Make cd push the old directory onto the directory stack
setopt PUSHD_IGNORE_DUPS    # Don't push duplicate directories onto the stack
setopt PUSHD_MINUS          # Invert the meaning of + and - for pushd

# History Configuration
unsetopt SHARE_HISTORY          # Do NOT auto-import commands from other shells
setopt INC_APPEND_HISTORY_TIME  # Write to HISTFILE immediately upon command completion
setopt EXTENDED_HISTORY         # Save timestamps & elapsed execution duration
setopt HIST_IGNORE_ALL_DUPS     # Purge older duplicates when writing new entries
setopt HIST_SAVE_NO_DUPS        # Prevent writing duplicates to the file
setopt HIST_FIND_NO_DUPS        # Don't show duplicates during history search
setopt HIST_REDUCE_BLANKS       # Strip trailing and redundant whitespace
setopt HIST_VERIFY              # Don't immediately execute history expansions (!$)

# Completion & Globbing
setopt EXTENDED_GLOB        # Enable advanced pattern matching (#, ~, ^)
setopt NUMERIC_GLOB_SORT    # Sort numeric filenames naturally (1, 2, 10 instead of 1, 10, 2)
setopt COMPLETE_IN_WORD     # Complete from both ends of a word
setopt MAGIC_EQUAL_SUBST    # Perform file completion after 'prefix=' expressions

# Terminal & Process Control
setopt NO_BEEP              # Mute all terminal audio bells
setopt NOTIFY               # Report status of background jobs immediately
setopt LONG_LIST_JOBS       # List jobs in the long format by default
setopt NO_BG_NICE           # Run background jobs at full CPU priority
setopt CORRECT              # Suggest spell corrections for commands

# Load the line-editor search widgets
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
# Standard Up / Down arrow keys
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
# Application keypad mode escape sequences (xterm / Ghostty / iTerm / tmux)
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

# -------- finished audit here

custom_functions=~/dot-configs/zsh/functions
if [[ -d $custom_functions ]]; then
  fpath=($custom_functions $fpath)
  # compinit will load all the _ prefixed functions, because it assumes that
  # they are for completions. This will lazy-load the rest.
  #
  # (:t) is like basename, so it enumerates all filenames found in this
  # location. So the filenames must correspond to function names.
  autoload -U $custom_functions/*(:t)
fi

autoload -Uz compinit

zcompdump="${XDG_CACHE_HOME}/zsh/zcompdump-${ZSH_VERSION}"
# If .zcompdump is older than 24 hours, regenerate it without -C
# This caches options for a day, but regenerates if new tools are added.
if [[ -n ${zcompdump}(#qN.mh+24) ]]; then
  compinit -d "$zcompdump"
else
  compinit -C -d "$zcompdump"
fi

# bash completion adapter for completions below
autoload -Uz bashcompinit
bashcompinit

# importantly, on corp workstation, this overrides RPROMPT above
local_additions=~/dot-configs/zsh/local.zsh
[[ -r $local_additions ]] && source $local_additions

# Google tools; the (N) flag prevents errors if a file doesn't exist.
for comp in /etc/bash_completion.d/(p4|g4d|hgd|jjd)(N); do
  source "$comp" 2>/dev/null
done

if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
elif command -v gdircolors >/dev/null 2>&1; then
  # Homebrew coreutils on macOS
  eval "$(gdircolors -b)"
fi
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

zstyle ':completion:*' menu select
# do not suggest ~root and ~your_username alongside standard local directories.
zstyle ':completion::complete:cd::' tag-order '! users' -
zstyle ':completion::complete:-command-::' tag-order '! users' -

# from ///devtools/blaze/scripts/zsh_completion/README - blaze has too many flags
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh"
# zsh fix for tab completion lag in google3 (from https://docs.google.com/presentation/d/1ka8wkaev4Kn5tKuyuMgD3xjEgrIanUacGRDDaE_5Hz8/edit#slide=id.g4e92381d66_1_78)
zstyle ':completion:*' users root $USER

export FZF_DEFAULT_OPTS='--height 41% --layout=reverse --border'
# export FZF_CTRL_R_OPTS="${FZF_CTRL_R_OPTS:+$FZF_CTRL_R_OPTS }--preview 'echo {}' --preview-window down:5:hidden:wrap --bind '?:toggle-preview'"
export FZF_CTRL_R_OPTS="${FZF_CTRL_R_OPTS:+$FZF_CTRL_R_OPTS }--preview 'echo {}' --preview-window down:5:wrap --bind '?:toggle-preview'"


##################
#
# Zsh Keybindings
#
bindkey -e     # emacs key bindings

# Force the Spacebar to expand history shortcuts (like !$, !!, !-2) inline
bindkey ' ' magic-space

## do not know what these are
#bindkey '\C-w' kill-region
#bindkey "\e[1~" beginning-of-line
#bindkey "\e[4~" end-of-line
#bindkey "\e[5~" beginning-of-history
#bindkey "\e[6~" end-of-history
#bindkey "\e[3~" delete-char
#bindkey "\e[2~" quoted-insert
#bindkey "\e[5C" forward-word
#bindkey "\eOc" forward-word # emacs-forward-word
#bindkey "\e[5D" backward-word
#bindkey "\eOd" backward-word # emacs-backward-word
#bindkey "\e\e[C" forward-word
#bindkey "\e\e[D" backward-word
# bindkey "^H" backward-delete-word
# for rxvt
#bindkey "\e[8~" end-of-line
#bindkey "\e[7~" beginning-of-line

# Bind xterm-style arrow sequences
bindkey "^[[1;3D" backward-word    # Alt + Left
bindkey "^[[1;3C" forward-word     # Alt + Right
bindkey "^[[1;5D" backward-word    # Ctrl + Left (if preferred)
bindkey "^[[1;5C" forward-word     # Ctrl + Right (if preferred)

# completion in the middle of a line
bindkey '^i' expand-or-complete-prefix

# make word-breaking more useful for editing paths
autoload select-word-style
select-word-style bash

if command -v fzf &> /dev/null; then
  source <(fzf --zsh)
fi

if [ -f $PLUGIN_DIR/powerlevel10k/powerlevel10k.zsh-theme ]; then
  source $PLUGIN_DIR/powerlevel10k/powerlevel10k.zsh-theme
fi

# zsh-syntax-highlighting and p10K have to be last
if [ -f $PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source $PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [[ -f ~/dot-configs/public/zsh/p10k.zsh ]]; then
  source ~/dot-configs/public/zsh/p10k.zsh
fi

update-plugins() {
  if [ ! -d $PLUGIN_DIR ]; then
    echo "❌ No plugins found at $PLUGIN_DIR"
    return 1
  fi

  echo "🔄 Checking for Zsh plugin/theme updates..."

  for repo in $PLUGIN_DIR/*/; do
    if [ -d $repo/.git ]; then
      local repo_name=$(basename $repo)
      echo -e "\n📦 Updating \033[1;34m${repo_name}\033[0m..."
      (cd $repo && git pull --rebase)
    fi
  done

  echo -e "\n✅ All modules updated! Restart your terminal or run: source ~/.zshrc"
}
