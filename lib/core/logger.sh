#!/usr/bin/env bash
# lib/core/logger.sh
# Centralized logging functionality for autocommit

# Guard against multiple sourcing
[[ -n "${_AUTOCOMMIT_LOGGER_SH:-}" ]] && return 0
readonly _AUTOCOMMIT_LOGGER_SH=1

# Log levels
readonly LOG_LEVEL_ERROR=0
readonly LOG_LEVEL_WARN=1
readonly LOG_LEVEL_INFO=2
readonly LOG_LEVEL_DEBUG=3
readonly LOG_LEVEL_VERBOSE=4

# Export log levels for tests
export LOG_LEVEL_ERROR LOG_LEVEL_WARN LOG_LEVEL_INFO LOG_LEVEL_DEBUG LOG_LEVEL_VERBOSE

# Current log level (default: INFO)
CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO
export CURRENT_LOG_LEVEL

# Set log level
set_log_level() {
    local level="$1"
    
    # Handle numeric levels
    if [[ "$level" =~ ^[0-4]$ ]]; then
        CURRENT_LOG_LEVEL=$level
        return 0
    fi
    
    # Handle string levels
    case "$level" in
        error)   CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR ;;
        warn)    CURRENT_LOG_LEVEL=$LOG_LEVEL_WARN ;;
        info)    CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
        debug)   CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        verbose) CURRENT_LOG_LEVEL=$LOG_LEVEL_VERBOSE ;;
        *)       return 1 ;;
    esac
    return 0
}

# Internal logging function
_log() {
    local level="$1"
    local level_name="$2"
    local message="$3"
    
    if [[ $level -le $CURRENT_LOG_LEVEL ]]; then
        local timestamp
        timestamp=$(date '+[%Y-%m-%d %H:%M:%S]')
        printf '%s %s: %s\n' "$timestamp" "$level_name" "$message" >&2
    fi
}

# Log error message and optionally exit
log_error() {
    local message="$1"
    _log $LOG_LEVEL_ERROR "ERROR" "$message"
}

# Log warning message
log_warn() {
    local message="$1"
    _log $LOG_LEVEL_WARN "WARN" "$message"
}

# Log info message
log_info() {
    local message="$1"
    _log $LOG_LEVEL_INFO "INFO" "$message"
}

# Log debug message
log_debug() {
    local message="$1"
    _log $LOG_LEVEL_DEBUG "DEBUG" "$message"
}

# Log verbose message
log_verbose() {
    local message="$1"
    _log $LOG_LEVEL_VERBOSE "TRACE" "$message"
}

# Log error and exit
error_exit() {
    local message="$1"
    local code="${2:-1}"
    log_error "$message"
    exit "$code"
} 