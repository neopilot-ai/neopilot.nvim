-- This file contains functions for renaming variables
-- Based on "Rename Variable" refactoring from Martin Fowler's book

local api = vim.api
local fn = vim.fn

local M = {}

---Rename Variable: Change the name of a variable to better express its purpose
---This refactoring improves code readability by using more descriptive names
---@param old_name string Current variable name
---@param new_name string New variable name
---@param bufnr number|nil Buffer number (defaults to current buffer)
---@param scope string|nil Scope of renaming ('buffer', 'function', 'local') defaults to 'function'
function M.rename_variable(old_name, new_name, bufnr, scope)
  bufnr = bufnr or api.nvim_get_current_buf()
  scope = scope or "function"

  if not old_name or not new_name then
    vim.notify("rename_variable: Missing required parameters", vim.log.levels.ERROR)
    return false
  end

  if old_name == new_name then
    vim.notify("rename_variable: Old and new names are the same", vim.log.levels.WARN)
    return false
  end

  -- Validate new name (basic Lua identifier validation)
  if not new_name:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then
    vim.notify("rename_variable: Invalid variable name: " .. new_name, vim.log.levels.ERROR)
    return false
  end

  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local current_line = api.nvim_win_get_cursor(0)[1]

  local start_line, end_line = M._get_scope_boundaries(lines, current_line, scope)
  local replacements = 0

  -- Process each line within the scope
  for i = start_line, end_line do
    local line = lines[i]
    local new_line = M._replace_variable_in_line(line, old_name, new_name)

    if new_line ~= line then
      lines[i] = new_line
      replacements = replacements + 1
    end
  end

  if replacements > 0 then
    -- Update the buffer
    api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.notify(
      string.format("Renamed '%s' to '%s' (%d replacements)", old_name, new_name, replacements),
      vim.log.levels.INFO
    )
    return true
  else
    vim.notify("rename_variable: No occurrences found for '" .. old_name .. "'", vim.log.levels.WARN)
    return false
  end
end

---Replace variable name in a single line, respecting word boundaries
---@param line string The line to process
---@param old_name string Variable name to replace
---@param new_name string New variable name
---@return string Modified line
function M._replace_variable_in_line(line, old_name, new_name)
  -- Use word boundaries to avoid partial matches
  -- This pattern matches the variable name when it's not part of another identifier
  local pattern = "(%W)" .. old_name .. "(%W)"
  local replacement = "%1" .. new_name .. "%2"

  -- Handle start of line
  line = line:gsub("^" .. old_name .. "(%W)", new_name .. "%1")
  -- Handle end of line
  line = line:gsub("(%W)" .. old_name .. "$", "%1" .. new_name)
  -- Handle middle of line
  line = line:gsub(pattern, replacement)

  return line
end

---Get the boundaries of the specified scope
---@param lines table All lines in the buffer
---@param current_line number Current cursor line
---@param scope string Scope type ('buffer', 'function', 'local')
---@return number, number Start line and end line (1-indexed)
function M._get_scope_boundaries(lines, current_line, scope)
  if scope == "buffer" then
    return 1, #lines
  elseif scope == "function" then
    return M._get_function_boundaries(lines, current_line)
  elseif scope == "local" then
    return M._get_local_scope_boundaries(lines, current_line)
  else
    return 1, #lines
  end
end

---Find the boundaries of the current function
---@param lines table All lines in the buffer
---@param current_line number Current cursor line
---@return number, number Start line and end line (1-indexed)
function M._get_function_boundaries(lines, current_line)
  local start_line = 1
  local end_line = #lines
  local function_depth = 0

  -- Find function start (going backwards)
  for i = current_line, 1, -1 do
    local line = lines[i]
    if line:match("^%s*end%s*$") or line:match("^%s*end%s*%-%-") then
      function_depth = function_depth + 1
    elseif line:match("^%s*function") or line:match("^%s*local%s+function") then
      if function_depth == 0 then
        start_line = i
        break
      else
        function_depth = function_depth - 1
      end
    end
  end

  -- Find function end (going forwards)
  function_depth = 0
  for i = start_line, #lines do
    local line = lines[i]
    if line:match("^%s*function") or line:match("^%s*local%s+function") then
      if i > start_line then function_depth = function_depth + 1 end
    elseif line:match("^%s*end%s*$") or line:match("^%s*end%s*%-%-") then
      if function_depth == 0 then
        end_line = i
        break
      else
        function_depth = function_depth - 1
      end
    end
  end

  return start_line, end_line
end

---Find the boundaries of the local scope (basic implementation)
---@param lines table All lines in the buffer
---@param current_line number Current cursor line
---@return number, number Start line and end line (1-indexed)
function M._get_local_scope_boundaries(lines, current_line)
  -- For now, just return a small range around the current line
  local start_line = math.max(1, current_line - 10)
  local end_line = math.min(#lines, current_line + 10)
  return start_line, end_line
end

---Rename variable under cursor interactively
function M.rename_variable_under_cursor()
  local word = fn.expand("<cword>")
  if word == "" then
    vim.notify("rename_variable: No word under cursor", vim.log.levels.WARN)
    return false
  end

  local new_name = fn.input("Rename '" .. word .. "' to: ")
  if new_name == "" then return false end

  return M.rename_variable(word, new_name)
end

return M
