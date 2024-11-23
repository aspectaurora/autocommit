#!/usr/bin/env bash
#
# install.sh - Installation script for Autocommit
# This script installs autocommit.sh to /usr/local/bin and sets up necessary configurations.

set -e

# Variables
SCRIPT_NAME="autocommit.sh"
TARGET_DIR="/usr/local/bin"
TARGET_PATH="$TARGET_DIR/autocommit"
SHELL_PROFILE=""

# Function to display messages
print_message() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

# Check for sudo/root permissions
if [ "$(id -u)" -ne 0 ]; then
    SUDO='sudo'
else
    SUDO=''
fi

# Copy the script to /usr/local/bin
print_message "Copying $SCRIPT_NAME to $TARGET_DIR..."
$SUDO cp "$SCRIPT_NAME" "$TARGET_PATH"

# Set executable permissions
print_message "Setting executable permissions for $TARGET_PATH..."
$SUDO chmod +x "$TARGET_PATH"

# Ensure /usr/local/bin is in PATH
if [[ ":$PATH:" != *":$TARGET_DIR:"* ]]; then
    print_message "Adding $TARGET_DIR to your PATH..."
    if [ -f "$HOME/.zshrc" ]; then
        SHELL_PROFILE="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_PROFILE="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        SHELL_PROFILE="$HOME/.bash_profile"
    else
        SHELL_PROFILE="$HOME/.profile"
    fi

    echo "" >> "$SHELL_PROFILE"
    echo "# Add /usr/local/bin to PATH for Autocommit" >> "$SHELL_PROFILE"
    echo "export PATH=\"\$PATH:$TARGET_DIR\"" >> "$SHELL_PROFILE"
    print_message "Added $TARGET_DIR to PATH in $SHELL_PROFILE. Please reload your shell or run 'source $SHELL_PROFILE' to update PATH."
fi

print_message "Autocommit has been installed as an executable command!"