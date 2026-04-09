#!/bin/bash
# migrate-bash-to-zsh.sh - Complete bash to zsh migration tool
# Usage: ./migrate-bash-to-zsh.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# File paths
BASHRC="$HOME/.bashrc"
BASH_PROFILE="$HOME/.bash_profile"
ZSHRC="$HOME/.zshrc"
ZSH_HISTORY="$HOME/.zsh_history"
BASH_HISTORY="$HOME/.bash_history"

# Statistics
MIGRATED_ITEMS=0
SKIPPED_ITEMS=0

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   bash → zsh Migration Tool${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_info() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_step() { echo -e "${CYAN}→${NC} $1"; }

check_file() {
    local file="$1"
    [[ -f "$file" ]]
}

line_exists() {
    local line="$1"
    local file="$2"
    check_file "$file" && /usr/bin/grep -qF "$line" "$file" 2>/dev/null
}

append_if_not_exists() {
    local line="$1"
    local file="$2"
    
    /bin/mkdir -p "$(dirname "$file")" 2>/dev/null
    
    if ! line_exists "$line" "$file"; then
        echo "$line" >> "$file"
        MIGRATED_ITEMS=$((MIGRATED_ITEMS + 1))
        return 0
    fi
    SKIPPED_ITEMS=$((SKIPPED_ITEMS + 1))
    return 1
}

check_zsh_installed() {
    echo -e "${BLUE}🔍 Checking zsh installation...${NC}"
    if command -v zsh &>/dev/null; then
        local version
        version=$(zsh --version 2>&1 | /usr/bin/head -n1)
        print_info "Zsh is installed: $version"
        return 0
    else
        print_error "Zsh is NOT installed on your system"
        return 1
    fi
}

migrate_settings() {
    local source_file="$1"
    local description="$2"
    
    if ! check_file "$source_file"; then
        print_warning "$description ($source_file) not found"
        return
    fi
    
    echo -e "${BLUE}📖 Processing $description...${NC}"
    
    # 1. Import PATH settings
    echo "  → PATH settings..."
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        line=$(echo "$line" | /usr/bin/sed 's/;$//')
        if append_if_not_exists "$line" "$ZSHRC"; then
            echo "    + $line"
        fi
    done < <(/usr/bin/grep -E '^export\s+PATH' "$source_file" 2>/dev/null || true)
    
    # 2. Import other environment variables
    echo "  → Environment variables..."
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        line=$(echo "$line" | /usr/bin/sed 's/;$//')
        if append_if_not_exists "$line" "$ZSHRC"; then
            echo "    + $line"
        fi
    done < <(/usr/bin/grep -E '^export\s+(LANG|LC_|EDITOR|VISUAL|TERM)' "$source_file" 2>/dev/null | /usr/bin/grep -v PATH || true)
    
    # 3. Import aliases
    echo "  → Aliases..."
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        line=$(echo "$line" | /usr/bin/sed 's/;$//')
        if append_if_not_exists "$line" "$ZSHRC"; then
            echo "    + $line"
        fi
    done < <(/usr/bin/grep -E '^alias\s+' "$source_file" 2>/dev/null || true)
}

merge_history() {
    echo -e "${BLUE}📚 Merging history...${NC}"
    if [[ -f "$BASH_HISTORY" ]]; then
        if [[ -f "$ZSH_HISTORY" ]]; then
            /bin/cat "$BASH_HISTORY" "$ZSH_HISTORY" | /usr/bin/sort -u > "${ZSH_HISTORY}.tmp"
            /bin/mv "${ZSH_HISTORY}.tmp" "$ZSH_HISTORY"
        else
            /bin/cp "$BASH_HISTORY" "$ZSH_HISTORY"
        fi
        print_info "Merged bash history"
        MIGRATED_ITEMS=$((MIGRATED_ITEMS + 1))
    else
        print_warning "No bash history found"
    fi
}

setup_zsh_options() {
    echo -e "${BLUE}⚙️  Setting up zsh options...${NC}"
    if check_file "$ZSHRC"; then
        echo '' >> "$ZSHRC"
    fi
    echo '# ========================================
# Zsh Options (auto-configured by migrate-bash-to-zsh.sh)
# ==========================================' >> "$ZSHRC"
    echo '' >> "$ZSHRC"
    echo '# History settings' >> "$ZSHRC"
    echo 'HISTFILE=$HOME/.zsh_history' >> "$ZSHRC"
    echo 'HISTSIZE=10000' >> "$ZSHRC"
    echo 'SAVEHIST=10000' >> "$ZSHRC"
    echo 'setopt EXTENDED_HISTORY INC_APPEND_HISTORY SHARE_HISTORY' >> "$ZSHRC"
    echo 'setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS' >> "$ZSHRC"
    echo '' >> "$ZSHRC"
    echo '# Completion settings' >> "$ZSHRC"
    echo 'setopt AUTO_MENU AUTO_LIST COMPLETE_IN_WORD MENU_COMPLETE' >> "$ZSHRC"
    echo '' >> "$ZSHRC"
    echo '# Quality of Life settings' >> "$ZSHRC"
    echo 'setopt NO_BEep AUTO_PUSHD PUSHD_IGNORE_DUPS CDABLE_VARS AUTO_CD' >> "$ZSHRC"
    echo 'setopt GLOB_COMPLETE HASH_LIST_ALL LIST_TYPES' >> "$ZSHRC"
    print_info "Zsh options configured"
    MIGRATED_ITEMS=$((MIGRATED_ITEMS + 1))
}

change_default_shell() {
    echo -e "${BLUE}🐚 Setting Zsh as default shell...${NC}"
    local zsh_path
    zsh_path=$(which zsh)
    
    if [[ -z "$zsh_path" ]]; then
        print_error "Zsh path not found. Skipping default shell change."
        return 1
    fi
    
    echo "Executing: chsh -s $zsh_path"
    if chsh -s "$zsh_path"; then
        print_info "Default shell changed to Zsh successfully!"
        echo -e "${YELLOW}Note: You must log out and log back in (or restart SSH session) for this to take effect.${NC}"
    else
        print_warning "Failed to change default shell automatically."
        echo -e "You can do it manually by running: ${CYAN}chsh -s $zsh_path${NC}"
    fi
}

generate_report() {
    echo ""
    print_header
    echo -e "${GREEN}✅ Migration complete!${NC}"
    echo ""
    echo -e "${CYAN}Statistics:${NC}"
    echo "  • Migrated: $MIGRATED_ITEMS items"
    echo "  • Skipped (duplicates): $SKIPPED_ITEMS items"
    echo ""
}

main() {
    print_header
    echo "Starting bash to zsh migration..."
    echo ""
    
    if ! check_zsh_installed; then
        exit 1
    fi
    echo ""
    
    # Backup existing zshrc
    if [[ -f "$ZSHRC" ]]; then
        local backup="${ZSHRC}.bak.$(/bin/date +%Y%m%d_%H%M%S)"
        /bin/cp "$ZSHRC" "$backup"
        print_info "Backed up ~/.zshrc → $backup"
    fi
    
    migrate_settings "$BASHRC" "~/.bashrc"
    migrate_settings "$BASH_PROFILE" "~/.bash_profile"
    merge_history
    setup_zsh_options
    generate_report
    
    echo -e "${BLUE}Would you like to set Zsh as your default shell? [Y/n]${NC}"
    read -r -p "" response
    if [[ "$response" =~ ^[Yy]$ || -z "$response" ]]; then
        change_default_shell
    else
        echo "Skipping default shell change."
    fi
    
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Review ~/.zshrc content"
    echo "  2. Run: source ~/.zshrc"
    echo "  3. Or restart terminal (and log back in if you changed default shell)"
}

main "$@"
