local M = {}
local config = require('neopilot.config')
local uv = vim.loop or vim.uv or vim.loop

-- Performance metrics storage
local metrics = {
  requests = {},
  memory_usage = {
    current = 0,
    peak = 0,
  },
  timings = {},
  errors = {},
}

-- Track memory usage
local function update_memory_usage()
  local mem = collectgarbage('count') / 1024 -- Convert KB to MB
  metrics.memory_usage.current = mem
  if mem > metrics.memory_usage.peak then
    metrics.memory_usage.peak = mem
  end
  
  -- Log warning if approaching memory limit
  if mem > config.performance.max_memory_usage_mb * 0.8 then
    vim.schedule(function()
      vim.notify(string.format(
        "High memory usage: %.2fMB (%.1f%% of limit)",
        mem,
        (mem / config.performance.max_memory_usage_mb) * 100
      ), vim.log.levels.WARN)
    end)
  end
end

-- Track request timing
function M.track_request(provider, request_type)
  if not config.performance.enable_telemetry or math.random() > config.performance.telemetry_sample_rate then
    return function() end -- No-op if telemetry is disabled or not sampled
  end
  
  local request_id = #metrics.requests + 1
  local start_time = uv.hrtime()
  
  metrics.requests[request_id] = {
    provider = provider,
    type = request_type,
    start_time = start_time,
    status = 'started',
  }
  
  return function(success, error_msg)
    local end_time = uv.hrtime()
    local duration_ms = (end_time - start_time) / 1e6 -- Convert to milliseconds
    
    metrics.requests[request_id] = {
      provider = provider,
      type = request_type,
      duration_ms = duration_ms,
      status = success and 'completed' or 'failed',
      error = error_msg,
      timestamp = os.time(),
    }
    
    -- Update memory usage after request
    update_memory_usage()
    
    -- Log slow requests
    if duration_ms > 5000 then  -- 5 seconds
      vim.schedule(function()
        vim.notify(string.format(
          "Slow %s request to %s: %.2fms",
          request_type,
          provider,
          duration_ms
        ), vim.log.levels.WARN)
      end)
    end
  end
end

-- Get performance metrics
function M.get_metrics()
  return {
    memory = metrics.memory_usage,
    requests = metrics.requests,
    errors = metrics.errors,
  }
end

-- Reset metrics
function M.reset_metrics()
  metrics = {
    requests = {},
    memory_usage = {
      current = 0,
      peak = metrics.memory_usage.peak, -- Keep peak memory
    },
    timings = {},
    errors = {},
  }
end

-- Periodically log performance metrics
local timer = uv.new_timer()
if config.performance.enable_telemetry then
  timer:start(0, 60000, function() -- Log every minute
    local mem = collectgarbage('count') / 1024
    vim.schedule(function()
      vim.notify(string.format(
        "Neopilot: Memory: %.2fMB (Peak: %.2fMB) | Active requests: %d",
        mem,
        metrics.memory_usage.peak,
        #metrics.requests
      ), vim.log.levels.INFO)
    end)
  end)
end

-- Cleanup on exit
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    if timer then
      timer:stop()
      timer:close()
    end
  end,
})

return M
