#!/usr/bin/env bash
#
# Autocommit - A helper for automatically generating commit messages, Jira tickets, and PR descriptions using AI.
# Like having a butler for your git commits, only less British (c) Marc Fasel
# 
# Version: 1.3
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

VERSION="1.3"

# Resolve the real path of the script to handle symlinks
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Source required modules with error handling
for module in core/logger.sh core/config.sh git/utils.sh ai/prompts.sh; do
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
set_log_level $LOG_LEVEL_INFO

# Check if inside a Git repository
if ! is_git_repo; then
    error_exit "Not inside a Git repository." 2
fi

# Load configuration before checking dependencies
load_config

# Check if dependencies are installed
if ! command -v sgpt &> /dev/null; then
    error_exit "sgpt is not installed. Please install it using 'pip install shell-gpt'." 3
fi

if ! command -v git &> /dev/null; then
    error_exit "git is not installed. Please install it and try again." 4
fi

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
                echo "autocommit version $VERSION"
                exit 0
                ;;
            h) # help
                show_help
                exit 0
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
                        echo "autocommit version $VERSION"
                        exit 0
                        ;;
                    help)
                        show_help
                        exit 0
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