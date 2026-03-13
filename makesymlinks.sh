#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DOTFILES_DIR="$SCRIPT_DIR"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

BACKUP_DIR="$HOME/dotfiles_backup_$TIMESTAMP"
BACKUP_CREATED=0
DRY_RUN=0
SKIP_BACKUP=0
CREATE_LOCAL_FILES=1

readonly CONFIG_MAPPINGS=(
    "bashrc:.bashrc"
    "vimrc:.vimrc"
    "vim:.vim"
    "zshenv:.zshenv"
    "zshrc:.zshrc"
    "Xresources:.Xresources"
    "matplotlibrc:.config/matplotlib/matplotlibrc"
    "gitconfig:.gitconfig"
    "gitignore_global:.gitignore_global"
    "tmux.conf:.tmux.conf"
    "ripgreprc:.ripgreprc"
    "starship.toml:.config/starship.toml"
    "fzf.zsh:.fzf.zsh"
    "zellij:.config/zellij"
)

log_info() { printf '\033[32m[INFO]\033[0m %s\n' "$*"; }
log_warn() { printf '\033[33m[WARN]\033[0m %s\n' "$*"; }
log_error() { printf '\033[31m[ERROR]\033[0m %s\n' "$*"; }

usage() {
    cat <<'EOF'
Usage: ./makesymlinks.sh [options]

Safe dotfiles installer:
- backs up existing targets before replacing them
- creates symlinks for tracked repo-managed config
- seeds local-only files like ~/.local_zshrc and ~/.private

Options:
  --dry-run         Show what would happen without changing anything
  --skip-backup     Replace targets without creating a backup directory
  --no-local-files  Do not create ~/.local_zshrc, ~/.private, or ~/.gitconfig.local
  --help            Show this help message
EOF
}

run() {
    if (( DRY_RUN )); then
        printf '\033[36m[DRYRUN]\033[0m'
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi
    "$@"
}

parse_args() {
    while (($#)); do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                ;;
            --skip-backup)
                SKIP_BACKUP=1
                ;;
            --no-local-files)
                CREATE_LOCAL_FILES=0
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

resolve_path() {
    local path="$1"

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$path" <<'PY'
import os, sys
print(os.path.realpath(sys.argv[1]))
PY
        return
    fi

    (
        cd "$(dirname "$path")" >/dev/null 2>&1 &&
        printf '%s/%s\n' "$(pwd -P)" "$(basename "$path")"
    )
}

ensure_backup_dir() {
    if (( SKIP_BACKUP )) || (( BACKUP_CREATED )); then
        return
    fi

    log_info "Creating backup directory: $BACKUP_DIR"
    run mkdir -p "$BACKUP_DIR"
    BACKUP_CREATED=1
}

target_points_to_source() {
    local target_path="$1"
    local source_path="$2"

    [[ -L "$target_path" ]] || return 1

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$target_path" "$source_path" <<'PY'
import os, sys
target, source = sys.argv[1], sys.argv[2]
try:
    raise SystemExit(0 if os.path.samefile(target, source) else 1)
except FileNotFoundError:
    raise SystemExit(1)
PY
        return
    fi

    [[ "$(resolve_path "$target_path")" == "$(resolve_path "$source_path")" ]]
}

backup_target() {
    local target_path="$1"
    local target_rel="$2"
    local backup_path="$BACKUP_DIR/$target_rel"

    (( SKIP_BACKUP )) && return
    [[ -e "$target_path" || -L "$target_path" ]] || return

    ensure_backup_dir
    log_info "Backing up $target_rel"
    run mkdir -p "$(dirname "$backup_path")"

    if [[ -L "$target_path" ]]; then
        run cp -P "$target_path" "$backup_path"
    elif [[ -d "$target_path" ]]; then
        run cp -RP "$target_path" "$backup_path"
    else
        run cp -P "$target_path" "$backup_path"
    fi
}

link_mapping() {
    local source_rel="$1"
    local target_rel="$2"
    local source_path="$DOTFILES_DIR/$source_rel"
    local target_path="$HOME/$target_rel"

    if [[ ! -e "$source_path" ]]; then
        log_warn "Skipping missing source: $source_rel"
        return
    fi

    if target_points_to_source "$target_path" "$source_path"; then
        log_info "Already linked: $target_rel"
        return
    fi

    if [[ -e "$target_path" || -L "$target_path" ]]; then
        backup_target "$target_path" "$target_rel"
        log_info "Removing existing target: $target_rel"
        run rm -rf "$target_path"
    fi

    run mkdir -p "$(dirname "$target_path")"
    log_info "Linking $target_rel -> $source_rel"
    run ln -s "$source_path" "$target_path"
}

create_private_file() {
    local target="$HOME/.private"

    if [[ -e "$target" ]]; then
        log_info "Keeping existing ~/.private"
        return
    fi

    log_info "Creating ~/.private"
    if (( DRY_RUN )); then
        return
    fi

    umask 077
    cat > "$target" <<'EOF'
# ~/.private - secrets only
# API keys, tokens, and passwords belong here.
#
# Example:
# export OPENAI_API_KEY="..."
EOF
    chmod 600 "$target"
}

create_local_zshrc() {
    local target="$HOME/.local_zshrc"

    if [[ -e "$target" ]]; then
        log_info "Keeping existing ~/.local_zshrc"
        return
    fi

    if [[ -f "$DOTFILES_DIR/local_zshrc.template" ]]; then
        log_info "Creating ~/.local_zshrc from template"
        if (( DRY_RUN )); then
            return
        fi
        cp "$DOTFILES_DIR/local_zshrc.template" "$target"
        return
    fi

    log_info "Creating minimal ~/.local_zshrc"
    if (( DRY_RUN )); then
        return
    fi

    cat > "$target" <<'EOF'
# ~/.local_zshrc - machine-specific config
# Non-secret paths, aliases, and toggles belong here.
#
# Secrets go in ~/.private.
EOF
}

create_gitconfig_local() {
    local target="$HOME/.gitconfig.local"

    if [[ -e "$target" ]]; then
        log_info "Keeping existing ~/.gitconfig.local"
        return
    fi

    log_info "Creating ~/.gitconfig.local"
    if (( DRY_RUN )); then
        return
    fi

    cat > "$target" <<'EOF'
# Machine-local Git settings.
#
# Example:
# [user]
#     name = Your Name
#     email = your.email@example.com
EOF
}

create_local_files() {
    (( CREATE_LOCAL_FILES )) || return

    create_private_file
    create_local_zshrc
    create_gitconfig_local
}

verify_links() {
    local failures=0

    if (( DRY_RUN )); then
        log_info "Dry-run complete; skipping post-link verification"
        return 0
    fi

    for mapping in "${CONFIG_MAPPINGS[@]}"; do
        local source_rel="${mapping%%:*}"
        local target_rel="${mapping#*:}"
        local source_path="$DOTFILES_DIR/$source_rel"
        local target_path="$HOME/$target_rel"

        [[ -e "$source_path" ]] || continue

        if target_points_to_source "$target_path" "$source_path"; then
            log_info "Verified $target_rel"
        else
            log_error "Verification failed for $target_rel"
            ((failures++))
        fi
    done

    if (( failures > 0 )); then
        log_error "Completed with $failures verification error(s)"
        return 1
    fi

    log_info "Dotfiles linked successfully"
    if (( BACKUP_CREATED )); then
        log_info "Backup saved to: $BACKUP_DIR"
    fi
}

main() {
    parse_args "$@"

    log_info "Dotfiles repo: $DOTFILES_DIR"
    (( DRY_RUN )) && log_info "Dry-run mode enabled"

    for mapping in "${CONFIG_MAPPINGS[@]}"; do
        link_mapping "${mapping%%:*}" "${mapping#*:}"
    done

    create_local_files
    verify_links
}

main "$@"
