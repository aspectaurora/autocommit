# Autocommit

**Autocommit** is a Bash script designed to streamline your Git workflow by automatically generating concise commit messages, Jira tickets, or Pull Request (PR) descriptions based on your staged changes or recent commits. Leveraging the power of AI through `sgpt`, it ensures that your commit messages are both meaningful and standardized.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Options](#options)
- [Examples](#examples)
- [Logging](#logging)
- [Contributing](#contributing)
- [License](#license)
- [Inspiration](#inspiration)

## Features

- **Automated Commit Messages:** Generate concise, structured commit messages, optionally referencing Jira tickets derived from your branch name.
- **Jira Ticket & PR Generation:** Create Jira tickets and PR summaries with titles and descriptions that follow a set format.
- **Configurable AI Model & Behavior:** Use a `.autocommitrc` configuration file to customize the AI model and other settings.
- **Logfile Support:** Log generated messages to a file for auditing.
- **Consistent Formatting & Validation:** The script validates and enforces consistency in commit messages.

## Prerequisites

Before installing and using Autocommit, ensure that you have the following dependencies installed:

- **Git**: Must be installed and you must be inside a Git repository.
- **sgpt**:  
  Install via `pip install shell-gpt`.

## Installation

### Using the Install Script

1. **Clone the Repository:**

```bash
git clone https://github.com/yourusername/autocommit.git
cd autocommit
```

2. **Run the Install Script:**

```bash
chmod +x install.sh
./install.sh
```

This script will:
• Copy `autocommit.sh` to `/usr/local/bin/autocommit`.
• Create a symlink /`usr/local/bin/autocommit` for easy access
• Create a `~/.autocommitrc` template if none exists.

3. **Ensure `/usr/local/bin` is in your `PATH`. If not, `install.sh` attempts to add it to your shell profile**

4. **Reload Your Shell Profile:**

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
| -l <logfile> | Log the commit messages to a file                                                          |
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
autocommit -c "Fixes issue #123" -l ~/logs/autocommit.log
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

**Logging**

If the -l option is used, Autocommit will log the generated messages along with timestamps to the specified logfile. Ensure that the directory for the logfile exists or let Autocommit create it.

```bash
autocommit -c "Add new feature" -l ~/logs/autocommit.log
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

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](/LICENSE.md) file for details.

## Inspiration

Inspired by [Smash Your Git Commit Messages Like a Champ Using ChatGPT](https://medium.com/@marc_fasel/smash-your-git-commit-messages-like-a-champ-using-chatgpt-0cbe8ea7b3df) by [Marc Fasel](https://medium.com/@marc_fasel).
