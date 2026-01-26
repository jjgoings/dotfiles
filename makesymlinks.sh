#!/bin/bash
set -eo pipefail

# Enhanced dotfiles setup with proper config separation
# Supports macOS, Debian/Ubuntu, RHEL/CentOS, Arch Linux

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$HOME/dotfiles"
readonly BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Configuration mapping: source_file:target_location
readonly CONFIG_MAPPINGS=(
    "bashrc:.bashrc"
    "vimrc:.vimrc"
    "vim:.vim"
    "zshenv:.zshenv"
    "zshrc:.zshrc"
    "zshrc.local:.zshrc.local"
    "Xresources:.Xresources"
    "private:.private"
    "matplotlibrc:.config/matplotlib/matplotlibrc"
    "gitconfig:.gitconfig"
    "tmux.conf:.tmux.conf"
    "ripgreprc:.ripgreprc"
    "starship.toml:.config/starship.toml"
    "fzf.zsh:.fzf.zsh"
)

# Logging functions
log_info() { echo -e "\033[32m[INFO]\033[0m $*"; }
log_warn() { echo -e "\033[33m[WARN]\033[0m $*"; }
log_error() { echo -e "\033[31m[ERROR]\033[0m $*"; }

# Check if we have sudo access
has_sudo() {
    if command -v sudo >/dev/null 2>&1; then
        sudo -n true 2>/dev/null || sudo -v 2>/dev/null
        return $?
    fi
    return 1
}

# Platform detection
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# Package installation by platform
install_packages() {
    local platform="$1"
    shift
    local packages=("$@")
    
    case "$platform" in
        macos)
            if command -v brew >/dev/null 2>&1; then
                brew install "${packages[@]}"
            else
                log_warn "Homebrew not found. Install manually: ${packages[*]}"
            fi
            ;;
        debian)
            sudo apt-get update
            sudo apt-get install -y "${packages[@]}"
            ;;
        rhel)
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y "${packages[@]}"
            else
                sudo yum install -y "${packages[@]}"
            fi
            ;;
        arch)
            sudo pacman -S --noconfirm "${packages[@]}"
            ;;
        *)
            log_error "Unknown platform. Manual installation required: ${packages[*]}"
            return 1
            ;;
    esac
}

# Backup existing configurations
backup_configs() {
    log_info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    for mapping in "${CONFIG_MAPPINGS[@]}"; do
        local target="${mapping#*:}"
        local full_path="$HOME/$target"
        
        if [[ ! -e "$full_path" ]]; then
            continue
        fi
        
        # Skip if already pointing to our dotfiles
        if [[ -L "$full_path" ]]; then
            local link_target
            link_target="$(readlink "$full_path")"
            if [[ "$link_target" == "$DOTFILES_DIR"* ]]; then
                log_info "Skipping $target (already managed by dotfiles)"
                continue
            fi
        fi
        
        log_info "Backing up $target"
        local backup_path="$BACKUP_DIR/$target"
        mkdir -p "$(dirname "$backup_path")"
        
        # Handle symlinks and regular files/directories differently
        if [[ -L "$full_path" ]]; then
            # Preserve symlink as-is
            cp -P "$full_path" "$backup_path"
        elif [[ -d "$full_path" ]]; then
            # Use rsync for directories to handle cycles gracefully
            if command -v rsync >/dev/null 2>&1; then
                rsync -av --exclude='.git' "$full_path/" "$backup_path/"
            else
                # Fallback: copy without following symlinks
                cp -r --no-dereference "$full_path" "$backup_path" 2>/dev/null || {
                    log_warn "Could not backup $target due to circular references"
                    continue
                }
            fi
        else
            # Regular file
            cp "$full_path" "$backup_path"
        fi
    done
}

# Create symbolic links
create_symlinks() {
    log_info "Creating symbolic links"
    
    for mapping in "${CONFIG_MAPPINGS[@]}"; do
        local source_file="${mapping%:*}"
        local target="${mapping#*:}"
        local source_path="$DOTFILES_DIR/$source_file"
        local target_path="$HOME/$target"
        
        if [[ ! -f "$source_path" && ! -d "$source_path" ]]; then
            log_warn "Source file not found: $source_path"
            continue
        fi
        
        # Remove existing file/link
        [[ -e "$target_path" ]] && rm -rf "$target_path"
        
        # Create target directory if needed
        mkdir -p "$(dirname "$target_path")"
        
        # Create symlink
        ln -s "$source_path" "$target_path"
        log_info "Linked $source_file -> $target"
    done
}

# Install shell tools (starship, zoxide, zsh plugins)
setup_shell_tools() {
    local platform="$1"
    log_info "Setting up shell tools (starship, zoxide, zsh plugins)"

    # Starship - can install to ~/.local/bin without sudo
    if ! command -v starship >/dev/null 2>&1; then
        log_info "Installing starship to ~/.local/bin"
        mkdir -p "$HOME/.local/bin"
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" 2>/dev/null || \
            log_warn "Failed to install starship. Install manually: https://starship.rs"
    else
        log_info "✓ starship already installed"
    fi

    # Zoxide - can install to ~/.local/bin without sudo
    if ! command -v zoxide >/dev/null 2>&1; then
        log_info "Installing zoxide to ~/.local/bin"
        mkdir -p "$HOME/.local/bin"
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash 2>/dev/null || \
            log_warn "Failed to install zoxide. Install manually: https://github.com/ajeetdsouza/zoxide"
    else
        log_info "✓ zoxide already installed"
    fi

    # Zsh plugins - clone to user directory if system-wide not available
    local zsh_plugin_dir="$HOME/.zsh/plugins"

    # Check for system-wide plugins first
    local has_syntax_hl=false has_autosugg=false
    for p in /opt/homebrew/share /usr/local/share /usr/share /usr/share/zsh/plugins; do
        [[ -f "$p/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && has_syntax_hl=true
        [[ -f "$p/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && has_autosugg=true
    done

    if ! $has_syntax_hl; then
        if [[ ! -d "$zsh_plugin_dir/zsh-syntax-highlighting" ]]; then
            log_info "Installing zsh-syntax-highlighting to $zsh_plugin_dir"
            mkdir -p "$zsh_plugin_dir"
            git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_plugin_dir/zsh-syntax-highlighting" 2>/dev/null || \
                log_warn "Failed to clone zsh-syntax-highlighting"
        else
            log_info "✓ zsh-syntax-highlighting already installed"
        fi
    fi

    if ! $has_autosugg; then
        if [[ ! -d "$zsh_plugin_dir/zsh-autosuggestions" ]]; then
            log_info "Installing zsh-autosuggestions to $zsh_plugin_dir"
            mkdir -p "$zsh_plugin_dir"
            git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$zsh_plugin_dir/zsh-autosuggestions" 2>/dev/null || \
                log_warn "Failed to clone zsh-autosuggestions"
        else
            log_info "✓ zsh-autosuggestions already installed"
        fi
    fi

    # Clear cached init scripts so they regenerate with new binaries
    rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/starship_init.zsh"
    rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/zoxide_init.zsh"
    log_info "✓ Shell tools setup complete"
}

# Install modern CLI tools (optional, skip if no sudo on Linux)
install_modern_tools() {
    local platform="$1"

    case "$platform" in
        macos)
            if command -v brew >/dev/null 2>&1; then
                log_info "Installing modern CLI tools via Homebrew"
                local tools=(bat eza fd ripgrep fzf tmux git-delta htop tree)
                for tool in "${tools[@]}"; do
                    if ! brew list "$tool" >/dev/null 2>&1; then
                        log_info "Installing $tool"
                        brew install "$tool" || log_warn "Failed to install $tool"
                    fi
                done
            fi
            ;;
        *)
            if has_sudo; then
                log_info "Installing modern CLI tools (requires sudo)"
                # Platform-specific installs...
            else
                log_info "Skipping modern CLI tools (no sudo). These are optional."
                log_info "Available tools will be used if installed by admin."
            fi
            ;;
    esac
}

# Install zsh and set as default shell
setup_zsh() {
    local platform="$1"

    if ! command -v zsh >/dev/null 2>&1; then
        if has_sudo; then
            log_info "Installing zsh"
            case "$platform" in
                macos) install_packages "$platform" zsh ;;
                debian) install_packages "$platform" zsh ;;
                rhel) install_packages "$platform" zsh ;;
                arch) install_packages "$platform" zsh ;;
            esac
        else
            log_warn "zsh not found and no sudo access. Install zsh manually or ask admin."
            return 0
        fi
    fi

    # Set zsh as default shell (skip if no sudo)
    local zsh_path
    zsh_path="$(command -v zsh)"

    if [[ -z "$zsh_path" ]]; then
        log_warn "zsh not available, skipping shell setup"
        return 0
    fi

    if [[ "$SHELL" != "$zsh_path" ]]; then
        if has_sudo; then
            log_info "Setting zsh as default shell"
            if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
                echo "$zsh_path" | sudo tee -a /etc/shells
            fi
            chsh -s "$zsh_path"
            log_info "Shell changed. Restart terminal or login again to take effect"
        else
            log_warn "Cannot change default shell without sudo. Run 'zsh' manually or add to ~/.bash_profile:"
            log_warn "  exec zsh"
        fi
    fi
}

# Setup tmux plugin manager
setup_tmux() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    
    if [[ ! -d "$tpm_dir" ]]; then
        log_info "Installing tmux plugin manager"
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
        log_info "Run 'prefix + I' in tmux to install plugins"
    fi
}

# Setup FZF
setup_fzf() {
    if command -v fzf >/dev/null 2>&1; then
        local fzf_dir="$HOME/.fzf"
        if [[ ! -d "$fzf_dir" ]]; then
            log_info "Setting up FZF key bindings"
            git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir"
            "$fzf_dir/install" --key-bindings --completion --no-update-rc
        fi
    fi
}

# Create local config files
create_local_configs() {
    log_info "Creating local configuration files"

    # Create .private for secrets if it doesn't exist
    if [[ ! -f "$HOME/.private" ]]; then
        cat > "$HOME/.private" << 'EOF'
# ~/.private - SECRETS ONLY
# API keys, tokens, passwords - NEVER commit this file
#
# Add secrets with: add-secret VAR_NAME "value"
# Or manually:      export VAR_NAME="value"
#
# Machine config (paths, aliases, tools) goes in ~/.local_zshrc
# ─────────────────────────────────────────────────────────────

EOF
        chmod 600 "$HOME/.private"
        log_info "Created ~/.private (mode 600)"
    fi

    # Create .local_zshrc from template if it doesn't exist
    if [[ ! -f "$HOME/.local_zshrc" ]]; then
        if [[ -f "$DOTFILES_DIR/local_zshrc.template" ]]; then
            cp "$DOTFILES_DIR/local_zshrc.template" "$HOME/.local_zshrc"
            log_info "Created ~/.local_zshrc from template"
        else
            cat > "$HOME/.local_zshrc" << 'EOF'
# ~/.local_zshrc - MACHINE-SPECIFIC CONFIG
# Non-secret settings, paths, and tools for this machine
#
# SECRETS (API keys, tokens) go in ~/.private
# Add secrets with: add-secret VAR_NAME "value"
EOF
            log_info "Created ~/.local_zshrc (minimal)"
        fi
    fi
    
    # Create .gitconfig.local if it doesn't exist
    if [[ ! -f "$HOME/.gitconfig.local" ]]; then
        cat > "$HOME/.gitconfig.local" << 'EOF'
# Local git configuration
# Add machine-specific git settings here

[user]
    # Update with your information
    name = Your Name
    email = your.email@example.com

# Example: machine-specific settings
# [core]
#     sshCommand = ssh -i ~/.ssh/id_rsa_work

# Example: work-specific settings for certain directories
# [includeIf "gitdir:~/work/"]
#     path = ~/.gitconfig.work
EOF
        log_info "Created ~/.gitconfig.local - UPDATE WITH YOUR GIT CREDENTIALS"
    fi
}

# Verify installation
verify_setup() {
    log_info "Verifying installation"
    local errors=0
    
    for mapping in "${CONFIG_MAPPINGS[@]}"; do
        local target="${mapping#*:}"
        local target_path="$HOME/$target"
        if [[ -L "$target_path" ]]; then
            log_info "✓ $target properly linked"
        else
            log_error "✗ $target not linked correctly"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_info "Setup completed successfully!"
        log_info "Backup created in: $BACKUP_DIR"
        log_info ""
        log_info "Next steps:"
        log_info "1. Restart your terminal or run: exec zsh"
        log_info "2. Add API keys/secrets: add-secret VAR_NAME \"value\""
        log_info "3. Update ~/.gitconfig.local with your git credentials"
        log_info "4. Customize ~/.local_zshrc for machine-specific paths/tools"
        log_info "5. Edit ~/.config/starship.toml to customize your prompt"
        log_info "6. In tmux, press 'prefix + I' to install plugins"
    else
        log_error "Setup completed with $errors errors"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting enhanced dotfiles setup"
    
    # Ensure we're in the correct directory
    if [[ ! -f "$DOTFILES_DIR/makesymlinks.sh" ]]; then
        log_error "Please run from dotfiles directory or ensure ~/dotfiles exists"
        exit 1
    fi
    
    local platform
    platform="$(detect_platform)"
    log_info "Detected platform: $platform"
    
    # Create backups
    backup_configs
    
    # Install dependencies
    setup_zsh "$platform"
    setup_shell_tools "$platform"
    install_modern_tools "$platform"
    
    # Setup additional tools
    setup_tmux
    setup_fzf
    
    # Create configuration links
    create_symlinks
    
    # Create local config files
    create_local_configs
    
    # Verify installation
    verify_setup
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
