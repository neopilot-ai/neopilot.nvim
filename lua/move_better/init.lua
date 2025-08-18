-- Main entry point for MoveBetter plugin
-- This plugin helps users improve their Vim movements

local tracker = require("move_better.tracker")
local suggestions = require("move_better.suggestions")
local ui = require("move_better.ui")

---@class MoveBetter
local M = {}

---Initialize the plugin
function M.setup()
  tracker.setup()
  suggestions.setup()
  ui.setup_keymaps()
  print("MoveBetter plugin loaded!")
end

return M
