#!/usr/bin/env bats

# Use newer Bash for associative arrays
BASH="/opt/homebrew/bin/bash"
export BASH

load '../lib/core/logger.sh'

setup() {
    # Create a temporary directory for test output
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"
    
    # Reset log level to default
    CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO
    export CURRENT_LOG_LEVEL
}

teardown() {
    # Clean up temporary directory
    rm -rf "$TEST_DIR"
}

@test "set_log_level sets valid log levels" {
    for level in {0..4}; do
        set_log_level $level
        [ "$?" -eq 0 ]
        [ "$CURRENT_LOG_LEVEL" -eq $level ]
    done
}

@test "set_log_level rejects invalid log levels" {
    run set_log_level 5
    [ "$status" -eq 1 ]
    
    run set_log_level -1
    [ "$status" -eq 1 ]
    
    run set_log_level "invalid"
    [ "$status" -eq 1 ]
}

@test "log_error outputs error messages" {
    set_log_level $LOG_LEVEL_ERROR
    
    run log_error "Test error message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ERROR: Test error message" ]]
}

@test "log_warn outputs warning messages at appropriate levels" {
    set_log_level $LOG_LEVEL_WARN
    
    run log_warn "Test warning message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "WARN: Test warning message" ]]
    
    set_log_level $LOG_LEVEL_ERROR
    run log_warn "Test warning message"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "log_info outputs info messages at appropriate levels" {
    set_log_level $LOG_LEVEL_INFO
    
    run log_info "Test info message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "INFO: Test info message" ]]
    
    set_log_level $LOG_LEVEL_ERROR
    run log_info "Test info message"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "log_debug outputs debug messages at appropriate levels" {
    set_log_level $LOG_LEVEL_DEBUG
    
    run log_debug "Test debug message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DEBUG: Test debug message" ]]
    
    set_log_level $LOG_LEVEL_INFO
    run log_debug "Test debug message"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "log_verbose outputs verbose messages at appropriate levels" {
    set_log_level $LOG_LEVEL_VERBOSE
    
    run log_verbose "Test verbose message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "TRACE: Test verbose message" ]]
    
    set_log_level $LOG_LEVEL_DEBUG
    run log_verbose "Test verbose message"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "error_exit logs error and exits with code" {
    run error_exit "Test error" 42
    [ "$status" -eq 42 ]
    [[ "$output" =~ "ERROR: Test error" ]]
}

@test "error_exit uses default exit code" {
    run error_exit "Test error"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "ERROR: Test error" ]]
}

@test "log messages include timestamps" {
    set_log_level $LOG_LEVEL_INFO
    
    run log_info "Test message"
    [[ "$output" =~ "[$(date +%Y)" ]]
}

@test "log messages respect log level hierarchy" {
    # Set to INFO level
    set_log_level $LOG_LEVEL_INFO
    
    # Error (0) should show
    run log_error "Error message"
    [[ "$output" =~ "Error message" ]]
    
    # Warning (1) should show
    run log_warn "Warning message"
    [[ "$output" =~ "Warning message" ]]
    
    # Info (2) should show
    run log_info "Info message"
    [[ "$output" =~ "Info message" ]]
    
    # Debug (3) should not show
    run log_debug "Debug message"
    [ -z "$output" ]
    
    # Verbose (4) should not show
    run log_verbose "Verbose message"
    [ -z "$output" ]
} 