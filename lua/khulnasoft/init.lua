-- lua/khulnasoft/init.lua
-- Main Neovim configuration entry point for KhulnaSoft

-- Protected load for submodules
local function safe_require(mod)
  local ok, result = pcall(require, mod)
  if not ok then
    vim.notify("Failed to load '" .. mod .. "': " .. result, vim.log.levels.WARN)
    return nil
  end
  return result
end

safe_require("khulnasoft.set")
safe_require("khulnasoft.remap")
safe_require("khulnasoft.lazy_init")

-- Utility: Reload a module (for development)
local function reload_module(name)
  local ok, reload = pcall(require, "plenary.reload")
  if ok then
    reload.reload_module(name)
    vim.notify("Module '" .. name .. "' reloaded!", vim.log.levels.INFO)
  else
    vim.notify("plenary.reload not found!", vim.log.levels.WARN)
  end
end
_G.R = reload_module

-- Register custom filetype extensions
pcall(function()
  vim.filetype.add({
    extension = {
      templ = "templ",
      -- Extend extensions here
    },
  })
end)

-- Create augroups
local augroup = vim.api.nvim_create_augroup
local khulna_group = augroup("KhulnaSoft", {})
local yank_group = augroup("HighlightYank", {})

-- Yank highlight
vim.api.nvim_create_autocmd("TextYankPost", {
  group = yank_group,
  pattern = "*",
  callback = function()
    vim.highlight.on_yank { higroup = "IncSearch", timeout = 80 }
  end,
})

-- Remove trailing whitespace before save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = khulna_group,
  pattern = "*",
  callback = function()
    local pos = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", pos)
  end,
})

-- Per-filetype colorscheme
vim.api.nvim_create_autocmd("BufEnter", {
  group = khulna_group,
  callback = function()
    local ok
    if vim.bo.filetype == "zig" then
      ok = pcall(vim.cmd.colorscheme, "tokyonight-night")
    else
      ok = pcall(vim.cmd.colorscheme, "rose-pine-moon")
    end
    if not ok then
      vim.notify("Colorscheme not found!", vim.log.levels.WARN)
    end
  end,
})

-- Set LSP keymaps in buffer
local function set_lsp_keymaps(bufnr)
  local opts = { buffer = bufnr }
  local map = vim.keymap.set
  map("n", "gd", vim.lsp.buf.definition, opts)
  map("n", "K", vim.lsp.buf.hover, opts)
  map("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
  map("n", "<leader>vd", vim.diagnostic.open_float, opts)
  map("n", "<leader>vca", vim.lsp.buf.code_action, opts)
  map("n", "<leader>vrr", vim.lsp.buf.references, opts)
  map("n", "<leader>vrn", vim.lsp.buf.rename, opts)
  map("i", "<C-h>", vim.lsp.buf.signature_help, opts)
  map("n", "[d", vim.diagnostic.goto_next, opts)
  map("n", "]d", vim.diagnostic.goto_prev, opts)
  -- Extend here as needed
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = khulna_group,
  callback = function(args)
    set_lsp_keymaps(args.buf)
  end,
})

-- Disable netrw for performance (uncomment to re-enable settings)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- vim.g.netrw_browse_split = 0
-- vim.g.netrw_banner = 0
-- vim.g.netrw_winsize = 25
