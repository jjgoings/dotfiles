# Interactive shell configuration

# Oh-my-zsh setup
ZSH=$HOME/.oh-my-zsh

# Shell options
setopt nonomatch
stty erase '^?'

# Theme and plugins
ZSH_THEME="risto"
COMPLETION_WAITING_DOTS="true"
plugins=(git z battery macos zsh-syntax-highlighting zsh-autosuggestions)

# SSH agent management
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    [[ -d "$XDG_RUNTIME_DIR" ]] && ssh-agent > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ ! "$SSH_AUTH_SOCK" && -f "$XDG_RUNTIME_DIR/ssh-agent.env" ]]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

# Source additional configurations
[[ -f $HOME/.local_zshrc ]] && source $HOME/.local_zshrc
[[ -f $HOME/.private ]] && source $HOME/.private
[[ -f $HOME/.profile ]] && source $HOME/.profile

# Google Cloud SDK
[[ -f "$HOME/opt/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/opt/google-cloud-sdk/path.zsh.inc"

# FZF configuration
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --bind=ctrl-k:kill-line"
export FZF_COMPLETION_TRIGGER='**'

if command -v fzf >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
fi

# Modern CLI aliases
command -v bat >/dev/null 2>&1 && alias cat='bat'
command -v rg >/dev/null 2>&1 && alias grep='rg'
command -v fd >/dev/null 2>&1 && alias find='fd'

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto --group-directories-first'
    alias ll='eza -la --color=auto --group-directories-first'
    alias lt='eza --tree --color=auto'
else
    alias ls="ls --color=auto -Gh"
    alias ll="ls -la"
fi

# Shell functions
qfind() {
    find . -exec grep -l -s $1 {} \;
    return 0
}

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Load completions
autoload -Uz compinit
compinit

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'micromamba shell init' !!
export MAMBA_EXE='/Users/goings/.local/bin/micromamba';
export MAMBA_ROOT_PREFIX='/Users/goings/micromamba';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias micromamba="$MAMBA_EXE"  # Fallback on help from micromamba activate
fi
micromamba activate main
unset __mamba_setup
# <<< mamba initialize <<<

. "$HOME/.local/share/../bin/env"
