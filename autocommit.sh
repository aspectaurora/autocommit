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

VERSION="1.3"
DEFAULT_MODEL="gpt-4o-mini"  # This can be overridden by .autocommitrc

# Resolve the real path of the script to handle symlinks
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Source required files with error handling
if ! source "$SCRIPT_DIR/lib/prompts.sh"; then
    echo "Error: Failed to load prompts.sh"
    exit 1
fi

if ! source "$SCRIPT_DIR/lib/utils.sh"; then
    echo "Error: Failed to load utils.sh"
    exit 1
fi

# Validate that required prompts are available
if ! validate_prompts; then
    exit 1
fi

# Check if inside a Git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not inside a Git repository."
    exit 1
fi

# Load configuration before checking dependencies so config can specify alternative paths or models
load_config

# Check if dependencies are installed
if ! command -v sgpt &> /dev/null; then
    echo "Error: sgpt is not installed. Please install it using 'pip install shell-gpt'."
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install it and try again."
    exit 1
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
            V) verbose=true;;
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
                        ;;
                    *)
                        echo "Invalid option --${OPTARG}"
                        exit 1
                        ;;
                esac
                ;;
            \?)
                echo "Invalid option -$OPTARG" >&2
                return 1
                ;;
        esac
    done
    shift $((OPTIND-1))

    model="${model:-$DEFAULT_MODEL}"

    if $generate_jira && $generate_pr; then
        echo "Error: Options -j and -p cannot be used together."
        exit 1
    fi

    local datetime=$(date +"%Y-%m-%d %H:%M:%S")

    $verbose && echo "[Verbose] Options parsed: context=$context, generate_jira=$generate_jira, generate_pr=$generate_pr, num_commits=$num_commits, message_only=$message_only, model=$model"

    # Validate num_commits if provided
    if [[ -n "$num_commits" ]]; then
        if ! [[ "$num_commits" =~ ^[0-9]+$ ]]; then
            echo "Error: Number of commits must be a positive integer"
            return 1
        fi
        if ((num_commits < 1)); then
            echo "Error: Number of commits must be greater than 0"
            return 1
        fi
    else
        # Check for staged changes when not analyzing previous commits
        if ! git diff --cached --quiet; then
            $verbose && echo "[Verbose] Found staged changes."
        else
            echo "Error: No changes staged for commit. Use 'git add' to stage changes."
            return 1
        fi
    fi

    # Normal mode
    $verbose && echo "Normal mode. Generating message based on provided flags..."
    if $generate_jira; then
        echo "Jira mode enabled. Generating Jira ticket..."
        local jira_message
        jira_message=$(generate_message true false "$num_commits" "$context" "$model" "$verbose")                                    
        [ $? -eq 0 ] || return 1
        echo "____________________________________ Jira Ticket Description ____________________________________"         
        echo "$jira_message"  
        $verbose && echo "[Verbose] Jira ticket generation completed."
        return 0
    elif $generate_pr; then
        echo "PR mode enabled. Generating Pull Request message..."
        local pr_message
        pr_message=$(generate_message false true "$num_commits" "$context" "$model" "$verbose")
        [ $? -eq 0 ] || return 1
        echo "____________________________________ Pull Request Description ____________________________________"         
        echo "$pr_message"
        $verbose && echo "[Verbose] Pull Request generation completed."
        return 0
    else
        echo "Commit message mode. Generating commit message..."
        local commit_message
        commit_message=$(generate_message false false "$num_commits" "$context" "$model" "$verbose")
        [ $? -eq 0 ] || return 1

        echo "____________________________________ Commit Message ____________________________________" 
        echo "$commit_message"

        if [[ -n "$num_commits" ]]; then
            echo "Generated commit message based on recent commits:"
            echo "$commit_message"
            $verbose && echo "[Verbose] Commit message based on recent commits printed."
            return 0
        else            
            if $message_only; then
                echo "$commit_message"
                return 0
            fi
            
            $verbose && echo "[Verbose] Attempting to commit changes with the generated commit message..."
            
            if git commit -m"$commit_message"; then
                echo "Commit successful: $commit_message"
                $verbose && echo "[Verbose] Commit succeeded."
            else
                echo "Commit failed"
                $verbose && echo "[Verbose] Commit failed."
                return 1
            fi
        fi
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    autocommit "$@"
fi