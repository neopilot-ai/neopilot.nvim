-- Set leader key early
vim.g.mapleader = " "

-- Helper for protected plugin keymaps
local function safe_map(mode, lhs, rhs, opts)
  local ok = pcall(vim.keymap.set, mode, lhs, rhs, opts)
  if not ok then
    -- Optionally, log or ignore
  end
end

-- ╔══════════════════════════════════════════════════╗
-- ║ File and Buffer Operations                      ║
-- ╚══════════════════════════════════════════════════╝
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Open netrw file explorer" })
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make file executable" })
vim.keymap.set("n", "<leader><leader>", function() vim.cmd("so") end, { desc = "Source current file" })

-- ╔══════════════════════════════════════════════════╗
-- ║ Moving and Editing Text                         ║
-- ╚══════════════════════════════════════════════════╝
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines, stay in place" })
vim.keymap.set("n", "=ap", "ma=ap'a", { desc = "Reformat paragraph & return" })

-- ╔══════════════════════════════════════════════════╗
-- ║ Scrolling and Search Navigation                 ║
-- ╚══════════════════════════════════════════════════╝
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half-page down & center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half-page up & center" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search result centered" })

-- ╔══════════════════════════════════════════════════╗
-- ║ Clipboard and Black Hole Register               ║
-- ╚══════════════════════════════════════════════════╝
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to black hole register" })
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste over selection without yank" })

-- ╔══════════════════════════════════════════════════╗
-- ║ Insertion and Escape                            ║
-- ╚══════════════════════════════════════════════════╝
vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "Use <C-c> as escape in insert mode" })

-- ╔══════════════════════════════════════════════════╗
-- ║ QuickFix & Location List Navigation             ║
-- ╚══════════════════════════════════════════════════╝
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Next quickfix entry" })
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Prev quickfix entry" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next location list entry" })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Prev location list entry" })

-- ╔══════════════════════════════════════════════════╗
-- ║ Substitute Word Under Cursor                    ║
-- ╚══════════════════════════════════════════════════╝
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substitute word under cursor globally" })

-- ╔══════════════════════════════════════════════════╗
-- ║ Plugin: PlenaryTestFile                         ║
-- ╚══════════════════════════════════════════════════╝
safe_map("n", "<leader>tf", "<Plug>PlenaryTestFile", { noremap = false, silent = false, desc = "Test current file (PlenaryTestFile)" })

-- ╔══════════════════════════════════════════════════╗
-- ║ Plugin: LSP                                     ║
-- ╚══════════════════════════════════════════════════╝
vim.keymap.set("n", "<leader>lsp", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })

-- ╔══════════════════════════════════════════════════╗
-- ║ Plugin: Vim With Me                             ║
-- ╚══════════════════════════════════════════════════╝
safe_map("n", "<leader>vwm", function() require("vim-with-me").StartVimWithMe() end, { desc = "Start Vim-With-Me" })
safe_map("n", "<leader>svwm", function() require("vim-with-me").StopVimWithMe() end, { desc = "Stop Vim-With-Me" })

-- ╔══════════════════════════════════════════════════╗
-- ║ Plugin: Conform (Formatter)                     ║
-- ╚══════════════════════════════════════════════════╝
safe_map("n", "<leader>f", function() require("conform").format({ bufnr = 0 }) end, { desc = "Format buffer (conform.nvim)" })

-- ╔══════════════════════════════════════════════════╗
-- ║ Plugin: Cellular Automaton                      ║
-- ╚══════════════════════════════════════════════════╝
safe_map("n", "<leader>ca", function() require("cellular-automaton").start_animation("make_it_rain") end, { desc = "Start cellular automaton (make it rain)" })

-- ╔══════════════════════════════════════════════════╗
-- ║ Tmux Integration                                ║
-- ╚══════════════════════════════════════════════════╝
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "Open Tmux sessionizer (requires tmux)" })

-- ╔══════════════════════════════════════════════════╗
-- ║ Miscellaneous                                   ║
-- ╚══════════════════════════════════════════════════╝
vim.keymap.set("n", "Q", "<nop>", { desc = "Disable Ex mode" })

-- ╔══════════════════════════════════════════════════╗
-- ║ Go Error Handling Snippets (Language-specific)   ║
-- ╚══════════════════════════════════════════════════╝
vim.keymap.set("n", "<leader>ee", "oif err != nil {<CR>}<Esc>Oreturn err<Esc>", { desc = "Go: Insert error check with return" })
vim.keymap.set("n", "<leader>ea", "oassert.NoError(err, \"\")<Esc>F\";a", { desc = "Go: Insert assert.NoError" })
vim.keymap.set("n", "<leader>ef", "oif err != nil {<CR>}<Esc>Olog.Fatalf(\"error: %s\\n\", err.Error())<Esc>jj", { desc = "Go: Insert log.Fatalf for error" })
vim.keymap.set("n", "<leader>el", "oif err != nil {<CR>}<Esc>O.logger.Error(\"error\", \"error\", err)<Esc>F.;i", { desc = "Go: Insert logger.Error for error" })
