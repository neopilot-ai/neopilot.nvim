# Contributing to Neopilot.nvim

Thank you for your interest in contributing to Neopilot.nvim! We welcome all forms of contributions, including bug reports, feature requests, documentation improvements, and code contributions.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Your First Code Contribution](#your-first-code-contribution)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Testing](#testing)
- [Performance Testing](#performance-testing)
- [Code Style](#code-style)
- [License](#license)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How to Contribute

### Reporting Bugs

Before creating a bug report, please check if the issue has already been reported. If it hasn't, please open a new issue with the following information:

1. **Description**: A clear and concise description of the bug
2. **Steps to Reproduce**: Step-by-step instructions to reproduce the issue
3. **Expected Behavior**: What you expected to happen
4. **Actual Behavior**: What actually happened
5. **Environment**: Your Neovim version, OS, and any relevant configuration
6. **Screenshots/Logs**: If applicable, add screenshots or logs to help explain your problem

### Suggesting Enhancements

We welcome suggestions for new features and improvements. When suggesting an enhancement, please include:

1. **Description**: A clear and concise description of the enhancement
2. **Use Case**: Why this enhancement would be useful
3. **Proposed Solution**: How you think this should be implemented (optional)
4. **Alternatives**: Any alternative solutions or features you've considered

### Your First Code Contribution

1. Fork the repository
2. Create a new branch for your feature or bugfix
3. Make your changes
4. Add tests if applicable
5. Run the test suite
6. Submit a pull request

### Pull Requests

When submitting a pull request, please ensure that:

1. Your code follows the project's code style
2. All tests pass
3. Your commit messages are clear and descriptive
4. You've updated the documentation if necessary
5. Your PR includes a description of the changes and any relevant issue numbers

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/neopilot-ai/neopilot.nvim.git
   cd neopilot.nvim
   ```

2. Install dependencies:
   ```bash
   # Install build dependencies
   make deps
   ```

3. Build the project:
   ```bash
   make build
   ```

## Testing

We use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for testing. To run the tests:

```bash
make test
```

## Performance Testing

We have a suite of performance tests to ensure Neopilot remains fast and efficient. To run the performance tests:

```bash
make test-performance
```

This will run several tests and generate a detailed performance report in the `reports` directory.

## Code Style

Please follow these code style guidelines:

- Use 2 spaces for indentation
- Use snake_case for variables and functions
- Use UPPER_SNAKE_CASE for constants
- Use PascalCase for classes and modules
- Keep lines under 80 characters when possible
- Add type annotations for functions and variables
- Document public APIs with LDoc comments

## License

By contributing to Neopilot.nvim, you agree that your contributions will be licensed under the [MIT License](LICENSE).
