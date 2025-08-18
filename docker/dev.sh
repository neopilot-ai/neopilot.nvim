#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
PLUGIN_MANAGER="lazy"
LSP_INSTALLER="mason"
NEOPILOT_BRANCH="main"
NEOVIM_VERSION="stable"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--plugin-manager)
      PLUGIN_MANAGER="$2"
      shift # past argument
      shift # past value
      ;;
    -l|--lsp-installer)
      LSP_INSTALLER="$2"
      shift
      shift
      ;;
    -b|--branch)
      NEOPILOT_BRANCH="$2"
      shift
      shift
      ;;
    -v|--neovim-version)
      NEOVIM_VERSION="$2"
      shift
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -p, --plugin-manager    Plugin manager to use (lazy, packer, packadd). Default: lazy"
      echo "  -l, --lsp-installer     LSP installer to use (mason, neopilot). Default: mason"
      echo "  -b, --branch            Neopilot.nvim branch to use. Default: main"
      echo "  -v, --neovim-version    Neovim version to use. Default: stable"
      echo "  -h, --help              Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate plugin manager
case $PLUGIN_MANAGER in
  lazy|packer|packadd)
    # Valid plugin manager
    ;;
  *)
    echo "Error: Invalid plugin manager. Must be one of: lazy, packer, packadd"
    exit 1
    ;;
esac

# Validate LSP installer
case $LSP_INSTALLER in
  mason|neopilot)
    # Valid LSP installer
    ;;
  *)
    echo "Error: Invalid LSP installer. Must be one of: mason, neopilot"
    exit 1
    ;;
esac

echo -e "${GREEN}🚀 Setting up Neovim development environment${NC}"
echo -e "  Plugin Manager: ${YELLOW}${PLUGIN_MANAGER}${NC}"
echo -e "  LSP Installer: ${YELLOW}${LSP_INSTALLER}${NC}"
echo -e "  Neopilot Branch: ${YELLOW}${NEOPILOT_BRANCH}${NC}"
echo -e "  Neovim Version: ${YELLOW}${NEOVIM_VERSION}${NC}"

# Export environment variables
export PLUGIN_MANAGER
export LSP_INSTALLER
export NEOPILOT_VIM_BRANCH=$NEOPILOT_BRANCH
export NEOVIM_VERSION

# Build and start the environment
docker-compose build --build-arg NEOVIM_VERSION

echo -e "${GREEN}✅ Environment ready!${NC}"
echo -e "To start Neovim, run: ${YELLOW}docker-compose up -d && docker-compose exec neovim nvim${NC}"
echo -e "To access the container shell: ${YELLOW}docker-compose exec neovim /bin/sh${NC}"
