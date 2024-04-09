#!/bin/bash
#
# Autocommit - like having a butler for your git commits, only less British (c) Marc Fasel
# 
# This script uses the sgpt command to generate a concise git commit message that summarizes the key changes.
# It automatically stages and commits the changes with the generated message.
#
# Usage:
# autocommit [-c <context>] [-l <logfile>]
#
# Options:
# -c <context>  Add a context to the commit message (e.g., the issue number)
# -l <logfile>  Log the commit messages to a file
#
# Examples:
# autocommit
# autocommit -c "Fixes issue #123"
# autocommit -c "Fixes issue #123" -l ~/logs/autocommit.log
#
# Dependencies:
# - sgpt
# - git
#   
# Installation:
# 1. Install sgpt:
#    $ pip install shell-gpt
# 2. Install the script:
#    $ sudo ./install.sh
# 3. Use the autocommit command in your git repositories:
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

autocommit() {
    local context=""
    local logfile=""
    local OPTIND opt

    while getopts "c:l:" opt; do
        case $opt in
            c) context="$OPTARG";;
            l) logfile="$OPTARG";;
            \?) echo "Invalid option -$OPTARG" >&2; return 1;;
        esac
    done

    shift $((OPTIND-1))

    local commitMessage
    local instructions="Generate a concise git commit message that summarizes the key changes. Ignore the boring reformatting stuff."
    if [[ -z "$context" ]]; then
        commitMessage=$(git diff --staged | sgpt "$instructions")
    else
        commitMessage=$(git diff --staged | sgpt "$instructions Context: $context")
    fi

    local datetime=$(date +"%Y-%m-%d %H:%M:%S")
    local successMessage="$datetime - Commit successful: $commitMessage"
    local failMessage="$datetime - Commit failed"

    if git commit -m"$commitMessage"; then
        if [[ -n "$logfile" ]]; then
            mkdir -p "$(dirname "$logfile")"
            echo "$successMessage" >> "$logfile"    
        fi
    else
        if [[ -n "$logfile" ]]; then
            mkdir -p "$(dirname "$logfile")"
            echo "$failMessage" >> "$logfile"
        else
            echo "$failMessage"
        fi
    fi
}

# If the script is called directly, execute the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    autocommit "$@"
fi