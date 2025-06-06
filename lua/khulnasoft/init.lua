-- lua/khulnasoft/init.lua
-- Main Neovim configuration entry point for KhulnaSoft

-- Load submodules with error protection
pcall(require, "khulnasoft.set")
pcall(require, "khulnasoft.remap")
pcall(require, "khulnasoft.lazy_init")

-- Utility: Reload a module (for development)
local function R(name)
  local ok, reload = pcall(require, "plenary.reload")
  if ok then
    reload.reload_module(name)
  end
end
_G.R = R -- Only export if needed elsewhere

-- Register custom filetype extensions
pcall(function()
  vim.filetype.add({
    extension = {
      templ = "templ",
      -- Add more extensions as needed
    }
  })
end)

-- Create augroups
local augroup = vim.api.nvim_create_augroup
local KhulnaSoftGroup = augroup("KhulnaSoft", {})
local YankGroup = augroup("HighlightYank", {})

-- Function: Highlight on yank
local function highlight_on_yank()
  vim.highlight.on_yank({
    higroup = "IncSearch",
    timeout = 80, -- visible but not annoying
  })
end

vim.api.nvim_create_autocmd("TextYankPost", {
  group = YankGroup,
  pattern = "*",
  callback = highlight_on_yank,
})

-- Function: Remove trailing whitespace on save
local function trim_trailing_whitespace()
  local cur = vim.fn.getpos(".")
  vim.cmd([[%s/\s\+$//e]])
  vim.fn.setpos(".", cur)
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = KhulnaSoftGroup,
  pattern = "*",
  callback = trim_trailing_whitespace,
})

-- Function: Switch colorscheme based on filetype
local function set_colorscheme_for_filetype()
  local ok
  if vim.bo.filetype == "zig" then
    ok = pcall(vim.cmd.colorscheme, "tokyonight-night")
  else
    ok = pcall(vim.cmd.colorscheme, "rose-pine-moon")
  end
  if not ok then
    vim.notify("Colorscheme not found!", vim.log.levels.WARN)
  end
end

vim.api.nvim_create_autocmd("BufEnter", {
  group = KhulnaSoftGroup,
  callback = set_colorscheme_for_filetype,
})

-- LSP Keymaps: Centralized, easy to extend
local function set_lsp_keymaps(bufnr)
  local opts = { buffer = bufnr }
  local keymap = vim.keymap.set
  keymap("n", "gd", vim.lsp.buf.definition, opts)
  keymap("n", "K", vim.lsp.buf.hover, opts)
  keymap("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
  keymap("n", "<leader>vd", vim.diagnostic.open_float, opts)
  keymap("n", "<leader>vca", vim.lsp.buf.code_action, opts)
  keymap("n", "<leader>vrr", vim.lsp.buf.references, opts)
  keymap("n", "<leader>vrn", vim.lsp.buf.rename, opts)
  keymap("i", "<C-h>", vim.lsp.buf.signature_help, opts)
  keymap("n", "[d", vim.diagnostic.goto_next, opts)
  keymap("n", "]d", vim.diagnostic.goto_prev, opts)
  -- Add more mappings as needed
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = KhulnaSoftGroup,
  callback = function(e)
    set_lsp_keymaps(e.buf)
  end,
})

-- Disable netrw for performance, unless you want it
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- Uncomment below if you use netrw:
-- vim.g.netrw_browse_split = 0
-- vim.g.netrw_banner = 0
-- vim.g.netrw_winsize = 25
