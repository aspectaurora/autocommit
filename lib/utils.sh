# lib/utils.sh
# Utility functions for autocommit

# Load configuration from .autocommitrc file if present
function load_config() {
    local repo_root    
    # Determine repository root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ $? -ne 0 || -z "$repo_root" ]]; then
        echo "Warning: Could not determine repository root. Skipping repository-level config."
    fi

    # Check for config in repo root
    if [[ -n "$repo_root" && -f "$repo_root/.autocommitrc" ]]; then
        source "$repo_root/.autocommitrc"
        echo "Loaded configuration from $repo_root/.autocommitrc"
        return
    fi

    # If not found in repo root, check home directory
    if [[ -f "$HOME/.autocommitrc" ]]; then
        source "$HOME/.autocommitrc"
        echo "Loaded configuration from $HOME/.autocommitrc"
        return
    fi

    # If no config file is found, proceed with defaults
    echo "No .autocommitrc configuration file found. Using default settings."
}

# Get current branch name
function get_branch_name() {
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ $? -ne 0 || -z "$branch" ]]; then
        echo "Error: Unable to retrieve the current Git branch name."
        exit 0
    fi
    echo "$branch"
}

# Show help message
function show_help() {
    echo "Usage: autocommit [options]"
    echo "Options:"
    echo "  -c <context>    Add context to the commit message (e.g., issue number)"
    echo "  -l <logfile>    Log the commit messages to a file"
    echo "  -j              Generate a Jira ticket instead of a commit message"
    echo "  -p              Generate a Pull Request message instead of a commit message"
    echo "  -n <number>     Analyze the last <number> commits instead of staged changes"
    echo "  -m              Message only, do not commit"
    echo "  -M <model>      Specify the AI model for sgpt (overrides DEFAULT_MODEL in .autocommitrc)"
    echo "  -v, --version   Display version information"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  autocommit"
    echo "  autocommit -c \"Fixes issue #123\""
    echo "  autocommit -c \"Fixes issue #123\" -l ~/logs/autocommit.log"
    echo "  autocommit -j"
    echo "  autocommit -p"
    echo "  autocommit -n 10"
    echo "  autocommit -m"
}

# Validate commit message
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
    return 0
}

# Enforce consistency in commit message formatting
function enforce_consistency() {
    echo "Enforcing commit message consistency..."
    local raw_message="$1"
    local branch_name="$2"
    local model="$3"

    local instructions="
        $CONSISTENCY_INSTRUCTIONS
        \n\n
        - If ticket number is not present, try to infer it from the branch name: $branch_name

        Raw commit message: \"$raw_message\""

    local refined_message=$(echo "$instructions" | sgpt --model "$model" --no-cache)

    if [[ -z "$ticket_number" ]]; then
        refined_message=$(echo "$refined_message" | sed 's/\[\] //')
    fi

    echo -e "$refined_message"
}

# Generate a commit message using sgpt
function generate_message() {
    # Parameters:
    # $1: generate_jira (true/false)
    # $2: generate_pr (true/false)
    # $3: message_only (true/false)
    # $4: num_commits
    # $5: context (additional user context)
    # $6: model (AI model)
    local generate_jira="$1"
    local generate_pr="$2"
    local message_only="$3"
    local num_commits="$4"
    local user_context="$5"
    local model="$6"

    local branch_name=$(get_branch_name)
    echo "Branch: $branch_name"

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
        return 1
    fi

    local role="You are Autocommit Assistant"
    if [[ -n "$num_commits" ]]; then
        changes="Recent commits: $changes"
    else
        changes="Staged changes: $changes"
    fi

    local instructions
    if $generate_jira; then
        instructions="$role \n\n$JIRA_INSTRUCTIONS\n\n$changes"
    elif $generate_pr; then
        instructions="$role \n\n$PR_INSTRUCTIONS\n\n- Use the current branch name for context: $branch_name.\n- Use the extracted Jira ticket number: \$ticket_number (if available).\n\n$changes"
    else
        instructions="$role \n\n$COMMIT_INSTRUCTIONS\n\n- Use the current branch name for context: $branch_name.\n- Use the extracted Jira ticket number: \$ticket_number (if available).\n\n$changes"
    fi

    local prompt="$instructions"
    if [[ -n "$user_context" ]]; then
        prompt="$prompt\n\n**THE LATEST CONTEXT**: $user_context"
    fi

    local raw_message
    raw_message=$(echo "$changes" | sgpt --model "$model" --no-cache "$prompt" 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$raw_message" ]; then
        echo "Error: Failed to generate message using sgpt."
        return 1
    fi

    # If it's a commit message (not jira/pr), validate it
    local message="$raw_message"
    if ! $generate_jira && ! $generate_pr; then
        if ! validate_message "$raw_message" "$branch_name"; then
            echo "Raw message validation failed."
            message=$(enforce_consistency "$raw_message" "$branch_name" "$model")
            if [[ -z "$message" ]]; then
                echo "Error: Could not refine commit message."
                return 1
            fi
        fi
    fi

    echo "$message"
    return 0
}