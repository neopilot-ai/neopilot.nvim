# Neopilot.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.10.0+-57A143?style=flat&logo=neovim)](https://neovim.io/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Security](https://img.shields.io/badge/Security-Hardened-brightgreen)](https://github.com/neopilot-ai/neopilot.nvim/security)
[![CodeQL](https://github.com/neopilot-ai/neopilot.nvim/actions/workflows/codeql-analysis.yml/badge.svg)](https://github.com/neopilot-ai/neopilot.nvim/actions/workflows/codeql-analysis.yml)
[![Dependabot](https://img.shields.io/badge/dependabot-enabled-0366d6.svg?logo=dependabot)](https://github.com/neopilot-ai/neopilot.nvim/network/updates)

Neopilot.nvim is a powerful AI-powered code assistant for Neovim that provides intelligent code completions, chat-based assistance, and code understanding capabilities.

## ✨ Features

- **AI-Powered Completions**: Get smart, context-aware code suggestions as you type
- **Chat Interface**: Interactive chat for code explanations and generation
- **Code Understanding**: Advanced analysis of your codebase for better suggestions
- **Multi-Language Support**: Works with a wide range of programming languages
- **Neovim Native**: Built specifically for Neovim 0.10.0 and above
- **Customizable**: Extensive configuration options to tailor to your workflow

## 🔒 Security Features

- **Dependabot Integration**: Automatic dependency updates with security patches
- **CodeQL Analysis**: Continuous code scanning for vulnerabilities
- **Secret Scanning**: Automated detection of sensitive information in code
- **CSP & Security Headers**: Protection against common web vulnerabilities
- **Automated Security Testing**: Regular security scans and compliance checks
- **Commit Signing**: Ensures the integrity of all commits

## 🚀 Getting Started

### Prerequisites

- Neovim 0.10.0 or higher
- [Lazy.nvim](https://github.com/folke/lazy.nvim) package manager
- Node.js 18+ (for web interface features)

### Security Considerations

Neopilot.nvim takes security seriously. Here are some key security features:

1. **Data Protection**:
   - All API calls use HTTPS with TLS 1.3
   - Sensitive data is never stored in plaintext
   - Secure credential management

2. **Secure Development**:
   - Regular security audits
   - Dependency vulnerability scanning
   - Secure coding practices enforced

3. **Compliance**:
   - Follows OWASP Top 10 guidelines
   - Implements security best practices
   - Regular security updates

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'neopilot-ai/neopilot.nvim',
  dependencies = {
    { 'neovim/nvim-lspconfig' },  -- Recommended but optional
  },
  config = function()
    require('neopilot').setup({
      -- Configuration options (see below)
    })
  end
}
```

## ⚙️ Configuration

```lua
require('neopilot').setup({
  -- Enable/disable auto-suggestions
  auto_suggestions = true,
  
  -- Key mappings
  mappings = {
    suggestion_accept = '<M-CR>',
    suggestion_next = '<M-]>',
    suggestion_prev = '<M-[>',
  },
  
  -- UI configuration
  ui = {
    -- Customize the appearance of suggestions
    suggestion = {
      border = 'rounded',
      highlight = 'NormalFloat',
    }
  },
  
  -- Performance optimizations
  performance = {
    debounce = 100,  -- ms
    throttle = 200,  -- ms
  }
})
```

## 🚀 Usage

### Commands

- `:NeopilotAsk [query]` - Open chat interface with optional query
- `:NeopilotAskNew` - Start a new chat session
- `:NeopilotAskEdit` - Edit selected code with AI assistance
- `:NeopilotExplain` - Get explanation for selected code
- `:NeopilotToggle` - Toggle Neopilot on/off

### Key Mappings

| Mode | Mapping | Description |
|------|---------|-------------|
| i/n  | `<M-CR>` | Accept suggestion |
| i/n  | `<M-]>`  | Next suggestion |
| i/n  | `<M-[>`  | Previous suggestion |

## 🔍 Features in Detail

### Smart Code Completion
- Context-aware suggestions based on your code
- Support for multiple programming languages
- Intelligent parameter completion

### Chat Interface
- Interactive conversation with the AI
- Code generation and explanation
- Context-aware responses based on your code

### Code Understanding
- Deep analysis of your codebase
- Cross-file context awareness
- Intelligent refactoring suggestions

## ⚡ Performance Optimizations

Neopilot.nvim includes several performance optimizations:

- **Code Chunking**: Efficiently handles large files
- **Request Batching**: Optimized network usage
- **Debouncing**: Prevents excessive computations
- **Smart Caching**: Reduces redundant processing
- **Memory Management**: Optimized for long sessions

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on how to get started.

## 📄 License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thanks to all contributors who have helped improve Neopilot.nvim
- Inspired by various AI coding assistants and Neovim plugins
