#!/usr/bin/env bats

# Use newer Bash for associative arrays
BASH="/opt/homebrew/bin/bash"
export BASH

load '../lib/core/config.sh'

setup() {
    # Create a temporary directory for test files
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR" || exit 1
    
    # Create a test repository
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Save original HOME
    ORIGINAL_HOME="$HOME"
    # Set HOME to test directory for config file testing
    HOME="$TEST_DIR"
    export HOME
    
    # Reset config variables to defaults
    unset model verbose
    model="$DEFAULT_MODEL"
    verbose="$DEFAULT_VERBOSE"
    export model verbose
    
    # Set log level to debug for tests
    CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG
    export CURRENT_LOG_LEVEL
}

teardown() {
    # Restore original HOME
    HOME="$ORIGINAL_HOME"
    export HOME
    # Clean up temporary directory
    rm -rf "$TEST_DIR"
    # Unset config variables
    unset model verbose
}

@test "load_config loads default values when no config file exists" {
    run load_config
    [ "$status" -eq 0 ]
    
    run bash -c "source $BATS_TEST_DIRNAME/../lib/core/config.sh && get_config model"
    [ "$status" -eq 0 ]
    [ "$output" = "$DEFAULT_MODEL" ]
    
    run bash -c "source $BATS_TEST_DIRNAME/../lib/core/config.sh && get_config verbose"
    [ "$status" -eq 0 ]
    [ "$output" = "$DEFAULT_VERBOSE" ]
}

@test "load_config loads values from repository config" {
    # Create repository config
    cat > .autocommitrc << 'EOF'
model=test-model
verbose=true
EOF
    
    run load_config
    [ "$status" -eq 0 ]
    
    run bash -c "source $BATS_TEST_DIRNAME/../lib/core/config.sh && get_config model"
    [ "$status" -eq 0 ]
    [ "$output" = "test-model" ]
    
    run bash -c "source $BATS_TEST_DIRNAME/../lib/core/config.sh && get_config verbose"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "load_config loads values from home directory config" {
    # Create home directory config
    cat > "$HOME/.autocommitrc" << 'EOF'
model=home-model
verbose=true
EOF
    
    run load_config
    [ "$status" -eq 0 ]
    
    run bash -c "source $BATS_TEST_DIRNAME/../lib/core/config.sh && get_config model"
    [ "$status" -eq 0 ]
    [ "$output" = "home-model" ]
}

@test "load_config prefers repository config over home config" {
    # Create home directory config
    cat > "$HOME/.autocommitrc" << 'EOF'
model=home-model
verbose=false
EOF
    
    # Create repository config
    cat > .autocommitrc << 'EOF'
model=repo-model
verbose=true
EOF
    
    run load_config
    [ "$status" -eq 0 ]
    
    run bash -c "source $BATS_TEST_DIRNAME/../lib/core/config.sh && get_config model"
    [ "$status" -eq 0 ]
    [ "$output" = "repo-model" ]
}

@test "load_config validates configuration values" {
    # Create config with invalid values
    cat > .autocommitrc << 'EOF'
model=
verbose=invalid
EOF
    
    run load_config
    [ "$status" -eq 1 ]
}

@test "get_config returns default value when config not set" {
    run bash -c "source $BATS_TEST_DIRNAME/../lib/core/config.sh && get_config nonexistent default-value"
    [ "$status" -eq 0 ]
    [ "$output" = "default-value" ]
}

@test "get_config returns config value when set" {
    # Set a test config value in the config file
    cat > .autocommitrc << 'EOF'
model=test-value
verbose=true
EOF
    
    run bash -c "source $BATS_TEST_DIRNAME/../lib/core/config.sh && get_config model"
    [ "$status" -eq 0 ]
    [ "$output" = "test-value" ]
}

@test "_validate_config_value validates string values" {
    run _validate_config_value "model" "test-string"
    [ "$status" -eq 0 ]
    
    run _validate_config_value "model" ""
    [ "$status" -eq 1 ]
}

@test "_validate_config_value validates boolean values" {
    run _validate_config_value "verbose" "true"
    [ "$status" -eq 0 ]
    
    run _validate_config_value "verbose" "false"
    [ "$status" -eq 0 ]
    
    run _validate_config_value "verbose" "invalid"
    [ "$status" -eq 1 ]
} 