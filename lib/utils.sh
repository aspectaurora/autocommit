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