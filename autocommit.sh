#!/usr/bin/env bash
#
# Autocommit - A helper for automatically generating commit messages, Jira tickets, and PR descriptions using AI.
# Like having a butler for your git commits, only less British (c) Marc Fasel
# 
# Version: 1.4
#
# This script uses the sgpt command to generate a concise git commit message or Jira ticket based on staged changes or recent commits.
# It automatically stages and commits the changes with the generated message.
#
# Usage:
#   autocommit [-c <context>] [-j] [-n <number_of_commits>] [-m]
#
# Options:
#   -c <context>   Add context (e.g., issue number) to the commit message.
#   -j             Generate a Jira ticket instead of a commit message.
#   -p             Generate a Pull Request message instead of a commit message.
#   -n <number>     Analyze the last <number> commits instead of staged changes.
#   -m             Print the generated message only, do not commit.
#   -M <model>      Specify the AI model for sgpt (overrides DEFAULT_MODEL in .autocommitrc).
#   -v, --version   Display version information.
#   -h, --help      Show this help message.
#
# Examples:
#   autocommit
#   autocommit -c "Fixes issue #123"
#   autocommit -j
#   autocommit -p
#   autocommit -n 10
#   autocommit -m
#
# Dependencies:
# - sgpt
# - git
#   
# Installation:
#   See README.md for detailed instructions and usage examples.
#
# Note:
#   This script looks for configuration in either the project's root directory (.autocommitrc)
#   or the user's home directory (~/.autocommitrc). Default settings are used if none found.
#
#   This script is a simple example and may need to be adapted to your specific requirements.
#   Test in a safe environment before using in production.
#   Use at your own risk.
#
# License: MIT
# 
# Inspired by:
# https://medium.com/@marc_fasel/smash-your-git-commit-messages-like-a-champ-using-chatgpt-0cbe8ea7b3df

# Ensure we're running with bash
if [ -z "${BASH_VERSION:-}" ]; then
    echo "Error: This script requires bash to run."
    echo "Please run with: bash $0"
    exit 1
fi

# Check bash version (we need 4.0+ for associative arrays)
if ((BASH_VERSINFO[0] < 4)); then
    echo "Error: This script requires bash version 4.0 or higher."
    echo "Current version: $BASH_VERSION"
    echo "Please upgrade your bash installation."
    exit 1
fi

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# Script version
VERSION_FILE="$(dirname "${BASH_SOURCE[0]}")/VERSION"
if [[ -f "$VERSION_FILE" ]]; then
    VERSION="$(cat "$VERSION_FILE")"
else
    VERSION="2.0.0"  # Fallback version if file not found
fi

# Function to display version
show_version() {
    echo "autocommit version $VERSION"
    exit 0
}

# Function to cleanup on exit
cleanup() {
    local exit_code=$?
    # Add any cleanup tasks here
    exit $exit_code
}
trap cleanup EXIT

# Function to handle errors
handle_error() {
    local exit_code=$?
    local line_no=$1
    echo "Error occurred in script $0 at line $line_no with exit code $exit_code"
    exit $exit_code
}
trap 'handle_error ${LINENO}' ERR

# Resolve the real path of the script to handle symlinks
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Source required modules with error handling
declare -a REQUIRED_MODULES=(
    "core/logger.sh"
    "core/config.sh"
    "git/utils.sh"
    "ai/prompts.sh"
)

for module in "${REQUIRED_MODULES[@]}"; do
    module_path="$SCRIPT_DIR/lib/$module"
    if [[ ! -f "$module_path" ]]; then
        echo "Error: Required module not found: $module"
        echo "Expected path: $module_path"
        exit 1
    fi
    if ! source "$module_path"; then
        echo "Error: Failed to load $module"
        exit 1
    fi
done

# Set initial log level
set_log_level "${LOG_LEVEL_INFO:-2}"

# Check if inside a Git repository
if ! is_git_repo; then
    error_exit "Not inside a Git repository." 2
fi

# Load configuration before checking dependencies
load_config

# Display version information
log_info "autocommit version $VERSION"

# Check if dependencies are installed
for cmd in sgpt git; do
    if ! command -v "$cmd" &> /dev/null; then
        case "$cmd" in
            sgpt)
                error_exit "sgpt is not installed. Please install it using 'pip install shell-gpt'." 3
                ;;
            git)
                error_exit "git is not installed. Please install it and try again." 4
                ;;
        esac
    fi
done

# Function to show help
show_help() {
    cat << EOF
Autocommit - A helper for automatically generating commit messages using AI.
Version: $VERSION

Usage:
    autocommit [-c <context>] [-j] [-n <number_of_commits>] [-m]

Options:
    -c <context>   Add context (e.g., issue number) to the commit message.
    -j             Generate a Jira ticket instead of a commit message.
    -p             Generate a Pull Request message instead of a commit message.
    -n <number>    Analyze the last <number> commits instead of staged changes.
    -m             Print the generated message only, do not commit.
    -M <model>     Specify the AI model for sgpt (overrides DEFAULT_MODEL in .autocommitrc).
    -v, --version  Display version information.
    -h, --help     Show this help message.
    -V, --verbose  Enable verbose logging.

Examples:
    autocommit
    autocommit -c "Fixes issue #123"
    autocommit -j
    autocommit -p
    autocommit -n 10
    autocommit -m
EOF
    exit 0
}

function autocommit() {
    local context=""
    local generate_jira=false
    local generate_pr=false
    local message_only=false
    local num_commits=""
    local OPTIND opt
    local model=""
    local verbose=false

    # Parse options
    while getopts "c:jn:mpM:vVh-:" opt; do
        case $opt in
            v) # version
                show_version
                ;;
            h) # help
                show_help
                ;;
            c) context="$OPTARG";;
            j) generate_jira=true;;
            n) num_commits="$OPTARG";;
            m) message_only=true;;
            p) generate_pr=true;;
            M) model="$OPTARG";;
            V) 
                verbose=true
                set_log_level $LOG_LEVEL_VERBOSE
                ;;
            -) # Long options
                case "${OPTARG}" in
                    version)
                        show_version
                        ;;
                    help)
                        show_help
                        ;;
                    verbose)
                        verbose=true
                        set_log_level $LOG_LEVEL_VERBOSE
                        ;;
                    *)
                        error_exit "Invalid option --${OPTARG}" 5
                        ;;
                esac
                ;;
            \?)
                error_exit "Invalid option -$OPTARG" 5
                ;;
        esac
    done
    shift $((OPTIND-1))

    # Get model from config or argument
    model="${model:-$(get_config DEFAULT_MODEL "$DEFAULT_MODEL")}"

    if $generate_jira && $generate_pr; then
        error_exit "Options -j and -p cannot be used together." 6
    fi

    log_debug "Options parsed: context=$context, generate_jira=$generate_jira, generate_pr=$generate_pr, num_commits=$num_commits, message_only=$message_only, model=$model"

    # Validate num_commits if provided
    if [[ -n "$num_commits" ]]; then
        if ! [[ "$num_commits" =~ ^[0-9]+$ ]]; then
            error_exit "Number of commits must be a positive integer" 7
        fi
        if ((num_commits < 1)); then
            error_exit "Number of commits must be greater than 0" 8
        fi
    else
        # Check for staged changes when not analyzing previous commits
        if ! has_staged_changes; then
            error_exit "No changes staged for commit. Use 'git add' to stage changes." 9
        fi
    fi

    # Generate message based on provided flags
    log_info "Generating message based on provided flags..."
    local message
    message=$(generate_message "$generate_jira" "$generate_pr" "$num_commits" "$context" "$model" "$verbose")
    if [[ $? -ne 0 || -z "$message" ]]; then
        error_exit "Failed to generate message." 10
    fi

    if $generate_jira; then
        log_info "Generated Jira ticket description:"
        echo "____________________________________ Jira Ticket Description ____________________________________"
        echo "$message"
        return 0
    elif $generate_pr; then
        log_info "Generated Pull Request description:"
        echo "____________________________________ Pull Request Description ____________________________________"
        echo "$message"
        return 0
    else
        log_info "Generated commit message:"
        echo "____________________________________ Commit Message ____________________________________"
        echo "$message"

        if [[ -n "$num_commits" ]]; then
            return 0
        fi

        if $message_only; then
            return 0
        fi

        log_debug "Attempting to commit changes with the generated commit message..."
        if create_commit "$message"; then
            log_info "Commit successful: $message"
        else
            error_exit "Commit failed" 11
        fi
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    autocommit "$@"
fi