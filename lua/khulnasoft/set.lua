-- UI and cursor settings
vim.opt.guicursor = ""  -- Use block cursor everywhere

-- Line numbers
vim.opt.nu = true               -- Show absolute line numbers
vim.opt.relativenumber = true   -- Show relative line numbers

-- Tabs and indentation
vim.opt.tabstop = 4             -- Number of spaces a <Tab> counts for
vim.opt.softtabstop = 4         -- Number of spaces for editing operations
vim.opt.shiftwidth = 4          -- Number of spaces for autoindent
vim.opt.expandtab = true        -- Use spaces instead of tabs

vim.opt.smartindent = true      -- Do smart autoindenting

-- Line wrapping
vim.opt.wrap = false            -- Do not wrap long lines

-- Swap and backup
vim.opt.swapfile = false        -- Do not use swap files
vim.opt.backup = false          -- Do not create backup files

-- Undo directory (only set if $HOME is defined)
local home = os.getenv("HOME")
if home then
    vim.opt.undodir = home .. "/.vim/undodir"
end
vim.opt.undofile = true         -- Persistent undo

-- Search
vim.opt.hlsearch = false        -- Do not highlight all search matches by default
vim.opt.incsearch = true        -- Show search matches as you type

-- Colors and UI
vim.opt.termguicolors = true    -- Enable 24-bit RGB colors
vim.opt.scrolloff = 8           -- Keep 8 lines above/below cursor
vim.opt.signcolumn = "yes"      -- Always show the signcolumn

-- Allow @ in file names
vim.opt.isfname:append("@-@")

-- Performance
vim.opt.updatetime = 50         -- Faster completion

-- Visual guide at 80 chars
vim.opt.colorcolumn = "80"

-- Extra: Enable mouse support (optional)
vim.opt.mouse = "a"

-- Extra: Show matching parentheses
vim.opt.showmatch = true

-- End of settings
