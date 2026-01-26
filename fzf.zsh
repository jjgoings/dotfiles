# Setup fzf
# ---------
if [[ -d "$HOME/.fzf/bin" && ! "$PATH" == *"$HOME/.fzf/bin"* ]]; then
    PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi

# Cache fzf keybindings/completion (faster than spawning fzf every shell)
_fzf_cache="${XDG_CACHE_HOME:-$HOME/.cache}/fzf.zsh"
if [[ ! -f "$_fzf_cache" ]]; then
    fzf --zsh > "$_fzf_cache" 2>/dev/null
fi
[[ -f "$_fzf_cache" ]] && source "$_fzf_cache"
unset _fzf_cache
