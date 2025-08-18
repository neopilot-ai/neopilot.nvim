local M = {}
local cache = {}
local debounce_timers = {}

-- Chunk size for processing large files (in lines)
local CHUNK_SIZE = 1000

-- Cache TTL in milliseconds (5 minutes)
local CACHE_TTL = 5 * 60 * 1000

--- Chunk a large string or table into smaller parts
---@param input string|table The input to chunk
---@param chunk_size? number Size of each chunk
---@return table[] List of chunks
function M.chunk_input(input, chunk_size)
    chunk_size = chunk_size or CHUNK_SIZE
    local chunks = {}
    
    if type(input) == "string" then
        local lines = vim.split(input, "\n")
        for i = 1, #lines, chunk_size do
            table.insert(chunks, table.concat(lines, "\n", i, math.min(i + chunk_size - 1, #lines)))
        end
    elseif type(input) == "table" then
        for i = 1, #input, chunk_size do
            local chunk = {}
            for j = i, math.min(i + chunk_size - 1, #input) do
                table.insert(chunk, input[j])
            end
            table.insert(chunks, chunk)
        end
    end
    
    return chunks
end

--- Batch process items with a given function
---@param items any[] Items to process
---@param process_func function Function to process each item
---@param batch_size? number Size of each batch
---@param callback? function Callback after each batch
function M.batch_process(items, process_func, batch_size, callback)
    batch_size = batch_size or 10
    local total = #items
    local processed = 0
    
    local function process_batch(start_idx)
        local end_idx = math.min(start_idx + batch_size - 1, total)
        for i = start_idx, end_idx do
            process_func(items[i], i)
        end
        
        processed = end_idx
        if callback then callback(processed, total) end
        
        if processed < total then
            vim.defer_fn(function() process_batch(processed + 1) end, 0)
        end
    end
    
    process_batch(1)
end

--- Debounce a function call
---@param fn function Function to debounce
---@param delay number Delay in milliseconds
---@param key? string Unique key for the debounced function (optional)
---@return function Debounced function
function M.debounce(fn, delay, key)
    key = key or tostring(fn)
    
    return function(...)
        local args = { ... }
        if debounce_timers[key] then
            debounce_timers[key]:stop()
            debounce_timers[key]:close()
        end
        
        debounce_timers[key] = vim.defer_fn(function()
            debounce_timers[key] = nil
            fn(unpack(args))
        end, delay)
    end
end

--- Cache a value with optional TTL
---@param key string Cache key
---@param value any Value to cache
---@param ttl? number Time to live in milliseconds
function M.cache_set(key, value, ttl)
    ttl = ttl or CACHE_TTL
    cache[key] = {
        value = value,
        expires = vim.loop.now() + ttl
    }
end

--- Get a cached value
---@param key string Cache key
---@return any|nil Cached value or nil if not found or expired
function M.cache_get(key)
    local item = cache[key]
    if not item then return nil end
    
    if item.expires and item.expires < vim.loop.now() then
        cache[key] = nil
        return nil
    end
    
    return item.value
end

--- Clear the cache
---@param key? string Optional key to clear specific item
function M.cache_clear(key)
    if key then
        cache[key] = nil
    else
        cache = {}
    end
end

return M
