local notifier = require("neopilot.notifier")

---@class neopilot.lsp.workspace
local M = {}

---@class NeopilotWorkspace
---@field configuration table
---@field change_configuration fun(self: NeopilotWorkspace, cfg: table)
---@field subscribe_client fun(client_id: number)

---Create a new workspace instance
---@return NeopilotWorkspace
function M.new()
  local notify_lsp_client = function() return nil end

  return {
    configuration = {},

    ---Change workspace configuration and notify LSP client
    ---@param cfg table New configuration to merge
    change_configuration = function(self, cfg)
      if not cfg or type(cfg) ~= "table" then
        notifier.notify("neopilot.vim: Invalid configuration provided", vim.log.levels.ERROR)
        return
      end

      local updated = vim.tbl_extend("keep", cfg, self.configuration)
      if not vim.deep_equal(self.configuration, updated) then
        self.configuration = updated

        -- Notify LSP client of configuration change
        notify_lsp_client("workspace/didChangeConfiguration", {
          settings = self.configuration,
        })

        notifier.notify("neopilot.vim: Workspace configuration changed", vim.log.levels.INFO)
      end
    end,

    ---Subscribe an LSP client to workspace notifications
    ---@param client_id number LSP client ID
    subscribe_client = function(client_id)
      if not client_id or type(client_id) ~= "number" then
        notifier.notify("neopilot.vim: Invalid client ID provided", vim.log.levels.ERROR)
        return
      end

      notifier.notify("neopilot.vim: Subscribing client " .. tostring(client_id), vim.lsp.log_levels.DEBUG)

      notify_lsp_client = function(...)
        local client = vim.lsp.get_client_by_id(client_id)
        if client then
          return client.notify(...)
        else
          notifier.notify("neopilot.vim: Client " .. tostring(client_id) .. " not found", vim.log.levels.WARN)
        end
      end
    end,
  }
end

return M
