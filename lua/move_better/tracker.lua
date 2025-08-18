-- Tracker for Vim movements

local M = {}

local movement_count = {}

---Setup the tracker module
function M.setup()
  -- Track normal mode movements like hjkl, w, b, etc
  vim.api.nvim_create_autocmd("CursorMoved", {
    pattern = "*",
    callback = function()
      local curr_buffer = vim.api.nvim_get_current_buf()
      movement_count[curr_buffer] = (movement_count[curr_buffer] or 0) + 1
      print("Movement Count: " .. movement_count[curr_buffer])
    end,
  })
  print("Tracker initialized")
end

return M
