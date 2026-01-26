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
    "matplotlibrc:.matplotlib/matplotlibrc"
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
    log_info "Installing shell tools (starship, zoxide, zsh plugins)"

    case "$platform" in
        macos)
            if command -v brew >/dev/null 2>&1; then
                local tools=(starship zoxide zsh-syntax-highlighting zsh-autosuggestions)
                for tool in "${tools[@]}"; do
                    if ! brew list "$tool" >/dev/null 2>&1; then
                        log_info "Installing $tool"
                        brew install "$tool" || log_warn "Failed to install $tool"
                    else
                        log_info "✓ $tool already installed"
                    fi
                done
            else
                log_warn "Homebrew not found. Install starship, zoxide, zsh-syntax-highlighting, zsh-autosuggestions manually"
            fi
            ;;
        debian)
            # Install starship
            if ! command -v starship >/dev/null 2>&1; then
                log_info "Installing starship"
                curl -sS https://starship.rs/install.sh | sh -s -- -y
            fi
            # Install zoxide
            if ! command -v zoxide >/dev/null 2>&1; then
                log_info "Installing zoxide"
                curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            fi
            # Install zsh plugins via apt or git
            if [[ ! -d /usr/share/zsh-syntax-highlighting ]]; then
                sudo apt-get install -y zsh-syntax-highlighting || {
                    log_info "Installing zsh-syntax-highlighting from git"
                    sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /usr/share/zsh-syntax-highlighting
                }
            fi
            if [[ ! -d /usr/share/zsh-autosuggestions ]]; then
                sudo apt-get install -y zsh-autosuggestions || {
                    log_info "Installing zsh-autosuggestions from git"
                    sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git /usr/share/zsh-autosuggestions
                }
            fi
            ;;
        arch)
            sudo pacman -S --noconfirm starship zoxide zsh-syntax-highlighting zsh-autosuggestions
            ;;
        *)
            log_warn "Unknown platform. Install starship, zoxide, zsh-syntax-highlighting, zsh-autosuggestions manually"
            ;;
    esac

    # Clear cached init scripts so they regenerate with new binaries
    rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/starship_init.zsh"
    rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/zoxide_init.zsh"
    log_info "✓ Shell tools setup complete"
}

# Install modern CLI tools
install_modern_tools() {
    local platform="$1"
    
    log_info "Installing modern CLI tools"
    
    case "$platform" in
        macos)
            if command -v brew >/dev/null 2>&1; then
                # Install modern CLI tools via Homebrew
                local tools=(
                    "bat"           # Better cat
                    "eza"           # Better ls
                    "fd"            # Better find
                    "ripgrep"       # Better grep
                    "fzf"           # Fuzzy finder
                    "tmux"          # Terminal multiplexer
                    "git-delta"     # Better git diff
                    "htop"          # Better top
                    "tree"          # Directory tree
                )
                
                for tool in "${tools[@]}"; do
                    if ! command -v "${tool}" >/dev/null 2>&1; then
                        log_info "Installing $tool"
                        brew install "$tool" || log_warn "Failed to install $tool"
                    fi
                done
            fi
            ;;
        debian)
            local tools=(
                "bat"
                "eza" 
                "fd-find"
                "ripgrep"
                "fzf"
                "tmux"
                "git-delta"
                "htop"
                "tree"
            )
            
            for tool in "${tools[@]}"; do
                if ! dpkg -l | grep -q "^ii  $tool "; then
                    log_info "Installing $tool"
                    sudo apt-get install -y "$tool" || log_warn "Failed to install $tool"
                fi
            done
            ;;
        arch)
            local tools=(
                "bat"
                "eza"
                "fd"
                "ripgrep"
                "fzf"
                "tmux"
                "git-delta"
                "htop"
                "tree"
            )
            
            for tool in "${tools[@]}"; do
                if ! pacman -Q "$tool" >/dev/null 2>&1; then
                    log_info "Installing $tool"
                    sudo pacman -S --noconfirm "$tool" || log_warn "Failed to install $tool"
                fi
            done
            ;;
    esac
}

# Install zsh and set as default shell
setup_zsh() {
    local platform="$1"
    
    if ! command -v zsh >/dev/null 2>&1; then
        log_info "Installing zsh"
        case "$platform" in
            macos) install_packages "$platform" zsh ;;
            debian) install_packages "$platform" zsh ;;
            rhel) install_packages "$platform" zsh ;;
            arch) install_packages "$platform" zsh ;;
        esac
    fi
    
    # Set zsh as default shell
    local zsh_path
    zsh_path="$(command -v zsh)"
    
    if [[ "$SHELL" != "$zsh_path" ]]; then
        log_info "Setting zsh as default shell"
        if ! grep -q "$zsh_path" /etc/shells; then
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi
        chsh -s "$zsh_path"
        log_info "Shell changed. Restart terminal or login again to take effect"
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
