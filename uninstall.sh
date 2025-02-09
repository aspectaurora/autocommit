#!/usr/bin/env bash
#
# Uninstallation script for Autocommit
# This script removes Autocommit and its files from the system.

# Source logger for consistent output
source "$(dirname "${BASH_SOURCE[0]}")/lib/core/logger.sh"

# Installation paths
INSTALL_DIR="/usr/local/share/autocommit"
BIN_DIR="/usr/local/bin"
CONFIG_FILE="$HOME/.autocommitrc"

# Check if running with sudo/root
if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run with sudo privileges." 1
fi

# Remove symlink
log_info "Removing symlink..."
if [[ -L "$BIN_DIR/autocommit" ]]; then
    rm -f "$BIN_DIR/autocommit" || error_exit "Failed to remove symlink." 2
else
    log_warn "Symlink not found in $BIN_DIR"
fi

# Remove installation directory
log_info "Removing installation directory..."
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR" || error_exit "Failed to remove installation directory." 3
else
    log_warn "Installation directory not found at $INSTALL_DIR"
fi

# Ask about removing config file
if [[ -f "$CONFIG_FILE" ]]; then
    read -p "Do you want to remove the configuration file ($CONFIG_FILE)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$CONFIG_FILE" || error_exit "Failed to remove configuration file." 4
        log_info "Configuration file removed."
    else
        log_info "Configuration file preserved at $CONFIG_FILE"
    fi
fi

# Warn about PATH modification
log_warn "Note: If you modified your shell profile to add /usr/local/bin to PATH,"
log_warn "you may want to remove that modification manually."

log_info "Uninstallation complete! 👋"
log_info "Thank you for using Autocommit!"