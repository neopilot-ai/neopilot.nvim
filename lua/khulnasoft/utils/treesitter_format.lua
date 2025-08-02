local M = {}

local function node_contains_cursor(node)
  local ts_utils = require("nvim-treesitter.ts_utils")
  local cursor_node = ts_utils.get_node_at_cursor()
  if not cursor_node or not node then return false end
  local srow, scol, erow, ecol = node:range()
  local cur_row, cur_col = unpack(vim.api.nvim_win_get_cursor(0))
  cur_row = cur_row - 1
  return (cur_row > srow or (cur_row == srow and cur_col >= scol)) and
         (cur_row < erow or (cur_row == erow and cur_col <= ecol))
end

local function get_large_node_range()
  local parsers = require("nvim-treesitter.parsers")
  local query = require("vim.treesitter.query")

  local bufnr = vim.api.nvim_get_current_buf()
  local lang = parsers.get_buf_lang(bufnr)
  if not lang then return nil end

  local q = query.get(lang, "textobjects")
  if not q then return nil end

  local parser = parsers.get_parser(bufnr, lang)
  local root = parser:parse()[1]:root()

  local captures = { "function.outer", "class.outer" }
  for _, capture_name in ipairs(captures) do
    for _, match, _ in q:iter_matches(root, bufnr, 0, -1) do
      for id, node in pairs(match) do
        if q.captures[id] == capture_name then
          if node_contains_cursor(node) then
            local srow, _, erow, _ = node:range()
            return { start = { srow + 1, 0 }, ["end"] = { erow + 1, 0 } }
          end
        end
      end
    end
  end
  return nil
end

local function get_node_range()
  local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
  if not ok then return nil end
  local node = ts_utils.get_node_at_cursor()
  if not node then return nil end
  local srow, _, erow, _ = node:range()
  return { start = { srow + 1, 0 }, ["end"] = { erow + 1, 0 } }
end

function M.smart_format()
  local range = get_large_node_range() or get_node_range()
  if not range then
    vim.notify("No format-able Treesitter node found", vim.log.levels.INFO)
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
