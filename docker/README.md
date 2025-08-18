# 🚀 Neovim Development Environment with Docker

This repository provides a fully containerized development environment for Neovim with Neopilot AI integration, supporting multiple plugin managers and LSP configurations.

## ✨ Features

- 🐳 **Containerized Neovim** with all necessary dependencies
- 🔄 **Multiple Plugin Managers**: Lazy.nvim (default), Packer.nvim, or native packadd
- 🛠 **LSP Support**: Pre-configured with Mason.nvim or Neopilot's built-in LSP
- 📊 **Analytics**: Optional Snowplow Micro integration
- 🔒 **Security First**: Non-root user by default
- ⚡ **Fast Development**: Optimized Docker layers for quick rebuilds
- 🔄 **CI/CD Ready**: GitHub Actions workflow for testing and deployment

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Git

### Using the Setup Script (Recommended)

```bash
# Clone the repository
git clone https://github.com/neopilot-ai/neopilot.nvim.git
cd neopilot.nvim/docker

# Make the setup script executable
chmod +x dev.sh

# Start the environment (with default options)
./dev.sh

# Or customize the setup
./dev.sh --plugin-manager lazy --lsp-installer mason --branch main --neovim-version stable
```

### Manual Setup

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. (Optional) Edit `.env` to customize your setup

3. Build and start the environment:
   ```bash
   docker-compose up -d
   ```

4. Access Neovim:
   ```bash
   docker-compose exec neovim nvim
   ```

## ⚙️ Configuration

### Environment Variables

Edit `.env` to customize:

| Variable | Description | Default |
|----------|-------------|---------|
| `PLUGIN_MANAGER` | Plugin manager to use (`lazy`, `packer`, `packadd`) | `lazy` |
| `LSP_INSTALLER` | LSP installer (`mason` or `neopilot`) | `mason` |
| `NEOPILOT_VIM_BRANCH` | Git branch/tag of neopilot.nvim to use | `main` |
| `NEOVIM_VERSION` | Neovim version (tag or branch) | `stable` |

## 🧩 Plugin Managers

### Lazy.nvim (Default)
- 🚀 Fastest plugin manager
- 🔄 Lazy loading for better performance
- 📦 Easy configuration

### Packer.nvim
- 🔧 Traditional plugin manager
- ⚡ Good performance
- 📝 Familiar configuration format

### Native Packadd
- 🪶 Lightweight (no external dependencies)
- 🔧 Manual management
- 🏗 Ideal for minimal setups

## 🛠 Development

### Build the Image

```bash
docker-compose build
```

### Run Tests

```bash
# Run all tests
docker-compose exec neovim nvim --headless -c 'PlenaryBustedDirectory tests/ {minimal_init = "tests/init.lua"}'

# Run specific test file
docker-compose exec neovim nvim --headless -c 'PlenaryBustedFile tests/your_test_file.lua'
```

### Access the Container

```bash
# Get a shell in the container
docker-compose exec neovim /bin/sh

# Run Neovim with custom command
docker-compose exec -e PLUGIN_MANAGER=lazy neovim nvim
```

## 🔄 CI/CD

The GitHub Actions workflow in `.github/workflows/ci.yml` provides:

- ✅ Linting of Lua files
- 🐋 Multi-architecture Docker builds
- 🧪 Testing with different plugin managers
- 📦 Automatic deployment to GitHub Container Registry

## 📄 License

MIT
