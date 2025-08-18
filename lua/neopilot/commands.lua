local M = {}
local SuggestionCache = require("neopilot.suggestion.cache")
local Utils = require("neopilot.utils")

--- Clear the suggestion cache
---@param opts? table Additional options
function M.clear_cache(opts)
    opts = opts or {}
    local stats = SuggestionCache.stats()
    
    SuggestionCache.clear()
    
    if not opts.silent then
        Utils.info(string.format(
            "Cleared suggestion cache (freed %dKB)",
            math.floor(stats.size / 1024)
        ))
    end
    
    return stats
end

--- Get cache statistics
---@return table Cache statistics
function M.cache_stats()
    return SuggestionCache.stats()
end

-- Register commands
local function setup_commands()
    vim.api.nvim_create_user_command('NeopilotCacheClear', function()
        M.clear_cache()
    end, {
        desc = 'Clear the Neopilot suggestion cache',
    })
    
    vim.api.nvim_create_user_command('NeopilotCacheStats', function()
        local stats = M.cache_stats()
        vim.notify(string.format(
            "Neopilot Cache Stats:\n- Entries: %d\n- Size: %dKB / %dMB",
            stats.count,
            math.floor(stats.size / 1024),
            math.floor(stats.max_size / (1024 * 1024))
        ), vim.log.levels.INFO)
    end, {
        desc = 'Show Neopilot cache statistics',
    })
end

-- Initialize commands when the module is loaded
setup_commands()

return M
