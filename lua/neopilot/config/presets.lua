local M = {}

---@class NeopilotPreset
---@field name string Name of the preset
---@field description string Description of what the preset does
---@field config table Configuration overrides for this preset

---@type table<string, NeopilotPreset>
local presets = {
  default = {
    name = "Default",
    description = "Balanced settings for general use",
    config = {}
  },
  performance = {
    name = "Performance",
    description = "Optimized for speed and lower resource usage",
    config = {
      suggestion = {
        max_context_lines = 500,
        chunk_size = 100,
        debounce = 150,
      },
      debug = false,
    }
  },
  accuracy = {
    name = "Accuracy",
    description = "Favors accuracy over performance",
    config = {
      suggestion = {
        max_context_lines = 2000,
        chunk_size = 300,
        debounce = 100,
        cache_ttl = 600, -- 10 minutes
      },
      debug = false,
    }
  },
  minimal = {
    name = "Minimal",
    description = "Minimal configuration with only essential features",
    config = {
      suggestion = {
        enabled = true,
        min_chars = 2,
        debounce = 200,
        max_context_lines = 300,
        chunk_size = 50,
      },
      debug = false,
      auto_suggestions = false,
    }
  },
  debug = {
    name = "Debug",
    description = "Configuration for debugging issues",
    config = {
      debug = true,
      suggestion = {
        max_context_lines = 500,
        chunk_size = 100,
      },
      log_level = "debug",
    }
  }
}

---Get a configuration preset by name
---@param name string Name of the preset to get
---@return NeopilotPreset|nil preset The preset if found, nil otherwise
function M.get_preset(name)
  return presets[name]
end

---Get all available presets
---@return table<string, NeopilotPreset>
function M.get_presets()
  return vim.deepcopy(presets)
end

---Apply a preset to the current configuration
---@param name string Name of the preset to apply
---@param config? table Optional base config to apply the preset to
---@return table merged_config The merged configuration
function M.apply_preset(name, config)
  config = config or {}
  local preset = M.get_preset(name)
  
  if not preset then
    vim.notify(string.format("Preset '%s' not found", name), vim.log.levels.WARN)
    return config
  end
  
  -- Deep merge the config with the preset
  return vim.tbl_deep_extend("force", config, preset.config)
end

---List all available presets
---@return string[] List of preset names
function M.list_presets()
  return vim.tbl_keys(presets)
end

return M
