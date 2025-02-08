# Autocommit

**Autocommit** is a Bash script designed to streamline your Git workflow by automatically generating concise commit messages, Jira tickets, or Pull Request (PR) descriptions based on your staged changes or recent commits. Leveraging the power of AI through `sgpt`, it ensures that your commit messages are both meaningful and standardized.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Options](#options)
- [Examples](#examples)
- [Uninstallation](#uninstallation)
- [Security](#security)
- [Contributing](#contributing)
- [License](#license)
- [Inspiration](#inspiration)

## Features

- **Automated Commit Messages:** Generate concise, structured commit messages, optionally referencing Jira tickets derived from your branch name.
- **Jira Ticket & PR Generation:** Create Jira tickets and PR summaries with titles and descriptions that follow a set format.
- **Configurable AI Model & Behavior:** Use a `.autocommitrc` configuration file to customize the AI model and other settings.
- **Consistent Formatting & Validation:** The script validates and enforces consistency in commit messages.
- **Security-First Approach:** Automatically excludes sensitive files (like .env, credentials, etc.) from AI analysis.
- **Verbose Mode:** Detailed logging for debugging and transparency.

## Prerequisites

Before installing and using Autocommit, ensure that you have the following dependencies installed:

- Bash shell
- Git
- [Shell GPT (sgpt)](https://github.com/TheR1D/shell_gpt)

## Installation

### Using the Install Script

1. **Clone the Repository:**

```bash
git clone https://github.com/yourusername/autocommit.git
```

2. **Run the Installation Script:**

```bash
cd autocommit
chmod +x install.sh
./install.sh
```

This script will:
• Copy `autocommit.sh` to `/usr/local/bin/autocommit`.
• Create a symlink /`usr/local/bin/autocommit` for easy access
• Create a `~/.autocommitrc` template if none exists.

3. **(Optional) Configure your preferred AI model in `~/.autocommitrc`**:

```bash
# ~/.autocommitrc
export AUTOCOMMIT_MODEL="gpt-4o-mini"
```

4. **Ensure `/usr/local/bin` is in your `PATH`. If not, `install.sh` attempts to add it to your shell profile**

5. **Reload Your Shell Profile:**

```bash
source ~/.bashrc # For Bash users
source ~/.zshrc # For Zsh users
```

## Usage

Run the `autocommit` command within your Git repository to generate commit messages, Jira tickets, or PR descriptions based on your staged changes or recent commits.

```bash
autocommit [options]
```

## Options

| Flag         | Description                                                                                |
| ------------ | ------------------------------------------------------------------------------------------ |
| -c <context> | Add context to the commit message (e.g., issue number)                                     |
| -j           | Generate a Jira ticket title and description instead of a commit message                   |
| -p           | Generate a Pull Request title and description instead of a commit message                  |
| -n <number>  | Number of recent commits to consider (if not provided, uses staged changes)                |
| -m           | Message only, do not commit                                                                |
| -M <model>   | Specify the AI model for sgpt (default: gpt-4o-mini, overrides default in `.autocommitrc`) |
| -v           | Display version information                                                                |
| -h           | Show the help message                                                                      |

## Examples

**Standard Commit Message Generation**

Generate a commit message based on staged changes:

```bash
autocommit
```

**Commit with Context and Logging**

Add context to the commit message and log it to a file:

```bash
autocommit -c "Fixes issue #123"
```

**Generate a Jira Ticket**

Create a Jira ticket based on staged changes:

```bash
autocommit -j
```

**Generate a Pull Request Description**

Create a Pull Request description based on recent commits:

```bash
autocommit -p -n 5
```

**Message Only Mode**

Generate a commit message without committing:

```bash
autocommit -m
```

**Using Verbose Mode**

```bash
autocommit -V
```

## Uninstallation

To remove Autocommit:

```bash
sudo ./uninstall.sh
```

This will:
• Remove the `/usr/local/bin/autocommit` symlink.
• Offer to remove `/usr/local/share/autocommit` installation directory.
• Offer to remove `~/.autocommitrc`.
• Will not automatically remove `PATH` modifications from your shell profile.

## Security

Autocommit automatically excludes the following types of files from AI analysis to prevent sensitive data exposure:

- Credential files (.env, .pem, .key, etc.)
- Configuration files that might contain secrets
- Database files
- Log files
- Backup files

When these files are detected in your changes, they will be listed as "[SENSITIVE FILE EXCLUDED]" in the change summary.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Inspiration

Inspired by [Smash Your Git Commit Messages Like a Champ Using ChatGPT](https://medium.com/@marc_fasel/smash-your-git-commit-messages-like-a-champ-using-chatgpt-0cbe8ea7b3df) by [Marc Fasel](https://medium.com/@marc_fasel).
