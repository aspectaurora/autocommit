#!/usr/bin/env bash
# lib/core/config.sh
# Configuration management for autocommit

# Guard against multiple sourcing
[[ -n "${_AUTOCOMMIT_CONFIG_SH:-}" ]] && return 0
readonly _AUTOCOMMIT_CONFIG_SH=1

# Source logger
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"


# Default configuration values
DEFAULT_MODEL="gpt-4o-mini"
DEFAULT_VERBOSE="false"
export DEFAULT_MODEL DEFAULT_VERBOSE

# Global configuration variables
model="$DEFAULT_MODEL"
verbose="$DEFAULT_VERBOSE"
export model verbose

# Configuration validation schema
declare -A CONFIG_SCHEMA
CONFIG_SCHEMA=(
    ["model"]="string"
    ["verbose"]="boolean"
)

# Source git utilities
source "$(dirname "${BASH_SOURCE[0]}")/../git/utils.sh"

# Validate configuration value based on type
# Args:
#   $1 - Config key
#   $2 - Value to validate
# Returns: 0 if valid, 1 if invalid
function _validate_config_value() {
    local key="$1"
    local value="$2"
    
    # Empty values are invalid
    [[ -z "$value" ]] && return 1
    
    case "$key" in
        model)
            # Model should be a non-empty string
            [[ -n "$value" ]] || return 1
            return 0
            ;;
        verbose)
            # Verbose should be true or false
            [[ "$value" == "true" || "$value" == "false" ]] || return 1
            return 0
            ;;
        *)
            log_warn "Unknown config key: $key"
            return 1
            ;;
    esac
}

# Parse a single config file
# Args:
#   $1 - Path to config file
#   $2 - Reference to associative array for storing values
# Returns: 0 if successful, 1 if any invalid values
function _parse_config_file() {
    local file="$1"
    local -n config_ref="$2"
    local any_invalid=0
    local line key value
    
    log_debug "Parsing config file: $file"
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        log_debug "Processing line: $line"
        
        # Extract key and value, handling export statements
        if [[ "$line" =~ ^[[:space:]]*export[[:space:]]+([^=]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
        elif [[ "$line" =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*(.*)[[:space:]]*$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
        else
            log_warn "Invalid config line format: $line"
            any_invalid=1
            continue
        fi
        
        # Skip internal variables
        [[ "$key" =~ ^DEFAULT_ ]] && continue
        
        # Trim whitespace
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        
        # Trim quotes if present
        if [[ "$value" =~ ^[\"\'].*[\"\']$ ]]; then
            value="${value#[\"\']}"
            value="${value%[\"\']}"
        fi
        
        log_debug "Found key=$key value=$value"
        
        # Skip empty values
        if [[ -z "$value" ]]; then
            log_warn "Empty value for $key"
            any_invalid=1
            continue
        fi
        
        # Validate and store
        if ! _validate_config_value "$key" "$value"; then
            log_warn "Invalid value for $key: $value"
            any_invalid=1
            continue
        fi
        
        log_debug "Setting $key=$value"
        config_ref["$key"]="$value"
    done < "$file"
    
    return $any_invalid
}

# Load configuration from files
# No args
# Returns: 0 if successful, 1 if any invalid values
function load_config() {
    local any_invalid=0
    local current_dir
    current_dir="$(pwd)"
    
    log_debug "Loading config from directory: $current_dir"
    log_debug "HOME directory: $HOME"
    
    # Reset to defaults first
    model="$DEFAULT_MODEL"
    verbose="$DEFAULT_VERBOSE"
    export model verbose
    
    # Use associative array to store config values
    declare -A config=(
        ["model"]="$DEFAULT_MODEL"
        ["verbose"]="$DEFAULT_VERBOSE"
    )
    
    # Load home config first (lower priority)
    if [[ -f "${HOME}/.autocommitrc" ]]; then
        log_debug "Loading home config from ${HOME}/.autocommitrc"
        if ! _parse_config_file "${HOME}/.autocommitrc" config; then
            any_invalid=1
        fi
        # Apply home config values
        model="${config[model]}"
        verbose="${config[verbose]}"
        # Export values immediately
        export model verbose
    else
        log_debug "No home config found at ${HOME}/.autocommitrc"
    fi
    
    # Load repo config (higher priority, overrides home config)
    if [[ -f "${current_dir}/.autocommitrc" ]]; then
        log_debug "Loading repo config from ${current_dir}/.autocommitrc"
        if ! _parse_config_file "${current_dir}/.autocommitrc" config; then
            any_invalid=1
        fi
        # Apply repo config values
        model="${config[model]}"
        verbose="${config[verbose]}"
        # Export values immediately
        export model verbose
    else
        log_debug "No repo config found at ${current_dir}/.autocommitrc"
    fi
    
    log_debug "Final config values: model=$model verbose=$verbose"
    
    # Return failure if any invalid values were found
    return $any_invalid
}

# Get configuration value
# Args:
#   $1 - Configuration key
#   $2 - (Optional) Default value if not found
# Returns: Configuration value
function get_config() {
    local key="$1"
    local default_value="${2:-}"
    
    # Always load config first to ensure we have the latest values
    load_config
    
    # Get value from environment
    local value
    case "$key" in
        model) value="${model:-}" ;;
        verbose) value="${verbose:-}" ;;
        *) value="" ;;
    esac
    
    # If not found, use default
    if [[ -z "$value" ]]; then
        value="$default_value"
    fi
    
    # Always export the value to ensure it's available in subshells
    case "$key" in
        model|verbose)
            declare -g "$key=$value"
            export "$key"
            ;;
    esac
    
    # Return the value without any quotes or whitespace
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    value="${value#[\"\']}"
    value="${value%[\"\']}"
    
    # In test environment, we need to handle output differently
    if [[ -n "${BATS_TEST_DIRNAME:-}" ]]; then
        # BATS run command captures stdout, so we need to write to it directly
        printf "%s" "$value" >&1
    else
        # Normal operation
        printf "%s" "$value"
    fi
}

# Initialize configuration on source
load_config 