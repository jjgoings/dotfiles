# Interactive shell configuration
# Machine-specific config goes in ~/.local_zshrc

# Fix fpath for minimal zsh installs (RHEL/CentOS)
for p in /usr/share/zsh/${ZSH_VERSION}/functions /usr/share/zsh/functions /usr/share/zsh/site-functions; do
    [[ -d "$p" ]] && fpath=("$p" $fpath)
done

# Load zsh built-in functions
autoload -Uz add-zsh-hook is-at-least compinit bashcompinit 2>/dev/null

# Shell options
setopt nonomatch
stty erase '^?'

# History configuration
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # Write timestamp to history
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first
setopt HIST_IGNORE_DUPS          # Don't record duplicates
setopt HIST_IGNORE_SPACE         # Don't record lines starting with space
setopt HIST_VERIFY               # Show command before executing from history
setopt SHARE_HISTORY             # Share history between sessions
setopt INC_APPEND_HISTORY        # Add commands immediately

# SSH agent management
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    [[ -d "$XDG_RUNTIME_DIR" ]] && ssh-agent > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ -z "$SSH_AUTH_SOCK" ]] && [[ -f "$XDG_RUNTIME_DIR/ssh-agent.env" ]]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

# Source machine-specific configurations (secrets, paths, etc.)
[[ -f $HOME/.local_zshrc ]] && source $HOME/.local_zshrc
[[ -f $HOME/.private ]] && source $HOME/.private

# Google Cloud SDK (if installed)
[[ -f "$HOME/opt/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/opt/google-cloud-sdk/path.zsh.inc"

# FZF configuration
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --bind=ctrl-k:kill-line"
export FZF_COMPLETION_TRIGGER='**'

if command -v fzf >/dev/null 2>&1; then
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
    [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
fi

# Modern CLI aliases (only if tools are installed)
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
# Note: qfind uses /usr/bin/find explicitly since 'find' may be aliased to fd
qfind() {
    /usr/bin/find . -exec grep -l -s "$1" {} \;
}

# Completion configuration (must be before compinit)
zstyle ':completion:*' menu select
fpath+=~/.zfunc

# Load completions
autoload -Uz compinit
compinit

# Key bindings for history search (up/down arrow match prefix)
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search    # Up arrow
bindkey "^[[B" down-line-or-beginning-search  # Down arrow
bindkey "^P" up-line-or-beginning-search      # Ctrl-P
bindkey "^N" down-line-or-beginning-search    # Ctrl-N

# Prompt (starship - async git, fast)
if command -v starship >/dev/null 2>&1; then
    _starship_cache="${XDG_CACHE_HOME:-$HOME/.cache}/starship_init.zsh"
    if [[ ! -f "$_starship_cache" ]]; then
        starship init zsh > "$_starship_cache"
        # Patch for old zsh that doesn't support [[ -v var ]] (harmless on new zsh)
        sed -i 's/\[\[ -v \([^ ]*\) \]\]/(( ${+\1} ))/g' "$_starship_cache" 2>/dev/null
    fi
    source "$_starship_cache"
fi

# Directory jumping (zoxide - same 'z' command)
if command -v zoxide >/dev/null 2>&1; then
    _zoxide_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide_init.zsh"
    if [[ ! -f "$_zoxide_cache" ]]; then
        zoxide init zsh --cmd z > "$_zoxide_cache"
        # Patch for old zsh (harmless on new zsh)
        sed -i 's/\[\[ -v \([^ ]*\) \]\]/(( ${+\1} ))/g' "$_zoxide_cache" 2>/dev/null
    fi
    source "$_zoxide_cache"
fi

# Syntax highlighting & autosuggestions (check common install locations + user dir)
for p in /opt/homebrew/share /usr/local/share /usr/share /usr/share/zsh/plugins "$HOME/.zsh/plugins"; do
    [[ -f "$p/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$p/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" && break
done
for p in /opt/homebrew/share /usr/local/share /usr/share /usr/share/zsh/plugins "$HOME/.zsh/plugins"; do
    [[ -f "$p/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$p/zsh-autosuggestions/zsh-autosuggestions.zsh" && break
done

# Micromamba/conda (if installed)
if [[ -x "$HOME/.local/bin/micromamba" ]]; then
    export MAMBA_EXE="$HOME/.local/bin/micromamba"
    export MAMBA_ROOT_PREFIX="$HOME/micromamba"
    _mamba_cache="${XDG_CACHE_HOME:-$HOME/.cache}/mamba_hook.zsh"
    if [[ ! -f "$_mamba_cache" || "$MAMBA_EXE" -nt "$_mamba_cache" ]]; then
        "$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" > "$_mamba_cache" 2>/dev/null
    fi
    [[ -f "$_mamba_cache" ]] && source "$_mamba_cache"
    [[ -d "$MAMBA_ROOT_PREFIX/envs/main" ]] && micromamba activate main
    unset _mamba_cache
fi

# Cargo env (if installed via rustup)
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Lazy-load NVM (auto-wraps all binaries in default node's bin directory)
if [[ -d "$HOME/.config/nvm" || -d "$HOME/.nvm" ]]; then
    export NVM_DIR="${HOME}/.config/nvm"
    [[ -d "$HOME/.nvm" ]] && export NVM_DIR="$HOME/.nvm"

    # Find default node bin directory without loading nvm
    _nvm_default_bin=""
    if [[ -f "$NVM_DIR/alias/default" ]]; then
        _nvm_default_version=$(<"$NVM_DIR/alias/default")
        # Resolve version alias to actual version directory
        for d in "$NVM_DIR/versions/node/"*"${_nvm_default_version}"*; do
            [[ -d "$d/bin" ]] && _nvm_default_bin="$d/bin" && break
        done
    fi

    # Core nvm loader function
    _nvm_load() {
        (( ${+_nvm_loaded} )) && return 0
        # Unfunction all wrapped commands
        for cmd in "${_nvm_wrapped_cmds[@]}"; do
            unfunction "$cmd" 2>/dev/null
        done
        unfunction nvm 2>/dev/null
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
        _nvm_loaded=1
    }

    nvm() { _nvm_load && nvm "$@"; }

    # Create lazy wrappers for all executables in default node bin
    _nvm_wrapped_cmds=()
    if [[ -n "$_nvm_default_bin" && -d "$_nvm_default_bin" ]]; then
        for bin in "$_nvm_default_bin"/*; do
            [[ -x "$bin" ]] || continue
            cmd="${bin:t}"
            [[ "$cmd" == "nvm" ]] && continue
            _nvm_wrapped_cmds+=("$cmd")
            eval "$cmd() { _nvm_load && $cmd \"\$@\"; }"
        done
    fi

    unset _nvm_default_version _nvm_default_bin
fi

# Source workflow functions (portable, in repo)
[[ -f ~/dotfiles/zshrc.local ]] && source ~/dotfiles/zshrc.local
