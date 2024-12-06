#!/usr/bin/env bash
#
# install.sh - Installation script for Autocommit
# Now also sets up a template ~/.autocommitrc if none exists.
#

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

# Create a template ~/.autocommitrc if it doesn't exist
if [ ! -f "$HOME/.autocommitrc" ]; then
    print_message "No ~/.autocommitrc found. Creating a template..."
    cat <<EOF > "$HOME/.autocommitrc"
# ~/.autocommitrc - Configuration file for Autocommit
#
# Uncomment and set this variable to change the default model:
# export DEFAULT_MODEL="gpt-4o-mini"
#
EOF
    print_message "A template ~/.autocommitrc has been created. You can customize it according to your needs."
else
    print_message "~/.autocommitrc already exists. Skipping template creation."
fi

print_message "Autocommit has been installed successfully as an executable command!"