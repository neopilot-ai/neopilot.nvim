# KhulnaSoft’s `init.lua` — Your Next-Level Neovim Setup

---

## Prerequisites

- **Neovim 0.8+** — Ensure you have the latest stable Neovim installed.  
- **ripgrep** — Install [ripgrep](https://github.com/BurntSushi/ripgrep#installation), a blazing-fast search tool that enhances Neovim’s searching capabilities.  
- **Git** — For cloning and updating this configuration.

---

## Installation Guide

### 1. Clone This Repository

```bash
git clone https://github.com/your-username/neopilot.nvim.git ~/.config/nvim
```

*(Replace `your-username` with your GitHub username if applicable.)*

### 2. Launch Neovim

Run:

```bash
nvim
```

On the first launch, this config will bootstrap and install all required plugins automatically.

### 3. Sync Plugins Manually (Optional)

If you want to manually update or install plugins, use:

```vim
:PackerSync
```

*(Or the equivalent command if you use another plugin manager.)*

---

## Features

- **Treesitter-Powered Syntax Highlighting & Folding**  
  Fast, accurate syntax highlighting and smart code folding based on syntax trees.

- **Smart Formatting with Conform.nvim**  
  Format code intelligently on demand or on save, leveraging Treesitter for precise ranges.

- **Custom Keymaps & Workflow Enhancements**  
  Streamlined keybindings to speed up navigation, searching, and refactoring.

- **Built-in Git Integration**  
  See changes, stage hunks, and navigate commits all within Neovim.

- **LSP and Autocompletion Support**  
  Out-of-the-box Language Server Protocol setup with `nvim-cmp` autocompletion.

- **Light & Dark Theme Support**  
  Choose your favorite colorscheme or switch themes dynamically.

---

## Why Follow the Commits?

Curious about how or why something changed?  
This repository has a **detailed commit history** documenting every tweak and improvement. Use the command below to quickly search commits related to any keyword or feature:

```bash
git log -S '<your-keyword-here>'
```

This helps you:

- Understand the reasoning behind changes  
- Discover new tricks and config tips  
- Adapt ideas into your own setup

---

## Customize Your Setup

This configuration is modular and designed for easy customization. You can tailor:

- Plugin list and configurations  
- Keybindings  
- Language servers and formatters  
- Themes and UI tweaks

Explore the `lua/khulnasoft/` directory to get started.

---

## Troubleshooting & Tips (Optional)

- If plugins don’t load properly, try running `:PackerSync` again.  
- Ensure you have a compatible version of Neovim (0.8 or newer).  
- Use `:checkhealth` in Neovim to diagnose potential issues.  
- Join Neovim communities on Discord or Reddit for more help!

---

Feel free to open issues or submit pull requests if you want to suggest improvements or report bugs.

Happy coding! 🚀
