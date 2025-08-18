---@class neopilot.lsp.health
local M = {}

---@class NeoPilotFeature
---@field id string Feature identifier
---@field name string Human-readable feature name
---@field engagedChecks table[] List of engaged health checks

-- Default feature configurations
local DEFAULT_FEATURES = {
  {
    id = "authentication",
    name = "Authentication",
    engagedChecks = {},
  },
  {
    id = "chat",
    name = "Chat",
    engagedChecks = {},
  },
  {
    id = "code_suggestions",
    name = "Code Suggestions",
    engagedChecks = {},
  },
}

-- Initialize features with deep copy to avoid reference issues
M.features = vim.deepcopy(DEFAULT_FEATURES)

---Run health checks for all NeoPilot features
M.check = function()
  for _, feature in ipairs(M.features) do
    vim.health.start(feature.name)

    if not feature.engagedChecks or #feature.engagedChecks == 0 then
      vim.health.ok("no issues found")
    else
      for _, check in ipairs(feature.engagedChecks) do
        local message = check.details or "Language server engaged feature state check: " .. vim.inspect(check)
        vim.health.warn(message)
      end
    end
  end
end

---Refresh the state of a specific feature
---@param id string Feature ID to refresh
---@param state table|nil New state with engagedChecks
M.refresh_feature = function(id, state)
  if not id or type(id) ~= "string" then
    vim.notify("neopilot.lsp.health: Invalid feature ID", vim.log.levels.ERROR)
    return
  end

  for _, feature in ipairs(M.features) do
    if feature.id == id then
      feature.engagedChecks = (state and state.engagedChecks) or {}
      return
    end
  end

  vim.notify("neopilot.lsp.health: Unknown feature ID: " .. id, vim.log.levels.WARN)
end

return M
