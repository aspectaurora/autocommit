#!/usr/bin/env bash
#
# Autocommit - A helper for automatically generating commit messages, Jira tickets, and PR descriptions using AI.
# Like having a butler for your git commits, only less British (c) Marc Fasel
# 
# Version: 1.2
#
# This script uses the sgpt command to generate a concise git commit message or Jira ticket based on staged changes or recent commits.
# It automatically stages and commits the changes with the generated message.
#
# Usage:
#   autocommit [-c <context>] [-l <logfile>] [-j] [-n <number_of_commits>] [-m]
#
# Options:
#   -c <context>   Add context (e.g., issue number) to the commit message.
#   -l <logfile>   Log the commit messages to a file.
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
#   autocommit -c "Fixes issue #123" -l ~/logs/autocommit.log
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

VERSION="1.2"
DEFAULT_MODEL="gpt-4o-mini"  # This can be overridden by .autocommitrc

# Resolve the real path of the script to handle symlinks
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

source "$SCRIPT_DIR/lib/prompts.sh"
source "$SCRIPT_DIR/lib/utils.sh"

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
    local logfile=""
    local generate_jira=false
    local generate_pr=false
    local message_only=false
    local num_commits=""
    local OPTIND opt
    local model=""
    local verbose=false

    # Parse options
    while getopts "c:l:jn:mpM:vVh-:" opt; do
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
            l) logfile="$OPTARG";;
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

    $verbose && echo "[Verbose] Options parsed: context=$context, logfile=$logfile, generate_jira=$generate_jira, generate_pr=$generate_pr, num_commits=$num_commits, message_only=$message_only, model=$model"

    # Normal mode
    $verbose && echo "Normal mode. Generating message based on provided flags..."
    if $generate_jira; then
        echo "Jira mode enabled. Generating Jira ticket..."
        local jira_message
        jira_message=$(generate_message true false "$num_commits" "$context" "$model" "$verbose")                                    
        [ $? -eq 0 ] || return 1
        echo "Generated Jira ticket suggestion:"
        echo "$jira_message"  
        if [[ -n "$logfile" ]]; then
            mkdir -p "$(dirname "$logfile")"
            echo "$datetime - Generated Jira ticket:" >> "$logfile"
            echo "$jira_message" >> "$logfile"
        fi
        $verbose && echo "[Verbose] Jira ticket generation completed."
        return 0
    elif $generate_pr; then
        echo "PR mode enabled. Generating Pull Request message..."
        local pr_message
        pr_message=$(generate_message false true "$num_commits" "$context" "$model" "$verbose")
        [ $? -eq 0 ] || return 1
        echo "Generated Pull Request suggestion:"
        echo "$pr_message"
        if [[ -n "$logfile" ]]; then
            mkdir -p "$(dirname "$logfile")"
            echo "$datetime - Generated Pull Request:" >> "$logfile"
            echo "$pr_message" >> "$logfile"
        fi
        $verbose && echo "[Verbose] Pull Request generation completed."
        return 0
    else
        echo "Commit message mode. Generating commit message..."
        local commit_message
        commit_message=$(generate_message false false "$num_commits" "$context" "$model" "$verbose")
        [ $? -eq 0 ] || return 1

        $verbose && echo "[Verbose] Commit message generated:\n$commit_message"

        if [[ -n "$num_commits" ]]; then
            local successMessage="$datetime - Generated commit message based on recent commits:"
            echo "$successMessage"
            echo "$commit_message"
            if [[ -n "$logfile" ]]; then
                mkdir -p "$(dirname "$logfile")"
                echo "$successMessage" >> "$logfile"
            fi
            $verbose && echo "[Verbose] Commit message based on recent commits printed."
            return 0
        else            
            if $message_only; then
                echo "Message-only mode enabled. Printing commit message:"
                echo "$commit_message"
                return 0
            fi
            local successMessage="$datetime - Commit successful: $commit_message"
            local failMessage="$datetime - Commit failed"
            
            $verbose && echo "[Verbose] Attempting to commit changes with the generated commit message..."
            
            if git commit -m"$commit_message"; then
                if [[ -n "$logfile" ]]; then
                    mkdir -p "$(dirname "$logfile")"
                    echo "$successMessage" >> "$logfile"
                else
                    echo "$successMessage"
                fi
                $verbose && echo "[Verbose] Commit succeeded."
            else
                if [[ -n "$logfile" ]]; then
                    mkdir -p "$(dirname "$logfile")"
                    echo "$failMessage" >> "$logfile"
                else
                    echo "$failMessage"
                fi
                $verbose && echo "[Verbose] Commit failed."
            fi
        fi
    fi
    
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    autocommit "$@"
fi