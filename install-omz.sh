#!/bin/bash
# install-omz.sh - Install Oh My Zsh non-interactively
# Usage: ./install-omz.sh

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

main() {
    echo -e "${BLUE}📦 Installing Oh My Zsh...${NC}"
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "Oh My Zsh is already installed, skipping..."
        return 0
    fi
    
    # Use --unattended to prevent the installer from switching shells immediately
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        print_info "Oh My Zsh installed successfully!"
    else
        print_error "Failed to install Oh My Zsh."
        return 1
    fi
}

main "$@"
