#!/usr/bin/env bash
# lib/ai/prompts.sh
# AI prompt templates and message generation for autocommit

# Guard against multiple sourcing
[[ -n "${_AUTOCOMMIT_PROMPTS_SH:-}" ]] && return 0
declare -r _AUTOCOMMIT_PROMPTS_SH=1

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/../core/logger.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../core/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../git/utils.sh"

# Prompt templates
JIRA_INSTRUCTIONS="JIRA_INSTRUCTIONS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
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
    Description: Add user login and registration functionality using OAuth 2.0. Ensure secure password storage and session management.
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< JIRA_INSTRUCTIONS END"

PR_INSTRUCTIONS="PR_INSTRUCTIONS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
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
    Description: Implemented OAuth 2.0 for user login and registration. Ensured secure password storage and session management.
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PR_INSTRUCTIONS END"

COMMIT_INSTRUCTIONS="COMMIT INSTRUCTIONS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
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
    
    FEAT:[ABC-123] Implement user authentication using OAuth 2.0.
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< COMMIT INSTRUCTIONS END"

CONSISTENCY_INSTRUCTIONS="CONSISTENCY INSTRUCTIONS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    Format the following commit message according to these specifications:

    - Begin with the appropriate category (e.g., FEAT, BUGFIX, REFACTOR).
    - Include the Jira ticket number if present.
    - The final format should be: CATEGORY:[JIRA_TICKET_NUMBER] A concise summary of changes.
    - Preserve the structure of the message, including any bullet points or line breaks.
    
    **IMPORTANT:**

    - **Provide only the final commit message**
    - **Do not include any introductory or concluding sentences.**
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< CONSISTENCY INSTRUCTIONS END"

# Export prompts for tests
export JIRA_INSTRUCTIONS PR_INSTRUCTIONS COMMIT_INSTRUCTIONS CONSISTENCY_INSTRUCTIONS

# Validate that all required prompts are defined
# No args
# Returns: 0 if valid, 1 if invalid
function validate_prompts() {
    local missing_prompts=()
    
    [[ -z "${JIRA_INSTRUCTIONS:-}" ]] && missing_prompts+=("JIRA_INSTRUCTIONS")
    [[ -z "${PR_INSTRUCTIONS:-}" ]] && missing_prompts+=("PR_INSTRUCTIONS")
    [[ -z "${COMMIT_INSTRUCTIONS:-}" ]] && missing_prompts+=("COMMIT_INSTRUCTIONS")
    [[ -z "${CONSISTENCY_INSTRUCTIONS:-}" ]] && missing_prompts+=("CONSISTENCY_INSTRUCTIONS")
    
    if ((${#missing_prompts[@]} > 0)); then
        log_error "Required prompt templates are missing: ${missing_prompts[*]}"
        return 1
    fi
    
    return 0
}

# Generate message using AI
# Args:
#   $1 - Generate Jira ticket (true/false)
#   $2 - Generate PR description (true/false)
#   $3 - Number of commits to analyze (empty for staged changes)
#   $4 - Additional context
#   $5 - AI model to use
#   $6 - Verbose mode (true/false)
# Returns: Generated message
function generate_message() {
    local is_jira="$1"
    local is_pr="$2"
    local num_commits="$3"
    local context="$4"
    local model="$5"
    local verbose="$6"
    
    # Validate prompts before proceeding
    if ! validate_prompts; then
        return 1
    fi
    
    [[ "$verbose" == "true" ]] && log_debug "Generating message with parameters: is_jira=$is_jira, is_pr=$is_pr, num_commits=$num_commits"
    
    local branch_name
    branch_name=$(get_branch_name) || return 1
    
    local ticket_number
    ticket_number=$(extract_ticket_number)
    
    local changes
    if [[ -n "$num_commits" ]]; then
        changes=$(get_recent_commits "$num_commits")
    else
        changes=$(get_staged_changes)
    fi
    
    # Handle no changes
    if [[ -z "$changes" ]]; then
        log_error "No changes to analyze"
        return 1
    fi
    
    local role
    if [[ "$is_jira" == "true" ]]; then
        role="You are an assistant helping to generate descriptive Jira ticket descriptions."
    elif [[ "$is_pr" == "true" ]]; then
        role="You are an assistant helping to generate clear and detailed Pull Request descriptions."
    else
        role="You are an intelligent assistant specializing in creating concise and descriptive Git commit messages."
    fi
    
    if [[ -n "$num_commits" ]]; then
        changes="RECENT COMMITS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n$changes\n\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< RECENT COMMITS END"
    else
        local files
        files=$(git diff --name-only --staged)
        local file_analysis
        file_analysis=$(classify_changes "$files")
        local diffs
        diffs=$(summarize_diffs "$files")
        changes="STAGED CHANGES >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n$file_analysis\n\nSummarized Diffs:\n$diffs\n\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< STAGED CHANGES END"
    fi
    
    local instructions
    local additional_params_message="- Use the current branch name for context: $branch_name.\n- Use this Jira ticket number: $ticket_number"
    if [[ "$is_jira" == "true" ]]; then
        instructions="$role\n\n$changes\n\n$JIRA_INSTRUCTIONS\n\n$additional_params_message"
    elif [[ "$is_pr" == "true" ]]; then
        instructions="$role\n\n$changes\n\n$PR_INSTRUCTIONS\n\n$additional_params_message"
    else
        instructions="$role\n\n$changes\n\n$COMMIT_INSTRUCTIONS\n\n$additional_params_message"
    fi
    
    local prompt="$instructions"
    if [[ -n "$context" ]]; then
        prompt="$prompt\n\n**THE LATEST CONTEXT**: $context"
    fi
    
    local raw_message
    raw_message=$(echo -e "$prompt" | sgpt --model "$model" --no-cache 2>/dev/null)
    if [[ $? -ne 0 || -z "$raw_message" ]]; then
        log_error "Failed to generate message using sgpt."
        return 1
    fi
    
    [[ "$verbose" == "true" ]] && log_debug "Raw message: $raw_message"
    
    # If it's a commit message (not jira/pr), validate it
    local message="$raw_message"
    if [[ "$is_jira" != "true" && "$is_pr" != "true" ]]; then
        if ! validate_commit_message "$raw_message" "$branch_name" "$ticket_number"; then
            [[ "$verbose" == "true" ]] && log_debug "Raw message validation failed."
            message=$(enforce_consistency "$raw_message" "$branch_name" "$model" "$ticket_number")
            if [[ -z "$message" ]]; then
                log_error "Could not refine commit message."
                return 1
            fi
        fi
    fi
    
    echo "$message"
}

# Validate commit message format
# Args:
#   $1 - Message to validate
#   $2 - Branch name
#   $3 - Ticket number
# Returns: 0 if valid, 1 if invalid
function validate_commit_message() {
    local message="$1"
    local branch_name="$2"
    local ticket_number="$3"
    
    # Basic validation rules
    if [[ ! $message =~ ^[A-Z] ]]; then
        log_error "Validation failed: Commit message must start with a capitalized word."
        return 1
    fi
    
    if [[ $message =~ Based\ on\ the\ changes ]]; then
        log_error "Validation failed: Commit message contains unnecessary phrases."
        return 1
    fi
    
    return 0
}

# Enforce consistency in commit message formatting
# Args:
#   $1 - Raw message
#   $2 - Branch name
#   $3 - Model
#   $4 - Ticket number
# Returns: Refined message
function enforce_consistency() {
    local raw_message="$1"
    local branch_name="$2"
    local model="$3"
    local ticket_number="$4"
    
    log_debug "Enforcing commit message consistency..."
    
    local instructions="
        $CONSISTENCY_INSTRUCTIONS
        \n\n
        - If ticket number is not present, try to infer it from the branch name: $branch_name
        - Use this Jira ticket number if available: $ticket_number

        Raw commit message: \"$raw_message\""
    
    local refined_message
    refined_message=$(echo -e "$instructions" | sgpt --model "$model" --no-cache)
    
    if [[ -z "$ticket_number" ]]; then
        refined_message=$(echo "$refined_message" | sed 's/\[\] //')
    fi
    
    echo -e "$refined_message"
} 