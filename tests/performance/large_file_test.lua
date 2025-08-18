local M = {}
local uv = vim.loop or vim.uv or vim.loop
local Path = require('plenary.path')
local performance = require('neopilot.performance')

-- Configuration
local TEST_FILE_SIZE_MB = 5 -- Target test file size in MB
local TEST_ITERATIONS = 5 -- Number of test iterations

--- Generate a large test file
---@param path string Path to save the test file
---@param size_mb number Size of the file in MB
local function generate_large_file(path, size_mb)
  local size = size_mb * 1024 * 1024
  local chunk_size = 1024 * 1024 -- 1MB chunks
  local chunks = math.ceil(size / chunk_size)
  
  -- Generate a chunk of random data
  local function generate_chunk()
    local t = {}
    for _ = 1, chunk_size do
      table.insert(t, string.char(math.random(32, 126)))
    end
    return table.concat(t)
  end
  
  -- Write chunks to file
  local file = io.open(path, 'w')
  if not file then return false end
  
  for _ = 1, chunks do
    file:write(generate_chunk())
  end
  
  file:close()
  return true
end

--- Test file processing performance
function M.test_large_file_processing()
  local test_file = vim.fn.tempname() .. '_large_file.txt'
  
  -- Generate test file
  print(string.format("Generating test file: %s (%.1f MB)", test_file, TEST_FILE_SIZE_MB))
  if not generate_large_file(test_file, TEST_FILE_SIZE_MB) then
    error("Failed to generate test file")
  end
  
  -- Test file reading with different chunk sizes
  local chunk_sizes = {512, 1024, 2048, 4096} -- Lines per chunk
  
  for _, chunk_size in ipairs(chunk_sizes) do
    print(string.format("\nTesting with chunk size: %d lines", chunk_size))
    
    local total_time = 0
    local total_memory = 0
    
    for i = 1, TEST_ITERATIONS do
      local start_time = uv.hrtime()
      local start_mem = collectgarbage('count')
      
      -- Process file in chunks
      local lines_processed = 0
      for _ in io.lines(test_file) do
        lines_processed = lines_processed + 1
        if lines_processed % chunk_size == 0 then
          -- Simulate processing
          collectgarbage('step', 2000) -- Process GC in steps
        end
      end
      
      local end_time = uv.hrtime()
      local end_mem = collectgarbage('count')
      
      local duration = (end_time - start_time) / 1e6 -- ms
      local memory_used = end_mem - start_mem -- KB
      
      total_time = total_time + duration
      total_memory = total_memory + memory_used
      
      print(string.format("  Iteration %d: %.2fms, Memory: %.2fKB", 
        i, duration, memory_used))
    end
    
    -- Calculate averages
    local avg_time = total_time / TEST_ITERATIONS
    local avg_memory = total_memory / TEST_ITERATIONS
    
    print(string.format("  Average: %.2fms, Memory: %.2fKB", avg_time, avg_memory))
  end
  
  -- Cleanup
  os.remove(test_file)
  print("\nTest completed. Temporary file removed.")
end

-- Run tests
M.test_large_file_processing()

return M
