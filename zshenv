# .zshenv - Universal environment variables (loaded for all zsh instances)

# Editor preference
[[ -x /usr/bin/vim ]] && export EDITOR=/usr/bin/vim

# Core environment
export CLICOLOR=1
export LSCOLORS=Gxfxcxdxbxegedabagacad

# Modern CLI tool configurations
export BAT_THEME="GitHub"
export BAT_STYLE="numbers,changes,header"

# FZF configuration
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --bind=ctrl-k:kill-line"
export FZF_COMPLETION_TRIGGER='**'

# Ripgrep configuration
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# Less configuration for better paging
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

# Compiler toolchain (update for your use-cases)
# Uncomment and modify based on your system setup
# export CC=/opt/homebrew/opt/llvm/bin/clang
# export CXX=/opt/homebrew/opt/llvm/bin/clang++
# export FC=gfortran
# export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
# export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"

# Application homes
# export JMOL_HOME="$HOME/micromamba/envs/main/share/jmol/"

# Python configuration
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Rust/Cargo
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"

# Go
[[ -d "$HOME/go/bin" ]] && export PATH="$HOME/go/bin:$PATH"

# Local binaries
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

# Docker configuration
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# GPG configuration
export GPG_TTY=$(tty)
