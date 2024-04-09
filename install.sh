#!/bin/bash

# Define the install directory
INSTALL_DIR="/usr/local/bin"

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root. Please try again with 'sudo'."
    exit 1
fi

# Copy the autocommit script to the install directory
cp autocommit "$INSTALL_DIR/autocommit"

# Make sure the script is executable
chmod +x "$INSTALL_DIR/autocommit"

echo "Autocommit has been successfully installed. You can now use it by typing 'autocommit' in your terminal."
