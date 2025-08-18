---@class neopilot.lsp
local M = {}

-- Lazy load modules to avoid circular dependencies
local function safe_require(module_name, fallback)
  local ok, module = pcall(require, module_name)
  if not ok then
    if fallback then
      vim.notify("neopilot.lsp: Failed to load " .. module_name .. ", using fallback", vim.log.levels.WARN)
      return fallback
    else
      vim.notify("neopilot.lsp: Failed to load " .. module_name, vim.log.levels.ERROR)
      return {}
    end
  end
  return module
end

-- Export modules with safe loading
M.client = safe_require("neopilot.lsp.client", {})
M.server = safe_require("neopilot.lsp.server")
M.workspace = safe_require("neopilot.lsp.workspace")
M.health = safe_require("neopilot.lsp.health")
M.handlers = safe_require("neopilot.lsp.handlers")

return M
