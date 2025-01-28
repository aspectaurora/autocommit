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
        echo "Error: Unable to retrieve the current Git branch name." >&2
        exit 1
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
    echo "  autocommit -V"
}

# Validate commit message
function validate_message() {
    # echo "Validating commit message..."
    local message="$1"
    local branch_name="$2"
    local ticket_number="$3"

    # Basic validation rules
    if [[ ! $message =~ ^[A-Z] ]]; then
        echo "Validation failed: Commit message must start with a capitalized word."
        return 1
    fi

    if [[ $message =~ Based\ on\ the\ changes ]]; then
        echo "Validation failed: Commit message contains unnecessary phrases."
        return 1
    fi
    # echo "Validation passed."
    return 0
}

# Enforce consistency in commit message formatting
function enforce_consistency() {
    echo "Enforcing commit message consistency..."
    local raw_message="$1"
    local branch_name="$2"
    local model="$3"
    local ticket_number="$4"

    local instructions="
        $CONSISTENCY_INSTRUCTIONS
        \n\n
        - If ticket number is not present, try to infer it from the branch name: $branch_name
        - Use this Jira ticket number if available: $ticket_number

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
    # $3: num_commits
    # $4: context (additional user context)
    # $5: model (AI model)
    # $6: verbose (true/false)
    local generate_jira="$1"
    local generate_pr="$2"    
    local num_commits="$3"
    local user_context="$4"
    local model="$5"
    local verbose="$6"

    local branch_name=$(get_branch_name)    
    # Extract ticket number from branch name
    local ticket_number=""
    if [[ $branch_name =~ ([A-Z]+-[0-9]+) ]]; then
        ticket_number="${BASH_REMATCH[1]}"
    fi

    if $verbose; then
        echo "[Verbose] Starting generate_message with params:"
        echo "  generate_jira: $generate_jira"
        echo "  generate_pr: $generate_pr"        
        echo "  num_commits: $num_commits"
        echo "  user_context: $user_context"
        echo "  model: $model"
        echo "  verbose: $verbose"
        echo "  Branch: $branch_name"
    fi

    local changes
    if [[ -n "$num_commits" ]]; then
        changes=$(git log -n "$num_commits" --pretty=format:"%h %s")
    else
        changes=$(git diff --staged)
    fi

    # Handle no changes
    if [[ -z "$changes" ]]; then
        echo "No changes to commit"
        return 1
    fi

    local role
    if $generate_jira; then
        role="You are an assistant helping to generate descriptive Jira ticket descriptions."
    elif $generate_pr; then
        role="You are an assistant helping to generate clear and detailed Pull Request descriptions."
    else
        role="You are an intelligent assistant specializing in creating concise and descriptive Git commit messages."
    fi

    # if [[ -n "$num_commits" ]]; then
    #     changes="RECENT COMMITS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n$changes\n\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< RECENT COMMITS END"
    # else
    #     changes="STAGED CHANGES START >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n$changes\n\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< STAGED CHANGES END"
    # fi

    if [[ -n "$num_commits" ]]; then
        changes="RECENT COMMITS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n$changes\n\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< RECENT COMMITS END"
    else
        local files
        files=$(git diff --name-only --staged) # Extract list of staged files
        local file_analysis
        file_analysis=$(classify_changes "$files")
        local diffs
        diffs=$(summarize_diffs "$files")
        # echo "File Analysis:\n$file_analysis"        
        # echo "Diffs:\n$diffs"
        changes="STAGED CHANGES >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n$file_analysis\n\nSummarized Diffs:\n$diffs\n\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< STAGED CHANGES END"
    fi

    local metadata
    # metadata=$(extract_metadata)
    
    local instructions
    local additional_params_message="- Use the current branch name for context: $branch_name.\n- Use this Jira ticket number: $ticket_number"
    if $generate_jira; then
        instructions="$role\n\n$changes\n\n$metadata\n\n$JIRA_INSTRUCTIONS\n\n$additional_params_message"
    elif $generate_pr; then
        instructions="$role\n\n$changes\n\n$metadata\n\n$PR_INSTRUCTIONS\n\n$additional_params_message"
    else
        instructions="$role\n\n$changes\n\n$metadata\n\n$COMMIT_INSTRUCTIONS\n\n$additional_params_message"
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
    $verbose && echo "[Verbose] Raw message: $raw_message"
    # If it's a commit message (not jira/pr), validate it
    local message="$raw_message"
    if ! $generate_jira && ! $generate_pr; then
        if ! validate_message "$raw_message" "$branch_name" "$ticket_number"; then
            $verbose && echo "[Verbose] Raw message validation failed."
            message=$(enforce_consistency "$raw_message" "$branch_name" "$model" "$ticket_number")
            if [[ -z "$message" ]]; then
                echo "Error: Could not refine commit message."
                return 1
            fi
        fi
    fi
    
    $verbose && echo "[Verbose] Generated message:"    
    echo -e "$message"
    return 0
}

function classify_changes() {
    local files="$1"
    local tests=""
    local src=""
    local docs=""
    local others=""

    while read -r file; do
        if [[ $file =~ \.(test|spec)\.(js|ts|jsx|tsx)$ ]]; then
            tests+="$file\n"
        elif [[ $file =~ \.(js|ts|jsx|tsx|py|go|java|cpp|c)$ ]]; then
            src+="$file\n"
        elif [[ $file =~ \.(md|rst)$ ]]; then
            docs+="$file\n"
        else
            others+="$file\n"
        fi
    done <<< "$files"
    local summary=""
    if [[ -n "$tests" ]]; then
        summary+="Tests:\n$tests\n"
    fi
    if [[ -n "$src" ]]; then
        summary+="Source Files:\n$src\n"
    fi
    if [[ -n "$docs" ]]; then
        summary+="Documentation:\n$docs\n"
    fi
    if [[ -n "$others" ]]; then
        summary+="Other Changes:\n$others\n"
    fi
    echo -e "$summary"
}

function summarize_diffs() {
    local files="$1"
    local summary=""
    for file in $files; do
        local max_lines=100
        
        # local total_lines
        # total_lines=$(git diff --staged "$file" | wc -l)
        
        # # Adjust lines dynamically
        # if (( total_lines > 50 )); then
        #     max_lines=20
        # elif (( total_lines > 20 )); then
        #     max_lines=10
        # else
        #     max_lines=$total_lines
        # fi
        
        # Adjust lines based on file type
        if [[ $file =~ \.(test|spec)\.(js|ts|jsx|tsx)$ ]]; then
            max_lines=5
        elif [[ $file =~ \.(js|ts|jsx|tsx|py|go|java|cpp|c)$ ]]; then
            max_lines=100
        # elif [[ $file =~ \.(md|rst)$ ]]; then
        #     max_lines=15
        else
            max_lines=50
        fi        
        
        # Extract the diff
        diff=$(git diff --staged "$file" | head -n $max_lines)
        summary+="$diff\n\n"
    done
    echo -e "$summary"
}

function extract_metadata() {
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    local metadata=""
    if [[ -f "$repo_root/CHANGELOG.md" ]]; then
        metadata+="Recent Changes from CHANGELOG.md:\n$(head -n 10 "$repo_root/CHANGELOG.md")\n\n"
    fi
    if [[ -f "$repo_root/package.json" ]]; then
        metadata+="Project Metadata from package.json:\n$(jq . "$repo_root/package.json")\n\n"
    fi
    echo -e "$metadata"
}