local M = {}
local H = require("vim.health")
local Utils = require("neopilot.utils")
local Config = require("neopilot.config")
local uv = vim.loop or vim.uv or vim.loop

function M.check()
  H.start("neopilot.nvim")

  -- Required dependencies with their module names
  local required_plugins = {
    ["plenary.nvim"] = {
      path = "nvim-lua/plenary.nvim",
      module = "plenary",
    },
    ["nui.nvim"] = {
      path = "MunifTanjim/nui.nvim",
      module = "nui.popup",
    },
  }

  for name, plugin in pairs(required_plugins) do
    if Utils.has(name) or Utils.has(plugin.module) then
      H.ok(string.format("Found required plugin: %s", plugin.path))
    else
      H.error(string.format("Missing required plugin: %s", plugin.path))
    end
  end

  -- Optional dependencies
  if Utils.icons_enabled() then
    H.ok("Found icons plugin (nvim-web-devicons or mini.icons)")
  else
    H.warn("No icons plugin found (nvim-web-devicons or mini.icons). Icons will not be displayed")
  end

  -- Check input UI provider
  local input_provider = Config.input and Config.input.provider or "native"
  if input_provider == "dressing" then
    if Utils.has("dressing.nvim") or Utils.has("dressing") then
      H.ok("Found configured input provider: dressing.nvim")
    else
      H.error("Input provider is set to 'dressing' but dressing.nvim is not installed")
    end
  elseif input_provider == "snacks" then
    if Utils.has("snacks.nvim") or Utils.has("snacks") then
      H.ok("Found configured input provider: snacks.nvim")
    else
      H.error("Input provider is set to 'snacks' but snacks.nvim is not installed")
    end
  end
  
  -- Check performance configuration
  H.start("Performance Configuration")
  if Config.performance.enable_telemetry then
    H.ok("Telemetry is enabled (sample rate: " .. (Config.performance.telemetry_sample_rate * 100) .. "%)")
  else
    H.warn("Telemetry is disabled. Performance monitoring will be limited")
  end
  
  if Config.performance.max_concurrent_requests > 10 then
    H.warn("High concurrent request limit: " .. Config.performance.max_concurrent_requests .. " may impact performance")
  end
  
  -- Check system resources
  H.start("System Resources")
  local mem = collectgarbage('count') / 1024 -- MB
  local mem_percent = (mem / Config.performance.max_memory_usage_mb) * 100
  
  if mem_percent > 80 then
    H.error(string.format("High memory usage: %.2fMB (%.1f%% of limit)", mem, mem_percent))
  else
    H.ok(string.format("Memory usage: %.2fMB (%.1f%% of limit)", mem, mem_percent))
  end
  
  -- Check provider health
  H.start("AI Provider Health")
  for name, provider in pairs(Config.providers) do
    if provider.api_key then
      H.ok(string.format("API key found for provider: %s", name))
      
      -- Simple connectivity check for the provider
      local start_time = uv.hrtime()
      local ok, _ = pcall(require, "neopilot.providers." .. name)
      local end_time = uv.hrtime()
      local load_time = (end_time - start_time) / 1e6 -- ms
      
      if ok then
        H.ok(string.format("Provider '%s' loaded successfully (%.2fms)", name, load_time))
      else
        H.error(string.format("Failed to load provider '%s'", name))
      end
    else
      H.warn(string.format("No API key configured for provider: %s", name))
    end
  end
    H.ok("Using native input provider (no additional dependencies required)")
  end

  -- Check Copilot if configured
  if Config.provider and Config.provider == "copilot" then
    if Utils.has("copilot.lua") or Utils.has("copilot.vim") or Utils.has("copilot") then
      H.ok("Found Copilot plugin")
    else
      H.error("Copilot provider is configured but neither copilot.lua nor copilot.vim is installed")
    end
  end

  -- Check TreeSitter dependencies
  M.check_treesitter()
end

-- Check TreeSitter functionality and parsers
function M.check_treesitter()
  H.start("TreeSitter Dependencies")

  -- List of important parsers for neopilot.nvim
  local essential_parsers = {
    "markdown",
  }

  local missing_parsers = {} ---@type string[]

  for _, parser_name in ipairs(essential_parsers) do
    local loaded_parser = vim.treesitter.language.add(parser_name)
    if not loaded_parser then missing_parsers[#missing_parsers + 1] = parser_name end
  end

  if #missing_parsers == 0 then
    H.ok("All essential TreeSitter parsers are installed")
  else
    H.warn(
      string.format(
        "Missing recommended parsers: %s. Install with :TSInstall %s",
        table.concat(missing_parsers, ", "),
        table.concat(missing_parsers, " ")
      )
    )
  end

  -- Check TreeSitter highlight
  local _, highlighter = pcall(require, "vim.treesitter.highlighter")
  if not highlighter then
    H.warn("TreeSitter highlighter not available. Syntax highlighting might be limited")
  else
    H.ok("TreeSitter highlighter is available")
  end
end

return M
