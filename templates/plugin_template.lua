-- Neopilot Plugin Template
-- Save this file to ~/.local/share/nvim/site/pack/neopilot/start/your-plugin-name/
-- or use your favorite plugin manager

local M = {}

-- Plugin metadata
M.name = "neopilot-plugin-template"
M.version = "0.1.0"
M.description = "A template for Neopilot plugins"
M.author = "Your Name"
M.license = "MIT"

-- Default configuration
local default_config = {
  enabled = true,
  -- Add your default configuration here
  settings = {
    example_setting = "default value",
  },
}

-- Initialize the plugin
function M.setup(opts)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", default_config, opts or {})
  
  -- Register commands
  vim.api.nvim_create_user_command('NeopilotPluginExample', function()
    M.example_command()
  end, {})
  
  -- Set up autocommands
  M.setup_autocmds()
  
  -- Initialize any required components
  M.initialize()
  
  vim.notify(string.format("%s v%s initialized", M.name, M.version))
  return M
end

-- Example command
function M.example_command()
  print("Hello from " .. M.name)
  -- Your command logic here
end

-- Initialize plugin components
function M.initialize()
  -- Initialize any required components here
  if M.config.enabled then
    -- Your initialization code here
  end
end

-- Set up autocommands
function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup(M.name, { clear = true })
  
  -- Example autocommand
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    pattern = "*.lua",
    callback = function()
      if M.config.enabled then
        -- Your autocommand logic here
      end
    end,
    desc = string.format("%s: Example autocommand", M.name),
  })
end

-- Example function to interact with Neopilot
function M.integrate_with_neopilot()
  -- Access Neopilot's API
  local neopilot = require('neopilot')
  
  -- Example: Register a new provider
  neopilot.register_provider({
    name = "my-custom-provider",
    complete = function(params, callback)
      -- Your completion logic here
      local suggestions = {
        { text = "Example suggestion", priority = 1 }
      }
      callback(suggestions)
    end,
  })
end

-- Health check function
function M.health()
  vim.health.report_start(M.name .. " health check")
  
  -- Check if Neopilot is available
  local has_neopilot = pcall(require, 'neopilot')
  if has_neopilot then
    vim.health.ok("Neopilot is available")
  else
    vim.health.error("Neopilot is not available")
  end
  
  -- Add your health checks here
  vim.health.ok("Plugin is properly set up")
  
  return true
end

-- Return the module
return M
