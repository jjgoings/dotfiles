#!/bin/bash
set -eo pipefail

# Enhanced dotfiles setup with proper config separation
# Supports macOS, Debian/Ubuntu, RHEL/CentOS, Arch Linux

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$HOME/dotfiles"
readonly BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
readonly OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"

# Configuration mapping: source_file:target_location
readonly CONFIG_MAPPINGS=(
    "bashrc:.bashrc"
    "vimrc:.vimrc" 
    "vim:.vim"
    "zshenv:.zshenv"
    "zprofile:.zprofile"
    "zshrc:.zshrc"
    "Xresources:.Xresources"
    "private:.private"
    "matplotlibrc:.matplotlib/matplotlibrc"
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

# Install and configure oh-my-zsh
setup_oh_my_zsh() {
    if [[ -d "$OH_MY_ZSH_DIR" ]]; then
        log_info "oh-my-zsh already installed"
        return 0
    fi
    
    log_info "Installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Install additional plugins
    local custom_plugins="$OH_MY_ZSH_DIR/custom/plugins"
    
    # zsh-syntax-highlighting
    if [[ ! -d "$custom_plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_plugins/zsh-syntax-highlighting"
    fi
    
    # zsh-autosuggestions (optional but useful)
    if [[ ! -d "$custom_plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git "$custom_plugins/zsh-autosuggestions"
    fi
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
    else
        log_error "Setup completed with $errors errors"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting dotfiles setup"
    
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
    setup_oh_my_zsh
    
    # Create configuration links
    create_symlinks
    
    # Verify installation
    verify_setup
    
    log_info "To complete setup:"
    log_info "1. Restart your terminal or run: exec zsh"
    log_info "2. Customize ~/.local_zshrc for machine-specific settings"
    log_info "3. Add private configs to ~/.private"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
