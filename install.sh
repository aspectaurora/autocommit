#!/usr/bin/env bash
#
# Installation script for Autocommit
# This script installs Autocommit and its dependencies in the appropriate locations.

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

# Check dependencies
log_info "Checking dependencies..."

if ! command -v git &> /dev/null; then
    error_exit "Git is not installed. Please install Git and try again." 2
fi

if ! command -v sgpt &> /dev/null; then
    log_warn "shell-gpt is not installed. Installing..."
    if ! command -v pip3 &> /dev/null; then
        error_exit "pip3 is not installed. Please install Python 3 and pip3, then try again." 3
    fi
    if ! pip3 install shell-gpt; then
        error_exit "Failed to install shell-gpt. Please install it manually using 'pip3 install shell-gpt'." 4
    fi
fi

# Create installation directory
log_info "Creating installation directory..."
mkdir -p "$INSTALL_DIR" || error_exit "Failed to create installation directory." 5

# Copy files
log_info "Copying files..."

# Copy main script
cp "$(dirname "${BASH_SOURCE[0]}")/autocommit.sh" "$INSTALL_DIR/" || error_exit "Failed to copy main script." 6

# Copy library files
for dir in core git ai; do
    mkdir -p "$INSTALL_DIR/lib/$dir" || error_exit "Failed to create $dir directory." 7
    cp "$(dirname "${BASH_SOURCE[0]}")/lib/$dir/"*.sh "$INSTALL_DIR/lib/$dir/" || error_exit "Failed to copy $dir files." 8
done

# Create symlink
log_info "Creating symlink..."
cat > "$BIN_DIR/autocommit" << 'EOF'
#!/usr/bin/env bash
exec bash "/usr/local/share/autocommit/autocommit.sh" "$@"
EOF
chmod +x "$BIN_DIR/autocommit" || error_exit "Failed to make script executable." 10

# Create default config if it doesn't exist
if [[ ! -f "$CONFIG_FILE" ]]; then
    log_info "Creating default configuration file..."
    cat > "$CONFIG_FILE" << EOF
# Autocommit Configuration File
# See https://github.com/yourusername/autocommit for documentation

# Default AI model to use
DEFAULT_MODEL="gpt-4-turbo"

# Enable verbose logging by default
VERBOSE=false
EOF
    chmod 600 "$CONFIG_FILE" || error_exit "Failed to set config file permissions." 11
fi

# Check if /usr/local/bin is in PATH
if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    log_warn "/usr/local/bin is not in your PATH. Adding it to your shell profile..."
    
    # Determine shell and profile file
    SHELL_PROFILE=""
    if [[ "$SHELL" == */zsh ]]; then
        SHELL_PROFILE="$HOME/.zshrc"
    elif [[ "$SHELL" == */bash ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            SHELL_PROFILE="$HOME/.bash_profile"
        else
            SHELL_PROFILE="$HOME/.bashrc"
        fi
    fi
    
    if [[ -n "$SHELL_PROFILE" ]]; then
        echo 'export PATH="/usr/local/bin:$PATH"' >> "$SHELL_PROFILE"
        log_info "Added /usr/local/bin to PATH in $SHELL_PROFILE"
        log_info "Please run 'source $SHELL_PROFILE' to update your PATH"
    else
        log_warn "Could not determine shell profile. Please add /usr/local/bin to your PATH manually."
    fi
fi

log_info "Installation complete! 🎉"
log_info "You can now use 'autocommit' from anywhere in your terminal."
log_info "Configuration file is located at: $CONFIG_FILE"
log_info "For usage instructions, run: autocommit --help"