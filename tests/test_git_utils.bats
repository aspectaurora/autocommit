#!/usr/bin/env bats

# Use newer Bash for associative arrays
BASH="/opt/homebrew/bin/bash"
export BASH

load '../lib/core/git_utils.sh'

setup() {
    # Create a temporary directory for test repository
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR" || exit 1
    
    # Initialize test repository
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create initial commit
    echo "test content" > test.txt
    git add test.txt
    git commit -m "Initial commit"
}

teardown() {
    # Clean up temporary directory
    rm -rf "$TEST_DIR"
}

@test "get_branch_name returns current branch" {
    result=$(get_branch_name)
    [ "$result" = "main" ]
}

@test "extract_ticket_number returns ticket from branch name" {
    git checkout -b feature/TEST-123
    result=$(extract_ticket_number "feature/TEST-123")
    [ "$result" = "TEST-123" ]
}

@test "is_git_repo returns success in git repository" {
    run is_git_repo
    [ "$status" -eq 0 ]
}

@test "is_git_repo returns failure outside git repository" {
    local non_git_dir
    non_git_dir="$(mktemp -d)"
    cd "$non_git_dir" || exit 1
    run is_git_repo
    [ "$status" -eq 1 ]
    rm -rf "$non_git_dir"
    cd "$TEST_DIR" || exit 1
}

@test "get_repo_root returns repository path" {
    local repo_path
    repo_path="$(cd "$TEST_DIR" && pwd -P)"
    result="$(cd "$TEST_DIR" && get_repo_root)"
    [ "$result" = "$repo_path" ]
}

@test "has_staged_changes detects staged changes" {
    echo "new content" > new.txt
    git add new.txt
    run has_staged_changes
    [ "$status" -eq 0 ]
}

@test "has_staged_changes detects no staged changes" {
    run has_staged_changes
    [ "$status" -eq 1 ]
}

@test "get_staged_changes returns diff of staged changes" {
    echo "new content" > new.txt
    git add new.txt
    result=$(get_staged_changes)
    [[ "$result" =~ "new content" ]]
}

@test "get_recent_commits returns specified number of commits" {
    # Create additional commits
    for i in {1..3}; do
        echo "content $i" > "file$i.txt"
        git add "file$i.txt"
        git commit -m "Commit $i"
    done
    
    result=$(get_recent_commits 2)
    count=$(echo "$result" | wc -l)
    [ "$count" -eq 2 ]
}

@test "classify_changes detects file types and operations" {
    # Add a new file
    echo "new content" > new.txt
    git add new.txt
    
    # Modify an existing file
    echo "modified content" > test.txt
    git add test.txt
    
    result=$(classify_changes)
    [[ "$result" =~ "Added: new.txt" ]]
    [[ "$result" =~ "Modified: test.txt" ]]
}

@test "create_commit creates commit with message" {
    echo "new content" > new.txt
    git add new.txt
    run create_commit "Test commit message"
    [ "$status" -eq 0 ]
    
    # Verify commit was created
    result=$(git log -1 --pretty=format:"%s")
    [ "$result" = "Test commit message" ]
} 