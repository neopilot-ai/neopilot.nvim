---@module neopilot.config
-- Unified configuration system for Neopilot.nvim
-- Combines the best of config.lua and config_v2.lua with enhanced type safety and validation

local M = {}
local Utils = require("neopilot.utils")
local presets = require("neopilot.config.presets")

-- Type definitions
---@class neopilot.ProviderConfig
---@field endpoint string
---@field model string
---@field api_key string|nil
---@field extra table|nil

---@class neopilot.RAGServiceConfig
---@field enabled boolean
---@field host_mount string
---@field runner 'docker'|'nix'
---@field llm neopilot.ProviderConfig
---@field embed neopilot.ProviderConfig
---@field docker_extra_args string|nil

---@class neopilot.WebSearchEngineProvider
---@field api_key_name string
---@field extra_request_body table
---@field format_response_body fun(body: table): string, string?

---@class neopilot.SuggestionConfig
---@field enabled boolean
---@field debounce integer
---@field min_chars integer
---@field accept_key string
---@field accept_word_key string
---@field accept_line_key string
---@field next_suggestion_key string
---@field prev_suggestion_key string
---@field show_suggestion_on_enter boolean
---@field max_context_lines integer
---@field chunk_size integer
---@field cache_ttl integer

---@class neopilot.UIConfig
---@field border string
---@field winblend integer
---@field max_width number
---@field max_height number

---@class neopilot.PerformanceConfig
---@field enable_cache boolean
---@field max_memory_usage_mb integer
---@field chunk_size integer
---@field max_concurrent_requests integer
---@field request_timeout_ms integer
---@field enable_telemetry boolean
---@field telemetry_sample_rate number

---@class neopilot.Config
---@field debug boolean
---@field log_level 'debug'|'info'|'warn'|'error'
---@field mode 'agentic'|'legacy'
---@field provider string
---@field tokenizer 'tiktoken'|'hf'
---@field system_prompt string|fun():string|nil
---@field override_prompt_dir string|fun():string|nil
---@field suggestion neopilot.SuggestionConfig
---@field ui neopilot.UIConfig
---@field providers table<string, neopilot.ProviderConfig>
---@field performance neopilot.PerformanceConfig
---@field rag_service neopilot.RAGServiceConfig|nil
---@field web_search_engine table|nil

-- Default configuration
---@type neopilot.Config
local default_config = {
  -- Core settings
  debug = false,
  log_level = "warn",
  mode = "agentic",
  provider = "openai",
  tokenizer = "tiktoken",
  system_prompt = nil,
  override_prompt_dir = nil,
  
  -- Suggestion settings
  suggestion = {
    enabled = true,
    debounce = 100,
    min_chars = 1,
    accept_key = "<M-l>",
    accept_word_key = "<M-w>",
    accept_line_key = "<M-a>",
    next_suggestion_key = "<M-j>",
    prev_suggestion_key = "<M-k>",
    show_suggestion_on_enter = true,
    max_context_lines = 1000,
    chunk_size = 200,
    cache_ttl = 300, -- 5 minutes
  },
  
  -- UI settings
  ui = {
    border = "rounded",
    winblend = 0,
    max_width = 0.8,
    max_height = 0.8,
  },
  
  -- Provider settings
  providers = {
    openai = {
      endpoint = "https://api.openai.com/v1",
      model = "gpt-4-turbo-preview",
      api_key = os.getenv("OPENAI_API_KEY"),
    },
    anthropic = {
      endpoint = "https://api.anthropic.com/v1",
      model = "claude-3-opus-20240229",
      api_key = os.getenv("ANTHROPIC_API_KEY"),
    },
  },
  
  -- Performance settings
  performance = {
    enable_cache = true,
    max_memory_usage_mb = 500,
    chunk_size = 2000,  -- Process files in chunks of 2000 lines
    max_concurrent_requests = 5,  -- Maximum parallel requests to AI providers
    request_timeout_ms = 30000,  -- 30 second timeout for AI requests
    enable_telemetry = false,  -- Opt-in telemetry for performance monitoring
    telemetry_sample_rate = 0.1,  -- Sample 10% of requests for telemetry
  },
  
  -- RAG service (optional)
  rag_service = nil,
  
  -- Web search engine (optional)
  web_search_engine = nil,
  },
}

-- Schema for configuration validation
local config_schema = {
  debug = { type = "boolean" },
  log_level = { type = "string", one_of = { "trace", "debug", "info", "warn", "error", "fatal" } },
  suggestion = {
    type = "table",
    fields = {
      enabled = { type = "boolean" },
      min_chars = { type = "number", min = 0 },
      debounce = { type = "number", min = 0 },
      max_context_lines = { type = "number", min = 100, max = 10000 },
      chunk_size = { type = "number", min = 10, max = 1000 },
      cache_ttl = { type = "number", min = 0 },
    },
  },
  ui = {
    type = "table",
    fields = {
      border = { type = "string" },
      winblend = { type = "number", min = 0, max = 100 },
      max_width = { type = "number", min = 0.1, max = 1.0 },
      max_height = { type = "number", min = 0.1, max = 1.0 },
    },
  },
  performance = {
    type = "table",
    fields = {
      enable_cache = { type = "boolean" },
      max_memory_usage_mb = { type = "number", min = 10 },
    },
  },
}

-- Current configuration
local current_config = vim.deepcopy(default_config)

--- Validate a configuration value against a schema
---@param value any The value to validate
---@param schema table The schema to validate against
---@param path? string Path for error messages
---@return boolean, string|nil
local function validate_value(value, schema, path)
  path = path or "config"
  
  -- Check type
  if schema.type and type(value) ~= schema.type then
    return false, string.format("%s: expected %s, got %s", path, schema.type, type(value))
  end
  
  -- Check one_of if specified
  if schema.one_of and not vim.tbl_contains(schema.one_of, value) then
    return false, string.format(
      "%s: must be one of {%s}, got '%s'",
      path,
      table.concat(schema.one_of, ", "),
      tostring(value)
    )
  end
  
  -- Check min/max for numbers
  if type(value) == "number" then
    if schema.min and value < schema.min then
      return false, string.format("%s: must be >= %d, got %d", path, schema.min, value)
    end
    if schema.max and value > schema.max then
      return false, string.format("%s: must be <= %d, got %d", path, schema.max, value)
    end
  end
  
  -- Recursively validate tables
  if type(value) == "table" and schema.fields then
    for field, field_schema in pairs(schema.fields) do
      if field_schema.required and value[field] == nil then
        return false, string.format("%s.%s is required", path, field)
      end
      
      if value[field] ~= nil then
        local valid, err = validate_value(value[field], field_schema, path .. "." .. field)
        if not valid then
          return false, err
        end
      end
    end
  end
  
  return true
end

--- Apply a configuration with validation
---@param config table The configuration to apply
---@param preset? string Optional preset name to apply
---@return boolean success
---@return string|nil error_message
function M.setup(config, preset)
  config = config or {}
  
  -- Apply preset if specified
  if preset then
    local success, result = pcall(presets.apply_preset, preset, config)
    if not success then
      return false, string.format("Failed to apply preset '%s': %s", preset, result)
    end
  end
  
  return result
end

--- Setup Neopilot configuration
---@param user_config? neopilot.Config
---@return neopilot.Config
function M.setup(user_config)
  user_config = user_config or {}
  
  -- Deep merge with defaults
  local merged_config = deep_merge(default_config, user_config)
  
  -- Validate the merged configuration
  local valid, err = validate_config(merged_config, {
    debug = "boolean",
    log_level = "log_level",
    mode = "mode",
    provider = "string",
    tokenizer = "tokenizer",
    system_prompt = { "string", "function" },
    override_prompt_dir = { "string", "function", "nil" },
    suggestion = {
      enabled = "boolean",
      debounce = "number",
      min_chars = "number",
      accept_key = "string",
      accept_word_key = "string",
      accept_line_key = "string",
      next_suggestion_key = "string",
      prev_suggestion_key = "string",
      show_suggestion_on_enter = "boolean",
      max_context_lines = "number",
      chunk_size = "number",
      cache_ttl = "number",
    },
    ui = {
      border = "string",
      winblend = "number",
      max_width = "number",
      max_height = "number",
    },
    providers = "table", -- Will be validated per provider
    performance = {
      enable_cache = "boolean",
      max_memory_usage_mb = "number",
    },
    rag_service = { "table", "nil" },
    web_search_engine = { "table", "nil" },
  })
  
  if not valid then
    vim.notify("Invalid configuration: " .. tostring(err), vim.log.levels.ERROR)
    return default_config
  end
  
  -- Validate providers
  for name, provider in pairs(merged_config.providers) do
    if not validators.provider(provider) then
      vim.notify(
        string.format("Invalid provider config for '%s': missing required fields", name),
        vim.log.levels.ERROR
      )
      return default_config
    end
  end
  
  -- Update current config
  local current_config = merged_config
  
  -- Initialize logging
  M.setup_logging()
  
  -- Apply any presets
  if current_config.preset then
    M.apply_preset(current_config.preset)
  end
  
  M.debug("Configuration loaded")
  return current_config
end

--- Get configuration value(s)
---@param key? string
---@return any
function M.get(key)
  if not key then
    return vim.deepcopy(current_config)
  end
  
  local keys = vim.split(key, '\.', { plain = true })
  local value = current_config
  
  for _, k in ipairs(keys) do
    if type(value) ~= "table" then return nil end
    value = value[k]
    if value == nil then return nil end
  end
  
  return value
end

--- Reset configuration to defaults
---@return neopilot.Config
function M.reset()
  local current_config = vim.deepcopy(default_config)
  M.setup_logging()
  return current_config
end

--- Apply a configuration preset
---@param preset_name string
---@return boolean success
function M.apply_preset(preset_name)
  local preset = presets.get(preset_name)
  if not preset then
    vim.notify("Preset not found: " .. preset_name, vim.log.levels.WARN)
    return false
  end
  
  local current_config = deep_merge(current_config, preset)
  M.debug("Applied preset: %s", preset_name)
  return true
end

--- Setup logging with current configuration
function M.setup_logging()
  local log_levels = { debug = 1, info = 2, warn = 3, error = 4 }
  local current_level = log_levels[current_config.log_level:lower()] or 3
  
  --- Log a message at the specified level
  ---@param level string
  ---@param msg string
  ---@param ... any
  M.log = function(level, msg, ...)
    local level_num = log_levels[level:lower()] or 3
    if level_num < current_level then return end
    
    local formatted_msg = string.format("[Neopilot:%s] %s", level:upper(), string.format(msg, ...))
    vim.notify(formatted_msg, vim.log.levels[level:upper()])
  end
  
  -- Add convenience methods
  M.debug = function(msg, ...) M.log("debug", msg, ...) end
  M.info = function(msg, ...) M.log("info", msg, ...) end
  M.warn = function(msg, ...) M.log("warn", msg, ...) end
  M.error = function(msg, ...) M.log("error", msg, ...) end
  
  -- Set up debug logging if enabled
  if current_config.debug then
    M.debug("Debug logging enabled")
  end
end

-- Initialize with default config
M.setup({})

return M
