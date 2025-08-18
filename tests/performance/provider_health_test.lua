local M = {}
local uv = vim.loop or vim.uv or vim.loop
local Config = require('neopilot.config')
local performance = require('neopilot.performance')

-- Configuration
local TEST_DURATION_SEC = 300 -- 5 minutes
local CHECK_INTERVAL_MS = 5000 -- 5 seconds
local MAX_FAILURES = 3 -- Maximum consecutive failures before marking as unhealthy

-- Provider health state
local health_state = {}

--- Check provider health
---@param provider_name string
---@param provider_config table
local function check_provider_health(provider_name, provider_config)
  if not health_state[provider_name] then
    health_state[provider_name] = {
      healthy = true,
      consecutive_failures = 0,
      total_checks = 0,
      total_failures = 0,
      last_check = 0,
      avg_response_time = 0,
    }
  end
  
  local state = health_state[provider_name]
  state.total_checks = state.total_checks + 1
  
  -- Simulate health check (replace with actual provider check)
  local start_time = uv.hrtime()
  local success = math.random() > 0.1 -- 90% success rate for simulation
  local end_time = uv.hrtime()
  
  local response_time = (end_time - start_time) / 1e6 -- ms
  
  -- Update moving average of response time
  state.avg_response_time = (state.avg_response_time * (state.total_checks - 1) + response_time) / state.total_checks
  
  if not success then
    state.consecutive_failures = state.consecutive_failures + 1
    state.total_failures = state.total_failures + 1
    
    if state.consecutive_failures >= MAX_FAILURES and state.healthy then
      state.healthy = false
      vim.schedule(function()
        vim.notify(string.format("Provider '%s' is unhealthy!", provider_name), vim.log.levels.ERROR)
      end)
    end
  else
    if state.consecutive_failures > 0 then
      state.consecutive_failures = math.max(0, state.consecutive_failures - 1)
    end
    
    if not state.healthy and state.consecutive_failures < MAX_FAILURES / 2 then
      state.healthy = true
      vim.schedule(function()
        vim.notify(string.format("Provider '%s' is now healthy", provider_name), vim.log.levels.INFO)
      end)
    end
  end
  
  state.last_check = os.time()
  
  -- Log the check
  performance.track_request(provider_name, "health_check")(
    success,
    success and "" or "Health check failed"
  )
  
  return state.healthy, response_time
end

--- Run provider health monitoring
function M.run_health_monitoring()
  print("Starting provider health monitoring...")
  print("Press Ctrl+C to stop\n")
  
  local start_time = uv.hrtime()
  local timer = uv.new_timer()
  
  -- Print header
  print(string.format("%-15s %-10s %-8s %-10s %-15s %-10s", 
    "Provider", "Status", "Resp(ms)", "Success %", "Last Check", "Failures"))
  print("-" * 70)
  
  -- Function to check all providers
  local function check_providers()
    for name, provider in pairs(Config.providers) do
      local healthy, response_time = check_provider_health(name, provider)
      local state = health_state[name]
      
      -- Print status
      local status = healthy and "HEALTHY" or "UNHEALTHY"
      local success_rate = ((state.total_checks - state.total_failures) / state.total_checks) * 100
      local last_check = os.date("%H:%M:%S", state.last_check)
      
      print(string.format("%-15s %-10s %-8.1f %-10.1f %-15s %d/%d",
        name,
        status,
        state.avg_response_time,
        success_rate,
        last_check,
        state.total_failures,
        state.total_checks
      ))
    end
    print() -- Empty line between updates
  end
  
  -- Initial check
  check_providers()
  
  -- Schedule periodic checks
  uv.timer_start(timer, CHECK_INTERVAL_MS, CHECK_INTERVAL_MS, function()
    -- Check if test duration has been reached
    local elapsed = (uv.hrtime() - start_time) / 1e9 -- seconds
    if elapsed >= TEST_DURATION_SEC then
      uv.timer_stop(timer)
      print("\nTest completed. Duration limit reached.")
      return
    end
    
    check_providers()
  end)
  
  -- Return cleanup function
  return function()
    uv.timer_stop(timer)
    print("\nMonitoring stopped.")
    
    -- Print final report
    print("\nFinal Health Report:")
    print("-" * 50)
    
    for name, state in pairs(health_state) do
      local success_rate = ((state.total_checks - state.total_failures) / state.total_checks) * 100
      print(string.format("Provider: %s", name))
      print(string.format("  Status: %s", state.healthy and "HEALTHY" or "UNHEALTHY"))
      print(string.format("  Availability: %.1f%%", 100 - (state.total_failures / state.total_checks) * 100))
      print(string.format("  Avg Response: %.1fms", state.avg_response_time))
      print(string.format("  Total Checks: %d", state.total_checks))
      print(string.format("  Failures: %d (%.1f%%)", 
        state.total_failures, 
        (state.total_failures / state.total_checks) * 100))
      print()
    end
  end
end

-- Run the test
local stop_monitoring = M.run_health_monitoring()

-- Handle Ctrl+C to stop monitoring
vim.api.nvim_create_autocmd('User', {
  pattern = 'NeopilotHealthTestStop',
  callback = function()
    stop_monitoring()
  end,
})

print("Press <leader>ht to stop monitoring")

-- Add a command to stop monitoring
vim.api.nvim_set_keymap('n', '<leader>ht', [[<cmd>lua vim.api.nvim_exec_autocmds('User', {pattern = 'NeopilotHealthTestStop'})<CR>]], {noremap = true, silent = true})

return M
