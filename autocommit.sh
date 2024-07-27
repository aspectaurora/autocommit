#!/bin/bash
#
# Autocommit - like having a butler for your git commits, only less British (c) Marc Fasel
# 
# This script uses the sgpt command to generate a concise git commit message or Jira ticket based on staged changes or recent commits.
# It automatically stages and commits the changes with the generated message.
#
# Usage:
# autocommit [-c <context>] [-l <logfile>] [-j] [-n <number_of_commits>]
#
# Options:
# -c <context>  Add a context to the commit message (e.g., the issue number)
# -l <logfile>  Log the commit messages to a file
# -j            Generate a Jira ticket title and description instead of a commit message
# -n <number>   Number of recent commits to consider (if not provided, uses staged changes)
#
# Examples:
# autocommit
# autocommit -c "Fixes issue #123"
# autocommit -c "Fixes issue #123" -l ~/logs/autocommit.log
# autocommit -j
# autocommit -n 10
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

# Check if dependencies are installed
if ! command -v sgpt &> /dev/null; then
    echo "Error: sgpt is not installed. Please install it using 'pip install shell-gpt'."
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install it and try again."
    exit 1
fi

get_branch_name() {
    git rev-parse --abbrev-ref HEAD
}

autocommit() {
    local context=""
    local logfile=""
    local generate_jira=false
    local num_commits=""
    local OPTIND opt

    while getopts "c:l:jn:" opt; do
        case $opt in
            c) context="$OPTARG";;
            l) logfile="$OPTARG";;
            j) generate_jira=true;;
            n) num_commits="$OPTARG";;
            \?) echo "Invalid option -$OPTARG" >&2; return 1;;
        esac
    done

    shift $((OPTIND-1))

    local branch_name=$(get_branch_name)
    echo "Branch: $branch_name"

    local message
    local instructions
    local changes

    if [[ -n "$num_commits" ]]; then
        changes=$(git log -n "$num_commits" --pretty=format:"%h %s")
        echo "Analyzing $num_commits recent commits"        
    else
        changes=$(git diff --staged)
        echo "Analyzing staged changes"
    fi
    local generate_jira_instructions="generate a Jira ticket title and description. \
                Think retropectively as this ticket would be created way before the changes done. \
                Stay high-level and combine smaller changes to overarching topics. Skip describing any reformatting changes. \
                Format the output as follows: \
                Title: [A concise title for the Jira ticket] \
                Description: [A detailed description of the changes and their impact]" 

    if $generate_jira; then
        if [[ -n "$num_commits" ]]; then            
            instructions="Based on the following recent git commits, $generate_jira_instructions \
                Recent commits: $changes"            
        else            
            instructions="Based on the following git diff, $generate_jira_instructions"
        fi
    else
        if [[ -n "$num_commits" ]]; then            
            instructions="Generate a concise git commit message that summarizes the key changes from these recent commits. \
                Use the format 'REFACTOR|FEAT|CHORES|BUGFIX|ETC:[ABD-123] A commit message' \
                at the start of the message, choosing the most appropriate category. \
                Current branch: $branch_name \
                Recent commits: $changes"
        else
            instructions="Generate a concise git commit message that summarizes the key changes. \
                Stay high-level and combine smaller changes to overarching topics. Skip describing any reformatting changes. \
                Ignore the boring reformatting stuff. Use the format 'REFACTOR|FEAT|CHORES|BUGFIX|ETC:[ABD-123] A commit message' \
                at the start of the message, choosing the most appropriate category. \
                Current branch: $branch_name"
        fi
    fi

    if [[ -z "$context" ]]; then
        message=$(echo "$changes" | sgpt --model gpt-4o-mini "$instructions")
    else
        message=$(echo "$changes" | sgpt --model gpt-4o-mini "$instructions Context: $context")
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
        if [[ -n "$num_commits" ]]; then
            local successMessage="$datetime - Generated commit message based on recent commits: $message"
            echo "$successMessage"
            if [[ -n "$logfile" ]]; then
                mkdir -p "$(dirname "$logfile")"
                echo "$successMessage" >> "$logfile"
            fi
        else
            local successMessage="$datetime - Commit successful: $message"
            local failMessage="$datetime - Commit failed"

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
