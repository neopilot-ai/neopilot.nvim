local utils = require("neopilot.utils")

local M = {}

-- Constants
local DEFAULT_BINARY = "node"
local LSP_PACKAGE_NAME = "@neopilot-ai/neopilot-lsp"

---Resolve the executable path for NeoPilot LSP
---@return string path to executable
local function resolve_exepath()
  -- Check environment variable first
  local path = vim.env.NEOPILOT_VIM_LSP_BINARY_PATH

  -- Fall back to config
  if not path then
    local ok, config = pcall(require, "neopilot.config")
    if ok then path = config.current().code_suggestions.lsp_binary_path end
  end

  -- Default to node
  if not path then path = DEFAULT_BINARY end

  return vim.fn.exepath(path)
end

---Resolve the main script path for the Node.js LSP package
---@return string path to main script or empty string if not found
local function resolve_node_main_script()
  local ok, neopilot = pcall(require, "neopilot")
  if not ok then return "" end

  local lsp_package_dir = utils.joinpath(neopilot.plugin_root(), "node_modules", LSP_PACKAGE_NAME)

  local package_json_path = utils.joinpath(lsp_package_dir, "package.json")
  local package_json = io.open(package_json_path, "r")

  if not package_json then return "" end

  local json_content = package_json:read("*a")
  package_json:close()

  local ok_decode, package_data = pcall(vim.json.decode, json_content)
  if not ok_decode or not package_data.bin or not package_data.bin["neopilot-lsp"] then return "" end

  return utils.joinpath(lsp_package_dir, package_data.bin["neopilot-lsp"])
end

function M.new()
  local exepath = resolve_exepath()
  local node_main_script = resolve_node_main_script()

  return {
    cmd = function(self, opts)
      opts = opts or {}
      local args = vim.deepcopy(opts.args) or {}
      if self.is_node() then table.insert(args, 1, node_main_script) end

      return vim.tbl_flatten({ exepath, args })
    end,
    is_executable = function() return exepath ~= "" end,
    is_installed = function(self)
      if not self.is_executable() then return false end

      if self.is_node() then return node_main_script ~= "" and vim.loop.fs_stat(node_main_script) end

      return true
    end,
    is_node = function() return exepath:match("/node$") end,
  }
end

return M
