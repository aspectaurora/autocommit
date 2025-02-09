#!/usr/bin/env bash
# lib/git/utils.sh
# Git utility functions for autocommit

# Source logger
source "$(dirname "${BASH_SOURCE[0]}")/../core/logger.sh"

# Get current branch name
# No args
# Returns: Current branch name or exits with error
function get_branch_name() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ $? -ne 0 || -z "$branch" ]]; then
        log_error "Unable to retrieve the current Git branch name."
        return 1
    fi
    echo "$branch"
}

# Extract Jira ticket number from branch name
# No args
# Returns: Ticket number or empty string if not found
function extract_ticket_number() {
    local branch_name
    branch_name=$(get_branch_name) || return 1
    
    if [[ $branch_name =~ ([A-Z]+-[0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
}

# Check if inside a Git repository
# No args
# Returns: 0 if in repo, 1 if not
function is_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not inside a Git repository."
        return 1
    fi
    return 0
}

# Get repository root directory
# No args
# Returns: Repository root path or empty if not in repo
function get_repo_root() {
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ $? -ne 0 || -z "$repo_root" ]]; then
        log_error "Could not determine repository root."
        return 1
    fi
    echo "$repo_root"
}

# Check if there are staged changes
# No args
# Returns: 0 if there are staged changes, 1 if not
function has_staged_changes() {
    if ! git diff --cached --quiet; then
        return 0
    fi
    log_error "No changes staged for commit. Use 'git add' to stage changes."
    return 1
}

# Get staged changes diff
# No args
# Returns: Git diff of staged changes
function get_staged_changes() {
    git diff --staged
}

# Get recent commits
# Args:
#   $1 - Number of commits to retrieve
# Returns: Git log of recent commits
function get_recent_commits() {
    local num_commits="$1"
    git log -n "$num_commits" --pretty=format:"%h %s"
}

# Classify changes in staged files
# Args:
#   $1 - List of files (newline separated)
# Returns: Classification of changes
function classify_changes() {
    local files="$1"
    local classification=""
    local file_types=()
    local file_operations=()
    
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        
        # Determine file type
        local ext="${file##*.}"
        [[ "$ext" != "$file" ]] && file_types+=("$ext")
        
        # Determine operation
        if [[ ! -f "$file" ]]; then
            file_operations+=("deleted")
        elif git diff --cached --name-only --diff-filter=A "$file" | grep -q .; then
            file_operations+=("added")
        else
            file_operations+=("modified")
        fi
    done <<< "$files"
    
    # Summarize file types
    if [[ ${#file_types[@]} -gt 0 ]]; then
        classification+="File types: ${file_types[*]}\n"
    fi
    
    # Summarize operations
    if [[ ${#file_operations[@]} -gt 0 ]]; then
        classification+="Operations: ${file_operations[*]}"
    fi
    
    echo -e "$classification"
}

# Summarize diffs for staged files
# Args:
#   $1 - List of files (newline separated)
# Returns: Summary of changes
function summarize_diffs() {
    local files="$1"
    local summary=""
    
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        
        summary+="File: $file\n"
        summary+="$(git diff --cached --stat "$file")\n"
        summary+="$(git diff --cached --unified=1 "$file")\n\n"
    done <<< "$files"
    
    echo -e "$summary"
}

# Create a commit with the given message
# Args:
#   $1 - Commit message
# Returns: 0 if successful, 1 if failed
function create_commit() {
    local message="$1"
    
    if ! has_staged_changes; then
        return 1
    fi
    
    if ! git commit -m"$message"; then
        log_error "Failed to create commit."
        return 1
    fi
    
    log_info "Successfully created commit: $message"
    return 0
} 