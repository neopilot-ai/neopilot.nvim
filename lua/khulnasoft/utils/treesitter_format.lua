-- Treesitter + Conform: Smart Format Utilities
local M = {}

--- Get the Treesitter node under the cursor and its range.
-- @return range table or nil if no node is found or ts_utils is missing
local function get_node_range()
  local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
  if not ok then
    vim.notify("nvim-treesitter.ts_utils not found", vim.log.levels.ERROR)
    return nil
  end
  local node = ts_utils.get_node_at_cursor()
  if not node then return nil end
  local start_row, _, end_row, _ = node:range()
  -- Adjust for 1-based indexing
  return { start = { start_row + 1, 0 }, ["end"] = { end_row + 1, 0 } }
end

--- Format the code at the current Treesitter node using conform.nvim.
function M.smart_format_at_cursor()
  local range = get_node_range()
  if not range then
    vim.notify("No Treesitter node found under cursor.", vim.log.levels.WARN)
    return
  end

  local ok, conform = pcall(require, "conform")
  if not ok then
    vim.notify("conform.nvim not found", vim.log.levels.ERROR)
    return
  end

  conform.format({ range = range })
end

return M
