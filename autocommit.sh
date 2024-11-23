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
DEFAULT_MODEL="gpt-4o-mini"

JIRA_INSTRUCTIONS="
    Generate a Jira ticket title and description.

    **Requirements:**

    - **Title:** A concise, goal-oriented title for the task to be done.
    - **Description:** A detailed explanation of what needs to be implemented, focusing on high-level objectives and goals.

    **Important:**
    
    - **Provide only the title and description. Do not include any introductory or concluding sentences.**
    - **Do not add explanations, summaries, or lists of changes.**
    
    **Output Format:**
    
    Title: [Your Title]
    Description: [Your Description]
    
    **Example:**
    
    Title: FEAT: Implement user authentication
    Description: Add user login and registration functionality using OAuth 2.0. Ensure secure password storage and session management."

PR_INSTRUCTIONS="
    Create a Pull Request title and description.

    **Requirements:**

    - **Title:**
        - Start with one of these categories: FEAT, BUGFIX, REFACTOR, CHORE, CICD, ETC.
        - If a Jira ticket number is available, include it in the format: [ABC-123].
        - Format: CATEGORY: [JIRA_TICKET_NUMBER] A concise summary of changes.

    - **Description:**
        - Provide a detailed summary of the changes made.
        - Highlight key features, fixes, or improvements.
        - Focus on the purpose and impact of the changes.

    **IMPORTANT:**
    
    - **Provide only the title and description.**
    - **Do not include any introductory or concluding sentences.**

    **Output Format:**
    
    Title: CATEGORY: [JIRA_TICKET_NUMBER] Summary
    Description: Detailed description
    
    **Example:**
    
    Title: FEAT: [ABC-123] Add user authentication
    Description: Implemented OAuth 2.0 for user login and registration. Ensured secure password storage and session management."

COMMIT_INSTRUCTIONS="
    Generate a concise git commit message summarizing the key changes.

    **Requirements:**

    - Start with one of these categories: FEAT, BUGFIX, REFACTOR, CHORE, CICD, ETC.
    - Include the Jira ticket number if available in the format: [ABC-123].
    - Format the commit message as:
        - **With ticket number:** CATEGORY:[JIRA_TICKET_NUMBER] A concise summary.
        - **Without ticket number:** CATEGORY: A concise summary.
    - Focus on the overall purpose and impact of the changes.
    - Combine smaller changes into meaningful descriptions.
    - Ignore any code reformatting or minor cleanups.
    
    **IMPORTANT:**

    - **Provide only the commit message.**
    - **Do not include any introductory or concluding sentences.**
    - **Do not add explanations, summaries, or lists of changes.**

    **Output Format:**
    
    CATEGORY:[JIRA_TICKET_NUMBER] A concise summary of changes.
    
    **Example:**
    
    FEAT:[ABC-123] Implement user authentication using OAuth 2.0."

CONSISTENCY_INSTRUCTIONS="
    Format the following commit message according to these specifications:

    - Begin with the appropriate category (e.g., FEAT, BUGFIX, REFACTOR).
    - Include the Jira ticket number if present.
    - The final format should be: CATEGORY:[JIRA_TICKET_NUMBER] A concise summary of changes.
    - Preserve the structure of the message, including any bullet points or line breaks.
    
    **IMPORTANT:**

    - **Provide only the final commit message**
    - **Do not include any introductory or concluding sentences.**"    

# Check if inside a Git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not inside a Git repository."
    exit 1
fi

# Check if dependencies are installed
if ! command -v sgpt &> /dev/null; then
    echo "Error: sgpt is not installed. Please install it using 'pip install shell-gpt'."
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install it and try again."
    exit 1
fi

# Function: show_help
# Description: Displays the help message for the script.
function show_help() {
    echo "Usage: autocommit [options]"
    echo "Options:"
    echo "  -c <context>    Add context to the commit message (e.g., issue number)"
    echo "  -l <logfile>    Log the commit messages to a file"
    echo "  -j              Generate a Jira ticket"
    echo "  -p              Generate a Pull Request message"
    echo "  -n <number>     Number of recent commits to consider"
    echo "  -m              Message only, do not commit"
    echo "  -M <model>      Specify the AI model for sgpt (default: $DEFAULT_MODEL)"
    echo "  -v, --version   Display version information"
    echo "  -h, --help      Show this help message"
}

# Function: get_branch_name
# Description: Retrieves the current Git branch name.
function get_branch_name() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ $? -ne 0 || -z "$branch" ]]; then
        echo "Error: Unable to retrieve the current Git branch name."
        exit 0
    fi
    echo "$branch"
}
# Function: enforce_consistency
# Description: Enforces commit message consistency based on a given model.
function enforce_consistency() {
    echo "Enforcing commit message consistency..."
    local raw_message="$1"
    local branch_name="$2"
    local model="$3"

    # Adjusted the consistency instructions to preserve the formatting
    local consistency_instructions="$CONSISTENCY_INSTRUCTIONS"

    local instructions="
        $consistency_instructions
        \n\n
        - If ticket number is not present, try to infer it from the branch name: $branch_name

        Raw commit message: \"$raw_message\""

    # Generate the refined commit message
    local refined_message=$(echo "$instructions" | sgpt --model "$model" --no-cache)

    # If there was no ticket number, remove the empty brackets
    if [[ -z "$ticket_number" ]]; then
        refined_message=$(echo "$refined_message" | sed 's/\[\] //')
    fi
    
    # Preserve line breaks and ensure the message is passed correctly
    echo -e "$refined_message"
}
# Function: validate_message
# Description: Validates the commit message based on specific rules.
function validate_message() {
    echo "Validating commit message..."
    local message="$1"
    local branch_name="$2"
    local ticket_number=""

    # Extract the ticket number from the branch name (assuming it follows the pattern [ABC-123])
    if [[ $branch_name =~ ([A-Z]+-[0-9]+) ]]; then
        ticket_number="${BASH_REMATCH[1]}"
    fi
    echo "Ticket number: $ticket_number"

    # Basic validation rules
    if [[ ! $message =~ ^[A-Z] ]]; then
        echo "Validation failed: Commit message must start with a capitalized word."
        return 1
    fi

    if [[ $message =~ Based\ on\ the\ changes ]]; then
        echo "Validation failed: Commit message contains unnecessary phrases."
        return 1
    fi
    echo "Validation passed."
    # If all validations pass
    return 0
}

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
