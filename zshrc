# Explicitly configured $PATH variable
#PATH=/usr/local/git/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/local/bin:/opt/local/sbin:/usr/X11/bin:/Library/TeX/texbin

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# scp bash-like globbing
setopt nonomatch

# remap backspace
stty erase '^?'

# SSH agent management
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    [[ -d "$XDG_RUNTIME_DIR" ]] && ssh-agent > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ ! "$SSH_AUTH_SOCK" && -f "$XDG_RUNTIME_DIR/ssh-agent.env" ]]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

# use local_config for remote machines - FIXED: check existence first
[[ -f $HOME/.local_zshrc ]] && source $HOME/.local_zshrc

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="xiong-chiamiov-plus"
#ZSH_THEME="robbyrussell"
ZSH_THEME="risto"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Optimized plugin list - removed heavyweight plugins for better performance
# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git z battery macos zsh-syntax-highlighting zsh-autosuggestions)

# Put any proprietary or private functions/values in ~/.private, and this will source them
[[ -f $HOME/.private ]] && source $HOME/.private

[[ -f $HOME/.profile ]] && source $HOME/.profile  # Read Mac .profile, if present.

# Shell Functions
# qfind - used to quickly find files that contain a string in a directory
qfind () {
  find . -exec grep -l -s $1 {} \;
  return 0
}

# Lazy loading for micromamba to improve shell startup time
micromamba() {
    unfunction micromamba
    export MAMBA_EXE="$HOME/.local/bin/micromamba"
    export MAMBA_ROOT_PREFIX="$HOME/micromamba"
    __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
    if [[ $? -eq 0 ]]; then
        eval "$__mamba_setup"
        micromamba activate main
    fi
    unset __mamba_setup
    micromamba "$@"
}

# Modern CLI aliases
if command -v bat >/dev/null 2>&1; then
    alias cat='bat'
fi

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto --group-directories-first'
    alias ll='eza -la --color=auto --group-directories-first'
    alias lt='eza --tree --color=auto'
else
    alias ls="ls --color=auto -Gh"
    alias ll="ls -la"
fi

if command -v rg >/dev/null 2>&1; then
    alias grep='rg'
fi

if command -v fd >/dev/null 2>&1; then
    alias find='fd'
fi

# Custom exports
## Set EDITOR to /usr/bin/vim if Vim is installed
if [ -f /usr/bin/vim ]; then
  export EDITOR=/usr/bin/vim
fi

# FZF configuration
if command -v fzf >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    
    # Key bindings
    [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
fi

#test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

source $ZSH/oh-my-zsh.sh

# Load completions
autoload -Uz compinit
compinit
