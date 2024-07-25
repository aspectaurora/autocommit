#!/bin/bash
#
# Autocommit - like having a butler for your git commits, only less British (c) Marc Fasel
# 
# This script uses the sgpt command to generate a concise git commit message that summarizes the key changes.
# It automatically stages and commits the changes with the generated message.
#
# Usage:
# autocommit [-c <context>] [-l <logfile>] [-j]
#
# Options:
# -c <context>  Add a context to the commit message (e.g., the issue number)
# -l <logfile>  Log the commit messages to a file
# -j            Generate a Jira ticket title and description instead of a commit message
#
# Examples:
# autocommit
# autocommit -c "Fixes issue #123"
# autocommit -c "Fixes issue #123" -l ~/logs/autocommit.log
# autocommit -j
#
# Dependencies:
# - sgpt
# - git
#   
# Installation:
# 1. Install sgpt:
#    $ pip install shell-gpt
# 2. Add this script to your shell profile (e.g. .bashrc, .zshrc):
#    echo "source /path/to/autocommit.sh" >> ~/.bashrc
#    echo "source /path/to/autocommit.sh" >> ~/.zshrc
# 3. Reload your shell profile:
#    $ source ~/.bashrc
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
    local OPTIND opt

    while getopts "c:l:j" opt; do
        case $opt in
            c) context="$OPTARG";;
            l) logfile="$OPTARG";;
            j) generate_jira=true;;
            \?) echo "Invalid option -$OPTARG" >&2; return 1;;
        esac
    done

    shift $((OPTIND-1))

    local branch_name=$(get_branch_name)
    echo "Branch: $branch_name"

    local message
    local instructions

    if $generate_jira; then
        instructions="Based on the following git diff, generate a Jira ticket title and description. \
            Think retropectively as this ticket would be created way before the changes done. \
            DoD section is welcomed but not required. \
            Format the output as follows: \
            Title: [A concise title for the Jira ticket] \
            Description: [A detailed description of the changes to be done and their impact]"
    else
        instructions="Generate a concise git commit message that summarizes the key changes. \
            Ignore the boring reformatting stuff. Use the format 'REFACTOR|FEAT|CHORES|BUGFIX|ETC:[ABD-123] A commit message' \
            at the start of the message, choosing the most appropriate category. \
            Current branch: $branch_name"
    fi

    if [[ -z "$context" ]]; then
        message=$(git diff --staged | sgpt --model gpt-4o-mini "$instructions")
    else
        message=$(git diff --staged | sgpt --model gpt-4o-mini "$instructions Context: $context")
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
}