# .zprofile - Login shell configuration

# # Micromamba initialization (moved from .zshrc)
# export MAMBA_EXE="$HOME/.local/bin/micromamba"
# export MAMBA_ROOT_PREFIX="$HOME/micromamba"
# __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
# if [[ $? -eq 0 ]]; then
#     eval "$__mamba_setup"
#     micromamba activate main
# fi
# unset __mamba_setup

# Google Cloud SDK path initialization
[[ -f "$HOME/opt/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/opt/google-cloud-sdk/path.zsh.inc"

# Source standard profile if it exists
[[ -f $HOME/.profile ]] && source $HOME/.profile
