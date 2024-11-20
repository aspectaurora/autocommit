#!/bin/bash

# Define the install directory
INSTALL_DIR="/usr/local/bin"

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root. Please try again with 'sudo'."
    exit 1
fi

# Copy the autocommit script to the install directory
if ! cp autocommit "$INSTALL_DIR/autocommit"; then
    echo "Error: Failed to copy autocommit to $INSTALL_DIR."
    exit 1
fi

# Make sure the script is executable
if ! chmod +x "$INSTALL_DIR/autocommit"; then
    echo "Error: Failed to make autocommit executable."
    exit 1
fi

echo "Autocommit has been successfully installed. You can now use it by typing 'autocommit' in your terminal."

