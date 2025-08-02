-- Create a scratch buffer and a floating window in Neovim using the Lua API

local api = vim.api

-- Create a scratch buffer (not listed, scratch)
local scratch_buf = api.nvim_create_buf(false, true)
assert(scratch_buf ~= 0, "Failed to create buffer")

-- Set buffer options (optional)
api.nvim_buf_set_option(scratch_buf, 'bufhidden', 'wipe')
api.nvim_buf_set_option(scratch_buf, 'filetype', 'neopilot-scratch')

-- Define window options for a floating window
local win_opts = {
  relative = 'editor',  -- Use 'editor' for global position, or 'win' for relative to window
  row = 3,
  col = 3,
  width = 30,
  height = 8,
  style = 'minimal',    -- Optional: Removes window decorations
  border = 'rounded',   -- Optional: Adds a border
}

-- Open the floating window
local scratch_win = api.nvim_open_win(scratch_buf, true, win_opts)
assert(scratch_win ~= 0, "Failed to open floating window")

-- (Optional) Set some lines in the buffer
api.nvim_buf_set_lines(scratch_buf, 0, -1, false, { "Hello from NeoPilot!", "This is a floating window." })
