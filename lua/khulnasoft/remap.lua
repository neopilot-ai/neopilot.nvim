-- Set <Space> as leader
vim.g.mapleader = " "

-- File explorer
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Open netrw file explorer" })

-- Move selected lines up/down (visual mode)
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Test file (Plenary)
pcall(function()
  vim.keymap.set("n", "<leader>tf", "<Plug>PlenaryTestFile", { noremap = false, silent = false, desc = "Test current file" })
end)

-- Join lines, keep cursor in place
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines, stay in place" })

-- Center after half-page jump
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half-page down & center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half-page up & center" })

-- Center search results
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search, center" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search, center" })

-- Format around paragraph and return cursor
vim.keymap.set("n", "=ap", "ma=ap'a", { desc = "Reformat paragraph & return" })

-- LSP: Restart
vim.keymap.set("n", "<leader>lsp", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })

-- Vim With Me
pcall(function()
  vim.keymap.set("n", "<leader>vwm", function() require("vim-with-me").StartVimWithMe() end, { desc = "Start Vim-With-Me" })
  vim.keymap.set("n", "<leader>svwm", function() require("vim-with-me").StopVimWithMe() end, { desc = "Stop Vim-With-Me" })
end)

-- Paste over selection without yanking
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without yank" })

-- Yank to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })

-- Delete to black hole
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yank" })

-- Insert mode: <C-c> as <Esc>
vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Better escape in insert mode" })

-- Disable Q (Ex mode)
vim.keymap.set("n", "Q", "<nop>", { desc = "Disable Ex mode" })

-- Tmux sessionizer (document dependency!)
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "Open Tmux sessionizer" })

-- Format buffer (with conform.nvim plugin)
pcall(function()
  vim.keymap.set("n", "<leader>f", function() require("conform").format({ bufnr = 0 }) end, { desc = "Format buffer" })
end)

-- Quickfix/Loclist navigation
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Prev quickfix" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next loclist" })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Prev loclist" })

-- Substitute word under cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substitute word under cursor" })

-- Make current file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make file executable" })

-- Error handling snippets for Go (document language specificity)
vim.keymap.set("n", "<leader>ee", "oif err != nil {<CR>}<Esc>Oreturn err<Esc>", { desc = "Insert Go error check" })
vim.keymap.set("n", "<leader>ea", "oassert.NoError(err, \"\")<Esc>F\";a", { desc = "Insert Go assert no error" })
vim.keymap.set("n", "<leader>ef", "oif err != nil {<CR>}<Esc>Olog.Fatalf(\"error: %s\\n\", err.Error())<Esc>jj", { desc = "Insert Go fatal error handler" })
vim.keymap.set("n", "<leader>el", "oif err != nil {<CR>}<Esc>O.logger.Error(\"error\", \"error\", err)<Esc>F.;i", { desc = "Insert Go logger error" })

-- Cellular automaton (if plugin available)
pcall(function()
  vim.keymap.set("n", "<leader>ca", function() require("cellular-automaton").start_animation("make_it_rain") end, { desc = "Start cellular automaton" })
end)

-- Source current file
vim.keymap.set("n", "<leader><leader>", function() vim.cmd("so") end, { desc = "Source current file" })
