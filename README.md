# Autocommit

A powerful Git commit message generator powered by AI. Like having a butler for your git commits, only less British.

## Features

- Generate concise and descriptive commit messages based on staged changes
- Create Jira ticket descriptions from code changes
- Generate Pull Request descriptions
- Analyze recent commits for summaries
- Configurable AI model selection
- Consistent message formatting
- Extensive logging and debugging capabilities

## Requirements

- Git
- Python 3.6+
- [shell-gpt](https://github.com/TheR1D/shell_gpt) (`pip install shell-gpt`)
- Bash 4.0+ (required for associative arrays and other features)

## Installation

1. Ensure you have the requirements installed:

```bash
# Check bash version
bash --version

# Install shell-gpt if needed
pip install shell-gpt
```

2. Clone this repository:

```bash
git clone https://github.com/yourusername/autocommit.git
cd autocommit
```

3. Run the installation script:

```bash
bash install.sh
```

## Usage

```bash
# Basic usage
bash autocommit.sh [options]

# After installation
autocommit [options]
```

### Options

- `-c <context>` - Add context (e.g., issue number) to the commit message
- `-j` - Generate a Jira ticket instead of a commit message
- `-p` - Generate a Pull Request message instead of a commit message
- `-n <number>` - Analyze the last <number> commits instead of staged changes
- `-m` - Print the generated message only, do not commit
- `-M <model>` - Specify the AI model for sgpt (overrides DEFAULT_MODEL in .autocommitrc)
- `-v, --version` - Display version information
- `-h, --help` - Show help message
- `-V, --verbose` - Enable verbose logging

### Examples

```bash
# Generate commit message for staged changes
autocommit

# Add context to the commit message
autocommit -c "Fixes issue #123"

# Generate a Jira ticket description
autocommit -j

# Generate a Pull Request description
autocommit -p

# Analyze last 10 commits
autocommit -n 10

# Print message without committing
autocommit -m

# Use a specific AI model
autocommit -M gpt-4
```

## Configuration

Autocommit can be configured using a `.autocommitrc` file in either your repository root or home directory. Repository-level configuration takes precedence over home directory configuration.

Example `.autocommitrc`:

```bash
# Default AI model to use
DEFAULT_MODEL="gpt-4-turbo"

# Enable verbose logging by default
VERBOSE=false
```

## Project Structure

```
autocommit/
├── autocommit.sh           # Main script
├── lib/                    # Library modules
│   ├── core/              # Core functionality
│   │   ├── config.sh      # Configuration management
│   │   └── logger.sh      # Logging system
│   ├── git/               # Git operations
│   │   └── utils.sh       # Git utility functions
│   └── ai/                # AI integration
│       └── prompts.sh     # AI prompt templates and generation
├── tests/                 # Test suite
│   ├── test_config.bats   # Configuration tests
│   ├── test_git_utils.bats # Git utility tests
│   ├── test_logger.bats   # Logging system tests
│   └── test_prompts.bats  # AI prompt tests
└── install.sh             # Installation script
```

## Development

### Requirements

- [Bats](https://github.com/bats-core/bats-core) for testing
- [ShellCheck](https://www.shellcheck.net/) for linting

### Running Tests

```bash
# Install Bats
brew install bats-core  # macOS
# or
sudo apt-get install bats  # Ubuntu/Debian

# Run all tests
bats tests/

# Run specific test file
bats tests/test_git_utils.bats
```

### Code Style

- Use shellcheck for linting
- Follow [Google's Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Document functions with comments explaining purpose, arguments, and return values
- Use meaningful variable names
- Keep functions focused and modular

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`bats tests/`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

- Inspired by [this Medium article](https://medium.com/@marc_fasel/smash-your-git-commit-messages-like-a-champ-using-chatgpt-0cbe8ea7b3df)
- Thanks to the [shell-gpt](https://github.com/TheR1D/shell_gpt) project
- Built with love and AI 🤖❤️
