---@module neopilot.config_v2
-- Enhanced configuration module with type safety and validation

local M = {}
local Utils = require("neopilot.utils")

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
---@field engine_id_name string|nil
---@field extra_request_body table
---@field format_response_body fun(body: table): string, string?

---@class neopilot.WebSearchEngineConfig
---@field provider string
---@field proxy string|nil
---@field providers table<string, neopilot.WebSearchEngineProvider>

---@class neopilot.InputConfig
---@field provider 'native'|'dressing'|'snacks'|fun(input: table):nil
---@field provider_opts table

---@class neopilot.SuggestionConfig
---@field debounce number
---@field enabled boolean

---@class neopilot.Config
---@field debug boolean
---@field mode 'agentic'|'legacy'
---@field provider string
---@field auto_suggestions_provider string|nil
---@field memory_summary_provider string|nil
---@field tokenizer 'tiktoken'|'hf'
---@field system_prompt string|fun():string|nil
---@field override_prompt_dir string|fun():string|nil
---@field rules {project_dir: string|nil, global_dir: string|nil}
---@field rag_service neopilot.RAGServiceConfig
---@field web_search_engine neopilot.WebSearchEngineConfig
---@field input neopilot.InputConfig
---@field suggestion neopilot.SuggestionConfig

-- Default configuration with type annotations
---@type neopilot.Config
local default_config = {
  debug = false,
  mode = "agentic",
  provider = "claude",
  auto_suggestions_provider = nil,
  memory_summary_provider = nil,
  tokenizer = "tiktoken",
  system_prompt = nil,
  override_prompt_dir = nil,
  rules = {
    project_dir = nil,
    global_dir = nil,
  },
  rag_service = {
    enabled = false,
    host_mount = os.getenv("HOME") or "/",
    runner = "docker",
    llm = {
      provider = "openai",
      endpoint = "https://api.openai.com/v1",
      api_key = "OPENAI_API_KEY",
      model = "gpt-4o-mini",
      extra = nil,
    },
    embed = {
      provider = "openai",
      endpoint = "https://api.openai.com/v1",
      api_key = "OPENAI_API_KEY",
      model = "text-embedding-3-large",
      extra = nil,
    },
    docker_extra_args = "",
  },
  web_search_engine = {
    provider = "tavily",
    proxy = nil,
    providers = {}
  },
  input = {
    provider = "native",
    provider_opts = {},
  },
  suggestion = {
    debounce = 300,
    enabled = true,
  },
}

-- Current configuration
---@type neopilot.Config
local current_config = vim.deepcopy(default_config)

-- Validation functions
local validators = {
  mode = function(value)
    return value == "agentic" or value == "legacy",
      string.format("mode must be 'agentic' or 'legacy', got '%s'", tostring(value))
  end,
  
  tokenizer = function(value)
    return value == "tiktoken" or value == "hf",
      string.format("tokenizer must be 'tiktoken' or 'hf', got '%s'", tostring(value))
  end,
  
  rag_service = function(value)
    if type(value) ~= "table" then return false, "rag_service must be a table" end
    if value.runner ~= nil and value.runner ~= "docker" and value.runner ~= "nix" then
      return false, "rag_service.runner must be 'docker' or 'nix'"
    end
    return true
  end
}

---Deep merge two tables
---@param t1 table
---@param t2 table
---@return table
local function deep_merge(t1, t2)
  local result = vim.deepcopy(t1)
  for k, v in pairs(t2) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = deep_merge(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

---Validate configuration against schema
---@param config table
---@return boolean, string?
local function validate_config(config)
  for key, validator in pairs(validators) do
    if config[key] ~= nil then
      local ok, err = validator(config[key])
      if not ok then
        return false, string.format("Invalid config.%s: %s", key, err)
      end
    end
  end
  return true
end

---Setup configuration with validation
---@param user_config? table
---@return neopilot.Config
function M.setup(user_config)
  user_config = user_config or {}
  
  -- Merge with defaults
  local merged = deep_merge(default_config, user_config)
  
  -- Validate the merged configuration
  local ok, err = validate_config(merged)
  if not ok then
    vim.notify(string.format("Neopilot: Invalid configuration - %s", err), vim.log.levels.ERROR)
    return current_config
  end
  
  -- Apply the configuration
  current_config = merged
  return current_config
end

---Get the current configuration
---@return neopilot.Config
function M.get()
  return current_config
end

-- Initialize with empty configuration to set defaults
M.setup({})

return M
