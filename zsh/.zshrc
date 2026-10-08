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

setopt INC_APPEND_HISTORY  # append history one line at a time, rather then
                           # on shell exit
setopt EXTENDED_HISTORY    # record timestamps in the history file
setopt HIST_NO_STORE       # do not store 'history' command itself
setopt HIST_REDUCE_BLANKS  # remove superfluous blanks
# Turn on all dup-removing options
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_EXPIRE_DUPS_FIRST
setopt HIST_SAVE_NO_DUPS HIST_FIND_NO_DUPS

setopt notify
setopt nobeep
setopt rec_exact
setopt long_list_jobs
setopt list_types
setopt auto_resume
setopt autopushd
setopt pushd_minus
setopt extended_glob
setopt auto_menu
setopt no_list_beep
setopt pushd_ignore_dups
setopt no_nomatch  # do not print out "no matches found" when expanding globs
setopt equals
setopt magic_equal_subst
setopt hist_verify
setopt numeric_glob_sort
setopt print_eight_bit
setopt complete_in_word # ZSH FAQ: 4.4
setopt complete_aliases
setopt share_history
setopt correct          # spell-check command lines
setopt NO_BG_NICE  # do not nice down background processes
# setopt NO_BEEP     # do not beep on errors
setopt AUTO_CD     # cd to directories without typing 'cd'

unsetopt ignore_eof
unsetopt hash_cmds
unsetopt promptcr

# unsetopt beep extendedglob nomatch notify

export PROMPT='%# '
export RPROMPT=' %(?..%? )%~ %B%m%b'

# setopt nohup  # do not SIGHUP background processes when shell exits

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

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select=1
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

# unbind
bindkey -r main '^['

# make word-breaking more useful for editing paths
autoload select-word-style
select-word-style bash

# ==============================================================================
# 🔌 AUTOMATED PLUGIN MANAGEMENT & CONFIGURATION ORDER
# ==============================================================================
# Why this setup is the best path forward for a native Jujutsu (jj) setup:
# 1. Updatable: You can run `update-plugins` at any time to pull down upstream fixes.
# 2. Perfect for jj: Your dotfiles repository remains 100% pure configuration text.
#    jj never sees third-party .git tracking files, avoiding repo tree corruption.
# 3. Zero-Touch: When you log into a brand new computer, you just clone your jj repo
#    and run 'stow'. The first time you open a terminal, it builds itself.
# ==============================================================================

PLUGIN_DIR=$HOME/.local/share/zsh-plugins
ensure_dir $PLUGIN_DIR

# 1. BOOTSTRAP: Automatically clone external plugins & themes if missing
if [ ! -d $PLUGIN_DIR/zsh-syntax-highlighting ]; then
    echo "📥 Cloning zsh-syntax-highlighting for the first time..."
    git clone --depth=1 --shallow-submodules https://github.com/zsh-users/zsh-syntax-highlighting.git $PLUGIN_DIR/zsh-syntax-highlighting
fi

if [ ! -d $PLUGIN_DIR/powerlevel10k ]; then
    echo "📥 Cloning powerlevel10k theme..."
    git clone --depth=1 --shallow-submodules https://github.com/romkatv/powerlevel10k.git $PLUGIN_DIR/powerlevel10k
fi

# 2. SOURCING SEQUENCE: Order matters to keep hooks from stomping on each other

# [Step B] Load Powerlevel10k Configuration & Theme Engine (EARLY)
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "$XDG_CACHE_HOME/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
if [[ -f ~/dot-configs/public/zsh/p10k.zsh ]]; then
  source ~/dot-configs/public/zsh/p10k.zsh
  setopt transient_rprompt
fi

# Source the theme file
if [ -f $PLUGIN_DIR/powerlevel10k/powerlevel10k.zsh-theme ]; then
    source $PLUGIN_DIR/powerlevel10k/powerlevel10k.zsh-theme
fi

# [Step C] Load Intermediate Third-Party zsh Plugins

# [Step D] Load FZF (Modern Dynamic Method)
if command -v fzf &> /dev/null; then
    source <(fzf --zsh)
fi

# [Step E] Load Syntax Highlighting (ALWAYS ABSOLUTELY LAST)
if [ -f $PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source $PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi


# 3. AUTOMATED UPDATES: Pull downstream updates cleanly without polluting jj
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
