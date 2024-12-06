#!/usr/bin/env bash
#
# uninstall.sh - Uninstallation script for Autocommit
#
# This script removes the autocommit command and optionally cleans up
# the configuration file and PATH modifications.
#
# Usage:
# ./uninstall.sh
#
# It will:
# - Remove /usr/local/bin/autocommit
# - Prompt to remove ~/.autocommitrc
# - Prompt to remove PATH modifications from shell profile files

set -e

# Variables
TARGET_DIR="/usr/local/bin"
TARGET_PATH="$TARGET_DIR/autocommit"

# Function to display messages
print_message() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

print_message "Autocommit Uninstallation"

# Check if the autocommit command exists
if [ ! -f "$TARGET_PATH" ]; then
    echo "Autocommit not found at $TARGET_PATH. It may not be installed."
    exit 0
fi

# Confirm removal of autocommit executable
read -p "Are you sure you want to remove the Autocommit executable from $TARGET_PATH? [y/N]: " confirm_remove
if [[ "$confirm_remove" =~ ^[Yy]$ ]]; then
    sudo rm -f "$TARGET_PATH"
    echo "Removed $TARGET_PATH."
else
    echo "Autocommit uninstallation aborted."
    exit 0
fi

# Offer to remove ~/.autocommitrc
if [ -f "$HOME/.autocommitrc" ]; then
    read -p "Do you want to remove the ~/.autocommitrc configuration file? [y/N]: " confirm_rc
    if [[ "$confirm_rc" =~ ^[Yy]$ ]]; then
        rm -f "$HOME/.autocommitrc"
        echo "Removed ~/.autocommitrc."
    else
        echo "Kept ~/.autocommitrc."
    fi
fi

# Offer to remove PATH modifications from known shell profiles
# We'll search for the comment line added during install
CONFIG_COMMENT="# Add /usr/local/bin to PATH for Autocommit"
MOD_LINE='export PATH="$PATH:/usr/local/bin"'

remove_path_modification() {
    local file="$1"
    if [ -f "$file" ]; then
        # Check if the file contains the autocommit PATH modifications
        if grep -q "$CONFIG_COMMENT" "$file"; then
            read -p "Remove Autocommit PATH modifications from $file? [y/N]: " confirm_path
            if [[ "$confirm_path" =~ ^[Yy]$ ]]; then
                # Use sed to remove the lines
                sed -i.bak "/$CONFIG_COMMENT/d" "$file"
                sed -i.bak "/$MOD_LINE/d" "$file"
                rm -f "$file.bak"
                echo "Removed PATH modifications from $file."
            else
                echo "Kept PATH modifications in $file."
            fi
        fi
    fi
}

remove_path_modification "$HOME/.zshrc"
remove_path_modification "$HOME/.bashrc"
remove_path_modification "$HOME/.bash_profile"
remove_path_modification "$HOME/.profile"

print_message "Autocommit has been uninstalled."
echo "If you removed PATH modifications, please open a new terminal session or reload your shell."