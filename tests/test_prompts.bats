#!/usr/bin/env bats

# Use newer Bash for associative arrays
BASH="/opt/homebrew/bin/bash"
export BASH

load '../lib/ai/prompts.sh'

setup() {
    # Create a temporary directory for test repository
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"
    
    # Initialize test repository
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create initial commit
    echo "test content" > test.txt
    git add test.txt
    git commit -m "Initial commit"
    
    # Mock sgpt command
    function sgpt() {
        if [[ "$*" =~ "error" ]]; then
            return 1
        fi
        if [[ "$*" =~ "--no-cache" ]]; then
            echo "FEAT:[TEST-123] Test commit message"
        else
            echo "FEAT:[TEST-123] Test commit message"
        fi
    }
    export -f sgpt
    
    # Set log level to debug for verbose tests
    CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG
    export CURRENT_LOG_LEVEL
}

teardown() {
    # Clean up temporary directory
    rm -rf "$TEST_DIR"
}

@test "validate_prompts detects all required prompts" {
    run validate_prompts
    [ "$status" -eq 0 ]
}

@test "validate_prompts fails when prompts are missing" {
    # Temporarily unset a required prompt
    local BACKUP_JIRA_INSTRUCTIONS="$JIRA_INSTRUCTIONS"
    unset JIRA_INSTRUCTIONS
    
    run validate_prompts
    [ "$status" -eq 1 ]
    [[ "$output" =~ "JIRA_INSTRUCTIONS" ]]
    
    # Restore the prompt
    JIRA_INSTRUCTIONS="$BACKUP_JIRA_INSTRUCTIONS"
}

@test "generate_message creates commit message" {
    # Create a staged change
    echo "new content" > new.txt
    git add new.txt
    
    run generate_message false false "" "" "test-model" false
    [ "$status" -eq 0 ]
    [[ "$output" =~ "FEAT:[TEST-123] Test commit message" ]]
}

@test "generate_message creates Jira ticket" {
    # Create a staged change
    echo "new content" > new.txt
    git add new.txt
    
    run generate_message true false "" "" "test-model" false
    [ "$status" -eq 0 ]
    [[ "$output" =~ "FEAT:[TEST-123] Test commit message" ]]
}

@test "generate_message creates PR description" {
    # Create a staged change
    echo "new content" > new.txt
    git add new.txt
    
    run generate_message false true "" "" "test-model" false
    [ "$status" -eq 0 ]
    [[ "$output" =~ "FEAT:[TEST-123] Test commit message" ]]
}

@test "generate_message handles error from sgpt" {
    # Create a staged change
    echo "new content" > new.txt
    git add new.txt
    
    # Mock sgpt to fail
    function sgpt() { return 1; }
    export -f sgpt
    
    run generate_message false false "" "error" "test-model" false
    [ "$status" -eq 1 ]
}

@test "validate_commit_message accepts valid messages" {
    run validate_commit_message "FEAT: Add new feature" "main" ""
    [ "$status" -eq 0 ]
    
    run validate_commit_message "BUGFIX:[TEST-123] Fix critical issue" "feature/TEST-123" "TEST-123"
    [ "$status" -eq 0 ]
}

@test "validate_commit_message rejects invalid messages" {
    # Test lowercase start
    run validate_commit_message "feat: lowercase start" "main" ""
    [ "$status" -eq 1 ]
    
    # Test unwanted phrases
    run validate_commit_message "Based on the changes, this commit adds a feature" "main" ""
    [ "$status" -eq 1 ]
}

@test "enforce_consistency refines commit messages" {
    result=$(enforce_consistency "add new feature" "feature/TEST-123" "test-model" "TEST-123")
    [[ "$result" =~ "FEAT:[TEST-123] Test commit message" ]]
}

@test "generate_message with recent commits" {
    # Create some test commits
    for i in {1..3}; do
        echo "content $i" > "file$i.txt"
        git add "file$i.txt"
        git commit -m "Commit $i"
    done
    
    run generate_message false false "2" "" "test-model" false
    [ "$status" -eq 0 ]
    [[ "$output" =~ "FEAT:[TEST-123] Test commit message" ]]
}

@test "generate_message with context" {
    # Create a staged change
    echo "new content" > new.txt
    git add new.txt
    
    run generate_message false false "" "Test context" "test-model" false
    [ "$status" -eq 0 ]
    [[ "$output" =~ "FEAT:[TEST-123] Test commit message" ]]
}

@test "generate_message with verbose logging" {
    # Create a staged change
    echo "new content" > new.txt
    git add new.txt
    
    # Set log level to debug
    CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG
    export CURRENT_LOG_LEVEL
    
    run generate_message false false "" "" "test-model" true
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DEBUG: Generating message with parameters" ]]
    [[ "$output" =~ "FEAT:[TEST-123] Test commit message" ]]
} 