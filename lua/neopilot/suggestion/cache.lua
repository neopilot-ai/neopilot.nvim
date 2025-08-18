local M = {}
local cache = {}
local cache_size = 0
local MAX_CACHE_SIZE = 50 * 1024 * 1024 -- 50MB max cache size
local CACHE_TTL = 5 * 60 * 1000 -- 5 minutes TTL

-- Generate a cache key from buffer content and cursor position
function M.generate_key(bufnr, cursor_pos)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local context = table.concat(lines, "\n"):sub(-2000) -- Last 2000 chars for context
    local cursor_line = cursor_pos and cursor_pos[1] or 0
    local cursor_col = cursor_pos and cursor_pos[2] or 0
    return string.format("%d:%d:%s", cursor_line, cursor_col, vim.fn.sha256(context))
end

-- Get a cached suggestion
function M.get(key)
    local item = cache[key]
    if not item then return nil end
    
    -- Check if cache item is expired
    if item.expires < vim.loop.now() then
        cache[key] = nil
        cache_size = cache_size - #item.suggestion
        return nil
    end
    
    -- Update last accessed time (LRU)
    item.last_accessed = vim.loop.now()
    return item.suggestion
end

-- Store a suggestion in cache
function M.set(key, suggestion)
    -- Check if we need to evict old items
    local suggestion_size = #suggestion
    while cache_size + suggestion_size > MAX_CACHE_SIZE do
        local oldest_key, oldest_time
        for k, v in pairs(cache) do
            if not oldest_time or v.last_accessed < oldest_time then
                oldest_key = k
                oldest_time = v.last_accessed
            end
        end
        if oldest_key then
            cache_size = cache_size - #cache[oldest_key].suggestion
            cache[oldest_key] = nil
        else
            break
        end
    end
    
    -- Add new item to cache
    cache[key] = {
        suggestion = suggestion,
        last_accessed = vim.loop.now(),
        expires = vim.loop.now() + CACHE_TTL,
    }
    cache_size = cache_size + suggestion_size
end

-- Clear the cache
function M.clear()
    cache = {}
    cache_size = 0
end

-- Get cache statistics
function M.stats()
    local count = 0
    local size = 0
    for _, v in pairs(cache) do
        count = count + 1
        size = size + #v.suggestion
    end
    return {
        count = count,
        size = size,
        max_size = MAX_CACHE_SIZE,
    }
end

return M
