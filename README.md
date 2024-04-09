# Autocommit

Autocommit automates the process of committing changes in your git repository by generating meaningful commit messages based on the staged changes. This tool leverages the sgpt command to analyze your changes and create concise, relevant commit messages, simplifying your git workflow.

## Features

- **Automatic Commit Messages**: Autocommit uses the sgpt command to analyze staged changes and generate commit messages that accurately reflect the key modifications. This feature helps maintain a clear and meaningful project history without the need for manual message composition.

- **Custom Context**: You can add a custom context (e.g., issue or task numbers) to your commit messages. This is particularly useful for linking commits to specific work items or issues in your project management tools.

- **Logging**: Autocommit supports logging all generated commit messages to a specified file. This can be invaluable for record-keeping, auditing, or simply keeping track of changes over time.

## Installation

To install Autocommit, follow these steps:

1. Clone this repository:

```bash
git clone https://github.com/aspectaurora/autocommit.git
```

2. Navigate to the cloned directory:

```bash
cd autocommit
```

3. Run the installation script with root privileges:

```bash
sudo bash install.sh
```

## Usage

To use Autocommit, navigate to your git repository and run:

```bash
autocommit
```

Additional options include:

- `-c <context>`: Add a custom context to the commit message.
- `-l <logfile>`: Specify a logfile to record commit messages.

Example:

```bash
autocommit -c "Fixes issue #123" -l ~/logs/autocommit.log
```

For more examples and detailed usage instructions, refer to the [Usage](#usage) section.

## Troubleshooting

Encountering issues with Autocommit can be frustrating, but here are a few steps to help diagnose and resolve the most common problems:

1. **Verify Dependencies**: Ensure that both `git` and `sgpt` are installed on your system. You can check this by running `git --version` and `sgpt --version` in your terminal. If either command is not recognized, you will need to install the missing software.

2. **Check for Permission Errors**: If you encounter permission errors during installation or execution, make sure you have the necessary permissions to install scripts in the target directory and to execute the Autocommit script. Running the installation script with `sudo` can resolve most permission issues.

3. **Review Installation Steps**: If Autocommit is not working as expected, revisit the installation steps in this document to ensure all steps were followed correctly. Missing a step or executing commands in the wrong order can lead to issues.

4. **Consult the Log File**: If you're using the logging feature, check the log file for error messages or commit failures. This can provide clues to what might be going wrong.

5. **Check Git Repository Status**: Autocommit works within the context of a git repository. Ensure you're running Autocommit in a directory that is part of a git repository and that there are staged changes to commit.

If you've gone through these steps and are still experiencing issues, please visit the GitHub issues page for Autocommit and search for similar problems or open a new issue with a detailed description of your problem.

## License

Autocommit is released under the MIT License, a permissive free software license that allows for private, commercial, and open-source use. The MIT License also permits modification and distribution of the software under the same license.

For the full license text, please see the LICENSE file included in this repository or visit [MIT License](https://opensource.org/licenses/MIT) on the Open Source Initiative website.

This ensures that users can confidently use, modify, and share Autocommit while understanding their rights and responsibilities under the license.

### Inspired by:
