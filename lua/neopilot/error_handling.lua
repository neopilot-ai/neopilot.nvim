local M = {}
local Config = require("neopilot.config")
local Utils = require("neopilot.utils")

---@class NeopilotError
---@field code string Error code for programmatic handling
---@field message string Human-readable error message
---@field details? table Additional error details
---@field source? string Where the error originated from

---@type table<string, {message: string, level: integer}>
local ERROR_CODES = {
    -- API errors (1000-1999)
    API_CONNECTION_FAILED = { message = "Failed to connect to the API", level = vim.log.levels.ERROR },
    API_RATE_LIMIT = { message = "API rate limit exceeded", level = vim.log.levels.WARN },
    API_INVALID_RESPONSE = { message = "Received invalid response from API", level = vim.log.levels.ERROR },
    API_AUTH_FAILED = { message = "API authentication failed", level = vim.log.levels.ERROR },
    
    -- Validation errors (2000-2999)
    INVALID_INPUT = { message = "Invalid input provided", level = vim.log.levels.WARN },
    MISSING_REQUIRED_FIELD = { message = "Missing required field", level = vim.log.levels.WARN },
    INVALID_CONFIG = { message = "Invalid configuration", level = vim.log.levels.ERROR },
    
    -- Suggestion errors (3000-3999)
    SUGGESTION_GENERATION_FAILED = { message = "Failed to generate suggestions", level = vim.log.levels.ERROR },
    SUGGESTION_CACHE_FAILED = { message = "Failed to cache suggestion", level = vim.log.levels.WARN },
    
    -- System errors (4000-4999)
    FILE_OPERATION_FAILED = { message = "File operation failed", level = vim.log.levels.ERROR },
    PROCESSING_ERROR = { message = "Error during processing", level = vim.log.levels.ERROR },
    
    -- Unknown error
    UNKNOWN = { message = "An unknown error occurred", level = vim.log.levels.ERROR },
}

--- Create a new Neopilot error
---@param code string Error code from ERROR_CODES
---@param details? table Additional error details
---@param source? string Where the error originated from
---@return NeopilotError
function M.new(code, details, source)
    local error_info = ERROR_CODES[code] or ERROR_CODES.UNKNOWN
    return {
        code = code,
        message = error_info.message,
        details = details or {},
        source = source,
        __is_neopilot_error = true,
    }
end

--- Check if an object is a Neopilot error
---@param err any
---@return boolean
function M.is_neopilot_error(err)
    return type(err) == "table" and err.__is_neopilot_error == true
end

--- Handle an error, logging it appropriately
---@param err string|table Error message or NeopilotError
---@param context? string Additional context about where the error occurred
function M.handle_error(err, context)
    local error_obj
    
    if type(err) == "string" then
        error_obj = M.new("UNKNOWN", { message = err }, context)
    elseif M.is_neopilot_error(err) then
        error_obj = err
        error_obj.source = error_obj.source or context
    else
        error_obj = M.new("UNKNOWN", {
            message = tostring(err),
            original_error = err
        }, context)
    end
    
    local error_info = ERROR_CODES[error_obj.code] or ERROR_CODES.UNKNOWN
    local log_level = error_info.level or vim.log.levels.ERROR
    
    -- Build error message
    local message = string.format("[Neopilot] %s", error_obj.message)
    if error_obj.source then
        message = string.format("%s (Source: %s)", message, error_obj.source)
    end
    
    -- Add details if present
    if next(error_obj.details or {}) then
        message = string.format("%s\nDetails: %s", message, vim.inspect(error_obj.details))
    end
    
    -- Log the error
    vim.schedule(function()
        vim.notify(message, log_level)
        
        -- Debug logging if enabled
        if Config.debug then
            Utils.debug(string.format("Error: %s", message))
            if error_obj.trace then
                Utils.debug("Stack trace:", error_obj.trace)
            end
        end
    end)
    
    -- Return the error object for further handling if needed
    return error_obj
end

--- Wrap a function with error handling
---@param fn function Function to wrap
---@param context? string Context for error messages
---@return function Wrapped function with error handling
function M.wrap(fn, context)
    return function(...)
        local ok, result = xpcall(fn, debug.traceback, ...)
        if not ok then
            return M.handle_error(result, context)
        end
        return result
    end
end

--- Validate input parameters
---@param params table Parameters to validate
---@param required_fields string[] List of required field names
---@return boolean, string|nil True if valid, false and error message if not
function M.validate_params(params, required_fields)
    if type(params) ~= "table" then
        return false, "Parameters must be a table"
    end
    
    for _, field in ipairs(required_fields or {}) do
        if params[field] == nil then
            return false, string.format("Missing required parameter: %s", field)
        end
    end
    
    return true
end

-- Add error codes to the module for easy access
for code, _ in pairs(ERROR_CODES) do
    M[code] = code
end

return M
