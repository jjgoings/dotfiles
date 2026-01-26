# .zshenv - Universal environment variables (loaded for all zsh instances)
# Machine-specific config (JAVA_HOME, API keys, etc.) goes in ~/.local_zshrc

# Editor preference (check common locations, fallback to PATH lookup)
if [[ -x /opt/homebrew/bin/vim ]]; then
    export EDITOR=/opt/homebrew/bin/vim
elif [[ -x /usr/local/bin/vim ]]; then
    export EDITOR=/usr/local/bin/vim
elif [[ -x /usr/bin/vim ]]; then
    export EDITOR=/usr/bin/vim
elif command -v vim >/dev/null 2>&1; then
    export EDITOR=vim
fi

# Core environment
export CLICOLOR=1
export LSCOLORS=Gxfxcxdxbxegedabagacad

# Modern CLI tool configurations
export BAT_THEME="GitHub"
export BAT_STYLE="numbers,changes,header"
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
export LESS="-R -F -X -z-4"
export LESSHISTFILE="-"

# History configuration
export HISTSIZE=50000
export SAVEHIST=50000
export HISTFILE="$HOME/.zsh_history"

# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Language and locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Python configuration
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Docker configuration
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# GPG configuration
export GPG_TTY=$(tty)

# PATH modifications (portable paths only)
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
[[ -d "$HOME/go/bin" ]] && export PATH="$HOME/go/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# Homebrew (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
        export HOMEBREW_NO_ANALYTICS=1
        export HOMEBREW_NO_AUTO_UPDATE=1
    elif [[ -x "/usr/local/bin/brew" ]]; then
        export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
        export HOMEBREW_NO_ANALYTICS=1
        export HOMEBREW_NO_AUTO_UPDATE=1
    fi
fi
