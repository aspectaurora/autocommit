#!/usr/bin/env bash
#
# uninstall.sh - Uninstallation script for Autocommit
#
# This script removes Autocommit by:
# - Removing the symlink at /usr/local/bin/autocommit
# - Removing the /usr/local/share/autocommit directory
# - Optionally removing ~/.autocommitrc and PATH modifications

set -e

INSTALL_DIR="/usr/local/share/autocommit"
BIN_PATH="/usr/local/bin/autocommit"

print_message() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

print_message "Autocommit Uninstallation"

if [ ! -L "$BIN_PATH" ]; then
    echo "Autocommit symlink not found at $BIN_PATH. It may already be uninstalled."
else
    read -p "Remove the Autocommit symlink at $BIN_PATH? [y/N]: " confirm_symlink
    if [[ "$confirm_symlink" =~ ^[Yy]$ ]]; then
        sudo rm -f "$BIN_PATH"
        echo "Removed symlink $BIN_PATH."
    else
        echo "Kept symlink. Uninstallation halted."
        exit 0
    fi
fi

if [ -d "$INSTALL_DIR" ]; then
    read -p "Remove Autocommit installation directory at $INSTALL_DIR? [y/N]: " confirm_dir
    if [[ "$confirm_dir" =~ ^[Yy]$ ]]; then
        sudo rm -rf "$INSTALL_DIR"
        echo "Removed $INSTALL_DIR."
    else
        echo "Kept $INSTALL_DIR. Uninstallation incomplete."
    fi
else
    echo "No directory found at $INSTALL_DIR. Skipping."
fi

if [ -f "$HOME/.autocommitrc" ]; then
    read -p "Remove ~/.autocommitrc file? [y/N]: " confirm_rc
    if [[ "$confirm_rc" =~ ^[Yy]$ ]]; then
        rm -f "$HOME/.autocommitrc"
        echo "Removed ~/.autocommitrc."
    else
        echo "Kept ~/.autocommitrc."
    fi
fi

# Note: Removing PATH modifications from user shell profiles is optional and risky.
# The user might have other entries in their PATH. Unless you strictly restore backups,
# it's best just to inform the user to manually edit their PATH if desired.
# For safety, we won't automatically remove PATH modifications here.

print_message "Autocommit has been uninstalled."
echo "If needed, remove any PATH modifications manually from your shell profiles."