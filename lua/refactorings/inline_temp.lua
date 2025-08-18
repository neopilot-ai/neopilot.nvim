-- This file contains functions for inlining temporary variables
-- Based on "Inline Temp" refactoring from Martin Fowler's book

local api = vim.api
local fn = vim.fn

local M = {}

---Inline Temp: Replace a temporary variable with the expression that assigns to it
---This refactoring removes unnecessary temporary variables to simplify code
---@param variable_name string Name of the temporary variable to inline
---@param bufnr number|nil Buffer number (defaults to current buffer)
function M.inline_temp(variable_name, bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()

  if not variable_name then
    vim.notify("inline_temp: Missing variable name", vim.log.levels.ERROR)
    return false
  end

  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local current_line = api.nvim_win_get_cursor(0)[1]

  -- Find the variable declaration and its value
  local declaration_line, variable_value = M._find_variable_declaration(lines, variable_name, current_line)

  if not declaration_line or not variable_value then
    vim.notify("inline_temp: Could not find declaration for '" .. variable_name .. "'", vim.log.levels.ERROR)
    return false
  end

  -- Find all usages of the variable after the declaration
  local usages = M._find_variable_usages(lines, variable_name, declaration_line)

  if #usages == 0 then
    vim.notify("inline_temp: No usages found for '" .. variable_name .. "'", vim.log.levels.WARN)
    return false
  end

  -- Replace all usages with the variable value (in reverse order to maintain line numbers)
  for i = #usages, 1, -1 do
    local line_num = usages[i]
    local line = lines[line_num]
    local new_line = M._replace_variable_with_value(line, variable_name, variable_value)
    lines[line_num] = new_line
  end

  -- Remove the variable declaration line
  table.remove(lines, declaration_line)

  -- Update the buffer
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  vim.notify(string.format("Inlined variable '%s' (%d usages replaced)", variable_name, #usages), vim.log.levels.INFO)
  return true
end

---Find the declaration line and value of a variable
---@param lines table All lines in the buffer
---@param variable_name string Name of the variable to find
---@param start_line number Line to start searching from
---@return number|nil, string|nil Line number and variable value
function M._find_variable_declaration(lines, variable_name, start_line)
  -- Look for patterns like:
  -- local var = value
  -- var = value
  local patterns = {
    "^%s*local%s+" .. variable_name .. "%s*=%s*(.+)$",
    "^%s*" .. variable_name .. "%s*=%s*(.+)$",
  }

  -- Search backwards from current line, then forwards
  local search_ranges = {
    { start_line, 1, -1 }, -- backwards
    { start_line + 1, #lines, 1 }, -- forwards
  }

  for _, range in ipairs(search_ranges) do
    local start, stop, step = range[1], range[2], range[3]
    for i = start, stop, step do
      local line = lines[i]
      for _, pattern in ipairs(patterns) do
        local value = line:match(pattern)
        if value then
          -- Clean up the value (remove trailing comments, semicolons, etc.)
          value = value:gsub("%s*%-%-.*$", ""):gsub("%s*;%s*$", ""):gsub("%s+$", "")
          return i, value
        end
      end
    end
  end

  return nil, nil
end

---Find all usages of a variable after its declaration
---@param lines table All lines in the buffer
---@param variable_name string Name of the variable
---@param declaration_line number Line where the variable is declared
---@return table Array of line numbers where the variable is used
function M._find_variable_usages(lines, variable_name, declaration_line)
  local usages = {}

  -- Search for usages after the declaration line
  for i = declaration_line + 1, #lines do
    local line = lines[i]

    -- Skip lines that are reassignments to the same variable
    if
      not line:match("^%s*" .. variable_name .. "%s*=")
      and not line:match("^%s*local%s+" .. variable_name .. "%s*=")
    then
      -- Check if the variable is used in this line
      if M._line_contains_variable(line, variable_name) then table.insert(usages, i) end
    end
  end

  return usages
end

---Check if a line contains a variable usage (not declaration)
---@param line string The line to check
---@param variable_name string Name of the variable
---@return boolean True if the variable is used in the line
function M._line_contains_variable(line, variable_name)
  -- Use word boundaries to avoid partial matches
  local patterns = {
    "^" .. variable_name .. "(%W)", -- start of line
    "(%W)" .. variable_name .. "(%W)", -- middle of line
    "(%W)" .. variable_name .. "$", -- end of line
  }

  for _, pattern in ipairs(patterns) do
    if line:match(pattern) then return true end
  end

  return false
end

---Replace variable with its value in a line
---@param line string The line to process
---@param variable_name string Variable name to replace
---@param variable_value string Value to replace with
---@return string Modified line
function M._replace_variable_with_value(line, variable_name, variable_value)
  -- Use word boundaries to avoid partial matches
  local pattern = "(%W)" .. variable_name .. "(%W)"
  local replacement = "%1(" .. variable_value .. ")%2"

  -- Handle start of line
  line = line:gsub("^" .. variable_name .. "(%W)", "(" .. variable_value .. ")%1")
  -- Handle end of line
  line = line:gsub("(%W)" .. variable_name .. "$", "%1(" .. variable_value .. ")")
  -- Handle middle of line
  line = line:gsub(pattern, replacement)

  return line
end

---Inline temporary variable under cursor
function M.inline_temp_under_cursor()
  local word = fn.expand("<cword>")
  if word == "" then
    vim.notify("inline_temp: No word under cursor", vim.log.levels.WARN)
    return false
  end

  return M.inline_temp(word)
end

---Inline temporary variable with interactive selection
function M.inline_temp_interactive()
  local word = fn.expand("<cword>")
  local default = word ~= "" and word or ""

  local variable_name = fn.input("Variable to inline: ", default)
  if variable_name == "" then return false end

  return M.inline_temp(variable_name)
end

return M
