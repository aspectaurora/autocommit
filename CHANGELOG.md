# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3] - 2025-01-28

### Added

- Security-first approach with automatic exclusion of sensitive files
- Verbose mode (-V flag) for detailed logging and debugging
- Configuration file support (.autocommitrc) for customizing settings
- Proper installation and uninstallation scripts
- Structured project organization with lib/ directory
- Improved error handling and validation
- Template .autocommitrc creation during installation

### Changed

- Moved prompt templates to separate lib/prompts.sh file
- Improved code organization with utility functions in lib/utils.sh
- Enhanced diff summarization with file type-specific handling
- Updated installation process to use /usr/local/share/autocommit
- Improved help messages and documentation
- Removed logfile functionality in favor of verbose mode

### Fixed

- Better handling of empty diffs and invalid inputs
- Improved error messages for missing dependencies
- Fixed path handling for script location
- Better handling of symlinks during installation

### Security

- Added automatic detection and exclusion of sensitive files:
  - Credential files (.env, .pem, .key, etc.)
  - Configuration files with potential secrets
  - Database files
  - Log files
  - Backup files
- Improved handling of sensitive data in diffs

## [1.2] - 2024-11-23

### Added

#### Installation Script:

- Automated installation process with options for function-based or executable command setup.
- Shell profile detection for Bash and Zsh, facilitating easy sourcing of the script.
- User prompts to choose installation type, enhancing flexibility and user control.

#### Enhanced Prompts:

- Refined instructions for generating commit messages, Jira tickets, and Pull Requests to ensure output consistency.
- Inclusion of explicit directives to generate only the desired messages without additional explanatory text.
- Added example formats within prompts to guide AI response formatting.

#### Logging Capability:

- Conditional logging feature allowing users to log generated messages along with timestamps to a specified logfile using the `-l` flag.

#### Interactive Features:

- Enhanced `README.md` with comprehensive usage examples and detailed option explanations.
- Function-based and executable command installations to cater to diverse user preferences.

### Changed

#### Shebang Update:

- Changed from `#!/bin/bash` to `#!/usr/bin/env` bash for improved portability across different Unix-like systems.

#### Option Parsing:

- Improved option parsing in `autocommit.sh` using `getopts` to handle command-line arguments more effectively.
- Corrected option flags from `-mo` to `-m` (Message Only) and `-p` (Pull Request) to prevent ambiguity and ensure proper functionality.

#### Error Handling:

- Enhanced error handling for branch name retrieval, ensuring the script gracefully exits with informative messages if the branch name cannot be determined.
- Improved validation logic to enforce commit message standards and consistency without introducing unwanted text.

#### Script Structure:

- Modularization of instruction prompts for commits, Jira tickets, and PRs to promote maintainability and scalability.
- Added inline comments and function descriptions within `autocommit.sh` to improve readability and ease future modifications.

### Fixed

#### Option Flags:

- Resolved conflicts in option parsing by removing the unused `-o` flag and properly handling the `-p` flag for Pull Requests.

#### Consistency Enforcement:

- Ensured that the `enforce_consistency` function outputs only the refined commit message without any additional comments or summaries.

#### Logging Errors:

- Addressed potential issues in logging mechanisms to ensure that messages are correctly appended to log files without permission or path errors.

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
- Created directories for log files if they don't exist.

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
