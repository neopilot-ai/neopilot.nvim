local uv = vim.loop or vim.uv or vim.loop
local Path = require('plenary.path')
local performance = require('neopilot.performance')

-- Test modules
local large_file_test = require('tests.performance.large_file_test')
local load_test = require('tests.performance.load_test')
local health_test = require('tests.performance.provider_health_test')

-- Output file for test results
local output_file = "neopilot_performance_report_" .. os.date("%Y%m%d_%H%M%S") .. ".md"
local report = {}

--- Append a line to the report
---@param line string
local function report_line(line)
  table.insert(report, line)
  print(line)
end

--- Save the report to a file
local function save_report()
  local file = io.open(output_file, 'w')
  if not file then
    print("Failed to save report to " .. output_file)
    return
  end
  
  file:write(table.concat(report, "\n"))
  file:close()
  print("\nReport saved to: " .. output_file)
end

--- Run a test and capture its output
---@param name string
---@param test_func function
local function run_test(name, test_func)
  report_line("# " .. name)
  report_line("")
  
  -- Redirect print to capture output
  local old_print = print
  local output = {}
  print = function(...)
    local args = {...}
    local line = table.concat(vim.tbl_map(tostring, args), "\t")
    table.insert(output, line)
    old_print(...)
  end
  
  -- Run the test
  local success, err = pcall(test_func)
  
  -- Restore print
  print = old_print
  
  -- Add test results to report
  if not success then
    report_line("❌ Test failed: " .. tostring(err))
  else
    report_line("✅ Test completed successfully")
  end
  
  report_line("")
  report_line("## Output")
  report_line("```")
  vim.list_extend(report, output)
  report_line("```")
  report_line("")
  report_line("---")
  report_line("")
  
  return success
end

-- Main function
local function main()
  -- Create reports directory if it doesn't exist
  local reports_dir = "reports"
  if not Path:new(reports_dir):exists() then
    Path:new(reports_dir):mkdir()
  end
  output_file = Path:new(reports_dir, output_file).filename
  
  -- Start the report
  report_line("# Neopilot Performance Test Report")
  report_line("")
  report_line("Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
  report_line("Neovim Version: " .. vim.fn.execute("version"):match("v[%d.]+[%d]"))
  report_line("")
  
  -- Run tests
  local tests = {
    ["Large File Processing"] = large_file_test.test_large_file_processing,
    ["Load Testing"] = load_test.run_load_test,
    ["Provider Health Monitoring"] = health_test.run_health_monitoring,
  }
  
  local all_passed = true
  for name, test_func in pairs(tests) do
    report_line("## Running Test: " .. name)
    report_line("")
    
    local success = run_test(name, test_func)
    if not success then
      all_passed = false
      report_line("❌ Test failed: " .. name)
    else
      report_line("✅ Test passed: " .. name)
    end
    
    report_line("")
  end
  
  -- Add summary
  report_line("# Test Summary")
  report_line("")
  if all_passed then
    report_line("✅ All tests completed successfully!")
  else
    report_line("❌ Some tests failed. See above for details.")
  end
  
  -- Save the report
  save_report()
  
  -- Print performance metrics
  local metrics = performance.get_metrics()
  print("\nPerformance Metrics:")
  print("-" * 30)
  print(string.format("Peak memory usage: %.2fMB", metrics.memory.peak))
  print(string.format("Total requests: %d", #metrics.requests))
  
  -- Calculate success rate
  local success_count = 0
  for _, req in ipairs(metrics.requests) do
    if req.status == 'completed' then
      success_count = success_count + 1
    end
  end
  
  print(string.format("Success rate: %.1f%%", (success_count / #metrics.requests) * 100))
  
  -- Open the report in the default markdown viewer
  if vim.fn.has('mac') == 1 then
    os.execute("open " .. output_file)
  elseif vim.fn.has('unix') == 1 then
    os.execute("xdg-open " .. output_file)
  end
end

-- Run the tests
main()
