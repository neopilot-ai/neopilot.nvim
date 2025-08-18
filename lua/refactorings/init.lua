-- Refactoring library based on Martin Fowler's "Refactoring" book
-- This module provides various refactoring techniques to improve code structure

local extract_method = require("refactorings.extract_method")
local rename_variable = require("refactorings.rename_variable")
local inline_temp = require("refactorings.inline_temp")

---@class Refactorings
local M = {}

-- Basic Refactorings (Chapter 6 from Martin Fowler's book)

---Extract Method: Turn a fragment of code into a method with a name that explains its purpose
---@param start_line number Starting line of the code to extract
---@param end_line number Ending line of the code to extract
---@param method_name string Name for the new method
---@param bufnr number|nil Buffer number (defaults to current buffer)
function M.extract_method(start_line, end_line, method_name, bufnr)
  return extract_method.extract_method(start_line, end_line, method_name, bufnr)
end

---Extract method with visual selection
---@param method_name string Name for the new method
function M.extract_method_visual(method_name) return extract_method.extract_method_visual(method_name) end

---Rename Variable: Change the name of a variable to better express its purpose
---@param old_name string Current variable name
---@param new_name string New variable name
---@param bufnr number|nil Buffer number (defaults to current buffer)
---@param scope string|nil Scope of renaming ('buffer', 'function', 'local') defaults to 'function'
function M.rename_variable(old_name, new_name, bufnr, scope)
  return rename_variable.rename_variable(old_name, new_name, bufnr, scope)
end

---Rename variable under cursor interactively
function M.rename_variable_under_cursor() return rename_variable.rename_variable_under_cursor() end

---Inline Temp: Replace a temporary variable with the expression that assigns to it
---@param variable_name string Name of the temporary variable to inline
---@param bufnr number|nil Buffer number (defaults to current buffer)
function M.inline_temp(variable_name, bufnr) return inline_temp.inline_temp(variable_name, bufnr) end

---Inline temporary variable under cursor
function M.inline_temp_under_cursor() return inline_temp.inline_temp_under_cursor() end

---Inline temporary variable with interactive selection
function M.inline_temp_interactive() return inline_temp.inline_temp_interactive() end

-- More refactoring methods can be added here following Martin Fowler's patterns:
-- - Extract Function
-- - Inline Function
-- - Extract Variable
-- - Replace Inline Code with Function Call
-- - Move Function
-- - Move Field
-- - Extract Class
-- - Inline Class
-- - Hide Delegate
-- - Remove Middle Man
-- - Substitute Algorithm

---Setup function for the refactoring library
function M.setup(opts)
  opts = opts or {}
  -- Configuration options can be added here
  -- For example: default keybindings, auto-save behavior, etc.
end

---Get all available refactoring methods
---@return table List of available refactoring methods
function M.get_available_refactorings()
  return {
    "extract_method",
    "rename_variable",
    "inline_temp",
    -- Add more as they are implemented
  }
end

return M
