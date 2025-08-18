local notifier = require("neopilot.notifier")
local globals = require("neopilot.globals")
local statusline = require("neopilot.statusline")
local lsp_health = require("neopilot.lsp.health")

---@class neopilot.lsp.handlers
local M = {}

-- LSP method handlers
local handlers = {
  ---Handle token check responses
  ---@param _err any Error information (unused)
  ---@param result table|nil Result from LSP server
  ---@param _ctx any Context information (unused)
  ---@param _config any Configuration (unused)
  ["$/neopilot/token/check"] = function(_err, result, _ctx, _config)
    local message
    if result and result.message then
      message = "neopilot.vim: " .. tostring(result.message)
    else
      message = "neopilot.vim: Unexpected error from LSP server: " .. vim.inspect(result)
    end

    notifier.notify_once(message, vim.log.levels.ERROR, {
      title = "LSP method: $/neopilot/token/check",
    })
    statusline.update_status_line(globals.GCS_UNAVAILABLE)
  end,

  ---Handle feature state change notifications
  ---@param _err any Error information (unused)
  ---@param result table|nil Result containing feature states
  ["$/neopilot/featureStateChange"] = function(_err, result)
    if not result or type(result) ~= "table" then
      notifier.notify("neopilot.vim: Invalid feature state change result", vim.log.levels.WARN)
      statusline.update_status_line(globals.GCS_UNAVAILABLE)
      return
    end

    local checks_passed = true
    local feature_states = result[1]

    if not feature_states or type(feature_states) ~= "table" then
      notifier.notify("neopilot.vim: No feature states provided", vim.log.levels.WARN)
      statusline.update_status_line(globals.GCS_UNAVAILABLE)
      return
    end

    for _, feature_state in ipairs(feature_states) do
      if feature_state.featureId then
        lsp_health.refresh_feature(feature_state.featureId, feature_state)
        if feature_state.engagedChecks and #feature_state.engagedChecks > 0 then checks_passed = false end
      end
    end

    local status = checks_passed and globals.GCS_AVAILABLE or globals.GCS_UNAVAILABLE
    statusline.update_status_line(status)
  end,
}

return handlers
