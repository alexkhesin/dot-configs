# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

. ~/dot-configs/public/zsh/aliases

set -o ignoreeof    # do not exit upon reading ^D

# zsh stuff
mkdir -p "$XDG_STATE_HOME/zsh"
HISTFILE="$XDG_STATE_HOME/zsh/histfile.ext"
HISTSIZE=1000000
SAVEHIST=1000000
DIRSTACKSIZE=10
setopt INC_APPEND_HISTORY  # append history one line at a time, rather then
                           # on shell exit
setopt EXTENDED_HISTORY    # record timestamps in the history file
setopt HIST_NO_STORE       # do not store 'history' command itself
setopt HIST_REDUCE_BLANKS  # remove superfluous blanks
unsetopt HIST_VERIFY       # do not confirm history substituitions
# Turn on all dup-removing options
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_EXPIRE_DUPS_FIRST
setopt HIST_SAVE_NO_DUPS HIST_FIND_NO_DUPS

# unsetopt beep extendedglob nomatch notify

export PROMPT='%# '
export RPROMPT=' %(?..%? )%~ %B%m%b'
# export WORDCHARS='*?_-[]~=&;!#$%^(){}<>'
setopt NO_NOMATCH  # do not print out "no matches found" when expanding globs
setopt NO_BG_NICE  # do not nice down background processes
setopt NO_BEEP     # do not beep on errors
setopt AUTO_CD     # cd to directories without typing 'cd'
setopt EXTENDED_GLOB # extended glob syntax
setopt CORRECT     # spell-check command lines

# setopt nohup  # do not SIGHUP background processes when shell exits

fpath=(~/.zsh-functions $fpath)
autoload compinit
compinit -C -d ~/.zcompdump-$ZSH_VERSION

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select=1
zstyle ':completion::complete:cd::' tag-order '! users' -
zstyle ':completion::complete:-command-::' tag-order '! users' -

# from ///devtools/blaze/scripts/zsh_completion/README
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
# zsh fix for tab completion lag in google3 (from https://docs.google.com/presentation/d/1ka8wkaev4Kn5tKuyuMgD3xjEgrIanUacGRDDaE_5Hz8/edit#slide=id.g4e92381d66_1_78)
zstyle ':completion:*' users root $USER

zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
     /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

export FZF_DEFAULT_OPTS='--height 41% --layout=reverse --border'
export FZF_CTRL_R_OPTS="${FZF_CTRL_R_OPTS:+$FZF_CTRL_R_OPTS }--preview 'echo {}' --preview-window down:5:hidden:wrap --bind '?:toggle-preview'"
export FZF_CTRL_R_OPTS="${FZF_CTRL_R_OPTS:+$FZF_CTRL_R_OPTS }--preview 'echo {}' --preview-window down:5:wrap --bind '?:toggle-preview'"


##################
#
# Zsh Keybindings
#
bindkey -e     # emacs key bindings
bindkey ' '    magic-space
bindkey '\C-w' kill-region
bindkey "\e[1~" beginning-of-line
bindkey "\e[4~" end-of-line
bindkey "\e[5~" beginning-of-history
bindkey "\e[6~" end-of-history
bindkey "\e[3~" delete-char
bindkey "\e[2~" quoted-insert
bindkey "\e[5C" forward-word
bindkey "\eOc" emacs-forward-word
bindkey "\e[5D" backward-word
bindkey "\eOd" emacs-backward-word
bindkey "\e\e[C" forward-word
bindkey "\e\e[D" backward-word
# bindkey "^H" backward-delete-word
# for rxvt
bindkey "\e[8~" end-of-line
bindkey "\e[7~" beginning-of-line
# completion in the middle of a line
bindkey '^i' expand-or-complete-prefix

# unbind
bindkey -r main '^['

#
# ZSH options
#
# limit coredumpsize 102400
setopt notify
setopt nobeep
setopt rec_exact
setopt long_list_jobs
setopt list_types
setopt auto_resume
setopt hist_ignore_dups
setopt autopushd
setopt pushd_minus
setopt extended_glob
setopt auto_menu
setopt no_list_beep
setopt pushd_ignore_dups
setopt no_nomatch
setopt extended_history
setopt equals
setopt magic_equal_subst
setopt hist_verify
setopt numeric_glob_sort
setopt print_eight_bit
setopt complete_in_word # ZSH FAQ: 4.4
setopt complete_aliases
setopt share_history
unsetopt ignore_eof
unsetopt hash_cmds
unsetopt promptcr
zstyle ':completion:*:default' menu select=1


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
mkdir -p $PLUGIN_DIR

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
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
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
