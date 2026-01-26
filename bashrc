##############################################################################
#   Filename: .bashrc                                                        #
# Maintainer: Michael J. Smalley <michaeljsmalley@gmail.com>                 #
#        URL: http://github.com/michaeljsmalley/dotfiles                     #
#                                                                            #
# Sections:                                                                  #
#   01. General ................. General Bash behavior                      #
#   02. Aliases ................. Aliases                                    #
#   03. Theme/Colors ............ Colors, prompts, fonts, etc.               #
##############################################################################

##############################################################################
# 01. General                                                                #
##############################################################################
# Switch to zsh if available (for systems where zsh isn't default)
# Only for interactive shells — keeps scp/rsync/batch jobs working
if [[ $- == *i* ]] && [[ -z "$ZSH_VERSION" ]] && command -v zsh >/dev/null 2>&1; then
    exec zsh -l
fi

# Shell prompt
export PS1="\[\033[1;36m\]\u\[\033[1;31m\]@\[\033[1;32m\]\h:\[\033[1;35m\]\w\[\033[1;31m\]\$\[\033[0m\] "

# checkwinsize on
shopt -s checkwinsize

# Source local bashrc if it exists
[[ -f "$HOME/.local_bashrc" ]] && source "$HOME/.local_bashrc"

# Use zoxide for directory jumping (if installed)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash --cmd z)"
fi

# History configuration
export HISTSIZE=1000000
export HISTFILESIZE=1000000000

bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\e[C": forward-char'
bind '"\e[D": backward-char'
set show-all-if-ambiguous on
set completion-ignore-case on

##############################################################################
# 02. Aliases                                                                #
##############################################################################
# Modern CLI aliases (only if tools are installed)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto --group-directories-first'
    alias ll='eza -la --color=auto --group-directories-first'
else
    alias ls="ls --color=auto -Gh"
    alias ll="ls -la"
fi

command -v bat >/dev/null 2>&1 && alias cat='bat'
command -v rg >/dev/null 2>&1 && alias grep='rg'

##############################################################################
# 03. Theme/Colors                                                           #
##############################################################################
# CLI Colors
export CLICOLOR=1
export LSCOLORS=Gxfxcxdxbxegedabagacad

# Cargo env (if installed)
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Micromamba/conda (if installed)
if [[ -x "$HOME/.local/bin/micromamba" ]]; then
    export MAMBA_EXE="$HOME/.local/bin/micromamba"
    export MAMBA_ROOT_PREFIX="$HOME/micromamba"
    eval "$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX" 2>/dev/null)"
    [[ -d "$MAMBA_ROOT_PREFIX/envs/main" ]] && micromamba activate main
fi
