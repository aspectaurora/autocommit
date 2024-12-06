#!/usr/bin/env bash
#
# Autocommit - like having a butler for your git commits, only less British (c) Marc Fasel
# 
# Version: 1.2
# This script uses the sgpt command to generate a concise git commit message or Jira ticket based on staged changes or recent commits.
# It automatically stages and commits the changes with the generated message.
#
# Usage:
# autocommit [-c <context>] [-l <logfile>] [-j] [-n <number_of_commits>] [-m]
#
# Options:
# -c <context>  Add a context to the commit message (e.g., the issue number)
# -l <logfile>  Log the commit messages to a file
# -j            Generate a Jira ticket title and description instead of a commit message
# -p           Generate a Pull Request title and description instead of a commit message
# -n <number>   Number of recent commits to consider (if not provided, uses staged changes)
# -m           Message only, do not commit
#
# Examples:
# autocommit
# autocommit -c "Fixes issue #123"
# autocommit -c "Fixes issue #123" -l ~/logs/autocommit.log
# autocommit -j
# autocommit -p
# autocommit -n 10
# autocommit -m
#
# Dependencies:
# - sgpt
# - git
#   
# Installation:
# 1. Install sgpt:
#    $ pip install shell-gpt
# 2. Add this script to your shell profile (e.g. .bashrc, .zshrc):
#    source /path/to/autocommit.sh
# 3. Reload your shell profile:
#    $ source ~/.zshrc
# 4. Use the autocommit command in your git repositories:
#    $ autocommit
#
# Note: This script is a simple example and may need to be adapted to your specific requirements.
#   It is recommended to test it in a safe environment before using it in production.
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


# Function: autocommit
# Description: Generates a commit message or Jira ticket based on staged changes or recent commits.
function autocommit() {
    local context=""
    local logfile=""
    local generate_jira=false
    local generate_pr=false
    local message_only=false
    local num_commits=""
    local OPTIND opt

    while getopts "c:l:jn:mpM:vh" opt; do
        case $opt in
            v) echo "autocommit version $VERSION"; exit 0;;
            h) show_help; exit 0;;
            c) context="$OPTARG";;
            l) logfile="$OPTARG";;
            j) generate_jira=true;;
            n) num_commits="$OPTARG";;            
            m) message_only=true;;  # Set the flag when -m is used
            p) generate_pr=true;;
            M) model="$OPTARG";;
            \?) echo "Invalid option -$OPTARG" >&2; return 1;;
        esac
    done
    echo "Options: context=$context, logfile=$logfile, generate_jira=$generate_jira, num_commits=$num_commits, message_only=$message_only"

    if $generate_jira && $generate_pr; then
        echo "Error: Options -j and -p cannot be used together."
        exit 1
    fi

    shift $((OPTIND-1))

    local branch_name=$(get_branch_name)
    echo "Branch: $branch_name"
    
    local instructions
    local changes

    if [[ -n "$num_commits" ]]; then
        changes=$(git log -n "$num_commits" --pretty=format:"%h %s")
        echo "Analyzing $num_commits recent commits"        
    else
        changes=$(git diff --staged)
        echo "Analyzing staged changes"
    fi

    # Handle no changes
    if [[ -z "$changes" ]]; then
        echo "No changes to commit"
        return
    fi
            
    local role="You are Autocommit Assistant - like having a butler for your git commits, only less British (c) Marc Fasel"
    
    if [[ -n "$num_commits" ]]; then
        changes="Recent commits: $changes"
    else
        changes="Staged changes: $changes"
    fi

    if $generate_jira; then
        # local jira_instructions=$(cat prompts/jira_instructions.txt)
        local jira_instructions="$JIRA_INSTRUCTIONS"
        instructions="$role 
            \n\n
            $jira_instructions
            \n\n
            $changes"     
    elif $generate_pr; then
        # local pr_instructions=$(cat prompts/pr_instructions.txt)
        local pr_instructions="$PR_INSTRUCTIONS"
        instructions="$role 
            \n\n
            $pr_instructions
            \n\n
            - Use the current branch name for context: $branch_name.
            - Use the extracted Jira ticket number: $ticket_number (if available).
            \n\n
            $changes"
    else
        # local commit_instructions=$(cat prompts/commit_instructions.txt)
        local commit_instructions="$COMMIT_INSTRUCTIONS"
        instructions="$role            
            \n\n
            $commit_instructions
            \n\n
            - Use the current branch name for context: $branch_name.
            - Use the extracted Jira ticket number: $ticket_number (if available).
            \n\n
            $changes"
    fi
    
    model="${model:-$DEFAULT_MODEL}"

    local raw_message
    if [[ -z "$context" ]]; then
        raw_message=$(echo "$changes" | sgpt --model "$model" --no-cache "$instructions")
    else
        raw_message=$(echo "$changes" | sgpt --model "$model" --no-cache "$instructions \n\n **THE LATEST CONTEXT**: $context")
    fi
    
    if [ $? -ne 0 ] || [ -z "$raw_message" ]; then
        echo "Error: Failed to generate commit message using sgpt."
        return 1
    fi
            
    local message
    # Validate the raw commit message
    if ! $generate_jira && ! $generate_pr && ! validate_message "$raw_message" "$branch_name"; then
        echo "Raw message:"
        echo "$raw_message"
        echo "Raw message validation failed."
        
        # Optionally enforce consistency if validation fails
        message=$(enforce_consistency "$raw_message" "$branch_name" "$model")
    else
        message="$raw_message"
    fi

    # Handle empty commit messages
    if [[ -z "$message" ]]; then
        echo "Error: No commit message generated."
        return 1
    fi
    
    local datetime=$(date +"%Y-%m-%d %H:%M:%S")

    if $generate_jira; then
        echo "Generated Jira ticket:"
        echo "$message"
        if [[ -n "$logfile" ]]; then
            mkdir -p "$(dirname "$logfile")"
            echo "$datetime - Generated Jira ticket:" >> "$logfile"
            echo "$message" >> "$logfile"
        fi
    else
        if $generate_pr; then
            echo "Generated Pull Request:"
            echo "$message"
            if [[ -n "$logfile" ]]; then
                mkdir -p "$(dirname "$logfile")"
                echo "$datetime - Generated Pull Request:" >> "$logfile"
                echo "$message" >> "$logfile"
            fi
            return
        fi
        if [[ -n "$num_commits" ]]; then
            local successMessage="$datetime - Generated commit message based on recent commits:"
            echo "$successMessage"
            echo "$message"
            if [[ -n "$logfile" ]]; then
                mkdir -p "$(dirname "$logfile")"
                echo "$successMessage" >> "$logfile"
            fi
        else            
            if $message_only; then
                echo "$message"
                return
            fi
            local successMessage="$datetime - Commit successful: $message"
            local failMessage="$datetime - Commit failed"
            
            echo "Committing changes..."
            
            if git commit -m"$message"; then
                if [[ -n "$logfile" ]]; then
                    mkdir -p "$(dirname "$logfile")"
                    echo "$successMessage" >> "$logfile"
                else
                    echo "$successMessage"
                fi
            else
                if [[ -n "$logfile" ]]; then
                    mkdir -p "$(dirname "$logfile")"
                    echo "$failMessage" >> "$logfile"
                else
                    echo "$failMessage"
                fi
            fi
        fi
    fi
}

# If the script is called directly, execute the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    autocommit "$@"
fi
