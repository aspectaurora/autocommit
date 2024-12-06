#!/usr/bin/env bash
#
# install.sh - Installation script for Autocommit
#
# Installs autocommit into /usr/local/share/autocommit and creates a symlink in /usr/local/bin.
# Also sets up a template ~/.autocommitrc if none exists.

set -e

# Variables
INSTALL_DIR="/usr/local/share/autocommit"
BIN_PATH="/usr/local/bin/autocommit"
SCRIPT_NAME="autocommit.sh"

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

print_message "Installing Autocommit..."

# Create the installation directory
$SUDO mkdir -p "$INSTALL_DIR"

# Copy the main script
print_message "Copying $SCRIPT_NAME to $INSTALL_DIR..."
$SUDO cp "$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
$SUDO chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Copy the lib directory
print_message "Copying lib directory to $INSTALL_DIR..."
$SUDO rm -rf "$INSTALL_DIR/lib" 2>/dev/null || true
$SUDO cp -r lib "$INSTALL_DIR/lib"

# Create the symlink in /usr/local/bin
print_message "Creating symlink at $BIN_PATH..."
if [ -f "$BIN_PATH" ]; then
    $SUDO rm -f "$BIN_PATH"
fi
$SUDO ln -s "$INSTALL_DIR/$SCRIPT_NAME" "$BIN_PATH"

# Ensure /usr/local/bin is in PATH (if needed)
if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    print_message "Adding /usr/local/bin to your PATH..."
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
    echo "export PATH=\"\$PATH:/usr/local/bin\"" >> "$SHELL_PROFILE"
    print_message "Added /usr/local/bin to PATH in $SHELL_PROFILE. Please reload your shell or run 'source $SHELL_PROFILE' to update PATH."
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

print_message "Autocommit has been installed successfully!"
echo "You can now run 'autocommit' from any directory inside a Git repository."