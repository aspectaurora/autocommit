#!/bin/bash
#
# Autocommit - like having a butler for your git commits, only less British (c) Marc Fasel
# 
# This script uses the sgpt command to generate a concise git commit message or Jira ticket based on staged changes or recent commits.
# It automatically stages and commits the changes with the generated message.
#
# Usage:
# autocommit [-c <context>] [-l <logfile>] [-j] [-n <number_of_commits>] [-mo]
#
# Options:
# -c <context>  Add a context to the commit message (e.g., the issue number)
# -l <logfile>  Log the commit messages to a file
# -j            Generate a Jira ticket title and description instead of a commit message
# -pr           Generate a Pull Request title and description instead of a commit message
# -n <number>   Number of recent commits to consider (if not provided, uses staged changes)
# -mo           Message only, do not commit
#
# Examples:
# autocommit
# autocommit -c "Fixes issue #123"
# autocommit -c "Fixes issue #123" -l ~/logs/autocommit.log
# autocommit -j
# autocommit -pr
# autocommit -n 10
# autocommit -mo
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
    local generate_pr=false
    local message_only=false
    local num_commits=""
    local OPTIND opt

    while getopts "c:l:jn:mopr" opt; do
        case $opt in
            c) context="$OPTARG";;
            l) logfile="$OPTARG";;
            j) generate_jira=true;;
            n) num_commits="$OPTARG";;            
            m) message_only=true;;  # Set the flag when -mo is used
            o) ;;  # This is needed to properly handle the 'o' in 'mo'            
            p) generate_pr=true;;
            r) ;;            
            \?) echo "Invalid option -$OPTARG" >&2; return 1;;
        esac
    done

    shift $((OPTIND-1))

    local branch_name=$(get_branch_name)
    echo "Branch: $branch_name"
    echo "Options: context=$context, logfile=$logfile, generate_jira=$generate_jira, num_commits=$num_commits, message_only=$message_only"

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
    local generate_jira_instructions="generate a Jira ticket title and description as if it were being created before the work was done. \
        Describe what needs to be implemented, even though these changes have already been made. \
        Focus on high-level objectives and overarching goals rather than specific code changes. \
        Combine smaller changes into broader, more strategic tasks. \
        Ignore any reformatting or minor code cleanup. \
        It is crucial to strictly adhere to the following output format: \
        Title: [A concise, goal-oriented title for the Jira ticket] \
        Description: [A detailed description of what needs to be done, expected outcomes, and potential impacts]"
    local generate_pr_instructions="generate a Pull Request title and description. \                        
        Ignore any reformatting or minor code cleanup. \
        The title must strictly follow this format: \
        REFACTOR|FEAT|CHORES|BUGFIX|CICD|ETC:[ABD-123] A concise summary of changes \
        Replace [ABD-123] with an appropriate ticket number if known, or remove it if not applicable. \
        Jira ticket number is optional and could be found in the branch name."
    local role="You are Autocommit - like having a butler for your git commits, only less British (c) Marc Fasel"
    if $generate_jira; then
        if [[ -n "$num_commits" ]]; then
            instructions="$role \
                Based on the following recent git commits, $generate_jira_instructions \
                Use these commits to infer what the original task or feature request might have been. \
                Remember to strictly follow the specified output format. \
                Recent commits: $changes"
        else
            instructions="$role \
                Based on the following git diff, $generate_jira_instructions \
                Use this diff to infer what the original task or feature request might have been. \
                Remember to strictly follow the specified output format."
        fi
    elif $generate_pr; then
        if [[ -n "$num_commits" ]]; then
            instructions="$role \
                Based on the following recent git commits, $generate_pr_instructions \
                Recent commits: $changes \
                Current branch: $branch_name"                
        else
            instructions="$role \
                Based on the following git diff, $generate_pr_instructions \
                Current branch: $branch_name"
        fi
    else
        if [[ -n "$num_commits" ]]; then
            instructions="$role \
                Generate a concise git commit message that summarizes the key changes from these recent commits. \
                The message must strictly follow this format: \
                REFACTOR|FEAT|CHORES|BUGFIX|CICD|ETC:[ABD-123] A concise summary of changes \
                \
                - Key change or impact \
                - Another key change or impact \
                - A third key change or impact if necessary \
                \
                Choose the most appropriate category (REFACTOR|FEAT|CHORES|BUGFIX|CICD|ETC). \
                Replace [ABD-123] with an appropriate ticket number if known, or remove it if not applicable. \
                Jira ticket number is optional and could be found in the branch name. \
                Focus on the overall purpose and impact of the changes, not just technical details. \
                Combine smaller changes into broader, more meaningful descriptions. \
                Ignore any reformatting or minor code cleanup. \
                Ignore the boring reformatting stuff. \                
                Recent commits: $changes \
                Current branch: $branch_name"
        else
            instructions="You are Autocommit - like having a butler for your git commits, only less British (c) Marc Fasel \
                Generate a concise git commit message that summarizes the key changes. \
                Ignore the boring reformatting stuff. 
                If brach name starts as 'abd-123-*' use the format 'REFACTOR|FEAT|CHORES|BUGFIX|ETC:[ABD-123] A commit message' \
                If not, use the format 'REFACTOR|FEAT|CHORES|BUGFIX|ETC: A commit message' \
                at the start of the message, choosing the most appropriate category. \
                Current branch: $branch_name"
                
            # instructions="Generate a concise git commit message that summarizes the key changes. \
            #     The message must strictly follow this format: \
            #     REFACTOR|FEAT|CHORES|BUGFIX|CICD|ETC:[ABD-123] A concise summary of changes \
            #     \
            #     - Key change or impact \
            #     - Another key change or impact \
            #     - A third key change or impact if necessary \
            #     \
            #     Choose the most appropriate category (REFACTOR|FEAT|CHORES|BUGFIX|CICD|ETC). \
            #     Focus on the overall purpose and impact of the changes, not just technical details. \
            #     Combine smaller changes into broader, more meaningful descriptions. \
            #     Ignore any reformatting or minor code cleanup. \
            #     Ignore the boring reformatting stuff. \
            #     Current branch: $branch_name"
        fi
    fi

    # Handle no changes
    if [[ -z "$changes" ]]; then
        echo "No changes to commit"
        return
    fi
    
    if [[ -z "$context" ]]; then
        message=$(echo "$changes" | sgpt --model gpt-4o-mini "$instructions" --no-cache)
    else
        message=$(echo "$changes" | sgpt --model gpt-4o-mini "$instructions \n\n Important Context: $context" --no-cache)
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
            local successMessage="$datetime - Generated commit message based on recent commits: $message"
            echo "$successMessage"
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
