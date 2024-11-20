# Changelog

## [1.1] - 2024-11-20

### Added

#### Versioning:

- Introduced a VERSION variable (VERSION="1.1") to track script versions.
- Added version display option -v and help option -h for user convenience.

#### Dependency Checks:

- Implemented checks to ensure the script is run inside a Git repository.
- Added validation to confirm that `sgpt` and `git` are installed before execution.

#### New Options:

- -j: Generate a Jira ticket title and description instead of a commit message.
- -pr: Generate a Pull Request title and description.
- -n <number>: Specify the number of recent commits to consider for message generation.
- -mo: Output the commit message only, without committing changes.
- -M <model>: Specify the AI model to use with `sgpt`.

#### Functions:

- get_branch_name: Retrieves the current Git branch name.
- enforce_consistency: Adjusts commit messages to follow a consistent format.
- validate_message: Validates the generated commit message against predefined rules.

#### Model Configuration:

- Added a DEFAULT_MODEL variable (DEFAULT_MODEL="gpt-4o-mini") for `sgpt`.
- Allowed users to specify the model via the -M option.

#### Logging Enhancements:

- Improved logging with timestamps and conditional logging based on user input.
- Created directories for log files if they don’t exist.

#### Error Handling:

- Enhanced error messages for better user feedback.
- Implemented checks for empty commit messages and `sgpt` command failures.

#### User Feedback:

- Displayed current branch and options selected at runtime.
- Provided detailed output for generated Jira tickets and Pull Requests.

### Changed

#### Option Parsing:

- Updated `getopts` to handle new options and improve parsing logic.
- Refactored code for better readability and maintenance.

#### Usage Instructions:

- Expanded usage examples and option descriptions in the script header.
- Included new options in the help (-h) output.

#### Commit Message Generation:

- Enhanced instructions sent to `sgpt` for more accurate commit messages.
- Integrated branch name and ticket number extraction for contextual messages.

#### Functionality:

- The script now handles both staged changes and recent commits based on user input.
- Added the ability to generate Jira tickets and Pull Request descriptions.

### Fixed

#### Validation Issues:

- Addressed potential validation failures in commit messages.
- Ensured that messages start with a capitalized word and avoid unnecessary phrases.

#### Minor Bugs:

- Fixed issues with option parsing for combined options like -mo.
- Resolved problems when no changes are present to commit.

### Removed

- Cleaned up commented-out code and unnecessary parameters in functions.
