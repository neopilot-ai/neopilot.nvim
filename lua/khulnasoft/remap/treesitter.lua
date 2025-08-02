-- lua/khulnasoft/remap/treesitter.lua
-- Keymaps for Treesitter-related features in Neovim

local keymap = vim.keymap.set

-- Treesitter Playground
keymap("n", "<leader>tp", "<cmd>TSPlaygroundToggle<CR>", { desc = "Toggle Treesitter Playground" })

-- Incremental Selection (recommended: use Treesitter's built-in mapping if configured)
-- If you want to use Treesitter's incremental selection, ensure it's enabled in your config
-- For demonstration, this just triggers the default <C-space>
keymap("n", "<C-space>", "<cmd>lua vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<C-space>', true, true, true))<CR>", { desc = "Incremental selection" })

-- Treesitter Refactor: Navigation
keymap("n", "gnd", function()
  local ok, nav = pcall(require, "nvim-treesitter.refactor.navigation")
  if ok and nav.goto_definition then
    nav.goto_definition()
  else
    vim.notify("nvim-treesitter.refactor.navigation not available", vim.log.levels.ERROR)
  end
end, { desc = "Goto definition" })

keymap("n", "gnD", "<cmd>TSDef<CR>", { desc = "List definitions" })

keymap("n", "<A-*>", function()
  local ok, nav = pcall(require, "nvim-treesitter.refactor.navigation")
  if ok and nav.goto_next_usage then
    nav.goto_next_usage()
  else
    vim.notify("nvim-treesitter.refactor.navigation not available", vim.log.levels.ERROR)
  end
end, { desc = "Next usage" })

keymap("n", "<A-#>", function()
  local ok, nav = pcall(require, "nvim-treesitter.refactor.navigation")
  if ok and nav.goto_previous_usage then
    nav.goto_previous_usage()
  else
    vim.notify("nvim-treesitter.refactor.navigation not available", vim.log.levels.ERROR)
  end
end, { desc = "Previous usage" })

-- Smart format current node (AST)
keymap("n", "<leader>tf", function()
  local ok, ts_fmt = pcall(require, "khulnasoft.utils.treesitter_format")
  if ok and ts_fmt.smart_format_node then
    ts_fmt.smart_format_node()
  else
    vim.notify("Treesitter format utility not available", vim.log.levels.ERROR)
  end
end, { desc = "Smart format current node (AST)" })
