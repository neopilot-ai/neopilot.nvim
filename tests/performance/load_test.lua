local M = {}
local uv = vim.loop or vim.uv or vim.loop
local performance = require('neopilot.performance')
local Config = require('neopilot.config')

-- Configuration
local CONCURRENT_REQUESTS = 10
local TOTAL_REQUESTS = 50
local REQUEST_DELAY_MS = 100

--- Simulate an AI provider request
---@param request_id number
---@param callback fun(success: boolean, result: any)
local function simulate_ai_request(request_id, callback)
  local start_time = uv.hrtime()
  
  -- Simulate network delay (50-500ms)
  local delay = math.random(50, 500)
  
  uv.timer_start(uv.new_timer(), delay, 0, function()
    local end_time = uv.hrtime()
    local duration_ms = (end_time - start_time) / 1e6
    
    -- Randomly fail 5% of requests
    local success = math.random() > 0.05
    local result = {
      request_id = request_id,
      duration_ms = duration_ms,
      success = success,
      timestamp = os.time(),
    }
    
    callback(success, result)
  end)
end

--- Run load test
function M.run_load_test()
  print("Starting load test...")
  print(string.format("Concurrent requests: %d", CONCURRENT_REQUESTS))
  print(string.format("Total requests: %d", TOTAL_REQUESTS))
  print("-" * 50)
  
  local completed = 0
  local failed = 0
  local active_requests = 0
  local results = {}
  local start_time = uv.hrtime()
  
  -- Function to process next request
  local function process_next(request_id)
    if request_id > TOTAL_REQUESTS then return end
    
    active_requests = active_requests + 1
    
    -- Track request with performance module
    local end_tracking = performance.track_request("test_provider", "load_test")
    
    simulate_ai_request(request_id, function(success, result)
      end_tracking(success, success and "" or "Simulated failure")
      
      active_requests = active_requests - 1
      completed = completed + 1
      if not success then failed = failed + 1 end
      
      table.insert(results, result)
      
      -- Print progress
      if completed % 5 == 0 then
        local mem_usage = collectgarbage('count') / 1024 -- MB
        print(string.format("Progress: %d/%d (%.1f%%) | Active: %d | Mem: %.2fMB",
          completed, TOTAL_REQUESTS, 
          (completed / TOTAL_REQUESTS) * 100,
          active_requests,
          mem_usage
        ))
      end
      
      -- Process next request
      process_next(request_id + CONCURRENT_REQUESTS)
    end)
  end
  
  -- Start initial batch of requests
  for i = 1, math.min(CONCURRENT_REQUESTS, TOTAL_REQUESTS) do
    process_next(i)
  end
  
  -- Wait for all requests to complete
  local function wait_for_completion()
    if completed < TOTAL_REQUESTS then
      uv.timer_start(uv.new_timer(), 1000, 0, wait_for_completion)
      return
    end
    
    -- Calculate statistics
    local end_time = uv.hrtime()
    local total_time = (end_time - start_time) / 1e9 -- seconds
    local req_per_sec = TOTAL_REQUESTS / total_time
    local avg_time = 0
    
    for _, r in ipairs(results) do
      avg_time = avg_time + r.duration_ms
    end
    avg_time = avg_time / #results
    
    -- Print summary
    print("\nLoad Test Complete!")
    print("-" * 50)
    print(string.format("Total time: %.2f seconds", total_time))
    print(string.format("Requests per second: %.2f", req_per_sec))
    print(string.format("Average request time: %.2fms", avg_time))
    print(string.format("Success rate: %.1f%%", ((TOTAL_REQUESTS - failed) / TOTAL_REQUESTS) * 100))
    
    -- Print memory usage
    local mem_usage = collectgarbage('count') / 1024 -- MB
    print(string.format("\nMemory usage: %.2fMB", mem_usage))
    
    -- Print performance metrics
    local metrics = performance.get_metrics()
    print("\nPerformance Metrics:")
    print("-" * 50)
    print(string.format("Peak memory: %.2fMB", metrics.memory.peak))
    print(string.format("Total requests: %d", #metrics.requests))
    
    -- Calculate success rate
    local success_count = 0
    for _, req in ipairs(metrics.requests) do
      if req.status == 'completed' then
        success_count = success_count + 1
      end
    end
    print(string.format("Recorded success rate: %.1f%%", (success_count / #metrics.requests) * 100))
  end
  
  -- Start monitoring
  wait_for_completion()
end

-- Run the test
M.run_load_test()

return M
