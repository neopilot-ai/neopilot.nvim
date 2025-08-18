-- This file contains functions for extracting methods
-- Based on "Extract Method" refactoring from Martin Fowler's book

local api = vim.api
local fn = vim.fn

local M = {}

---Extract Method: Turn a fragment of code into a method with a name that explains its purpose
---This is one of the most common refactoring techniques
---@param start_line number Starting line of the code to extract
---@param end_line number Ending line of the code to extract
---@param method_name string Name for the new method
---@param bufnr number|nil Buffer number (defaults to current buffer)
function M.extract_method(start_line, end_line, method_name, bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()

  if not start_line or not end_line or not method_name then
    vim.notify("extract_method: Missing required parameters", vim.log.levels.ERROR)
    return false
  end

  if start_line > end_line then
    vim.notify("extract_method: start_line cannot be greater than end_line", vim.log.levels.ERROR)
    return false
  end

  -- Get the lines to extract
  local lines_to_extract = api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

  if #lines_to_extract == 0 then
    vim.notify("extract_method: No lines to extract", vim.log.levels.ERROR)
    return false
  end

  -- Detect indentation of the first line
  local first_line = lines_to_extract[1]
  local indent = first_line:match("^(%s*)")

  -- Create the new method
  local new_method = {
    indent .. "local function " .. method_name .. "()",
  }

  -- Add the extracted lines with proper indentation
  for _, line in ipairs(lines_to_extract) do
    table.insert(new_method, indent .. "    " .. line:gsub("^%s*", ""))
  end

  table.insert(new_method, indent .. "end")
  table.insert(new_method, "")

  -- Find a good place to insert the new method (before the current function)
  local insert_line = M._find_method_insertion_point(bufnr, start_line)

  -- Insert the new method
  api.nvim_buf_set_lines(bufnr, insert_line - 1, insert_line - 1, false, new_method)

  -- Replace the extracted lines with a method call
  local method_call = indent .. method_name .. "()"
  api.nvim_buf_set_lines(bufnr, start_line - 1 + #new_method, end_line + #new_method, false, { method_call })

  vim.notify("Successfully extracted method: " .. method_name, vim.log.levels.INFO)
  return true
end

---Find the best insertion point for the extracted method
---@param bufnr number Buffer number
---@param current_line number Current line number
---@return number Line number where the method should be inserted
function M._find_method_insertion_point(bufnr, current_line)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Look backwards from current line to find the start of the current function
  for i = current_line, 1, -1 do
    local line = lines[i]
    if line:match("^%s*function") or line:match("^%s*local%s+function") then return i end
  end

  -- If no function found, insert at the beginning
  return 1
end

---Extract method with visual selection
---This function works with the current visual selection
---@param method_name string Name for the new method
function M.extract_method_visual(method_name)
  local start_pos = fn.getpos("'<")
  local end_pos = fn.getpos("'>")

  local start_line = start_pos[2]
  local end_line = end_pos[2]

  return M.extract_method(start_line, end_line, method_name)
end

return M
