#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define dotfiles mappings (source -> destination)
declare -A DOTFILES=(
    ["$SCRIPT_DIR/git/.gitconfig"]="$HOME/.gitconfig"
    ["$SCRIPT_DIR/zsh/.zshrc"]="$HOME/.zshrc"
    ["$SCRIPT_DIR/wezterm/wezterm.lua"]="$HOME/.config/wezterm/wezterm.lua"
)

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Function to create symbolic link
create_symlink() {
    local source="$1"
    local destination="$2"
    local dest_dir=$(dirname "$destination")

    # Check if source exists
    if [ ! -e "$source" ]; then
        print_error "Source file not found: $source"
        return 1
    fi

    # Create parent directory if it doesn't exist
    if [ ! -d "$dest_dir" ]; then
        print_info "Creating directory: $dest_dir"
        mkdir -p "$dest_dir"
    fi

    # Handle existing destination
    if [ -e "$destination" ] || [ -L "$destination" ]; then
        # Check if it's already a symlink to our source
        if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
            print_info "Already linked: $destination → $source"
            return 0
        fi

        # Warn about existing file
        print_warning "Destination already exists: $destination"
        print_warning "Backing up to: ${destination}.bak"
        mv "$destination" "${destination}.bak"
    fi

    # Create the symlink
    ln -s "$source" "$destination"
    print_info "Linked: $destination → $source"
}

# Main setup
main() {
    echo "========================================="
    echo "    Dotfiles Setup Script"
    echo "========================================="
    echo ""
    echo "Dotfiles directory: $SCRIPT_DIR"
    echo "Home directory: $HOME"
    echo ""

    local success_count=0
    local error_count=0

    # Process each dotfile
    for source in "${!DOTFILES[@]}"; do
        destination="${DOTFILES[$source]}"
        if create_symlink "$source" "$destination"; then
            ((success_count++)) || true
        else
            ((error_count++)) || true
        fi
    done

    echo ""
    echo "========================================="
    echo -e "${GREEN}Setup completed!${NC}"
    echo "Successfully linked: $success_count files"
    if [ "$error_count" -gt 0 ]; then
        echo -e "${RED}Failed to link: $error_count files${NC}"
    fi
    echo "========================================="
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTION]

Options:
    (no args)    Set up dotfiles (create symlinks)
    --help       Show this help message
    --unlink     Remove all symlinks and restore backups

Examples:
    # First time setup
    $0

    # Remove symlinks
    $0 --unlink

EOF
}

# Function to unlink dotfiles
unlink_dotfiles() {
    echo "Unlinking dotfiles..."

    for source in "${!DOTFILES[@]}"; do
        destination="${DOTFILES[$source]}"

        if [ -L "$destination" ]; then
            rm "$destination"
            print_info "Removed symlink: $destination"

            # Restore backup if it exists
            if [ -e "${destination}.bak" ]; then
                mv "${destination}.bak" "$destination"
                print_info "Restored backup: $destination"
            fi
        elif [ -e "$destination" ]; then
            print_warning "File is not a symlink, skipping: $destination"
        fi
    done

    echo "Unlink completed!"
}

# Parse command line arguments
case "${1:-}" in
    --help)
        show_usage
        ;;
    --unlink)
        unlink_dotfiles
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac
